# 🔐 CipherTask - Security Cheatsheet

## Overview

CipherTask is a secure task management app for high-profile executives. All data is encrypted end-to-end with AES-256.

---

## 🛡️ Security Features Implemented

### 1. Database Encryption (Trust No One) ✅

- **What:** Entire database file is encrypted
- **How:** Hive with AES-256 encryption (`HiveAesCipher`)
- **Result:** Even if hackers extract the .hive file via ADB, they only see garbage data
- **File:** `lib/services/database_service.dart`

### 2. Session Security (Auto-lock) ✅

- **What:** Auto-logout after inactivity
- **How:** Session timer tracks user activity
- **Timeout:** 2 minutes (120 seconds)
- **File:** `lib/services/session_service.dart`

### 3. Hardware Security (Keys in Secure Enclave) ✅

- **What:** Encryption keys stored in hardware-backed secure storage
- **How:**
  - Android: Android Keystore (hardware-backed)
  - iOS: Keychain
- **NOT stored:** Keys are NEVER hardcoded - generated at runtime
- **File:** `lib/services/key_storage_service.dart`

### 4. Screenshot Prevention ✅

- **What:** Blocks screenshots and screen recording
- **How:** `FlutterWindowManager.FLAG_SECURE`
- **File:** `lib/main.dart`

### 5. Biometric Authentication ✅

- **What:** Fingerprint/Face ID login support
- **How:** `FlutterFragmentActivity` + `local_auth` package
- **File:** `android/app/src/main/java/.../MainActivity.kt`

---

## 📁 Project Structure

```
ciphertask/
├── lib/
│   ├── main.dart                    # App entry point, window security
│   ├── models/
│   │   ├── todo_model.dart         # ToDo data model
│   │   └── user_model.dart         # User data model
│   ├── services/
│   │   ├── database_service.dart   # Encrypted Hive database
│   │   ├── encryption_service.dart # AES-256 encryption/decryption
│   │   ├── key_storage_service.dart # Hardware-backed key storage
│   │   ├── session_service.dart     # Auto-logout timer
│   │   └── otp_service.dart         # OTP generation & verification
│   ├── utils/
│   │   └── constants.dart         # App-wide constants
│   ├── viewmodels/
│   │   ├── auth_viewmodel.dart     # Authentication logic
│   │   └── todo_viewmodel.dart     # ToDo CRUD logic
│   └── views/
│       ├── login_view.dart          # Login screen
│       ├── register_view.dart       # Registration screen
│       └── todo_list_view.dart      # Main to-do list screen
├── android/
│   └── app/src/main/java/.../MainActivity.kt  # Biometric activity
└── pubspec.yaml                     # Dependencies
```

---

## 🔑 Key Constants

| Constant                | Value                 | Purpose                 |
| ----------------------- | --------------------- | ----------------------- |
| `sessionTimeoutSeconds` | 120                   | Auto-lock after 2 min   |
| `todoBoxName`           | 'secure_todos'        | Encrypted Hive box name |
| `hiveEncryptionKeyName` | 'hive_encryption_key' | Key storage identifier  |
| `hasLoggedInOnceKey`    | 'has_logged_in_once'  | Biometric prerequisite  |

---

## 👥 Team Members & Responsibilities

### 🔐 CipherTask Development Team

| **Member**                 | **Role**                     | **Responsibilities**                                                      |
| -------------------------- | ---------------------------- | ------------------------------------------------------------------------- |
| **Christian Ville Ranque** | Lead Architect & DB Engineer | Project setup, MVVM structure, Encrypted Hive DB, CRUD operations         |
| **Antonio Uy**             | Security & Cryptography Lead | AES-256 EncryptionService, Key generation & FlutterSecureStorage          |
| **Joemarie Estologa**      | Auth & Biometrics Specialist | local_auth biometrics, SessionService (2-min auto-logout), AuthViewModel  |
| **Stephen Pusta**          | Backend & Network (SSL)      | Firebase Auth registration/login, HTTPS enforcement, OTP bonus screen     |
| **Nicole James Landoy**    | UI/UX & Integration          | LoginView, RegisterView, TodoListView, privacy blur, Provider integration |

### Role Breakdown by File

#### Frontend Developer (Nicole James Landoy)

- **Files:** `lib/views/*.dart`, `lib/main.dart`
- **Key Files:**
  - `login_view.dart` - Login screen
  - `register_view.dart` - Registration screen
  - `todo_list_view.dart` - Main task list

#### Backend/Security Developer (Christian Ville Ranque, Antonio Uy)

- **Files:** `lib/services/*.dart`, `lib/viewmodels/*.dart`
- **Key Files:**
  - `database_service.dart` - Encrypted storage
  - `encryption_service.dart` - AES-256 encryption
  - `key_storage_service.dart` - Hardware-backed key storage
  - `auth_viewmodel.dart` - Authentication logic
  - `todo_viewmodel.dart` - ToDo CRUD logic

#### Android Developer (Joemarie Estologa)

- **Files:** `android/app/src/main/java/`
- **Key Files:**
  - `MainActivity.kt` - Biometric authentication setup
  - `session_service.dart` - Auto-logout functionality

#### Network/Auth Specialist (Stephen Pusta)

- **Files:** `lib/services/otp_service.dart`, Firebase configuration
- **Key Files:**
  - `otp_service.dart` - OTP generation and verification
  - `android/app/google-services.json` - Firebase configuration

---

## 📋 Common Tasks Quick Reference

### Adding a New Screen

1. Create view in `lib/views/`
2. Add route in `lib/main.dart` routes section
3. Import in `main.dart`

### Modifying Session Timeout

Edit `lib/utils/constants.dart`:

```
dart
static const int sessionTimeoutSeconds = 120; // Change value here
```

### Changing Encryption Key Storage

Edit `lib/services/key_storage_service.dart`

---

## 🔒 Security Flow Diagram

```
User Login
    ↓
AuthViewModel.verifyCredentials()
    ↓
SessionService.start() ← Starts 2-min timer
    ↓
User creates task
    ↓
EncryptionService.encrypt() ← AES-256
    ↓
DatabaseService.createTodo() ← Stored in encrypted Hive
    ↓
[If inactive for 2 min] → Auto-logout
```

---

## ✅ Testing Checklist

- [ ] Login with email/password works
- [ ] Biometric login works (fingerprint/face)
- [ ] Tasks are encrypted in database
- [ ] Session auto-locks after 2 minutes
- [ ] Screenshots are blocked
- [ ] Encryption keys are in secure storage

---

## 📞 Quick Commands

```
bash
# Run app
flutter run

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Run tests
flutter test
```

---

_Last Updated: March 2026_
_CipherTask v1.0.0_
