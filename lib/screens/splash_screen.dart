import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../core/app_router.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/playvo_logo.dart';

/// First screen shown on launch. While the logo is on screen it decides
/// where to go: a stored token that `/auth/me` still accepts means the
/// player is signed in, anything else means the login screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.authService});

  /// Injectable so the decision can be unit tested without a real backend.
  final AuthService? authService;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Minimum time the logo stays visible, so a fast decision does not make
  /// the splash flash for a single frame.
  static const Duration _minimumDisplay = Duration(milliseconds: 1200);

  late final AuthService _authService = widget.authService ?? AuthService();

  @override
  void initState() {
    super.initState();
    _resolveStartScreen();
  }

  Future<void> _resolveStartScreen() async {
    final Future<void> minimumWait = Future<void>.delayed(_minimumDisplay);
    final bool isSignedIn = await _hasValidSession();
    await minimumWait;

    if (!mounted) {
      return;
    }
    if (isSignedIn) {
      await AppRouter.toHomeAndClearStack(context);
    } else {
      await AppRouter.toLoginAndClearStack(context);
    }
  }

  Future<bool> _hasValidSession() async {
    if (!await _authService.hasStoredToken()) {
      return false;
    }
    try {
      final bool valid = (await _authService.me()).success;
      return valid;
    } on ApiException {
      // Offline or server trouble on launch is not a reason to claim the
      // token is invalid, but we cannot open the app on unverified state
      // either, so we fall back to login.
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: <Widget>[
          Positioned(top: -70, left: -70, child: _ArcRing()),
          Positioned(bottom: -70, right: -70, child: _ArcRing()),
          Center(child: PlayvoLogo(markHeight: 130, wordmarkSize: 30)),
        ],
      ),
    );
  }
}

/// The decorative corner ring from the splash design.
class _ArcRing extends StatelessWidget {
  const _ArcRing();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.navy50, width: 26),
      ),
    );
  }
}
