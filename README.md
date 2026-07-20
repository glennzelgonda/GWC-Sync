<p align="center">
  <img src="assets/images/gwc_logor.png" alt="GWC Sync Logo" width="200"/>
</p>

# GWC Sync

**Multi-Branch Tire Inventory Management — Mobile Application**

A Flutter mobile application built for Glomags Tire Center, enabling branch managers to track inventory, log stock movement, and monitor performance across multiple store locations in real time.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Firebase Setup](#firebase-setup)
- [Demo Accounts](#demo-accounts)
- [Team](#team)
- [Course Information](#course-information)

---

## Overview

GWC Sync replaces manual, paper-based stock tracking with a single mobile app shared across three branches — **Lipa City**, **Mahabang Parang**, and **Sta. Rita**. Each branch manager sees only their own branch's inventory, restocks and deductions are logged automatically to an audit trail, and the dashboard surfaces low-stock alerts and monthly stocking trends at a glance.

The app is built entirely in Flutter with a Cloud Firestore backend, real-time data sync, and Firebase Authentication — no mock or local-only data is used in the delivered build.

---

## Features

### UI Design
- Custom dark "Glow Industrial" theme, centralized in a single `AppColors`/`AppTheme` definition
- Consistent card, border, and spacing system applied across every screen
- Custom-drawn splash screen animation (rotating tread-ring, glow pulse, branch-sync status cycling)
- Brand-initial icon badges throughout the Inventory Directory and Tire Details for quick visual scanning

### UX Design
- Bottom-sheet quick actions for restocking or deducting stock without leaving the list
- Swipe-to-discontinue with a confirmation dialog and a 4-second Undo window before the change is committed
- Empty, loading, and error states on every data-driven screen — never a blank screen with no explanation
- Inline form validation with specific, actionable error messages

### Navigation and Routing
- Bottom navigation bar (phone) and persistent navigation rail (tablet/desktop) for the three primary sections: Home, Inventory, Log History
- Side drawer (hamburger menu) for secondary actions: Settings, Log Out
- Custom fade-and-slide page transitions between screens
- Hero animations connecting the Inventory list to the Tire Details screen

### Data Handling
- **Cloud Firestore** as the live backend — not local/mock data
- Real-time snapshot listeners keep the Dashboard, Inventory, and Stock History screens in sync automatically after any change
- **Firebase Authentication** (email/password) for manager login
- Server-side **Firestore Security Rules** enforce branch isolation — a manager's client-side filters are a UX convenience only; the actual access boundary is enforced by the backend
- Full audit trail: every stock movement (restock, deduction, discontinue) writes a permanent, append-only log entry with a timestamp

### Responsiveness
- Layout breakpoint system (`Responsive.isTablet`) that switches:
  - Bottom navigation bar → Navigation rail
  - Single-column list → Two-column grid
  - Stacked KPI cards → Wider multi-column layout

### Widgets, Gestures & Animations
A non-exhaustive list of what's demonstrated across the app:

| Category | Examples |
|---|---|
| Gestures | Swipe-to-dismiss, long-press, pull-to-refresh, tap, press-and-hold glow |
| Animations | Hero transitions, staggered fade/slide-in cards, custom `CustomPaint` splash animation, cross-fading app bar titles |
| Forms | Login, Restock Entry, Change Password, custom-quantity dialogs — all with validation |
| Charts | Monthly stocking volume line chart (`fl_chart`) |
| Feedback | Snackbars with Undo actions, confirmation dialogs, inline error banners |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Backend | Cloud Firestore |
| Auth | Firebase Authentication |
| Charts | `fl_chart` |
| State management | `ChangeNotifier` singleton (`InventoryStore`) — no external state package required |

---

## Project Structure

```
lib/
  main.dart                          -> App entry point, Firebase init, theme wiring
  firebase_options.dart              -> Generated FlutterFire configuration
  theme/
    app_theme.dart                   -> Centralized color palette + ThemeData
  mock_data/
    inventory_store.dart             -> Tire/HistoryLog models + Firestore-backed InventoryStore
  utils/
    responsive.dart                  -> Tablet/phone breakpoint helper
    page_transitions.dart            -> Custom fade + slide PageRouteBuilder
  screens/
    splash_screen.dart               -> Branded loading screen, session check
    login_screen.dart                -> Firebase Auth sign-in
    nav_shell.dart                   -> Bottom nav / navigation rail shell + drawer
    dashboard_screen.dart            -> KPI cards, stock-level bars, monthly volume chart
    inventory_list_screen.dart       -> Searchable, branch-isolated tire directory
    tire_details_screen.dart         -> Full tire specification sheet
    add_inventory_screen.dart        -> Validated restock/intake form
    stock_history_screen.dart        -> Branch-isolated, read-only audit trail
    settings_screen.dart             -> Profile info, change password, app version
```

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and configured
- A Firebase project with **Firestore** and **Authentication** (Email/Password provider) enabled
- Xcode/Android Studio (or an emulator/physical device) for running the app

### Installation

```bash
git clone https://github.com/<your-org>/<your-repo>.git
cd <your-repo>
flutter pub get
flutter run
```

---

## Firebase Setup

This app requires a connected Firebase project — it will not run against local/mock data.

1. Create a Firebase project and register an Android/iOS/Web app.
2. Enable **Cloud Firestore** and **Authentication → Email/Password**.
3. Run `flutterfire configure` to generate `lib/firebase_options.dart` for your own project (the one in this repo points to the team's development project).
4. Publish the Firestore Security Rules found in `firestore.rules` — these enforce that a manager can only read/write data belonging to their own branch.
5. Manually create one document per manager account in the `managers` collection (document ID = the manager's Firebase Auth UID), containing:
   ```json
   { "branchId": "LIPA_CITY", "name": "Branch Manager Name" }
   ```

---

## Demo Accounts

> For grading/demo purposes only. Real deployments should issue individual credentials per manager.

| Username | Branch |
|---|---|
| `manager_lipa` | Lipa City |
| `manager_mahabang` | Mahabang Parang |
| `manager_starita` | Sta. Rita |

*(Passwords provided separately to the instructor.)*

---

## Team

| Name | Role / Contribution |
|---|---|
| _Glennzel Emman S.Gonda_ | _Full-stack development — Flutter app, Firebase integration, Firestore data layer, all screens_ |
| _Ralph Lorenz Ilagan_ | _	UI design support, Documentation_ |
| _Poul Bhenjamin Aranas_ | _Documentation_ |

---

## Course Information

- **Course:** IT 331
- **Project:** Mobile Application — Flutter Front-End Development

