# LocoFly — Flutter App Setup Guide

## Project Structure

```
locofly/
├── pubspec.yaml
├── supabase_setup.sql
└── lib/
    ├── main.dart
    ├── core/
    │   ├── constants/
    │   │   └── app_constants.dart
    │   ├── theme/
    │   │   ├── app_colors.dart
    │   │   ├── app_theme.dart
    │   │   └── app_text_styles.dart
    │   └── router/
    │       └── app_router.dart
    ├── data/
    │   ├── models/
    │   │   └── models.dart
    │   └── supabase/
    │       └── supabase_client.dart
    └── features/
        ├── auth/
        ├── home/
        ├── flights/
        ├── bids/
        ├── bookings/
        ├── notifications/
        └── profile/
```

## Step 1 — Open the Project

Copy the project folder into your Flutter workspace and open it in VS Code.

```bash
cd path/to/locofly
code .
```

## Step 2 — Configure Supabase

1. Open your Supabase project.

2. Navigate to Project Settings → API.

3. Copy the following:

   * Project URL
   * Anon Public Key

4. Open:

```text
lib/core/constants/app_constants.dart
```

Replace:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

with your actual Supabase credentials.

## Step 3 — Create the Database

1. Open Supabase SQL Editor.
2. Create a new query.
3. Open the file:

```text
supabase_setup.sql
```

4. Copy its contents into the SQL Editor.
5. Execute the script.

After execution, verify that the required tables have been created in the Table Editor.

## Step 4 — Install Dependencies

Run:

```bash
flutter pub get
```

This downloads all dependencies listed in `pubspec.yaml`.

## Step 5 — Launch the Application

Connect an Android device, emulator, iOS simulator, or physical device and run:

```bash
flutter run
```

The application should start and navigate to the main interface.

## Implemented Features

### Authentication

* Email-based sign up and login
* User session management
* Supabase authentication integration

### Home & Flight Discovery

* Flight listing screen
* Flight detail screen
* Aircraft and amenities display

### Bidding System

* Flight bidding workflow
* Bid placement and tracking
* Bid history management

### Passenger Management

* Passenger information collection
* Booking details management

### Booking System

* Booking confirmation
* E-ticket generation
* Booking history

### Notifications

* In-app notification support

### User Profile

* Profile management
* Account information updates

## Current Limitations

The following features are currently not fully implemented and exist only as placeholders or future extensions:

* Google OAuth login
* Apple Sign-In
* Phone OTP authentication
* Third-party SMS provider integration
* Razorpay payment gateway integration
* Production-ready payment processing
* Advanced notification delivery services

The application currently relies primarily on Supabase authentication and database functionality.

## Troubleshooting

### Dependency Installation Fails

Verify Flutter installation:

```bash
flutter --version
```

Then run:

```bash
flutter pub get
```

again.

### Database Script Errors

Some storage-related SQL statements may fail if the resources already exist in Supabase. These statements can be skipped if the required tables and buckets have already been created.

### Build Errors

Run:

```bash
flutter clean
flutter pub get
```

and rebuild the project.

### Supabase Connection Issues

Ensure that the values configured in:

```text
lib/core/constants/app_constants.dart
```
### Project Status

Most planned application screens and core workflows have been completed. Authentication, flight browsing, bidding, booking management, notifications, and profile functionality are available. Certain external service integrations, including OAuth providers and Razorpay payments, remain pending along with UI transitions, beautifications, etc. Back buttons may be missing in some places and only placeholder images are being used currently. Dark theme remains to be implemented.

match the Project URL and Anon Key from your Supabase project.

