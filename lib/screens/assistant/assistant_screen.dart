import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_button.dart';

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

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    setState(() {
      _messages.add(AssistantMessage(text: trimmed, isFromPlayer: true));
      _inputController.clear();
    });
    // Jump to the newest message after the frame that adds it.
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
                centerTitle: true,
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                children: <Widget>[
                  const Center(child: _AssistantMascot()),
                  const SizedBox(height: AppSpacing.md),
                  _Bubble(
                    text: l10n.assistantGreeting,
                    isFromPlayer: false,
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
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.9,
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
                  ..._messages.map(
                    (AssistantMessage message) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _Bubble(
                        text: message.text,
                        isFromPlayer: message.isFromPlayer,
                      ),
                    ),
                  ),
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

/// The circular assistant mark above the greeting.
class _AssistantMascot extends StatelessWidget {
  const _AssistantMascot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: AppColors.successAccent,
        borderRadius: BorderRadius.circular(32),
      ),
      child: const Icon(
        Icons.smart_toy_outlined,
        size: 52,
        color: AppColors.white,
      ),
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
