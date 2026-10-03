import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_button.dart';

/// "تقييم تجربتك" — a star score, what the player liked, and a free note.
///
/// TODO(api): no feedback endpoint exists yet. Sending currently confirms
/// locally; point it at the endpoint once the backend adds one.
class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final TextEditingController _notesController = TextEditingController();

  int _stars = 0;
  final Set<String> _selectedTags = <String>{};

  /// The design caps the note at 500 characters and shows the count.
  static const int _notesLimit = 500;

  @override
  void initState() {
    super.initState();
    _notesController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _scoreLabel(AppLocalizations l10n) {
    switch (_stars) {
      case 1:
        return l10n.ratingBad;
      case 2:
        return l10n.ratingFair;
      case 3:
        return l10n.ratingGood;
      case 4:
        return l10n.ratingVeryGood;
      case 5:
        return l10n.ratingExcellent;
      default:
        return '';
    }
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.ratingSent)),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final List<String> tags = <String>[
      l10n.tagInfoAccuracy,
      l10n.tagVenueVariety,
      l10n.tagEasyBooking,
      l10n.tagCustomerService,
      l10n.tagPrices,
      l10n.tagAppExperience,
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          children: <Widget>[
            AppScreenHeader(title: l10n.ratingTitle, subtitle: l10n.ratingSubtitle),
            const SizedBox(height: AppSpacing.xl),
            const Center(child: _RatingMascot()),
            const SizedBox(height: AppSpacing.xl),
            _Panel(
              child: Column(
                children: <Widget>[
                  Text(
                    l10n.ratingOverall,
                    style: textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.ratingOverallHint, style: textTheme.labelSmall),
                  const SizedBox(height: AppSpacing.md),
                  // Left to right, so one star means the leftmost.
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(5, (int index) {
                        final int value = index + 1;
                        return IconButton(
                          onPressed: () => setState(() => _stars = value),
                          icon: Icon(
                            value <= _stars
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 34,
                            color: value <= _stars
                                ? AppColors.orange500
                                : AppColors.grey400,
                          ),
                        );
                      }),
                    ),
                  ),
                  if (_stars > 0)
                    Text(
                      _scoreLabel(l10n),
                      style: textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.ratingLiked,
                    style: textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.ratingLikedHint, style: textTheme.labelSmall),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: tags
                        .map(
                          (String tag) => _Tag(
                            label: tag,
                            isSelected: _selectedTags.contains(tag),
                            onTap: () => setState(() {
                              if (!_selectedTags.remove(tag)) {
                                _selectedTags.add(tag);
                              }
                            }),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.ratingNotesLabel,
                    style: textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    maxLength: _notesLimit,
                    decoration: InputDecoration(
                      hintText: l10n.ratingNotesHint,
                      counterText: '',
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      '${_notesController.text.characters.length}/$_notesLimit',
                      textDirection: TextDirection.ltr,
                      style: textTheme.labelSmall?.copyWith(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              // A rating with no stars says nothing, so it cannot be sent.
              onPressed: _stars == 0 ? null : _submit,
              child: Text(l10n.sendRating),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// The friendly mark above the rating panels.
class _RatingMascot extends StatelessWidget {
  const _RatingMascot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 140,
            height: 140,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.successAccentHalo,
            ),
          ),
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: AppColors.successAccent,
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              Icons.sentiment_satisfied_alt,
              size: 52,
              color: AppColors.white,
            ),
          ),
          const PositionedDirectional(
            bottom: 14,
            child: Icon(Icons.star_rounded, size: 40, color: Color(0xFF2E7DF6)),
          ),
        ],
      ),
    );
  }
}

/// A bordered panel, used for each block of the form.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusField),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: child,
    );
  }
}

/// One selectable reason chip.
class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy50 : AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: isSelected ? AppColors.navy900 : AppColors.fieldBorder,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.navy900,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
