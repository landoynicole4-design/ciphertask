/// UserModel — Authenticated User State
///
/// Holds the minimal user data needed in memory after login.
/// This is NOT stored in Hive — it lives only in AuthViewModel's state
/// and is cleared on logout.
class UserModel {
  final String uid;
  final String email;
  final String? passwordHash;
  final bool isEmailVerified;

  UserModel({
    required this.uid,
    required this.email,
    this.passwordHash,
    this.isEmailVerified = true,
  });

  /// Convert UserModel to JSON map for local storage
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'passwordHash': passwordHash,
      'isEmailVerified': isEmailVerified,
    };
  }

  /// Create UserModel from JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool? ?? true,
    );
  }
}
