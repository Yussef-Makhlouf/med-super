import 'user_role.dart';

/// Authenticated account — pure domain, no Flutter/Dio imports.
class User {
  const User({
    required this.id,
    required this.phone,
    required this.roles,
    required this.activeRole,
    this.displayName,
  });

  final String id;
  final String phone;
  final List<UserRole> roles;
  final UserRole activeRole;
  final String? displayName;

  bool get profileComplete =>
      displayName != null && displayName!.trim().isNotEmpty;

  bool get isPatient => activeRole == UserRole.patient;
  bool get isProvider =>
      activeRole == UserRole.doctor ||
      activeRole == UserRole.clinic ||
      activeRole == UserRole.pharmacy ||
      activeRole == UserRole.lab;

  User copyWith({
    String? id,
    String? phone,
    List<UserRole>? roles,
    UserRole? activeRole,
    String? displayName,
  }) =>
      User(
        id: id ?? this.id,
        phone: phone ?? this.phone,
        roles: roles ?? this.roles,
        activeRole: activeRole ?? this.activeRole,
        displayName: displayName ?? this.displayName,
      );
}
