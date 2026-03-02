import 'package:hive/hive.dart';

part 'todo_model.g.dart';

/// Represents a single To-Do task stored in the encrypted Hive database.
///
/// [id]          - Unique identifier (UUID)
/// [title]       - Plain task title (still protected by DB encryption)
/// [description] - General description (still protected by DB encryption)
/// [secretNote]  - AES-256 encrypted field — even within the app, this is
///                 stored as ciphertext. Only decrypted when displayed.
/// [isCompleted] - Task completion status
/// [createdAt]   - Timestamp of creation
@HiveType(typeId: 0)
class TodoModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  /// This field is stored as AES-256 ciphertext in the database.
  /// M2 (EncryptionService) handles encryption/decryption of this field.
  @HiveField(3)
  String secretNote; // Stored encrypted

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  DateTime createdAt;

  TodoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.secretNote,
    this.isCompleted = false,
    required this.createdAt,
  });

  /// Creates a copy with updated fields (used in update operations)
  TodoModel copyWith({
    String? title,
    String? description,
    String? secretNote,
    bool? isCompleted,
  }) {
    return TodoModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      secretNote: secretNote ?? this.secretNote,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}
