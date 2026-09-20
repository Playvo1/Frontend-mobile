import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../core/app_router.dart';
import '../l10n/l10n.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/playvo_logo.dart';
import '../widgets/primary_button.dart';

/// Placeholder landing screen for a signed-in player. It exists so the
/// launch and logout paths are complete and testable; the real home screen
/// (venue search, bookings) replaces it.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AuthService _authService = widget.authService ?? AuthService();

  User? _user;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final User? user = (await _authService.me()).data;
      if (mounted) {
        setState(() => _user = user);
      }
    } on ApiException {
      // The profile is decorative on this placeholder; a failure here must
      // not block the screen.
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    try {
      await _authService.logout();
    } on ApiException {
      // The token is cleared locally either way (see AuthService.logout).
    }
    if (!mounted) {
      return;
    }
    setState(() => _isLoggingOut = false);
    await AppRouter.toLoginAndClearStack(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const PlayvoLogo(),
              const SizedBox(height: AppSpacing.xl),
              Text(
                _user?.name ?? '',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              PrimaryButton(
                label: context.l10n.logout,
                isLoading: _isLoggingOut,
                onPressed: _handleLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
