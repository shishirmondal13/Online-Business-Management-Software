import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/base_model.dart';

/// User model for authentication
class AppUser extends BaseModel {
  final String? email;
  final String? pin;
  final String businessName;
  final String language;
  final String role; // 'admin' or 'user'
  final String accessLevel; // 'view' or 'edit'

  const AppUser({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    this.email,
    this.pin,
    required this.businessName,
    required this.language,
    this.role = 'user',
    this.accessLevel = 'view',
  });

  bool get isAdmin => role == 'admin';
  bool get canEdit => isAdmin || accessLevel == 'edit';

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      userId: map['userId'] ?? id,
      email: map['email'],
      pin: map['pin'],
      businessName: map['businessName'] ?? '',
      language: map['language'] ?? 'en',
      role: map['role'] ?? 'user',
      accessLevel: map['accessLevel'] ?? 'view',
      createdAt: BaseModel.timestampToDate(map['createdAt']),
      updatedAt: BaseModel.timestampToDate(map['updatedAt']),
    );
  }

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser.fromMap(data, doc.id);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'pin': pin,
      'businessName': businessName,
      'language': language,
      'role': role,
      'accessLevel': accessLevel,
      'createdAt': BaseModel.dateToTimestamp(createdAt),
      'updatedAt': BaseModel.dateToTimestamp(updatedAt),
    };
  }

  AppUser copyWith({
    String? id,
    String? userId,
    String? email,
    String? pin,
    String? businessName,
    String? language,
    String? role,
    String? accessLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      pin: pin ?? this.pin,
      businessName: businessName ?? this.businessName,
      language: language ?? this.language,
      role: role ?? this.role,
      accessLevel: accessLevel ?? this.accessLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
