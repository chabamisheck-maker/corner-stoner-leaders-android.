# CORNER STONER LEADERS Android app

This is a small Android WebView wrapper for the existing website:

https://storied-sorbet-ab22e7.netlify.app/

## Build the APK using GitHub Actions

1. Upload the contents of this ZIP to the **root** of a GitHub repository.
2. Keep the `.github/workflows/android.yml` file and its folder structure.
3. Open the repository's **Actions** tab.
4. Choose **Build Corner Stoner Leaders APK** and tap **Run workflow** (or wait for the first push build).
5. Open the completed workflow run, scroll to **Artifacts**, and download `Corner-Stoner-Leaders-APK`.
6. Extract the downloaded artifact ZIP to get `app-debug.apk`.

The app loads the live website, so website changes appear in the app without rebuilding it. The Android app requires an internet connection.

Note: This is a debug APK for testing and direct installation. A release APK suitable for wider distribution should be signed before publishing.
