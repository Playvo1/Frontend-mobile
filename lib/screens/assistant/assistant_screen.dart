import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/app_illustration.dart';

/// One line of the conversation.
class AssistantMessage {
  const AssistantMessage({required this.text, required this.isFromPlayer});

  final String text;
  final bool isFromPlayer;
}

/// "المساعد الذكي" — a chat where the player can ask about pitches and
/// bookings, with example questions to start from.
///
/// TODO(api): there is no assistant endpoint yet, so replies are not
/// generated — sending a message only adds it to the thread. Point
/// [_send] at the endpoint once the backend adds one.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<AssistantMessage> _messages = <AssistantMessage>[];

  /// Drawn as the three-dot bubble while a reply is on its way.
  bool _isAssistantTyping = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    setState(() {
      _messages.add(AssistantMessage(text: trimmed, isFromPlayer: true));
      _inputController.clear();
      _isAssistantTyping = true;
    });
    _scrollToEnd();

    // TODO(api): there is no assistant endpoint yet. The indicator shows
    // that a reply is expected and then clears; replace this delay with
    // the call once the backend adds one.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isAssistantTyping = false);
    }
  }

  /// Jumps to the newest message after the frame that adds it.
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    final List<_Suggestion> suggestions = <_Suggestion>[
      _Suggestion(Icons.location_on_outlined, l10n.assistantQ1),
      _Suggestion(Icons.calendar_today_outlined, l10n.assistantQ2),
      _Suggestion(Icons.search, l10n.assistantQ3),
      _Suggestion(Icons.payments_outlined, l10n.assistantQ4),
      _Suggestion(Icons.schedule, l10n.assistantQ5),
      _Suggestion(Icons.verified_outlined, l10n.assistantQ6),
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: AppScreenHeader(
                title: l10n.assistantTitle,
                subtitle: l10n.assistantSubtitle,
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const _AssistantMascot(),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _Bubble(
                          text: l10n.assistantGreeting,
                          isFromPlayer: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.assistantExamples,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    // Three across, two rows — as the design lays them out.
                    crossAxisCount: 3,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.05,
                    children: suggestions
                        .map(
                          (_Suggestion s) => _SuggestionCard(
                            suggestion: s,
                            onTap: () => _send(s.label),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Bubble(text: l10n.assistantSampleUser, isFromPlayer: true),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '9:41',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(fontSize: 10),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check,
                        size: 13,
                        color: AppColors.successAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Bubble(text: l10n.assistantSampleReply, isFromPlayer: false),
                  const SizedBox(height: AppSpacing.sm),
                  _QuickReplies(
                    labels: <String>[
                      l10n.assistantOptionCurrent,
                      l10n.assistantOptionArea,
                      l10n.assistantOptionAll,
                    ],
                    onSelected: _send,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ..._messages.map(
                    (AssistantMessage message) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _Bubble(
                        text: message.text,
                        isFromPlayer: message.isFromPlayer,
                      ),
                    ),
                  ),
                  if (_isAssistantTyping) const _TypingBubble(),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
            _InputBar(
              controller: _inputController,
              onSend: () => _send(_inputController.text),
            ),
          ],
        ),
      ),
    );
  }
}

/// A question the player can tap instead of typing.
class _Suggestion {
  const _Suggestion(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// One suggestion tile.
class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion, required this.onTap});

  final _Suggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.sm + 2),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.sm + 2),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppColors.navy50,
                shape: BoxShape.circle,
              ),
              child: Icon(suggestion.icon, size: 15, color: AppColors.navy500),
            ),
            Text(
              suggestion.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.navy900, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// A chat bubble: navy for the player, light for the assistant.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.isFromPlayer});

  final String text;
  final bool isFromPlayer;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isFromPlayer
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: isFromPlayer ? AppColors.navy900 : AppColors.navy50,
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isFromPlayer ? AppColors.white : AppColors.navy900,
                fontSize: 12,
                height: 1.7,
              ),
        ),
      ),
    );
  }
}

/// The waving robot from the design.
class _AssistantMascot extends StatelessWidget {
  const _AssistantMascot();

  @override
  Widget build(BuildContext context) {
    return const AppIllustration(
      asset: AppIllustration.assistantRobot,
      height: 130,
    );
  }
}

/// The message box pinned to the bottom.
class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
        AppSpacing.screenHorizontal,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.fieldBorder)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: context.l10n.assistantInputHint,
                suffixIcon: const Icon(
                  Icons.attach_file,
                  size: 19,
                  color: AppColors.navy300,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          InkWell(
            onTap: onSend,
            customBorder: const CircleBorder(),
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: AppColors.navy900,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, size: 19, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// The chips the assistant offers after a question, so the player can
/// answer with a tap instead of typing.
class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.labels, required this.onSelected});

  final List<String> labels;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: labels
          .map(
            (String label) => InkWell(
              onTap: () => onSelected(label),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  border: Border.all(color: AppColors.successAccent),
                ),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.navy900,
                        fontSize: 12,
                      ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

/// The three-dot bubble shown while the assistant is composing a reply.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      // The dots carry no text, so the meaning is given to assistive
      // technology explicitly.
      child: Semantics(
        label: context.l10n.assistantTyping,
        child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.navy50,
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (BuildContext context, Widget? child) {
                    // Each dot lags the one before it, so the row reads as
                    // a wave rather than a blink.
                    final double phase = (_controller.value - i * 0.2) % 1.0;
                    final double lift = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
                    return Opacity(
                      opacity: 0.35 + lift * 0.65,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.navy500,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }
}
