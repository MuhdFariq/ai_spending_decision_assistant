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

### 3. Environment Variables (Required for AI Features)

The AI functionality requires environment variables to be set in the backend.

### Setup Steps:

1. Navigate to the backend folder:

   backend/

2. Create a file named:

   .env

   inside the backend directory.

3. Add the following content:

   ZAI_API_KEY=your_api_key_here
   ZAI_BASE_URL=https://api.ilmu.ai/v1
   ZAI_MODEL=ilmu-glm-5.1
   PORT=8000

4. Replace `your_api_key_here` with your actual API key.

5. Start the backend server:

   python -m uvicorn app.main:app --reload

### Notes:
- The `.env` file inside `/backend` is not included in the repository for security reasons.
- Without this file, AI features will fall back to local logic.
- Do NOT commit your `.env` file to GitHub.
