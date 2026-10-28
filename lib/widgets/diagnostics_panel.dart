import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/diagnostics.dart';

/// A collapsed strip that opens to show what the server answered.
///
/// Shown in debug builds only, so it cannot appear for a player. It exists
/// so a problem can be reported with a screenshot instead of a console
/// transcript.
class DiagnosticsPanel extends StatefulWidget {
  const DiagnosticsPanel({super.key});

  @override
  State<DiagnosticsPanel> createState() => _DiagnosticsPanelState();
}

class _DiagnosticsPanelState extends State<DiagnosticsPanel> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<List<String>>(
      valueListenable: Diagnostics.lines,
      builder: (BuildContext context, List<String> lines, _) {
        if (lines.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF08101C),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1D3A58)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              InkWell(
                onTap: () => setState(() => _isOpen = !_isOpen),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.bug_report_outlined,
                        size: 16,
                        color: Color(0xFFFC4B01),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تشخيص (${lines.length}) — اضغط للعرض',
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            color: Color(0xFFA9BBD0),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        _isOpen ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: const Color(0xFF7E96AC),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isOpen) ...<Widget>[
                const Divider(height: 1, color: Color(0xFF1D3A58)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: SelectableText(
                    lines.join('\n'),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: Color(0xFFE4EAF2),
                      fontSize: 11,
                      height: 1.6,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: lines.join('\n')),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم النسخ')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text('نسخ', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFA9BBD0),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
