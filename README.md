# Prevue (YouTube Creator Intelligence & Pre-Flight Simulator)

> **Shipathon Hackathon Submission**  
> *Category: Best RevenueCat Integration & Best Craft of App Development*

Prevue is a YouTube creator intelligence suite engineered with a Curated Studio Light design system, RevenueCat In-App Purchases, and live YouTube Data API v3 synchronization.

---

## ✨ Key Features

1. **Daily Prescriptive Briefing ("What to Film Tomorrow")**:
   - **Category & Theme Intelligence Engine**: Automatically mines live video tags, titles, view counts, and Wikipedia topic categories directly from YouTube API to generate authentic, high-conviction video blueprints.
   - **Creator Persona Studio Card**: Displays verified handle, subscriber count, median views, and exact upload mining metrics.
   - **Production Runbook Modal Sheet**: 4-step filming pacing breakdown with instant 1-tap handoff to Pre-Flight Simulator.

2. **Pre-Flight Content Simulator ("Will this work?")**:
   - **Dynamic Heuristic Evaluation**: Radial gauge with Hook Score (0–10) and Audience Resonance (0–10).
   - **Concrete Projected Views Card**: Computes estimated views anchored directly to the creator's live median view baseline (e.g. `240,000 views • 3.2× Median`).
   - **0:00–0:30 Retention Hazard Scrubber**: Flags drop-off risks with interactive waveform scrubber and sentence inspection.
   - **3 Actionable Prescriptive Fixes with 1-Click Apply**: Real script restructuring, title curiosity amplification, and pacing cuts.

3. **Monetization Engine (RevenueCat Integration)**:
   - Entitlement: `creator_pro_access`
   - Offering: `default_creator_offering` (Monthly `$19.99/mo`, Annual `$149.00/yr • Save 38%`)
   - Free Tier: 3 simulations / month.
   - Pro Paywall BottomSheet with 7-Day Free Trial CTA.

4. **Channel Graph Baseline & Live YouTube API v3**:
   - Connects to any YouTube handle (e.g. `@Telusko`, `@Fireship`).

   - Computes median views, dynamic topic clusters, and upload history.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: Flutter 3.x (Dart 3.x)
- **State Management**: Provider
- **Responsiveness**: `flutter_screenutil`
- **Monetization**: `purchases_flutter` (RevenueCat SDK with graceful mock demo fallback)
- **Networking**: `dio` with custom interceptors and logging
- **Typography & Theme**: Google Fonts (Plus Jakarta Sans & JetBrains Mono) on a Curated Studio Light palette (`#FAFAFC` canvas, pure white tactile cards, editorial cobalt accents)

---

## 🚀 Getting Started

### 1. Prerequisites
- Flutter SDK (>=3.12.2)
- Android Studio / Xcode / VS Code

### 2. Clone & Install Dependencies
```bash
git clone https://github.com/Uday-kiran9147/shipathon_hackathon.git
cd shipathon_hackathon
flutter pub get
```

### 3. Environment Setup
Copy `.env.example` to `.env` and fill in your keys (optional; app includes mock/demo fallback):
```bash
cp .env.example .env
```

### 4. Run App & Tests
```bash
flutter test
flutter run
```

---

## 📄 License

This project is licensed under the Apache License, Version 2.0 - see the [LICENSE](LICENSE) file for details.
