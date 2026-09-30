import 'package:flutter/material.dart';

import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/reset_success_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home_screen.dart';
import '../screens/offline_screen.dart';
import '../models/booking.dart';
import '../models/time_slot.dart';
import '../models/venue.dart';
import '../models/venue_filters.dart';
import '../screens/booking/booking_details_screen.dart';
import '../screens/booking/booking_confirmation_screen.dart';
import '../screens/booking/payment_proof_screen.dart';
import '../screens/account/account_screen.dart';
import '../screens/account/edit_profile_screen.dart';
import '../screens/assistant/assistant_screen.dart';
import '../screens/bookings/my_bookings_screen.dart';
import '../screens/rating/rating_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/venues/venue_details_screen.dart';
import '../screens/venues/venue_map_screen.dart';
import '../screens/venues/venue_search_screen.dart';
import '../services/mock_booking_service.dart';
import '../services/mock_venue_service.dart';
import '../screens/splash_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/language_selector.dart';
import 'preview_auth_service.dart';

/// A menu that opens every screen and every screen state directly, so the
/// team can review the UI without walking the flows or running a backend.
///
/// DEV ONLY. It is reachable only when the app is built with
/// `--dart-define=PLAYVO_GALLERY=true`, so it can never appear in a release
/// build, and `lib/dev/` is deleted once the real API is connected.
class ScreenGallery extends StatelessWidget {
  const ScreenGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen gallery'),
        backgroundColor: AppColors.navy900,
        foregroundColor: AppColors.white,
        actions: const <Widget>[
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.sm),
            child: Center(child: LanguageSelector()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: <Widget>[
          const _SectionHeader('Login'),
          _GalleryEntry(
            title: 'Login — default',
            subtitle: 'The plain form, state 1 in the design',
            builder: (_) => const LoginScreen(),
          ),
          _GalleryEntry(
            title: 'Login — wrong credentials',
            subtitle: 'Type anything and press the button. State 2: red field, '
                '4 attempts remaining',
            builder: (_) =>
                LoginScreen(authService: PreviewAuthService.wrongCredentials),
          ),
          _GalleryEntry(
            title: 'Login — locked account',
            subtitle: 'Type anything and press the button. State 3: everything '
                'disabled, 15:00 counting down',
            builder: (_) =>
                LoginScreen(authService: PreviewAuthService.lockedAccount),
          ),

          const _SectionHeader('Registration'),
          _GalleryEntry(
            title: 'Signup',
            builder: (_) =>
                SignupScreen(authService: PreviewAuthService.alwaysOk),
          ),
          _GalleryEntry(
            title: 'OTP — email verification',
            subtitle: 'Verify button',
            builder: (_) => OtpVerificationScreen(
              purpose: OtpPurpose.signupVerification,
              email: 'omar@example.com',
              authService: PreviewAuthService.alwaysOk,
            ),
          ),

          const _SectionHeader('Password reset'),
          _GalleryEntry(
            title: 'Forgot password',
            builder: (_) =>
                ForgotPasswordScreen(authService: PreviewAuthService.alwaysOk),
          ),
          _GalleryEntry(
            title: 'OTP — password reset',
            subtitle: 'Continue button; carries the code forward',
            builder: (_) => OtpVerificationScreen(
              purpose: OtpPurpose.passwordReset,
              email: 'omar@example.com',
              authService: PreviewAuthService.alwaysOk,
            ),
          ),
          _GalleryEntry(
            title: 'Reset password',
            builder: (_) => ResetPasswordScreen(
              email: 'omar@example.com',
              // code: '482913',
              authService: PreviewAuthService.alwaysOk,
            ),
          ),

          _GalleryEntry(
            title: 'Reset password — success',
            subtitle: 'Shown after the password is actually changed',
            builder: (_) => const ResetSuccessScreen(),
          ),

          const _SectionHeader('Home'),
          _GalleryEntry(
            title: 'Home',
            subtitle: 'Sample venues; the filter icon opens the filter sheet',
            builder: (_) => HomeScreen(venueService: MockVenueService()),
          ),

          const _SectionHeader('Booking'),
          _GalleryEntry(
            title: 'Search results',
            subtitle: 'Filter chips, result count, "عرض التفاصيل" cards',
            builder: (_) => VenueSearchScreen(
              initialFilters: VenueFilters(
                city: 'غزة',
                sportType: SportType.football,
                date: DateTime.now(),
              ),
              venueService: MockVenueService(),
            ),
          ),
          _GalleryEntry(
            title: 'Venue details',
            subtitle: 'Gallery, amenities, date strip and time slots',
            builder: (_) => VenueDetailsScreen(
              venueId: 1,
              venueService: MockVenueService(),
            ),
          ),
          _GalleryEntry(
            title: 'Booking — step 1, details',
            builder: (_) => BookingDetailsScreen(
              venue: _sampleVenue,
              slot: _sampleSlot,
              date: DateTime.now(),
              bookingService: MockBookingService(),
            ),
          ),
          _GalleryEntry(
            title: 'Venue map',
            subtitle: 'Pins and the selected-venue card; the map itself '
                'needs google_maps_flutter',
            builder: (_) => VenueMapScreen(
              filters: const VenueFilters(city: 'غزة'),
              venueService: MockVenueService(),
            ),
          ),
          _GalleryEntry(
            title: 'Booking — step 2, payment proof',
            subtitle: 'Choosing a receipt needs a real device or emulator',
            builder: (_) => PaymentProofScreen(
              booking: const Booking(id: 18, status: BookingStatus.pending),
              venue: _sampleVenue,
              slot: _sampleSlot,
              date: DateTime.now(),
              bookingService: MockBookingService(),
            ),
          ),
          _GalleryEntry(
            title: 'Booking — step 3, confirmation',
            builder: (_) => BookingConfirmationScreen(
              booking: const Booking(id: 258731, status: BookingStatus.pending),
              venue: _sampleVenue,
              slot: _sampleSlot,
              date: DateTime.now(),
            ),
          ),

          const _SectionHeader('Player area'),
          _GalleryEntry(
            title: 'My bookings',
            subtitle: 'One card per status: upcoming, completed, cancelled',
            builder: (_) => MyBookingsScreen(
              bookingService: MockBookingService(),
            ),
          ),
          _GalleryEntry(
            title: 'My bookings — empty',
            builder: (_) => MyBookingsScreen(
              bookingService: EmptyBookingService(),
            ),
          ),
          _GalleryEntry(
            title: 'Favourites',
            builder: (_) => FavoritesScreen(venueService: MockVenueService()),
          ),
          _GalleryEntry(
            title: 'My account',
            builder: (_) => AccountScreen(
              bookingService: MockBookingService(),
            ),
          ),
          _GalleryEntry(
            title: 'Edit profile',
            builder: (_) => const EditProfileScreen(),
          ),
          _GalleryEntry(
            title: 'Smart assistant',
            builder: (_) => const AssistantScreen(),
          ),
          _GalleryEntry(
            title: 'Rate your experience',
            builder: (_) => const RatingScreen(),
          ),

          const _SectionHeader('Other'),
          _GalleryEntry(
            title: 'Offline',
            subtitle: 'What is cached, and the last sync time',
            builder: (BuildContext context) => OfflineScreen(
              lastSyncedLabel: 'اليوم، 10:35 ص',
              onContinueOffline: () => Navigator.of(context).pop(),
              onRetry: () => Navigator.of(context).pop(),
            ),
          ),
          _GalleryEntry(
            title: 'Splash',
            subtitle: 'Moves on by itself after about a second',
            builder: (_) => const SplashScreen(),
          ),
        ],
      ),
    );
  }
}

/// Stand-in data for the two booking steps, which normally arrive from the
/// venue page.
const Venue _sampleVenue = Venue(
  id: 1,
  name: 'ملعب الوحدة',
  city: 'غزة',
  area: 'الرمال',
  sportType: SportType.football,
  rating: 4.8,
  reviewCount: 128,
  hourlyPrice: 50,
  photos: <String>['assets/venues/venue_5.jpg'],
);

const TimeSlot _sampleSlot = TimeSlot(
  id: 101,
  startTime: '10:00',
  endTime: '11:00',
  isAvailable: true,
  price: 50,
);

/// A group label between sets of entries.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.orange500,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
      ),
    );
  }
}

/// One tappable row that pushes the screen it describes.
class _GalleryEntry extends StatelessWidget {
  const _GalleryEntry({
    required this.title,
    required this.builder,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: Theme.of(context).textTheme.labelMedium),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: Theme.of(context).textTheme.labelSmall),
      trailing: const Icon(Icons.chevron_right, color: AppColors.navy300),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: builder),
      ),
    );
  }
}
