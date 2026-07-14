# 🔥 Firebase Setup Guide for I-Buzz BD Management App

## Prerequisites
- A Google account
- Firebase Console access: https://console.firebase.google.com
- Flutter SDK installed
- Android Studio (for Android) or Xcode (for iOS)

---

## Step 1: Create Firebase Project

1. Go to **[Firebase Console](https://console.firebase.google.com)**
2. Click **"Add Project"** or **"Create a project"**
3. Enter project name: `IBuzzBDManagement`
4. Disable Google Analytics (optional - not needed for this app)
5. Click **"Create Project"**
6. Wait for the project to be created, then click **"Continue"**

---

## Step 2: Enable Firebase Services

### 2.1 Enable Authentication
1. In the left sidebar, go to **Build → Authentication**
2. Click **"Get Started"**
3. Go to **Sign-in method** tab
4. Click on **"Anonymous"**
5. Toggle the **"Enable"** switch ON
6. Click **"Save"**

### 2.2 Enable Cloud Firestore
1. In the left sidebar, go to **Build → Firestore Database**
2. Click **"Create database"**
3. Select **"Start in test mode"** (we'll add security rules later)
4. Choose a location: **asia-south1 (Mumbai)** (closest to Bangladesh)
5. Click **"Enable"**

---

## Step 3: Android Setup 📱

### 3.1 Register Android App in Firebase
1. In Firebase Console, click the **gear icon** ⚙️ next to "Project Overview"
2. Select **"Project settings"**
3. Scroll down and click **"Add app"** → Select **Android icon** 🤖
4. Fill in the details:
   - **Android package name:** `com.ibuzz.ibuzz_bd_management`
   - **App nickname:** `I-Buzz BD Management`
   - **Debug signing certificate SHA-1:** (optional, skip for now)
5. Click **"Register app"**

### 3.2 Download and Place google-services.json
1. Click **"Download google-services.json"**
2. Save the file
3. Move/Copy the file to:
   ```
   d:\web app\I-buzz bd mangement\android\app\google-services.json
   ```
4. Click **"Next"** → **"Next"** → **"Continue to console"**

### 3.3 Verify Android Configuration
The Gradle files have already been configured. Just verify:
- `android/settings.gradle.kts` has Google Services plugin
- `android/app/build.gradle.kts` applies the plugin

---

## Step 4: iOS Setup 🍎

### 4.1 Register iOS App in Firebase
1. In Firebase Console Project Settings, click **"Add app"** → Select **iOS icon** 🍎
2. Fill in the details:
   - **iOS bundle ID:** `com.ibuzz.ibuzzBdManagement`
   - **App nickname:** `I-Buzz BD Management`
   - **App Store ID:** (optional, skip for now)
3. Click **"Register app"**

### 4.2 Download and Place GoogleService-Info.plist
1. Click **"Download GoogleService-Info.plist"**
2. Save the file
3. Open your project in **Xcode**:
   ```bash
   cd "d:\web app\I-buzz bd mangement\ios"
   open Runner.xcworkspace
   ```
4. In Xcode:
   - Right-click on **Runner** folder (with blue icon)
   - Select **"Add Files to 'Runner'..."**
   - Navigate to and select `GoogleService-Info.plist`
   - ✅ Check **"Copy items if needed"**
   - Click **"Add"**
5. In Firebase Console, click **"Next"** → **"Next"** → **"Continue to console"**

### 4.3 Update iOS Bundle Identifier
Open `ios/Runner.xcodeproj/project.pbxproj` or use Xcode:
1. Open Xcode
2. Select **Runner** project
3. Select **Runner** target
4. Go to **General** tab
5. Set **Bundle Identifier** to: `com.ibuzz.ibuzzBdManagement`

### 4.4 Update iOS Minimum Deployment Target
In Xcode or edit `ios/Podfile`:
```ruby
platform :ios, '13.0'
```

Then run:
```bash
cd ios
pod install
cd ..
```

---

## Step 5: Run the App 🚀

### Clean and get dependencies:
```bash
cd "d:\web app\I-buzz bd mangement"
flutter clean
flutter pub get
```

### Run on Android:
```bash
flutter run
```
Or select an Android emulator/device in VS Code and press F5.

### Run on iOS (Mac only):
```bash
flutter run
```
Or open `ios/Runner.xcworkspace` in Xcode and run.

---

## Step 6: Security Rules (Production) 🔒

Before releasing to production, update Firestore security rules:

Go to **Firestore Database → Rules** and add:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /{collection}/{document=**} {
      allow read, write: if request.auth != null 
        && request.resource.data.userId == request.auth.uid;
    }
    
    // Allow users to read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Troubleshooting 🔧

### Android: "google-services.json not found"
- Make sure the file is in: `android/app/google-services.json`
- The package name in the file must match: `com.ibuzz.ibuzz_bd_management`

### iOS: "GoogleService-Info.plist not found"
- Make sure the file is added to the Xcode project (not just the folder)
- The bundle ID must match: `com.ibuzz.ibuzzBdManagement`

### "No Firebase App has been created"
- Ensure `Firebase.initializeApp()` is called in `main.dart` (already done)
- Check that configuration files are in place

### Build errors with minSdk
- The project is configured with `minSdk = 23` which should work with Firebase

---

## Quick Checklist ✅

- [ ] Firebase project created
- [ ] Anonymous Authentication enabled
- [ ] Cloud Firestore enabled (test mode)
- [ ] Android: `google-services.json` placed in `android/app/`
- [ ] iOS: `GoogleService-Info.plist` added to Xcode project
- [ ] Run `flutter clean && flutter pub get`
- [ ] Run `flutter run` successfully

---

## Need Help?

If you encounter any issues, please share:
1. The exact error message
2. Which step you're on
3. Whether it's Android or iOS

Happy coding! 🎉
