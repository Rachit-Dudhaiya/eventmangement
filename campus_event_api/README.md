# Campus Event & Attendance REST API (PHP 8)

## Quick Start

1. **Install Composer autoloader**:
   ```bash
   cd campus_event_api
   composer install
   ```
2. **Configure environment**:
   ```bash
   cp .env.example .env
   ```
   Update `DB_HOST`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD` in `.env`.
3. **Import MySQL schema & seed data**:
   ```bash
   mysql -u root -p < database/database.sql
   ```
   For an existing database, apply the inbox migration:
   ```bash
   mysql -u root -p campus_event_db < database/migrations/20261120_create_notification_recipients.sql
   ```
   Replace `campus_event_db` with the database configured in `.env` if it differs.
4. **Run the built-in PHP development server** (exposing only `public/`):
   ```bash
   php -S 0.0.0.0:8000 -t public
   ```
5. **Verify**:
   Open `http://localhost:8000/api/health`.

## Push Notifications

1. Create a Firebase project and register the Flutter app's Android (`com.example.eventmanagment`) and iOS bundle IDs.
2. Provide the Firebase app options as Flutter compile-time values. For example:

   ```bash
   flutter run \
     --dart-define=FIREBASE_PROJECT_ID=your-project-id \
     --dart-define=FIREBASE_MESSAGING_SENDER_ID=your-sender-id \
     --dart-define=FIREBASE_ANDROID_API_KEY=your-android-api-key \
     --dart-define=FIREBASE_ANDROID_APP_ID=your-android-app-id \
     --dart-define=FIREBASE_IOS_API_KEY=your-ios-api-key \
     --dart-define=FIREBASE_IOS_APP_ID=your-ios-app-id \
     --dart-define=FIREBASE_IOS_BUNDLE_ID=your.ios.bundle.id
   ```

   Include `FIREBASE_WEB_API_KEY`, `FIREBASE_WEB_APP_ID`, `FIREBASE_WEB_AUTH_DOMAIN`, and `FIREBASE_WEB_VAPID_KEY` when running the web app. For web, replace the `YOUR_FIREBASE_*` placeholders in `web/firebase-messaging-sw.js` with the same Firebase web app values. Never commit Firebase service-account credentials or private keys.
3. Configure an APNs authentication key for the iOS app in Firebase Console. Android 13+ will request notification permission in the app.
4. Configure `FCM_PROJECT_ID` and `FCM_SERVICE_ACCOUNT_PATH` in `.env` with a Firebase service account that has Firebase Cloud Messaging permission. Keep the service-account JSON outside `public/`.
5. Sign in on a device and allow notifications. Organizers and admins can send event updates (such as venue changes or corrections) using **Notify Registrants**. Users can open **Notifications** from their profile to view received messages; senders can view messages in the **Sent** tab.

## Development Accounts (Password: `Password123!`)
- **Admin**: `admin@campus.edu`
- **Organizer**: `organizer@campus.edu`
- **Student**: `student@campus.edu`
