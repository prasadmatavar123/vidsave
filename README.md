# VidSave – Flutter video downloader (MVVM)

## Setup (Steps 1 & 12)
```bash
flutter create --org com.example --project-name vidsave --platforms android vidsave_app
cd vidsave_app
# copy this project's `lib/` folder and `pubspec.yaml` over the generated ones
# copy android_setup/AndroidManifest.xml -> android/app/src/main/AndroidManifest.xml
flutter pub get
```
In `android/app/build.gradle` (or `build.gradle.kts`) set `minSdk = 24` (or `minSdkVersion 24`).

## Run (Step 11 – physical device)
Enable USB debugging, connect the phone, then `flutter run`.
Test link: any direct HTTPS .mp4 you are allowed to download.

## Release APK (Step 12)
`flutter build apk --release`  ->  build/app/outputs/flutter-apk/app-release.apk
(For Play Store distribution create a keystore and configure signing, then use `flutter build appbundle`.)
