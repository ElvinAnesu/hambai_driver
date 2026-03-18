# Hambai Driver App – Implementation Plan

This document is a step-by-step plan to build the **Hambai Driver** app. The app will reuse the **same theme and color scheme** as the passenger app (Hambai Passenger): `AppColors`, `AppTheme` (light/dark), and `AppTextStyles`.

---

## Passenger App Summary (Reference)

- **Theme**: Primary `#FF1A4A`, primaryVariant, primaryLight, secondary, background, surface, surfaceBright, error, textPrimary, textSecondary.
- **Auth**: Splash → Onboarding → Login (phone +263) → OTP → Complete profile. Stored via SharedPreferences (AuthService); no Supabase auth in 

## Driver App Features Overview

| Feature | Description |
|--------|-------------|
| **Theme & branding** | Same as passenger: AppColors, AppTheme, AppTextStyles, gradients, card styles. |
| **Driver auth** | Login (phone + OTP), driver profile/registration; same flow as passenger or role-based. |
| **Driver dashboard** | Today’s summary, current session status, quick actions (Start ride / End ride). |
| **Start ride / session** | Select predefined route (or current route); start session → generate and show **driver code** (and optionally QR) for passengers. |
| **Active ride (driver)** | Show route name and stops; advance current stop; accept passenger boardings (NFC/QR/code) to deduct passenger ride and link to this driver/session. |
| **End ride / session** | End current session; show trip summary (e.g. rides collected). |
| **Driver code & QR** | Display code and QR so passengers can tap/scan/enter code. |
| **Driver history** | List of past sessions/rides (routes, date, rides collected). |
| **Profile & settings** | Same pattern as passenger: profile, edit profile, settings (notifications, theme, logout). |
| **Backend / data** | Driver sessions, ride deductions linked to driver; align with passenger ride recording (driverId). Use  mock/local for now. |

---

## Implementation Steps (Checklist)

Use the format below to mark steps complete as you implement. Each major feature is broken into ordered steps.

---

### 1. Project setup and theme

- [ ] **Step 1.1** Create a new Flutter project for the driver app (e.g. `hambai_driver`) or add a driver flavour to the existing repo.
- [ ] **Step 1.2** Copy or share `lib/core/theme/app_colors.dart` (primary, primaryVariant, primaryLight, secondary, background, surface, surfaceBright, error, textPrimary, textSecondary) into the driver app.
- [ ] **Step 1.3** Copy or share `lib/core/theme/app_theme.dart` (light and dark ThemeData using AppColors) into the driver app.
- [ ] **Step 1.4** Copy or share `lib/core/theme/app_text_styles.dart` (headlineLarge, headlineMedium, bodyLarge, bodyMedium, button) into the driver app.
- [ ] **Step 1.5** Set the driver app’s `MaterialApp` to use the same theme and darkTheme (and themeMode from settings if applicable).
- [ ] **Step 1.6** Add `AppConstants` (or equivalent) with app name e.g. `Hambai Driver` and country code `+263`.

---

### 2. Core structure and navigation

- [ ] **Step 2.1** Create `lib/core/constants/route_names.dart` with routes: splash, onboarding, login, otp, home, profile, editProfile, completeProfile, settings, activeRide, driverCodeDisplay, (and any driver-specific routes).
- [ ] **Step 2.2** Create `main.dart` with `MultiProvider` and register providers (e.g. AuthProvider, SettingsProvider, and later DriverSessionProvider / DriverHistoryProvider).
- [ ] **Step 2.3** Implement SplashScreen: same gradient and branding as passenger; after delay, navigate to onboarding / login / home based on auth and onboarding state.
- [ ] **Step 2.4** Implement OnboardingScreen (driver-focused copy, e.g. “Start your shift”, “Show your code to passengers”, “Collect rides”) with same visual style (gradient, page indicators, Get started).
- [ ] **Step 2.5** Implement LoginScreen: phone input with +263 prefix, Send OTP; same layout and styling as passenger.
- [ ] **Step 2.6** Implement OtpScreen: 6-digit OTP fields, Verify; same styling as passenger; on success navigate to Complete profile or Home.
- [ ] **Step 2.7** Implement CompleteProfileScreen for driver (full name, optional avatar); same pattern as passenger.
- [ ] **Step 2.8** Implement MainShell for driver: bottom navigation and/or drawer; tabs could be Home (dashboard), History, Profile (or combine Profile in drawer). Use same drawer header style (secondary background, UserAvatar, name, phone).
- [ ] **Step 2.9** Register all routes in the main app widget (routes map and initialRoute).

