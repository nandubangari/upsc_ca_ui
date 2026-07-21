# UPSC CA ALL SOURCES

A Flutter app that aggregates **UPSC Current Affairs** from multiple coaching sources into a single, distraction-free reading feed — with reading progress tracking, bookmarks, revision reminders, and article history, built for serious UPSC/competitive-exam aspirants.

📱 **[Get it on Google Play](https://play.google.com/store/apps/details?id=com.nandu.upsc_ca_ui)**

---

## ✨ Features

- **Unified current affairs feed** — pulls daily articles from multiple coaching sources into one clean reading experience instead of juggling several apps/sites.
- **Reading progress tracking** — keeps track of what you've read so you never lose your place.
- **Bookmarks & article history** — save important articles and revisit your reading history anytime.
- **Revision reminders** — nudges you back to material using spaced-repetition-style scheduling.
- **Offline-friendly local storage** — articles and progress are cached locally using Isar for a fast, low-friction reading experience.
- **Google Sign-In & cloud sync** — sign in and keep your progress/bookmarks synced via Firebase.
- **In-app purchases** — supports a premium/subscription tier for additional features.

- ## 📸 Screenshots

<p align="center">
  <img src="assets/screenshots/screenshot (1).webp" width="200" alt="Home Feed" />
  <img src="assets/screenshots/screenshot (2).webp" width="200" alt="Articles" />
  <img src="assets/screenshots/screenshot (4).webp" width="253" alt="Article Reader" />
</p>

---

## 🛠️ Tech Stack

Built with **Flutter** (Dart SDK `^3.11.5`), targeting Android, iOS, Web, Windows, macOS, and Linux.

| Category | Packages |
|---|---|
| State management | `provider` |
| Networking | `http`, `connectivity_plus` |
| Content rendering | `html`, `flutter_widget_from_html_core`, `webview_flutter`, `flutter_custom_tabs`, `cached_network_image` |
| Backend / Auth | `firebase_core`, `firebase_auth`, `firebase_database`, `cloud_firestore`, `firebase_analytics`, `google_sign_in` |
| Local storage | `isar_community`, `shared_preferences`, `path_provider` |
| Monetization | `in_app_purchase` |
| Utilities | `url_launcher`, `intl`, `crypto`, `visibility_detector`, `cupertino_icons` |

---

## 📋 Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (compatible with Dart `^3.11.5`)
- A configured Firebase project (Auth, Firestore, Realtime Database, Analytics) with `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) added to the respective platform folders
- Android Studio / Xcode for building the mobile targets

---

## 🚀 Getting Started

Clone the repository and fetch dependencies:

```bash
git clone https://github.com/nandubangari/upsc_ca_ui.git
cd upsc_ca_ui
flutter pub get
```

Run on a connected device or emulator:

```bash
flutter run
```

Build a release APK:

```bash
flutter build apk --release
```

> **Note:** This project depends on Firebase services. You'll need to connect it to your own Firebase project (via `flutterfire configure` or by manually adding the platform config files) before auth, sync, or analytics features will work.

---

## 📁 Project Structure

```
upsc_ca_ui/
├── android/          # Android platform project
├── ios/               # iOS platform project
├── linux/             # Linux desktop platform project
├── macos/             # macOS desktop platform project
├── windows/           # Windows desktop platform project
├── web/                # Web platform project
├── lib/                 # Main Dart/Flutter application source
├── assets/
│   ├── data/            # Bundled app data
│   └── branding/         # App icon / branding assets
├── test/                # Widget/unit tests
├── pubspec.yaml
└── analysis_options.yaml
```

---

## 📱 App Info

| | |
|---|---|
| Package name | `com.nandu.upsc_ca_ui` |
| Category | Education |
| Platform | Android (Google Play), with cross-platform Flutter targets in this repo |

---

## 🤝 Contributing

This is an actively developed personal project built for UPSC aspirants. Issues, feature suggestions, and pull requests are welcome.


## 📬 Support

For app support or feedback, reach out via the contact details listed on the [Google Play Store page](https://play.google.com/store/apps/details?id=com.nandu.upsc_ca_ui).
