import 'package:hive/hive.dart';

part 'todo_model.g.dart';

/// Represents a single To-Do task stored in the encrypted Hive database.
///
/// [userId]      - Email of the owning user — used to filter tasks per account
/// [id]          - Unique identifier (UUID)
/// [title]       - Plain task title (still protected by DB encryption)
/// [description] - General description (still protected by DB encryption)
/// [secretNote]  - AES-256 encrypted field — even within the app, this is
///                 stored as ciphertext. Only decrypted when displayed.
/// [isCompleted] - Task completion status
/// [createdAt]   - Timestamp of creation
@HiveType(typeId: 0)
class TodoModel extends HiveObject {
  // FIX: Added userId so tasks are scoped per account.
  // Stored at HiveField(6) to avoid breaking existing field indices.
  @HiveField(6)
  String userId;

  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  /// This field is stored as AES-256 ciphertext in the database.
  /// EncryptionService handles encryption/decryption of this field.
  @HiveField(3)
  String secretNote;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  DateTime createdAt;

  TodoModel({
    required this.userId,
    required this.id,
    required this.title,
    required this.description,
    required this.secretNote,
    this.isCompleted = false,
    required this.createdAt,
  });

  TodoModel copyWith({
    String? title,
    String? description,
    String? secretNote,
    bool? isCompleted,
  }) {
    return TodoModel(
      userId: userId,
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      secretNote: secretNote ?? this.secretNote,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}
