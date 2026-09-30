import 'package:flutter/material.dart';

import '../../core/reference_data.dart';
import '../../core/validators.dart';
import '../../l10n/l10n.dart';
import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_button.dart';

/// "تعديل الملف الشخصي" — the editable version of the profile card.
///
/// TODO(api): there is no update-profile endpoint in the Postman
/// collection. Saving currently returns the edited user to the caller;
/// point it at `PUT /auth/me` (or whatever the backend settles on) once it
/// exists.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.user});

  final User? user;

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

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.profileSaved)),
    );
    Navigator.of(context).pop();
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
              const Center(child: _EditableAvatar()),
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
                decoration: const InputDecoration(
                  prefixIcon: Icon(
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
                decoration: const InputDecoration(
                  prefixIcon: Icon(
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
                decoration: const InputDecoration(
                  prefixIcon: Icon(
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
                onPressed: _save,
                child: Text(l10n.saveChanges),
              ),
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
  const _EditableAvatar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        children: <Widget>[
          Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              color: AppColors.grey200,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 56,
              color: AppColors.navy300,
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
