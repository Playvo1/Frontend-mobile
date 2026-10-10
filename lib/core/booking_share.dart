import 'package:share_plus/share_plus.dart';

import '../l10n/l10n.dart';
import '../models/booking.dart';

/// Opens the system share sheet for a booking (SRS FR-15).
class BookingShare {
  BookingShare._();

  /// The public page that renders a shared booking for someone without the
  /// app. The backend serves the data at `GET /bookings/share/{token}`, but
  /// no web page consumes it yet — that page belongs to the web team.
  ///
  /// Leave this empty and the share goes out as text alone, which is
  /// better than a link that opens raw JSON. Fill it in and every share
  /// gains the link, with no other change.
  static const String publicBase = '';

  static bool get hasPublicPage => publicBase.isNotEmpty;

  /// Null when there is nowhere public to point at.
  static String? linkFor(Booking booking) {
    final String? token = booking.shareToken;
    if (!hasPublicPage || token == null || token.isEmpty) {
      return null;
    }
    return '$publicBase/$token';
  }

  /// Always shares something: the match details, plus the link when one
  /// exists. Returns false only when there is no booking worth describing.
  static Future<bool> share(Booking booking, AppLocalizations l10n) async {
    final String? venue = booking.venue?.name;
    if (venue == null || venue.isEmpty) {
      return false;
    }

    final DateTime date = booking.date ?? DateTime.now();
    final String message = l10n.shareBookingText(
      venue,
      '${date.day}/${date.month}/${date.year}',
      booking.slot?.range ?? '',
    );

    final String? link = linkFor(booking);
    final String body = link == null
        ? '$message\n${l10n.bookingNumber}: ${booking.reference}'
        : '$message\n\n$link';

    await Share.share(body);
    return true;
  }
}
