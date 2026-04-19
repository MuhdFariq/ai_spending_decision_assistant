# 💰 AI Spending Assistant
A student-focused budget app with AI insights.

## 🏗 Project Architecture
- **Models (`lib/models`)**: Shared data structures (Expense, User).
- **Services (`lib/services`)**: Logic for Auth, Firestore, Z.ai, and Analytics.
- **Screens (`lib/screens`)**: UI pages for each member's feature.

## 👥 Team Tasks
- **Member A**: AI Brain & Chat Interface
- **Member B**: Dashboard & Budget Math
- **Member C**: Expense Entry & Firestore Logic
- **Member D (Lead)**: Insights, Validation & Setup

## 🚀 Getting Started for Team Members
To run this project locally, follow these steps:

### 1. Prerequisites
- Ensure you have **Flutter** installed (`flutter doctor`).
- Install **Firebase CLI**: `npm install -g firebase-tools`
- Activate **FlutterFire CLI**: `dart pub global activate flutterfire_cli`

### 2. Project Setup
1. Clone the repo: `git clone <your-repo-link>`
2. Run `flutter pub get` to install all plugins (Firebase, Z.ai http, etc.).
3. **Important:** Run `flutterfire configure` and select our shared project. This will generate the `firebase_options.dart` file on your machine (which is ignored by Git).

### 3. Environment Variables
- Create a `.env` file in the root directory (if we use one) or check the `ai_service.dart` to add your **Z.ai API Key**.
