/// One answer from `POST /assistant/query`.
///
/// The endpoint does more than return a sentence: it parses the question
/// into a sport, a date and an hour, may point at a venue, and may offer
/// options to pick from. Picking one sends `option_id` back instead of
/// another sentence, which is why [options] carries ids.
class AssistantReply {
  const AssistantReply({
    required this.text,
    this.options = const <AssistantOption>[],
    this.suggestions = const <String>[],
    this.queryId,
    this.conversationId,
    this.suggestedVenueId,
    this.intent,
  });

  /// What the assistant said, from `reply_text`.
  final String text;

  /// Choices the player can tap instead of typing.
  final List<AssistantOption> options;

  /// Follow-up questions offered as plain text.
  final List<String> suggestions;

  /// `assistant_query_id` — what `POST /assistant/feedback` refers to.
  final int? queryId;

  /// Ties follow-up questions to the same thread.
  final int? conversationId;

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
      conversationId: _toInt(json['conversation_id']),
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

  /// Tolerant of the shape: a list of strings, or of objects keyed by any
  /// of the usual id and label names.
  static List<AssistantOption> _options(dynamic raw) {
    if (raw is! List) {
      return const <AssistantOption>[];
    }
    final List<AssistantOption> parsed = <AssistantOption>[];
    for (final dynamic entry in raw) {
      if (entry is Map<String, dynamic>) {
        final int? id = _toInt(
          entry['option_id'] ?? entry['id'] ?? entry['value'],
        );
        final String label = (entry['label'] ??
                entry['title'] ??
                entry['text'] ??
                entry['name'] ??
                '')
            .toString()
            .trim();
        if (id != null && label.isNotEmpty) {
          parsed.add(AssistantOption(id: id, label: label));
        }
      }
    }
    return parsed;
  }

  static List<String> _suggestions(dynamic raw) {
    if (raw is! List) {
      return const <String>[];
    }
    return raw
        .map((dynamic s) {
          if (s is String) {
            return s.trim();
          }
          if (s is Map<String, dynamic>) {
            return (s['label'] ?? s['text'] ?? s['title'] ?? '')
                .toString()
                .trim();
          }
          return '';
        })
        .where((String s) => s.isNotEmpty)
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
}

/// A choice the assistant offered, sent back as `option_id`.
class AssistantOption {
  const AssistantOption({required this.id, required this.label});

  final int id;
  final String label;
}