---

### 3. Auth (driver)

- [x] **Step 3.1** Create or reuse AuthService: loadFromPreferences, sendOtp, verifyOtp, completeOnboarding, updateProfile, logout, deleteAccount. If reusing passenger logic, ensure driver app only uses driver role or separate prefs keys if needed.
- [x] **Step 3.2** Create or reuse AuthProvider wrapping AuthService; expose isAuthenticated, hasCompletedOnboarding, currentUser, isLoading, isInitialized.
- [x] **Step 3.3** Ensure splash and login flows use the same validators (phone, OTP) and formatters (e.g. normalizePhone) as passenger.
- [ ] **Step 3.4** (Optional) Add driver-specific registration or approval step if required (e.g. driver ID, vehicle); document in plan and add screens as needed.

---

### 4. Driver dashboard (home)

- [ ] **Step 4.1** Create HomeDashboardScreen (driver): greeting with driver name; summary card (e.g. “Today: X rides”, “Current route: none” or current route name).
- [ ] **Step 4.2** Add “Start ride” primary button: when no active session, tap opens route selection or “Start session” flow.
- [ ] **Step 4.3** When there is an active session, show “Active ride” card (route name, current stop) and actions: “Show code / QR”, “Advance stop”, “End ride”.
- [ ] **Step 4.4** Reuse same surface/background/card styling (AppColors.surface, rounded corners, subtle shadow) as passenger home.
- [ ] **Step 4.5** Add drawer menu: Profile, Settings, Terms, Privacy, Help (same as passenger where applicable).

---

### 5. Route selection and start session

- [ ] **Step 5.1** Reuse or copy Location and PredefinedRoute models and RouteSearchService (or driver-specific service that lists routes the driver can operate).
- [ ] **Step 5.2** Create a “Select route” screen or bottom sheet: list predefined routes (e.g. from mock_predefined_routes or API); driver selects one and confirms.
- [ ] **Step 5.3** Create DriverSessionProvider (or equivalent): state for activeSession (routeId, route display name, list of stops, currentStopIndex, sessionId, driverCode).
- [ ] **Step 5.4** On “Start ride” confirm: generate a driver code (e.g. 6-digit or short alphanumeric); store session in provider and optionally in backend (when Supabase is used).
- [ ] **Step 5.5** After starting session, navigate to Active ride (driver) screen or show driver code on dashboard; ensure driver code is visible for passengers to enter in passenger app.

---

### 6. Driver code and QR display

- [ ] **Step 6.1** Create DriverCodeDisplayScreen (or widget): large, readable display of the current session’s driver code (e.g. “ABC123” or “4829”) so passengers can type it in the passenger app.
- [ ] **Step 6.2** Optional: add QR code generation (use a package like qr_flutter) encoding the same session/code so passengers can scan; same screen or tab.
- [ ] **Step 6.3** Style the code/QR card with AppColors (primary light background, primary text) to match passenger app accents.
- [ ] **Step 6.4** Ensure code is tied to the current driver session so that when a passenger submits the code, the backend (or mock) can deduct their ride and associate it with this driver/session.

---

### 7. Active ride (driver) screen

- [ ] **Step 7.1** Create ActiveRideScreen (driver): show route name and ordered list of stops; highlight current stop (e.g. “Now at: Avondale shops”).
- [ ] **Step 7.2** Add “Next stop” / “Advance stop” button: increment currentStopIndex and update UI (and sync to backend if applicable); when at last stop, show “End ride” only.
- [ ] **Step 7.3** Add “End ride” button: end the current session; show confirmation; then navigate to trip summary or dashboard.
- [ ] **Step 7.4** (Optional) Add “Board passenger” flow: driver scans/taps for passenger (NFC/QR/code entry from driver side) to record one ride deduction for that passenger linked to this session; integrate with same deduction logic as passenger app (driverId = current driver/session id).
- [ ] **Step 7.5** Use same card and list styling as passenger active ride screen (surface, rounded corners, primary icons).

---

### 8. End session and trip summary

- [ ] **Step 8.1** On “End ride” confirm: clear active session in DriverSessionProvider; persist session to history (local or API).
- [ ] **Step 8.2** Create TripSummaryScreen or bottom sheet: show route name, date/time, number of rides collected during the session; optional list of boardings.
- [ ] **Step 8.3** Provide “Done” to return to dashboard.

---

### 9. Driver history

