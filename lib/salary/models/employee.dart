import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/base_model.dart';

class Employee extends BaseModel {
  final String name;
  final String designation;
  final String phone;
  final String email;
  final String address;
  final double salary;
  final DateTime joiningDate;
  final bool isActive;

  const Employee({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    required this.name,
    required this.designation,
    required this.phone,
    required this.email,
    required this.address,
    required this.salary,
    required this.joiningDate,
    required this.isActive,
  });

  factory Employee.fromMap(Map<String, dynamic> map, String id) {
    return Employee(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      designation: map['designation'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      salary: (map['salary'] ?? 0).toDouble(),
      joiningDate: BaseModel.timestampToDate(map['joiningDate']),
      isActive: map['isActive'] ?? true,
      createdAt: BaseModel.timestampToDate(map['createdAt']),
      updatedAt: BaseModel.timestampToDate(map['updatedAt']),
    );
  }

  factory Employee.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Employee.fromMap(data, doc.id);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'designation': designation,
      'phone': phone,
      'email': email,
      'address': address,
      'salary': salary,
      'joiningDate': BaseModel.dateToTimestamp(joiningDate),
      'isActive': isActive,
      'createdAt': BaseModel.dateToTimestamp(createdAt),
      'updatedAt': BaseModel.dateToTimestamp(updatedAt),
    };
  }

  Employee copyWith({
    String? name,
    String? designation,
    String? phone,
    String? email,
    String? address,
    double? salary,
    DateTime? joiningDate,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      designation: designation ?? this.designation,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      salary: salary ?? this.salary,
      joiningDate: joiningDate ?? this.joiningDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
