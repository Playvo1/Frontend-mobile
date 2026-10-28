import 'package:flutter/foundation.dart';

/// A short, on-screen log of what the server actually answered.
///
/// The console already carries this, but a console line is awkward to read
/// off a phone and awkward to pass on. These lines surface in the app
/// itself (see `DiagnosticsPanel`), so a screenshot carries the whole
/// diagnosis.
///
/// Debug builds only: [add] is a no-op in release, so nothing here reaches
/// a player, and the panel that shows it is likewise hidden.
class Diagnostics {
  Diagnostics._();

  /// The most recent lines, newest last.
  static final ValueNotifier<List<String>> lines =
      ValueNotifier<List<String>>(<String>[]);

  static const int _maxLines = 14;

  static void add(String line) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(line);
    final List<String> next = <String>[...lines.value, line];
    lines.value = next.length > _maxLines
        ? next.sublist(next.length - _maxLines)
        : next;
  }

  static void clear() => lines.value = <String>[];
}
