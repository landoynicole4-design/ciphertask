# 🔐 CipherTask — Secure Encrypted To-Do System

> A Flutter application implementing AES-256 encryption, biometric authentication, hardware-backed key storage, and MVVM architecture for secure task management.

---

Apk File: (build/app/outputs/flutter-apk/app-release.apk)[CipherTask Download APK](https://github.com/landoynicole4-design/ciphertask/releases/download/v1.0/app-release.apk)



## 👥 Team Members & Roles

| Member                 | Role                         | Responsibilities                                                          |
| ---------------------- | ---------------------------- | ------------------------------------------------------------------------- |
| Christian Ville Ranque | Lead Architect & DB Engineer | Project setup, MVVM structure, Encrypted Hive DB, CRUD operations         |
| Antonio Uy             | Security & Cryptography Lead | AES-256 EncryptionService, Key generation & FlutterSecureStorage          |
| Joemarie Estologa      | Auth & Biometrics Specialist | local_auth biometrics, SessionService (2-min auto-logout), AuthViewModel  |
| Stephen Pusta          | Backend & Network (SSL)      | Firebase Auth registration/login, HTTPS enforcement, OTP bonus screen     |
| Nicole James Landoy    | UI/UX & Integration          | LoginView, RegisterView, TodoListView, privacy blur, Provider integration |

---

## 🏗️ Architecture (Strict MVVM)

```
lib/
├── main.dart                  # Entry point — DI, routes, session listener
├── models/
│   ├── todo_model.dart        # Task data structure (Hive annotated)
│   └── user_model.dart        # User profile
├── views/
│   ├── login_view.dart        # Biometric & Password Login
│   ├── register_view.dart     # Registration
│   ├── todo_list_view.dart    # Main encrypted task list
│   └── otp_view.dart          # 6-digit OTP verification (Bonus)
├── viewmodels/
│   ├── auth_viewmodel.dart    # Login, Bio-Auth, auto-logout logic
│   └── todo_viewmodel.dart    # CRUD with encryption logic
├── services/
│   ├── encryption_service.dart   # AES-256 encrypt/decrypt
│   ├── database_service.dart     # Encrypted Hive CRUD
│   ├── key_storage_service.dart  # FlutterSecureStorage wrapper
│   └── session_service.dart      # 2-minute inactivity timer
└── utils/
    └── constants.dart         # App-wide config values
```

---

## 🔒 Security Features

### 1. Database Encryption

- Uses **Hive** with `HiveAesCipher` — the entire `.hive` file on disk is AES-256 encrypted
- Even if an attacker extracts the app's data folder, they only see random bytes
- The DB encryption key is generated on first run and stored in Android Keystore / iOS Keychain via `flutter_secure_storage`

### 2. AES-256 Field Encryption

- The `secretNote` field of every task is encrypted with AES-256-CBC via the `encrypt` package
- Even within the app, notes are stored as Base64 ciphertext — decrypted only when the user views them
- AES key and IV are stored in hardware-backed secure storage (never hardcoded)

### 3. Biometric Authentication

- Uses `local_auth` for fingerprint / Face ID login
- Prerequisite: user must have logged in with a password at least once
- Fallback to password login always available

### 4. Auto-Logout (Session Timeout)

- A 2-minute inactivity timer runs whenever the user is logged in
- Every screen touch (detected by a root-level `Listener` widget) resets the timer
- On timeout: user is automatically logged out and redirected to the login screen

### 5. Hardware-Backed Key Storage

- All encryption keys are stored using `flutter_secure_storage`
- Android: Android Keystore (hardware security module)
- iOS: Keychain with `kSecAttrAccessibleWhenUnlocked`
- Keys are **never** hardcoded or stored in SharedPreferences

### 6. Privacy Protection (Bonus)

- `flutter_windowmanager` with `FLAG_SECURE` prevents:
  - Screenshots of the app
  - App content appearing in the Android Recent Apps switcher (blurred)

### 7. MFA / OTP (Bonus)

- 6-digit OTP screen shown after registration
- Simulated for demo (real implementation would use Firebase Extensions or Twilio)

---

## 📦 Key Dependencies

```yaml
flutter_secure_storage: ^9.2.2 # Hardware-backed key storage
encrypt: ^5.0.3 # AES-256 encryption
hive_flutter: ^1.1.0 # Encrypted local database
local_auth: ^2.2.0 # Biometric authentication
firebase_auth: ^5.3.1 # User registration & login
flutter_windowmanager: ^0.2.0 # Screenshot prevention & privacy blur
provider: ^6.1.2 # State management (MVVM)
```

---

## 🚀 Setup & Run

```bash
# Install dependencies
flutter pub get

# Generate Hive adapters
flutter pub run build_runner build

# Run the app
flutter run
```

