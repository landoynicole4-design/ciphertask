# OTP Merge Task - TODO List

## Status: IN PROGRESS

### Task 1 — Delete otp_verification_view.dart:

- [ ] Remove lib/views/otp_verification_view.dart completely

### Task 2 — Create otp_service.dart:

- [ ] Create lib/services/otp_service.dart with simulation OTP logic

### Task 3 — Update auth_viewmodel.dart:

- [ ] Add OTP state variables
- [ ] Add sendOtp(), verifyOtp(), resetOtp() methods

### Task 4 — Update register_view.dart:

- [ ] Remove import of otp_verification_view.dart
- [ ] Add \_showOtpField boolean
- [ ] Embed OTP UI with toggle
- [ ] Add back button on OTP section

### Task 5 — Fix warnings:

- [ ] Remove unused \_onDigitPaste function
- [ ] Add const keyword to constructors
- [ ] Remove duplicate dart:math import

## Completed:

- [x] Plan created and confirmed
