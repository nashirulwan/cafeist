---
description: Build Android APK for sharing
---

# Build Android APK

Follow these steps to build an APK file that can be installed on other Android devices.

1.  **Open Terminal**
    Ensure you are in the project root directory.

2.  **Clean Project (Optional but Recommended)**
    Run this command to clear old build artifacts:
    ```bash
    flutter clean
    ```

3.  **Get Dependencies**
    ```bash
    flutter pub get
    ```

4.  **Build APK**
    Run the build command. This uses the 'release' build configuration, which we have verified is set to use your debug key for signing (allowing installation on other devices).
    ```bash
    flutter build apk --release
    ```
    *Note: This process may take a few minutes.*

5.  **Locate APK**
    Once the build finishes, the APK file will be located at:
    `build/app/outputs/flutter-apk/app-release.apk`

6.  **Install on Device**
    -   Transfer this file to your Android phone (via WhatsApp, USB, Drive, etc.).
    -   Tap the file to install.
    -   You may need to allow "Install from Unknown Sources".

> [!NOTE]
> Since this APK uses your local debug key, Google Sign-In will work ONLY if the SHA-1 of your debug key is added to the Firebase Console. If you send this to a friend and it doesn't work, it's likely an SHA-1 mismatch if you built it on a different machine than the one registered in Firebase. But since you built it, it should work.
