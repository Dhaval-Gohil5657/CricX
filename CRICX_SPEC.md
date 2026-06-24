# CricX – Specifications & Architecture Document

Welcome to the CricX project! This document outlines the project structure, state management, screen routing, and Firebase integration status to help developers and AI assistants navigate the codebase efficiently.

---

## 1. Product Vision & Requirements

**CricX** is a modern grassroots cricket management platform tailored for local teams, box cricket groups, clubs, school/college leagues, and casual players. It focuses on simplicity, speed, and clean user experience, enabling anyone to start live-scoring a match within minutes.

### User Roles & Navigation Bars
*   **Guest**: Can view public matches, live scores, scorecards, and tournaments.
*   **User**: Can create profiles, follow teams, view stats, and join teams.
*   **Scorer**: Can create teams, create matches, setup tosses, and score matches ball-by-ball.
*   **Organizer**: Can create tournaments, register teams, manage fixtures/matches, and update the points table.

---

## 2. Directory Layout & Key Modules

Below is the directory structure of the CricX codebase:

```
cricx/
├── android/
│   ├── app/
│   │   ├── build.gradle.kts      # App-level Gradle config (minSdk=21, google-services applied)
│   │   └── google-services.json   # Firebase Android configuration file
│   └── settings.gradle.kts       # Project-level Gradle settings (Google Services plugin version defined)
├── assets/
│   └── CricX_logo.png            # CricX branding logo asset
├── ios/                          # iOS build files (requires GoogleService-Info.plist if targeting iOS)
├── lib/
│   ├── main.dart                 # Application entry point (initializes Firebase & state)
│   ├── app_detail_info.dart      # Source document for Product Vision and Requirements
│   ├── constants/
│   │   └── app_colors.dart       # Curated brand theme colors (Turf Green, Stump Gold, Bat Wood)
│   ├── models/
│   │   ├── match_model.dart      # CricketMatch, BallEvent, MatchTeamInnings models
│   │   ├── player_model.dart     # Player profiles & stats models
│   │   ├── team_model.dart       # Team metadata & roster models
│   │   └── tournament_model.dart # Tournament, PointsTable entry models
│   ├── screens/
│   │   ├── welcome_screen.dart   # Role-selection portal & landing screen
│   │   ├── main_navigation.dart  # Multi-role bottom navigation router
│   │   ├── dashboard_screen.dart # Core dashboard displaying matches, live events, and stats
│   │   ├── matches_screen.dart   # Feed of completed, live, and upcoming matches
│   │   ├── teams_screen.dart     # Directory of teams, player rosters, and creation
│   │   ├── profile_screen.dart   # Player card, personal statistics, and achievements
│   │   ├── scorecard_screen.dart # Detailed match overview (runs, over-by-over, wickets)
│   │   ├── organizer/
│   │   │   ├── organizer_dashboard.dart       # Organizer overview (their active tournaments)
│   │   │   ├── create_tournament_screen.dart   # Tournament details & size setup form
│   │   │   └── tournament_detail_screen.dart  # Bracket, points table, and match schedules
│   │   └── scorer/
│   │       ├── scorer_dashboard.dart          # Scorer panel (active matches and history)
│   │       ├── create_team_screen.dart        # Custom team creation and roster setup
│   │       ├── create_match_screen.dart       # Match setup form (overs, teams)
│   │       ├── toss_setup_screen.dart         # Digital coin toss and match initiation
│   │       └── live_scoring_screen.dart       # Real-time ball-by-ball score input pad
│   └── state/
│       └── app_state.dart        # Global ChangeNotifier handling state and scoring logic
├── pubspec.yaml                  # Project dependencies (includes firebase_core)
└── README.md                     # Brief overview of CricX setup
```

---

## 3. Brand & Visual Design System

Theme colors are defined centrally in [app_colors.dart](file:///C:/Users/dhava/StudioProjects/cricx/lib/constants/app_colors.dart):
*   **Deep Turf Green (`primaryTurf` - `#1F4D28`)**: Primary brand color representing the outfield.
*   **Turf Green Accent (`accentCrease` - `#4CAF50`)**: Secondary accent for highlights and primary buttons.
*   **Stump Gold (`pitchGold` - `#E5A65D`)**: Warm gold representing stumps and batting pitch.
*   **Espresso/Bat Wood (`textDark` - `#2E241F`)**: Primary dark text color for excellent contrast.
*   **Background (`background` - `#FDFCF9`)**: Soft warm off-white that minimizes screen glare.

---

## 4. State Management & Live Scoring Logic

Global app state is managed using the **Provider** package in [app_state.dart](file:///C:/Users/dhava/StudioProjects/cricx/lib/state/app_state.dart).

### Scoring Flow State Machine:
1.  **Match Created**: Status set to `upcoming` in `createMatch()`.
2.  **Toss setup**: Scorer completes toss logic in `toss_setup_screen.dart` triggering `updateMatchToss()`. State changes to `live` and `innings1` is initialized.
3.  **Active scoring**:
    *   Striker, Non-Striker, and Bowler are assigned (`setupLiveScoringPlayers()`).
    *   Ball outcomes are logged via `recordBall(matchId, BallEvent)`.
    *   `recordBall` automatically:
        *   Updates batsman score/balls faced.
        *   Updates bowler runs conceded/balls bowled/wickets taken.
        *   Applies extras (Wides, No Balls, Byes) to the team score.
        *   Switches strikers automatically on odd runs.
        *   Rotates the bowling end on completed overs (6 balls).
4.  **Match Completion**: Result generated and status set to `completed`.

---

## 5. Firebase Configuration Status

Firebase is successfully configured and initialized for the project:

### 1. SDK Integration
*   Added `firebase_core` and `firebase_auth` dependencies in [pubspec.yaml](file:///C:/Users/dhava/StudioProjects/cricx/pubspec.yaml).
*   Initialized Firebase asynchronously in the entry point [main.dart](file:///C:/Users/dhava/StudioProjects/cricx/lib/main.dart):
    ```dart
    void main() async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();
      runApp(...);
    }
    ```

### 2. Android Configuration
*   **Config File**: Loaded `google-services.json` into [android/app/google-services.json](file:///C:/Users/dhava/StudioProjects/cricx/android/app/google-services.json).
*   **Project Gradle**: Registered the Google Services plugin `com.google.gms.google-services:4.4.2` inside [android/settings.gradle.kts](file:///C:/Users/dhava/StudioProjects/cricx/android/settings.gradle.kts).
*   **App Gradle**: Applied the `com.google.gms.google-services` plugin inside [android/app/build.gradle.kts](file:///C:/Users/dhava/StudioProjects/cricx/android/app/build.gradle.kts).
*   **MinSdkVersion**: Set `minSdk = 23` explicitly inside [android/app/build.gradle.kts](file:///C:/Users/dhava/StudioProjects/cricx/android/app/build.gradle.kts) to support Firebase's and other plugins' underlying dependencies.

### 3. iOS / macOS Configuration
*   To enable Firebase on iOS/macOS, developers need to add the `GoogleService-Info.plist` download to `ios/Runner/` and `macos/Runner/` respectively, matching the app's bundle identifier.
