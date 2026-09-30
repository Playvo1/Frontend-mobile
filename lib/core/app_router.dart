import 'package:flutter/material.dart';

import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/reset_success_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../models/booking.dart';
import '../models/time_slot.dart';
import '../models/venue.dart';
import '../models/venue_filters.dart';
import '../screens/booking/booking_details_screen.dart';
import '../screens/booking/payment_proof_screen.dart';
import '../screens/home_screen.dart';
import '../widgets/app_bottom_nav.dart';
import '../l10n/l10n.dart';
import '../models/user.dart';
import '../screens/account/account_screen.dart';
import '../screens/account/edit_profile_screen.dart';
import '../screens/assistant/assistant_screen.dart';
import '../screens/booking/booking_confirmation_screen.dart';
import '../screens/offline_screen.dart';
import '../screens/rating/rating_screen.dart';
import '../screens/bookings/my_bookings_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/venues/venue_details_screen.dart';
import '../screens/venues/venue_map_screen.dart';
import '../screens/venues/venue_search_screen.dart';

/// Every navigation in the app goes through one of these methods.
///
/// Named routes were dropped deliberately: half the screens need typed
/// arguments (the OTP screen needs a purpose and an email, the reset screen
/// needs an email and a code), and a route table passes those as
/// `Object?` that each screen then casts. Constructors give the compiler
/// the chance to catch a missing argument instead. Deep links are not a
/// requirement yet (YAGNI, Guidelines 2.1); when they are, this class is
/// the one place that changes.
class AppRouter {
  AppRouter._();

  /// Clears the whole stack — used after logout, after email verification,
  /// and after a password reset, so Back cannot return into a finished flow.
  static Future<void> toLoginAndClearStack(BuildContext context) {
    return Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  static Future<void> toHomeAndClearStack(BuildContext context) {
    return Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  static Future<void> toSignup(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SignupScreen()),
    );
  }

  static Future<void> toForgotPassword(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  static Future<void> toOtpVerification(
    BuildContext context, {
    required OtpPurpose purpose,
    required String email,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OtpVerificationScreen(purpose: purpose, email: email),
      ),
    );
  }

  /// The email and the verified code are carried in, because
  /// `POST /auth/reset-password` needs all three of email, code and the new
  /// password in one request (Guidelines 7.2).
 static Future<void> toResetPassword(
  BuildContext context, {
  required String email,
}) {
  return Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => ResetPasswordScreen(email: email),
    ),
  );
}

  /// Shown once the password has actually been changed. The stack is
  /// cleared so Back cannot return into the spent reset flow.
  static Future<void> toResetSuccess(BuildContext context) {
    return Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ResetSuccessScreen()),
      (Route<dynamic> route) => false,
    );
  }

  static Future<void> toVenueSearch(
    BuildContext context, {
    required VenueFilters filters,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VenueSearchScreen(initialFilters: filters),
      ),
    );
  }

  static Future<void> toVenueDetails(BuildContext context, int venueId) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VenueDetailsScreen(venueId: venueId),
      ),
    );
  }

  /// Step 1 of the booking. The slot travels as an object rather than an
  /// id, because both booking screens display its time and price.
  static Future<void> toBookingDetails(
    BuildContext context, {
    required Venue venue,
    required TimeSlot slot,
    required DateTime date,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            BookingDetailsScreen(venue: venue, slot: slot, date: date),
      ),
    );
  }

  /// Step 2. Uses pushReplacement so Back cannot resubmit step 1 and
  /// create a second booking for the same slot.
  static Future<void> toPaymentProof(
    BuildContext context, {
    required Booking booking,
    required Venue venue,
    required TimeSlot slot,
    required DateTime date,
  }) {
    return Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PaymentProofScreen(
          booking: booking,
          venue: venue,
          slot: slot,
          date: date,
        ),
      ),
    );
  }

  static Future<void> toVenueMap(
    BuildContext context, {
    required VenueFilters filters,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VenueMapScreen(filters: filters),
      ),
    );
  }

  /// Step 3. Replaces step 2 so Back cannot re-upload the receipt.
  static Future<void> toBookingConfirmation(
    BuildContext context, {
    required Booking booking,
    required Venue venue,
    required TimeSlot slot,
    required DateTime date,
  }) {
    return Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BookingConfirmationScreen(
          booking: booking,
          venue: venue,
          slot: slot,
          date: date,
        ),
      ),
    );
  }

  /// Moves between the four tabs of the bottom bar. Each tab becomes the
  /// root of the stack, so switching tabs never stacks screens forever.
  static Future<void> switchTab(BuildContext context, AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return toHomeAndClearStack(context);
      case AppTab.bookings:
        return _replaceRoot(context, const MyBookingsScreen());
      case AppTab.favorites:
        return _replaceRoot(context, const FavoritesScreen());
      case AppTab.account:
        return _replaceRoot(context, const AccountScreen());
    }
  }

  static Future<void> _replaceRoot(BuildContext context, Widget screen) {
    return Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => screen),
      (Route<dynamic> route) => false,
    );
  }

  static Future<void> toEditProfile(BuildContext context, User? user) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EditProfileScreen(user: user)),
    );
  }

  static Future<void> toAssistant(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AssistantScreen()),
    );
  }

  static Future<void> toRating(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RatingScreen()),
    );
  }

  /// Opens the offline explainer. [onRetry] runs after it closes, so the
  /// screen that opened it refetches rather than staying stale.
  static Future<void> toOfflineScreen(
    BuildContext context, {
    required Future<void> Function() onRetry,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext screenContext) => OfflineScreen(
          onContinueOffline: () => Navigator.of(screenContext).pop(),
          onRetry: () {
            Navigator.of(screenContext).pop();
            onRetry();
          },
        ),
      ),
    );
  }
}
