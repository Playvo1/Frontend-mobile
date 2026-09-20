import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_config.dart';
import '../theme/app_spacing.dart';

/// Separate boxes for entering a verification code, matching the
/// "تحقق من حسابك" design. Digits only; focus moves forward on entry and
/// backward on delete. Always laid out left-to-right, because a numeric
/// code is not read right-to-left in Arabic either.
class OtpBoxInput extends StatefulWidget {
  const OtpBoxInput({
    super.key,
    required this.onChanged,
    this.length = AppConfig.verificationCodeLength,
  });

  final ValueChanged<String> onChanged;
  final int length;

  @override
  State<OtpBoxInput> createState() => _OtpBoxInputState();
}

class _OtpBoxInputState extends State<OtpBoxInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List<TextEditingController>.generate(
      widget.length,
      (_) => TextEditingController(),
    );
    _focusNodes = List<FocusNode>.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers) {
      controller.dispose();
    }
    for (final FocusNode node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleChanged(int index, String value) {
    // A paste lands entirely in one box; spread it across the remaining ones.
    if (value.length > 1) {
      _distribute(value, from: index);
      return;
    }

    widget.onChanged(_currentCode());

    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _distribute(String pasted, {required int from}) {
    final String digits = pasted.replaceAll(RegExp(r'\D'), '');
    for (int i = 0; i < widget.length - from; i++) {
      _controllers[from + i].text = i < digits.length ? digits[i] : '';
    }
    final int lastFilled =
        (from + digits.length - 1).clamp(0, widget.length - 1);
    _focusNodes[lastFilled].requestFocus();
    widget.onChanged(_currentCode());
  }

  String _currentCode() =>
      _controllers.map((TextEditingController c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List<Widget>.generate(widget.length, _buildBox),
      ),
    );
  }

  Widget _buildBox(int index) {
    return SizedBox(
      width: AppSpacing.otpBoxWidth,
      height: AppSpacing.otpBoxHeight,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        autofillHints: index == 0
            ? const <String>[AutofillHints.oneTimeCode]
            : null,
        maxLength: 1,
        // Enforcement is off so a pasted code arrives whole in onChanged and
        // can be spread across the boxes; _distribute keeps one digit each.
        maxLengthEnforcement: MaxLengthEnforcement.none,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        decoration: const InputDecoration(counterText: ''),
        onChanged: (String value) => _handleChanged(index, value),
      ),
    );
  }
}
