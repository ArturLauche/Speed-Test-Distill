# Build an Android APK

This project is static HTML/JS/CSS. The scripts below wrap it into a Cordova Android WebView app and produce an APK you can install locally.

## Prerequisites

- Node.js 18+ (includes npm)
- Java JDK 17 (required by the Android toolchain)
- Android SDK + build tools
- `ANDROID_SDK_ROOT` (or `ANDROID_HOME`) set in your environment

If you don't have the Android SDK installed, install **Android Studio** and add the SDK/Build Tools during setup.

## macOS / Linux

```bash
./scripts/build-android-apk.sh
```

Output:

```
dist/android/*.apk
```

### Optional environment variables

- `APP_ID` (default: `com.openspeedtest.app`)
- `APP_NAME` (default: `OpenSpeedTest`)
- `PACKAGE_TYPE` (`debug` or `release`, default: `debug`)
- `ANDROID_PLATFORM` (default: `android-34`)
- `ANDROID_BUILD_TOOLS` (default: `34.0.0`)

Example:

```bash
APP_ID=com.example.speedtest APP_NAME=SpeedTest PACKAGE_TYPE=debug ./scripts/build-android-apk.sh
```

## Windows (PowerShell)

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-android-apk.ps1
```

Output:

```
dist\android\*.apk
```

### Optional environment variables

- `APP_ID` (default: `com.openspeedtest.app`)
- `APP_NAME` (default: `OpenSpeedTest`)
- `PACKAGE_TYPE` (`debug` or `release`, default: `debug`)
- `ANDROID_PLATFORM` (default: `android-34`)
- `ANDROID_BUILD_TOOLS` (default: `34.0.0`)

Example:

```powershell
$env:APP_ID="com.example.speedtest"
$env:APP_NAME="SpeedTest"
$env:PACKAGE_TYPE="debug"
.\scripts\build-android-apk.ps1
```

## Notes

- `release` builds require signing. You can sign the APK using Android Studio or `apksigner`.
- The scripts will try to install the required SDK platform/build tools if `sdkmanager` is on your PATH.
- If the build fails, verify that the Android SDK path is configured and that `adb`/`sdkmanager` are available in your PATH.
