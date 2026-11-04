import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_response.dart';
import '../../core/failure_messages.dart';
import '../../core/receipt_picker.dart';
import '../../core/reference_data.dart';
import '../../core/validators.dart';
import '../../l10n/l10n.dart';
import '../../models/user.dart';
import '../../services/profile_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/diagnostics_panel.dart';
import '../../widgets/error_banner.dart';

/// "تعديل الملف الشخصي" — the editable version of the profile card.
///
/// Saves through `PUT /player/profile`, and replaces the picture through
/// `POST /player/profile/photo`. The edited account is returned to the
/// caller so the account screen updates without another round trip.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.user, this.profileService});

  final User? user;

  /// Injectable so the screen can be exercised without a network.
  final ProfileService? profileService;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController =
      TextEditingController(text: widget.user?.name ?? '');
  late final TextEditingController _emailController =
      TextEditingController(text: widget.user?.email ?? '');
  late final TextEditingController _phoneController =
      TextEditingController(text: widget.user?.phone ?? '');
  final TextEditingController _aboutController = TextEditingController();

  String? _city = ReferenceData.cities.first;

  late final ProfileService _profileService =
      widget.profileService ?? ProfileService();

  /// The newest picture, once one has been uploaded this visit.
  String? _photoUrl;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;

  /// The design caps the bio at 200 characters and shows the count.
  static const int _aboutLimit = 200;

  @override
  void initState() {
    super.initState();
    _aboutController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final ApiResponse<User> response = await _profileService.update(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
      );
      if (!mounted) {
        return;
      }

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileSaved)),
        );
        // Hand the saved account back, so the screen behind refreshes
        // from the server's version rather than guessing at it.
        Navigator.of(context).pop(response.data);
        return;
      }
      setState(
        () => _errorMessage = response.message.trim().isNotEmpty
            ? response.message.trim()
            : l10n.assistantUnavailable,
      );
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() => _errorMessage = FailureMessages.of(exception, l10n));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Picks a picture and sends it straight away: a photo the player chose
  /// but that only uploads on "save" is a photo they think is already set.
  Future<void> _changePhoto() async {
    if (_isUploadingPhoto) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    final PickedReceipt? picked = await ReceiptPicker().pick();
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _isUploadingPhoto = true;
      _errorMessage = null;
    });

    try {
      final ApiResponse<User> response =
          await _profileService.updatePhoto(picked.path);
      if (!mounted) {
        return;
      }
      if (response.success) {
        setState(() => _photoUrl = response.data?.photoUrl ?? picked.path);
        return;
      }
      setState(
        () => _errorMessage = response.message.trim().isNotEmpty
            ? response.message.trim()
            : l10n.assistantUnavailable,
      );
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() => _errorMessage = FailureMessages.of(exception, l10n));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            children: <Widget>[
              AppScreenHeader(title: l10n.editProfileTitle, centerTitle: true),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: _EditableAvatar(
                  photoUrl: _photoUrl ?? widget.user?.photoUrl,
                  isBusy: _isUploadingPhoto,
                  onTap: _changePhoto,
                ),
              ),
              ErrorBanner(message: _errorMessage),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    l10n.changePhoto,
                    style: textTheme.labelMedium
                        ?.copyWith(color: AppColors.successAccent),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _Label(text: l10n.fullNameLabel, isRequired: true),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: l10n.fullNameHint,
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    size: 19,
                    color: AppColors.navy300,
                  ),
                ),
                validator: (String? value) => Validators.fullName(value, l10n),
              ),
              const SizedBox(height: AppSpacing.md),
              _Label(text: l10n.emailHint, isRequired: true),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: l10n.emailPlaceholder,
                  prefixIcon: const Icon(
                    Icons.mail_outline,
                    size: 19,
                    color: AppColors.navy300,
                  ),
                ),
                validator: (String? value) => Validators.email(value, l10n),
              ),
              const SizedBox(height: AppSpacing.md),
              _Label(text: l10n.phoneLabel, isRequired: true),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: l10n.phonePlaceholder,
                  prefixIcon: const Icon(
                    Icons.call_outlined,
                    size: 19,
                    color: AppColors.navy300,
                  ),
                ),
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty)
                        ? l10n.phoneRequired
                        : Validators.optionalPhone(value, l10n),
              ),
              const SizedBox(height: AppSpacing.md),
              _Label(text: l10n.cityLabel, isRequired: true),
              DropdownButtonFormField<String>(
                initialValue: _city,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.navy300,
                ),
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    size: 19,
                    color: AppColors.navy300,
                  ),
                ),
                items: ReferenceData.cities
                    .map(
                      (String city) => DropdownMenuItem<String>(
                        value: city,
                        child: Text(city),
                      ),
                    )
                    .toList(),
                onChanged: (String? city) => setState(() => _city = city),
              ),
              const SizedBox(height: AppSpacing.md),
              _Label(text: l10n.aboutMeLabel),
              TextFormField(
                controller: _aboutController,
                maxLines: 4,
                maxLength: _aboutLimit,
                decoration: InputDecoration(
                  hintText: l10n.aboutMeHint,
                  alignLabelWithHint: true,
                  counterText: '',
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  '${_aboutController.text.characters.length}/$_aboutLimit',
                  textDirection: TextDirection.ltr,
                  style: textTheme.labelSmall?.copyWith(fontSize: 10),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(l10n.saveChanges),
              ),
              // Debug builds only: shows what the profile endpoints
              // answered, including the photo upload.
              const DiagnosticsPanel(),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

/// The big avatar with its camera badge.
class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.photoUrl,
    required this.isBusy,
    required this.onTap,
  });

  final String? photoUrl;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String? url = photoUrl;

    return GestureDetector(
      onTap: isBusy ? null : onTap,
      child: SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        children: <Widget>[
          Container(
            width: 104,
            height: 104,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: AppColors.grey200,
              shape: BoxShape.circle,
            ),
            child: isBusy
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : url == null
                    ? const Icon(
                        Icons.person,
                        size: 56,
                        color: AppColors.navy300,
                      )
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        // A broken link must not leave a grey hole where a
                        // face should be.
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 56,
                          color: AppColors.navy300,
                        ),
                      ),
          ),
          PositionedDirectional(
            bottom: 2,
            start: 2,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.navy900,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
              child: const Icon(
                Icons.photo_camera_outlined,
                size: 15,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// A field caption, with the red asterisk when the field is required.
class _Label extends StatelessWidget {
  const _Label({required this.text, this.isRequired = false});

  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          Text(
            text,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.navy900),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(color: AppColors.orange500, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
