# ⚡ GET SET GO - Elite AI Discipline, Gym & Financial Performance Engine

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-v3.29+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/AI-Google%20Gemini%201.5%20Flash-4285F4?logo=google&logoColor=white" alt="Gemini AI" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20Windows-00C48C" alt="Platforms" />
  <img src="https://img.shields.io/badge/Storage-Cloud%20Vault%20%2B%20SQLite%20Offline-FF6B6B" alt="Storage" />
</p>

---

## 🌟 Overview

**GET SET GO** is a high-performance, cross-platform personal transformation suite built with Flutter and Dart. Engineered with modern dark cyberpunk aesthetics, responsive layouts for Mobile and Web/Desktop, real-time Gemini AI integration, 7-day gym weight/rep tracking with volume tonnage calculators, intelligent financial budgeting, and a zero-loss cloud sync vault.

---

## 🚀 Key Features

### 1. 🧠 Titan AI Coaching Engine (Google Gemini 1.5 Flash + Heuristic Fallback)
- **Direct Gemini 1.5 Flash Integration**: Real-time contextual prompt generation with custom user API keys.
- **Dual Engine Zero-Failure Fallback**: If offline or without an API key, the built-in heuristic neural fallback generates deep, structured, high-IQ blueprints for workouts, nutrition, daily schedules, and financial audits.
- **Interactive Multi-Turn Modal**: One-tap quick prompt chips (`⚡ Audit My Discipline`, `🏋️ 7-Day Push/Pull/Legs Plan`, `🥗 High-Protein Meal Plan`, `💰 Financial Audit`, etc.).

### 2. 🏋️ 7-Day Gym Workout Splits & Weight / Tonnage Tracker
- **7-Day Dynamic Weekly Splits**:
  - **Monday**: Chest & Triceps (Compound Push & Hypertrophy)
  - **Tuesday**: Back & Biceps (Vertical/Horizontal Pull & Deadlifts)
  - **Wednesday**: Quad & Hamstring Annihilation (Squats, RDLs & Calves)
  - **Thursday**: Shoulders, Traps & Core (OHP, Lateral Raises & Abs)
  - **Friday**: Arms Supremacy (Biceps Peak & Triceps Horseshoe)
  - **Saturday**: HIIT Conditioning & Core Engine
  - **Sunday**: Active Recovery & Deep Mobility
- **Set-by-Set Weight & Rep Logging**: Live toggle for completed sets, weight in kg, and rep counts.
- **Volume Tonnage Calculator**: Computes $\sum (\text{Weight} \times \text{Reps})$ dynamically to enforce progressive overload.
- **Custom Lift Builder**: Add personalized exercises with custom targets, sets, and notes.

### 3. 💰 Intelligent Expense Tracker & Financial Audit
- **Dynamic Budget Gauge**: Visual linear progress indicator with color alerts (Green $<60\%$, Amber $60-85\%$, Crimson $>85\%$).
- **Safe Daily Spend Allowance**: Automatically computes:
  $$\text{Safe Daily Allowance} = \frac{\text{Monthly Budget} - \text{Total Spent}}{\text{Days Left in Month}}$$
- **Titan AI Financial Mastery Audit**: Instant AI breakdown of high-frequency expense tags, leak warnings, and 50/30/20 saving strategies.

### 4. ☁️ Account & Cloud Sync Vault
- **User Profile Management**: Set custom athlete handle, biometrics (weight, height), discipline targets, and monthly budget.
- **Full Vault JSON Serialization**: Back up and restore workouts, goals, streaks, and expenses across devices.
- **Cross-Platform Storage**: SQLite persistence on Android/iOS/Desktop with automatic in-memory and `SharedPreferences` fallback on Web.

### 5. 📱 Cross-Platform Responsive Layout
- **Adaptive Shell**:
  - **Mobile ($<768\text{px}$)**: High-contrast `NavigationBar` with frosted glass app bar.
  - **Web / Desktop ($\ge 768\text{px}$)**: Ergonomic `NavigationRail` with expanded metrics and dashboard split views.
- **Overflow-Free UI**: Hardened against keyboard popups and localized overflow across all form factors.

---

## 🛠️ Tech Stack & Dependencies

- **Framework**: Flutter 3.29+ / Dart 3.7+
- **HTTP Client**: `http: ^1.2.0`
- **Preferences & Cloud Storage**: `shared_preferences: ^2.2.2`
- **Local DB**: `sqflite` (native) / `path_provider`
- **Charts & Visuals**: Custom painter & responsive gauges

---

## 🏁 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and added to PATH.
- Android Studio / VS Code with Dart & Flutter extensions.

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/getsetgo.git
   cd getsetgo
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run Unit & Widget Tests:**
   ```bash
   flutter test
   ```

4. **Launch on Web or Device:**
   ```bash
   # Launch in Chrome (Web)
   flutter run -d chrome

   # Launch on connected Android device / emulator
   flutter run
   ```

5. **Build Release / Debug APK:**
   ```bash
   flutter build apk --debug
   ```

---

## 📦 Pushing to GitHub

To push this repository to your GitHub account:

```bash
# 1. Initialize git (if not already initialized)
git init

# 2. Add all files
git add .

# 3. Commit changes
git commit -m "feat: complete GET SET GO app with Titan AI, 7-day gym weight tracking, cloud sync, and expense calculators"

# 4. Link your remote repository
git remote add origin https://github.com/<your-username>/getsetgo.git

# 5. Set main branch and push
git branch -M main
git push -u origin main
```

---

## 📄 License
This project is open-source under the MIT License.
