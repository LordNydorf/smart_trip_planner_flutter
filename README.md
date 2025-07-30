# Smart Trip Planner Flutter

A Flutter application for intelligent trip planning using AI-powered itinerary generation.

## 🚀 Features

- AI-powered trip planning with Gemini AI
- Firebase authentication and data storage
- Offline mode support
- Real-time itinerary generation
- User profile and usage tracking

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK (latest stable version)
- Firebase project setup
- Gemini AI API key

### 1. Clone and Install Dependencies
```bash
git clone <repository-url>
cd smart_trip_planner_flutter
flutter pub get
```

### 2. Configure API Keys
1. Copy the environment template:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` file with your actual API keys:
   ```
   GEMINI_API_KEY=your_gemini_api_key_here
   FIREBASE_WEB_API_KEY=your_firebase_web_key_here
   FIREBASE_ANDROID_API_KEY=your_firebase_android_key_here
   FIREBASE_IOS_API_KEY=your_firebase_ios_key_here
   ```

### 3. Firebase Configuration
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/google-services.json`
3. Download `GoogleService-Info.plist` from Firebase Console  
4. Place it in `ios/Runner/GoogleService-Info.plist`

### 4. Run the App
```bash
flutter run
```

## 🔒 Security

See [SECURITY.md](SECURITY.md) for detailed information about API key management and security best practices.

## 📚 Getting Started with Flutter

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
