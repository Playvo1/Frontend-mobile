import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';

/// Counts down before "resend code" becomes tappable, then restarts once
/// tapped. Uses a cancellable [Timer] so nothing keeps ticking after the
/// screen is gone.
class ResendCountdown extends StatefulWidget {
  const ResendCountdown({
    super.key,
    required this.onResend,
    this.cooldown = AppConfig.resendCooldown,
  });

  final VoidCallback onResend;
  final Duration cooldown;

  @override
  State<ResendCountdown> createState() => _ResendCountdownState();
}

class _ResendCountdownState extends State<ResendCountdown> {
  Timer? _timer;
  late int _secondsLeft = widget.cooldown.inSeconds;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() => _secondsLeft = widget.cooldown.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  void _handleResend() {
    widget.onResend();
    _start();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    if (_secondsLeft > 0) {
      final String minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
      final String seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
      return Text(
        l10n.resendIn('$minutes:$seconds'),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }

    return TextButton(
      onPressed: _handleResend,
      child: Text(
        l10n.resendNow,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: AppColors.navy900, fontWeight: FontWeight.w700),
      ),
    );
  }
}