- [x] **Step 9.1** Create a DriverSession or DriverRideSummary model (e.g. sessionId, routeId, routeDisplayName, startedAt, endedAt, ridesCollected, list of ride ids if needed).
- [x] **Step 9.2** Create DriverHistoryProvider and DriverHistoryService: fetch list of past sessions (mock list or Supabase query); expose list and loading state.
- [x] **Step 9.3** Create DriverHistoryScreen: list of past sessions (route name, date, rides collected); same list tile/card style as passenger ride history.
- [x] **Step 9.4** Add History tab or drawer item that navigates to DriverHistoryScreen.

---

### 10. Profile and settings

- [x] **Step 10.1** Reuse or copy ProfileScreen: show driver name, phone, avatar; Edit profile and Settings links; same layout and AppColors.
- [x] **Step 10.2** Reuse or copy EditProfileScreen and CompleteProfileScreen for driver (full name, avatar).
- [x] **Step 10.3** Reuse or copy SettingsScreen: Notifications toggle, Theme (light/dark/system), Logout, Delete account; same SettingsProvider and persistence.
- [x] **Step 10.4** Reuse SettingsProvider (themeMode, notificationsEnabled) and persist with SharedPreferences.
- [x] **Step 10.5** Copy or share UserAvatar widget and User model for drawer and profile.

---

### 11. Legal and help (reuse)

- [x] **Step 11.1** Add TermsScreen, PrivacyScreen, HelpScreen (same content and styling as passenger or driver-specific copy).
- [x] **Step 11.2** Link them from drawer or settings as in passenger app.

---

### 12. Backend and data (Supabase / API)

- [ ] **Step 12.1** Define Hambai Supabase schema (if not already): e.g. `drivers` (id, user_id, phone, full_name, created_at), `driver_sessions` (id, driver_id, route_id, driver_code, started_at, ended_at, rides_collected), `rides` (id, passenger_id, driver_session_id, rides_deducted, status, created_at). Use MCP or DB docs to align with passenger ride recording (driverId).
- [ ] **Step 12.2** Replace mock RouteSearchService in driver app with API calls to fetch routes/locations (server-side filtering) when backend is ready.
- [ ] **Step 12.3** Replace mock DriverHistoryService with Supabase queries for driver_sessions (and rides) for the logged-in driver.
- [ ] **Step 12.4** When a passenger taps/scans/enters code: backend validates code against active driver_sessions, deducts passenger ride balance, inserts ride row linked to driver_session; driver app can subscribe to real-time updates for “rides collected” if desired.
- [ ] **Step 12.5** (Optional) Use Supabase Auth for driver login and link driver profile to auth.users; keep phone OTP flow if already used for passenger.

---

### 13. Polish and parity

- [x] **Step 13.1** Reuse or copy core widgets: LoadingIndicator, EmptyState, ErrorState, validators, formatters from passenger app where applicable.
- [x] **Step 13.2** Ensure all app bar and FAB styling use AppColors.primary / secondary and white foreground.
- [x] **Step 13.3** Test light and dark theme across all driver screens.
- [ ] **Step 13.4** Add analytics or crash reporting if used in passenger app.
- [ ] **Step 13.5** Document driver-specific environment config (e.g. app name, API base URL) and any driver-only feature flags.

---

## Theme and color quick reference (same as passenger)

| Token | Value | Usage |
|-------|--------|--------|
| primary | `#FF1A4A` | Main brand, buttons, app bar |
| primaryVariant | `#CC1540` | Dark theme app bar, gradients |
| primaryLight | `#FFE5EB` | Card icon backgrounds |
| secondary | `#B31234` | CTAs, FAB |
| background | `#FAFAFA` | Scaffold |
| surface | `#F0F0F0` | Cards, list tiles |
| surfaceBright | white | Inputs, content blocks |
| textPrimary | `#212121` | Headings, body |
| textSecondary | `#757575` | Hints, subtitles |

Use the same gradient for splash and auth screens: `LinearGradient(colors: [AppColors.primary, AppColors.primaryVariant])`.

---

## Notes

- **No assumptions on DB**: The current Supabase project (from MCP) does not yet expose Hambai-specific tables. When implementing, use the MCP server to confirm schema or create migrations for drivers, driver_sessions, and rides.
- **Server-side filtering**: Any route or history lists should be filtered on the server (Supabase RPC or filtered queries), not only on the client.
- **Driver code lifecycle**: Driver code should be valid only for the active session and invalidated when the session ends; passenger app must send the code to the backend to resolve to a driver_session and then perform deduction.

You can mark each step with `[x]` as you complete it (e.g. `[x] Step 1.1`).
