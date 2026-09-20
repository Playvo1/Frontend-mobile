# Playvo — Flutter app (auth module)

Refactored to match **Playvo Team Development & Integration Guidelines V1.0**.

---

## Running it the first time

```bash
flutter pub get
flutter gen-l10n          # generates lib/l10n/app_localizations.dart from the .arb files
flutter run --dart-define=PLAYVO_API_BASE_URL=https://staging.playvo.app/api/v1
```

`lib/l10n/app_localizations.dart` is **generated**, not committed (it is in
`.gitignore`). Until `flutter gen-l10n` runs once, the analyzer will report it
as missing. `flutter run` and `flutter test` regenerate it automatically
because `generate: true` is set in `pubspec.yaml`.

Before pushing:

```bash
dart format .
flutter analyze
flutter test
```

---

## Brand color change

`AppColors.orange500` is now **#FC4B01**. The rest of the orange ramp was
re-derived from it with the same tint/shade steps the old ramp used, so the
scale stays consistent:

| Token       | Old       | New         |
| ----------- | --------- | ----------- |
| `orange50`  | `#FFF0EB` | `#FFF1EB`   |
| `orange100` | `#FFD9CE` | `#FEDCCE`   |
| `orange300` | `#FF9877` | `#FDA078`   |
| `orange500` | `#FF3D00` | **#FC4B01** |
| `orange700` | `#C22E00` | `#C03901`   |

Per Guidelines §4, update the shared Source of Truth file with these values so
React picks up the same ramp, before either platform ships it.

---

## What changed, and which rule it satisfies

### Localization — §4.1, §5.3

- The hand-rolled `AppStrings(bool isArabic)` class is gone. Translations now
  live in `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb`, consumed through the
  generated `AppLocalizations`.
- **The 50 keys in these files are the contract with React.** The i18next
  namespace on the dashboards must use the same key names.
- `MaterialApp` now declares `locale`, `supportedLocales` and
  `localizationsDelegates`, so Flutter drives text direction and the built-in
  Material strings (date pickers, text-selection menus) in Arabic too. Every
  per-screen `Directionality` wrapper was deleted; the only one left is the
  deliberate LTR wrapper around the OTP boxes, since a numeric code is not read
  right-to-left.
- The chosen language is persisted in `SharedPreferences` and read in `main()`
  before the first frame.

### API layer — §2.2, §5.3, §7.2

- `ApiResponse<T>` models the `success` / `data` / `message` / `errors`
  envelope once. `errorFor('email')` reaches a specific validation message.
- `ApiClient` owns the base URL (including the mandatory `/api/v1` prefix),
  the JSON headers, the `Authorization: Bearer` header, and the timeout.
- A business failure (wrong password, 422, locked account) comes back as
  `success: false` — it is **not** an exception. Only transport failures throw
  `ApiException`, which `FailureMessages` turns into a localized sentence. No
  `catch {}` is empty anywhere.
- `AuthService` implements every endpoint in §7.2 with the exact request bodies
  from the contract.
- The base URL comes from `--dart-define`, so no host is committed (§2.4).

### Data model — §3

- `User` maps the USER entity with the API's own field names (`name`, `phone`,
  `email_verified_at`, `status`, `roles`).
- `UserStatus` and `UserRole` hold the fixed strings from §3.1 so no literal
  `'active'` is compared inline.
- There is deliberately **no password field on the model**. `password` is a
  local variable inside a login/register call; `password_hash` never leaves the
  server.

### Bug fixes

- **The password-reset flow was broken.** The OTP screen navigated to the reset
  screen without the email or the code, so the reset call could never satisfy
  `POST /auth/reset-password`, which needs all three. Both are now carried
  forward as constructor arguments, and the code is spent on the reset call
  rather than verified early (it is single-use, §2.4).
- **Failed-attempt counting moved to the server.** The client no longer keeps
  `_remainingAttempts`; it shows whatever message the backend returns, driven by
  `USER.failed_login_attempts` / `locked_until` (§2.4).
- **The wordmark font.** `playvo_logo.dart` hardcoded `fontFamily: 'Cairo'`
  while the theme used `GoogleFonts.cairo`, whose runtime family name differs —
  the wordmark could silently render in the fallback font. It now reads
  `AppTheme.fontFamily`.
- **`ResendCountdown`** used a self-chaining `Future.delayed` that could not be
  cancelled. It is now a `Timer.periodic` cancelled in `dispose()`.
- **`AuthFooterLink`** built a `TapGestureRecognizer` inside `build()`, leaking
  one per rebuild. It is now created in `initState` and disposed.
- **OTP boxes** now accept digits only and handle a pasted code.
- **Email validation** is a real pattern instead of `contains('@')`, and the
  new-password rule (8+ chars, letter + digit) is stated in one place so it can
  be matched against the Laravel Form Request.

### Structure — §2.1

- One class per concern per file: `OrDivider` left `google_button.dart`,
  `ResendCountdown` left `otp_box_input.dart`.
- `AuthScreenScaffold` holds the frame the five auth screens shared (language
  selector, logo, title, subtitle, scroll padding) — roughly twenty duplicated
  lines per screen, now written once.
- `AppSpacing` replaces the loose `SizedBox(height: 14/18/24/28)` numbers, and
  every font size moved into the theme's `textTheme`. No screen sets a color or
  a font size directly any more.
- Navigation goes through `AppRouter`. The unused `routeName` constants are
  gone: half the screens need typed arguments, and a route table would pass
  those as `Object?` for each screen to cast.

### Tests — §2.5

`flutter test` covers:

- `test/core/api_response_test.dart` — the envelope, per-field errors, null data
- `test/core/validators_test.dart` — email, password and phone rules
- `test/services/auth_service_test.dart` — request bodies match §7.2, the token
  is stored on success and never on failure, the bearer header is sent on
  authenticated calls only, logout clears the token even when the call fails
- `test/widgets/` — `PrimaryButton`, `AppTextField`, `OtpBoxInput`, `OrDivider`,
  `ErrorBanner`, `ResendCountdown`

`SplashScreen`, `HomeScreen` and every auth screen take an optional
`authService` so screen-level tests can inject a fake without a network.

---

## Known gaps

- **`HomeScreen` is a placeholder.** It exists so the launch decision and the
  logout path are complete and testable; replace it with the real home screen.
- **Google Sign-In is not wired.** `AuthService.loginWithGoogle(idToken)` and
  the endpoint are ready; the `google_sign_in` call that produces the token is
  marked `TODO(auth)` in the login and signup screens.
- **Not started yet, from §5.3:** the sqflite cache for reference data
  (`SYNC_STATUS`), Firebase Cloud Messaging, and the `DEVICE_TOKEN` registration
  call.
- **Private `State` classes carry no doc comment.** Their public widget above
  them is documented; §2.1 read literally would want one on each. Worth a team
  decision either way.
- **State management is still ad hoc.** `LocaleController` is a static notifier,
  which is fine for a language switch, but auth state, bookings and
  notifications need a real approach (Provider / Riverpod / Bloc) agreed before
  the booking module starts — static globals are the main obstacle to the unit
  tests §2.5 requires.
- **Cairo is fetched at runtime** by `google_fonts`. Bundling the four weights
  in `assets/fonts/` would make a first launch work offline.
