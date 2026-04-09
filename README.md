<div align="center">

# 🔍 SachDrishti

### AI-Powered News Verification App for India

*"Sach" (सच) means **Truth** in Hindi — See the truth clearly.*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

## 📱 About

**SachDrishti** is a Flutter-based mobile application that helps Indian users verify the authenticity of news articles and screenshots using AI-powered OCR and multi-source news verification. In an era of rampant misinformation, SachDrishti empowers users to fact-check news in seconds — simply by taking a screenshot or uploading an image.

---

## ✨ Features

### 🧠 Core Verification
- **OCR Scanning** — Extract text from news screenshots using Google ML Kit
- **Multi-Source Verification Engine** — Cross-checks against trusted Indian & global news sources (NDTV, Hindustan Times, India Today, NewsAPI, etc.)
- **Confidence Scoring** — Provides a detailed confidence score with verdict (Real / Fake / Unverified)
- **Category Tagging** — Automatically tags news categories (Politics, Sports, Health, Tech, etc.)
- **Absurdity & Hoax Detection** — Catches fabricated headlines with semantic analysis

### 🔐 Authentication
- **Email/Password** sign-up & login
- **Google Sign-In** via OAuth
- **Email-based Password Reset** (only for manual accounts)
- **Firestore user profiles** with persistent data

### 📜 History & Offline Cache
- Full **verification history** stored in Firestore
- **Offline cache** (via Hive) for recent verifications — accessible without internet
- Shimmer loading states for smooth UX

### 💬 Chat Room (Social Sync)
- Real-time **group chat** using Firestore
- Share verification results directly into chat
- Media sharing support
- Username-based system messages

### 📤 Export & Share
- Generate detailed **PDF/text reports** of verification results
- Share results via the native **share sheet**
- Direct sharing from the result screen into the chat room

### 🌐 Multi-Language OCR
- Supports text extraction from **Hindi & English** news screenshots

---

## 🏗️ Project Architecture

```
lib/
├── main.dart                  # App entry point, Firebase init
├── firebase_options.dart      # Firebase config (auto-generated)
├── core/                      # App-wide theme, constants, routing
├── models/                    # Data models (VerificationResult, UserProfile, etc.)
├── providers/                 # Riverpod state providers
├── services/
│   ├── auth_service.dart          # Firebase Auth + Google Sign-In
│   ├── ocr_service.dart           # ML Kit OCR + text cleaning
│   ├── verification_engine.dart   # Core fact-check logic
│   ├── news_api_service.dart      # News API integrations
│   ├── category_tagger.dart       # Auto news categorization
│   ├── report_generator.dart      # PDF/text report export
│   ├── share_receiver_service.dart# Share sheet integration
│   ├── image_storage_service.dart # Image handling
│   └── connectivity_service.dart  # Network status detection
└── screens/
    ├── splash/       # Animated splash screen
    ├── onboarding/   # First-launch onboarding
    ├── auth/         # Login, Register, Forgot Password
    ├── home/         # Dashboard
    ├── scanner/      # Camera / gallery image picker
    ├── editor/       # Image crop/edit before OCR
    ├── processing/   # OCR + verification in progress
    ├── result/       # Verification result with score
    ├── history/      # Past verifications list
    ├── chat/         # Real-time chat room
    ├── profile/      # User profile & stats
    └── settings/     # App preferences
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart) |
| State Management | Riverpod 2.x |
| Navigation | go_router |
| Backend | Firebase (Auth, Firestore) |
| OCR | Google ML Kit Text Recognition |
| News APIs | NewsAPI, GNews, Times of India RSS |
| Local Storage | Hive (offline cache) |
| Animations | Lottie |
| Fonts | Google Fonts |
| Sharing | share_plus |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.0.0
- [Android Studio](https://developer.android.com/studio) or VS Code
- A Firebase project with **Authentication** and **Firestore** enabled
- A [NewsAPI](https://newsapi.org/) key

### 1. Clone the Repository

```bash
git clone https://github.com/Charan-Dasari/sachcheck.git
cd sachcheck
```

### 2. Firebase Setup

> ⚠️ The `google-services.json` file is **not included** in this repo for security reasons.

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Create a new project (or use an existing one)
3. Add an **Android app** with package name: `com.sachcheck.app`
4. Download `google-services.json` and place it at:
   ```
   android/app/google-services.json
   ```
5. Enable **Email/Password** and **Google** sign-in methods
6. Create a **Firestore Database** in your Firebase project

### 3. Configure API Keys

Create a file `lib/core/config.dart` (or update the existing config) with your API keys:

```dart
class AppConfig {
  static const String newsApiKey = 'YOUR_NEWS_API_KEY';
  static const String gNewsApiKey  = 'YOUR_GNEWS_API_KEY';
}
```

### 4. Install Dependencies

```bash
flutter pub get
```

### 5. Run Code Generation (for Hive models)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 6. Run the App

```bash
flutter run
```

---

## 🔒 Environment & Security Notes

The following files contain sensitive information and are excluded via `.gitignore`:

| File | Reason |
|------|--------|
| `android/app/google-services.json` | Firebase API keys |
| `ios/Runner/GoogleService-Info.plist` | Firebase iOS config |
| `android/local.properties` | Local Android SDK path |
| `.env` / `secrets.dart` | API keys |

> **Never commit these files** to a public repository.

---

## 🔐 Privacy Policy

SachDrishti is committed to protecting your privacy. Our full Privacy Policy is available here:

📄 **[View Privacy Policy](PRIVACY_POLICY.md)**

> This link is required for Google Play Store submission. Once you push this repo to GitHub, your hosted Privacy Policy URL will be:
> ```
> https://Charan-Dasari.github.io/sachcheck/PRIVACY_POLICY
> ```
> or via raw GitHub:
> ```
> https://github.com/Charan-Dasari/sachcheck/blob/main/PRIVACY_POLICY.md
> ```
> Use either URL in the **Google Play Console → App Content → Privacy Policy** field.

### Data We Collect
| Data | Purpose |
|------|---------|
| Email & Name | Account creation & authentication |
| Images / Screenshots | On-device OCR — **not stored on servers** |
| Verification history | Stored in your Firestore account |
| Chat messages | Real-time group chat via Firestore |
| Device permissions (Camera, Storage) | Scanning news screenshots |

We **do not** sell or share your data with third parties.

---



## 🤝 Contributing

Contributions are welcome! Please open an issue first to discuss what you'd like to change.

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add some amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## 👨‍💻 Author : Devicharan Dasari

Built with ❤️ for combating misinformation in India.

---

<div align="center">
  <i>If this project helped you, give it a ⭐ on GitHub!</i>
</div>
