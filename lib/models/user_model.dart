/// UserModel — Local user account stored in encrypted Hive box.
///
/// SECURITY NOTE:
///   - [passwordHash] stores SHA-256(salt + password) — never plain text
///   - [passwordSalt] is a unique per-user random salt (16 bytes, hex)
///     stored alongside the hash so login can re-derive and compare.
///   - Storing the salt is safe and standard practice (e.g. bcrypt does this).
///     The salt's job is to prevent rainbow tables, not to be secret.
class UserModel {
  final String uid;
  final String email;
  final String passwordHash;
  final String? passwordSalt; // ← NEW: per-user unique salt
  final bool isEmailVerified;

  UserModel({
    required this.uid,
    required this.email,
    required this.passwordHash,
    this.passwordSalt,
    required this.isEmailVerified,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'passwordHash': passwordHash,
        'passwordSalt': passwordSalt, // persisted with the user record
        'isEmailVerified': isEmailVerified,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['uid'] as String,
        email: json['email'] as String,
        passwordHash: json['passwordHash'] as String,
        passwordSalt:
            json['passwordSalt'] as String?, // nullable for backwards compat
        isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      );
}
