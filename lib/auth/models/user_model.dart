import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/base_model.dart';
import '../../shared/constants/admin_accounts.dart';

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
    this.accessLevel = 'edit',
  });

  bool get isAdmin =>
      role == 'admin' || AdminAccounts.contains(email);
  bool get canEdit => isAdmin || accessLevel == 'edit';

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      userId: map['userId'] ?? id,
      email: map['email'] as String?,
      pin: map['pin'] as String?,
      businessName: map['businessName'] ?? '',
      language: map['language'] ?? 'en',
      role: map['role'] ?? 'user',
      accessLevel: map['accessLevel'] ?? 'edit',
      createdAt: BaseModel.timestampToDate(map['createdAt']),
      updatedAt: BaseModel.timestampToDate(map['updatedAt']),
    );
  }

  factory AppUser.fromFirestore(
    DocumentSnapshot doc, {
    String? fallbackEmail,
  }) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final map = Map<String, dynamic>.from(data);
    if ((map['email'] == null || (map['email'] as String).isEmpty) &&
        fallbackEmail != null) {
      map['email'] = fallbackEmail;
    }
    return AppUser.fromMap(map, doc.id);
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
