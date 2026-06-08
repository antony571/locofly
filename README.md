# LocoFly — Flutter App Setup Guide

## What you have right now

```
locofly/
├── pubspec.yaml                    ← All dependencies (packages) the app needs
├── supabase_setup.sql              ← Run this in Supabase to create all tables
└── lib/
    ├── main.dart                   ← App entry point (starts here)
    ├── core/
    │   ├── constants/
    │   │   └── app_constants.dart  ← ⚠️ Put your Supabase URL here
    │   ├── theme/
    │   │   ├── app_colors.dart     ← All colors from Figma
    │   │   ├── app_theme.dart      ← Flutter theme (fonts, buttons, inputs)
    │   │   └── app_text_styles.dart← Named text styles
    │   └── router/
    │       └── app_router.dart     ← All screen routes
    ├── data/
    │   ├── models/
    │   │   └── models.dart         ← Data classes (Flight, Aircraft, Bid etc.)
    │   └── supabase/
    │       └── supabase_client.dart← Supabase connection setup
    └── features/
        └── home/screens/
            └── main_shell_screen.dart ← Bottom navigation bar
```

---

## Step 1 — Copy this project into your Flutter workspace

Copy the `locofly/` folder to wherever you keep your projects, then open it in VS Code:
```bash
cd path/to/locofly
code .
```

---

## Step 2 — Get your Supabase credentials

1. Go to [supabase.com](https://supabase.com) → your project
2. Click **Project Settings** (gear icon, left sidebar)
3. Click **API**
4. Copy:
   - **Project URL** — looks like `https://abcdefghij.supabase.co`
   - **anon public** key — a long string starting with `eyJ...`

5. Open `lib/core/constants/app_constants.dart` and replace:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```
with your actual values.

---

## Step 3 — Set up the database

1. In your Supabase project, click **SQL Editor** (left sidebar)
2. Click **New query**
3. Open `supabase_setup.sql` from this project
4. Copy the entire contents and paste into the SQL editor
5. Click **Run**

You should see "Success. No rows returned" — that means it worked.

To verify, click **Table Editor** — you should see 10 tables: users, aircraft, flights, bids, bookings, passengers, payments, notifications, special_offers.

---

## Step 4 — Install Flutter packages

In your terminal (inside the `locofly/` folder):
```bash
flutter pub get
```

This reads `pubspec.yaml` and downloads all the packages. It's like `npm install` if you've used Node.js.

---

## Step 5 — Run the app

With an Android emulator or iOS simulator open, or a real device connected:
```bash
flutter run
```

You should see the yellow LocoFly splash screen, then it navigates to a placeholder home screen with the bottom navigation bar.

---

## Step 6 — Enable Auth providers in Supabase

1. In Supabase → **Authentication** → **Providers**
2. Enable **Email** (already on by default)
3. Enable **Google** (you'll need a Google Cloud OAuth client ID — we'll set this up in Phase 2)
4. Enable **Apple** (needs Apple Developer account — we'll set this up in Phase 2)
5. Enable **Phone** (for OTP) — needs Twilio or similar SMS provider

---

## What's next

We'll build screens one phase at a time:

| Phase | What we build |
|-------|--------------|
| ✅ Phase 1 | Project setup (done!) |
| Phase 2 | Onboarding, Sign Up, Login, OTP |
| Phase 3 | Home, Flight List, Flight Detail, Amenities |
| Phase 4 | Place Bid, Passenger Details, Razorpay |
| Phase 5 | My Bids, Bookings, E-Ticket, Notifications, Profile |

---

## If something goes wrong

**`flutter pub get` fails** → Make sure you have Flutter 3.x installed. Run `flutter --version` to check.

**Supabase SQL errors** → Some lines (like `insert into storage.buckets`) may fail if your project already created default buckets. That's fine — just skip those lines and run the rest.

**App doesn't compile** → Run `flutter clean` then `flutter pub get` again.

**Red error screen in app** → This means your Supabase URL/key is wrong. Double-check `app_constants.dart`.
