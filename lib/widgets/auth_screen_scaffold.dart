import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'language_selector.dart';
import 'playvo_logo.dart';

/// The frame every auth screen shares: language switcher in the top outer
/// corner, logo, title, subtitle, then the screen's own content. Written
/// once here so five screens do not repeat the same twenty lines of layout.
class AuthScreenScaffold extends StatelessWidget {
  const AuthScreenScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.formKey,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  /// When provided, [children] are wrapped in a Form with this key.
  final GlobalKey<FormState>? formKey;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Align(
          alignment: AlignmentDirectional.topEnd,
          child: LanguageSelector(),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Center(child: PlayvoLogo()),
        const SizedBox(height: AppSpacing.xxl),
        Text(title, textAlign: TextAlign.center, style: textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center, style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xxl),
        ...children,
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.screenVertical,
          ),
          child: formKey == null ? body : Form(key: formKey, child: body),
        ),
      ),
    );
  }
}
