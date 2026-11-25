# CORNER STONER LEADERS Android app

This Android project wraps the existing private website in an Android WebView. It uses the existing website and Supabase backend, so the website remains the source of truth for sign-in, leader approval, finance and records.

## Build without a computer (GitHub Actions)
1. Create a GitHub repository named `corner-stoner-leaders-android`.
2. Extract this ZIP on your Android phone.
3. Upload the CONTENTS of the `csl-android` folder to the repository root, including the hidden `.github/workflows/android.yml` file. Keep the folders and paths intact.
4. In GitHub, open the repository's Actions tab. Enable Actions if asked.
5. Open `Build Android APK` and tap `Run workflow` (or wait for the first push build).
6. When the run succeeds, open it, scroll to Artifacts, and download `CORNER-STONER-LEADERS-APK`. Extract the downloaded artifact ZIP to get `app-debug.apk`.
7. Tap `app-debug.apk` to install. Android may ask you to allow installs from your browser or file manager.

## Notes
- Confirm `WEBSITE_URL` in `app/src/main/java/com/cornerstonerleaders/app/MainActivity.java` is the current live website URL before building.
- This is a WebView app shell; the website must remain deployed and reachable.
- Never put Supabase service-role or secret keys in this project.
