import '../core/locale_controller.dart';

/// One answer from `POST /assistant/query`.
///
/// The endpoint does more than return a sentence: it parses the question
/// into a sport, a date and an hour, offers [options] to narrow the search,
/// and returns [suggestions] — concrete venue-and-hour pairs the player can
/// book straight away.
class AssistantReply {
  const AssistantReply({
    required this.text,
    this.options = const <AssistantOption>[],
    this.suggestions = const <AssistantSuggestion>[],
    this.queryId,
    this.conversationId,
    this.suggestedVenueId,
    this.intent,
  });

  /// What the assistant said, from `reply_text`.
  final String text;

  /// Choices the player can tap instead of typing, such as `cheapest` or
  /// `use_location`.
  final List<AssistantOption> options;

  /// Bookable venue-and-hour pairs, shown as cards under the reply.
  final List<AssistantSuggestion> suggestions;

  /// `assistant_query_id` — what `POST /assistant/feedback` refers to.
  final int? queryId;

  /// Ties follow-up questions to the same thread. A string, not a number:
  /// the backend sends an opaque identifier, and parsing it as an int
  /// dropped it, which is why the assistant forgot the previous question.
  final String? conversationId;

  /// A venue the assistant thinks answers the question.
  final int? suggestedVenueId;

  /// What the backend understood the question to be.
  final String? intent;

  bool get hasText => text.trim().isNotEmpty;

  factory AssistantReply.fromJson(Map<String, dynamic> json) {
    return AssistantReply(
      text: _firstText(json),
      options: _options(json['options']),
      suggestions: _suggestions(json['suggestions']),
      queryId: _toInt(json['assistant_query_id']),
      conversationId: _toStringOrNull(json['conversation_id']),
      suggestedVenueId: _toInt(json['suggested_venue_id']),
      intent: json['intent']?.toString(),
    );
  }

  /// `reply_text` is what this backend sends. The others are accepted so a
  /// rename does not silence the assistant again.
  static String _firstText(Map<String, dynamic> json) {
    for (final String key in const <String>[
      'reply_text',
      'reply',
      'answer',
      'response_text',
      'response',
      'message',
      'text',
      'content',
    ]) {
      final dynamic value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  static List<AssistantOption> _options(dynamic raw) {
    if (raw is! List) {
      return const <AssistantOption>[];
    }
    final List<AssistantOption> parsed = <AssistantOption>[];
    for (final dynamic entry in raw) {
      if (entry is Map<String, dynamic>) {
        final String id = (entry['option_id'] ?? entry['id'] ?? entry['value'] ?? '')
            .toString()
            .trim();
        final String label = (entry['label'] ??
                entry['title'] ??
                entry['text'] ??
                entry['name'] ??
                '')
            .toString()
            .trim();
        if (id.isNotEmpty && label.isNotEmpty) {
          parsed.add(AssistantOption(id: id, label: label));
        }
      }
    }
    return parsed;
  }

  static List<AssistantSuggestion> _suggestions(dynamic raw) {
    if (raw is! List) {
      return const <AssistantSuggestion>[];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AssistantSuggestion.fromJson)
        .where((AssistantSuggestion s) => s.venueId != null)
        .toList();
  }

  static int? _toInt(dynamic raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.round();
    }
    return int.tryParse(raw?.toString() ?? '');
  }

  static String? _toStringOrNull(dynamic raw) {
    final String value = (raw ?? '').toString().trim();
    return value.isEmpty ? null : value;
  }
}

/// A choice the assistant offered, sent back as `option_id`.
///
/// The id is a string — the backend uses names like `cheapest`,
/// `all_venues`, `city_3` and `use_location`, not numbers.
class AssistantOption {
  const AssistantOption({required this.id, required this.label});

  final String id;
  final String label;

  /// The one option that needs the player's coordinates sent with it.
  bool get needsLocation => id == 'use_location';
}

/// A venue and a specific free hour, offered as a card the player can tap
/// straight through to booking.
class AssistantSuggestion {
  const AssistantSuggestion({
    this.venueId,
    this.timeSlotId,
    this.nameAr,
    this.nameEn,
    this.areaAr,
    this.areaEn,
    this.date,
    this.startTime,
    this.endTime,
    this.price,
    this.rating,
  });

  final int? venueId;
  final int? timeSlotId;
  final String? nameAr;
  final String? nameEn;
  final String? areaAr;
  final String? areaEn;

  /// "2026-11-04", as the server stores it.
  final String? date;

  /// "18:00", trimmed of seconds.
  final String? startTime;
  final String? endTime;

  final int? price;
  final double? rating;

  /// The venue name in the language being read, falling back to the other
  /// one so a missing translation never blanks the card.
  String get name => _localised(nameAr, nameEn);

  String get area => _localised(areaAr, areaEn);

  /// "18:00 - 19:00".
  String? get timeRange {
    if (startTime == null || endTime == null) {
      return null;
    }
    return '$startTime - $endTime';
  }

  /// The day as a [DateTime], for opening the venue on the right date.
  DateTime? get day => date == null ? null : DateTime.tryParse(date!);

  factory AssistantSuggestion.fromJson(Map<String, dynamic> json) {
    return AssistantSuggestion(
      venueId: AssistantReply._toInt(json['venue_id']),
      timeSlotId: AssistantReply._toInt(json['time_slot_id']),
      nameAr: _text(json['name_ar']),
      nameEn: _text(json['name_en']),
      areaAr: _text(json['area_ar']),
      areaEn: _text(json['area_en']),
      date: _text(json['date'])?.split('T').first,
      startTime: _hhmm(_text(json['start_time'])),
      endTime: _hhmm(_text(json['end_time'])),
      // Decimal columns arrive as strings ("85.00").
      price: _money(json['price'] ?? json['hourly_price']),
      rating: _toDouble(json['rating'] ?? json['avg_rating']),
    );
  }

  static String _localised(String? ar, String? en) {
    final bool isArabic = LocaleController.locale.value.languageCode == 'ar';
    final String? preferred = isArabic ? ar : en;
    return (preferred?.trim().isNotEmpty == true
            ? preferred!
            : (ar ?? en ?? ''))
        .trim();
  }

  static String? _text(dynamic raw) {
    final String value = (raw ?? '').toString().trim();
    return value.isEmpty ? null : value;
  }

  /// Trims "18:00:00" to "18:00".
  static String? _hhmm(String? raw) {
    if (raw == null) {
      return null;
    }
    return raw.length >= 5 ? raw.substring(0, 5) : raw;
  }

  static int? _money(dynamic raw) {
    if (raw is num) {
      return raw.round();
    }
    return double.tryParse(raw?.toString() ?? '')?.round();
  }

  static double? _toDouble(dynamic raw) {
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw?.toString() ?? '');
  }
}
