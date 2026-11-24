# VPL Player App (Flutter)

Player side of the VPL registration system. Talks to the Laravel API in `../backend-laravel`.

## Setup
This folder contains `lib/`, `pubspec.yaml` and a setup script. Generate the platform folders once:
```bash
flutter create . --project-name vpl_player --org com.webcreta --platforms=android,ios,web
dart run tool/setup_platforms.dart     # INTERNET, cleartext (local), UPI <queries>, iOS camera/photo strings
flutter pub get
```

## Point the app to your API
`lib/config/app_config.dart` (default `http://10.0.2.2:8000/api` = your PC from the Android emulator), or at run/build time:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api     # real phone on same Wi-Fi
flutter build apk --release --dart-define=API_BASE_URL=https://vpl.yourdomain.com/api
```
For production use **https** and remove `android:usesCleartextTraffic="true"` from AndroidManifest.

## Structure
```
lib/
  config/app_config.dart       API URL
  core/api_client.dart         HTTP + multipart + bearer token + error handling
  core/token_storage.dart      token in secure storage (Keychain / Keystore)
  models/                      API models + option lists (keys match the backend)
  services/player_api.dart     every API endpoint
  services/confirmation_pdf.dart  confirmation PDF
  state/session.dart           login state + dashboard (Provider)
  screens/
    auth/          login (email/mobile/name), signup, forgot/reset password (OTP)
    home/          dashboard: next step, statuses, progress, profile, tournament info
    profile/       edit personal + cricket info, change password
    documents/     photo + Aadhaar front/back upload with preview & verification status
    registration/  join tournament (jersey number/name, rules)
    payment/       admin QR, UPI ID (copy / open UPI app), locked fee, UTR + screenshot proof, history
    confirmation/  Registration ID pass + PDF download/share
    notifications/
```

## Flow
Account → Cricket details → Documents → Register (jersey) → Pay via QR → Upload proof → Admin verifies → Registration ID + confirmation PDF.
If the admin rejects the registration or payment, the reason is shown on the dashboard with a button to fix and resubmit.
