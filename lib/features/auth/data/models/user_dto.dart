import 'package:med_super/features/auth/domain/entities/user.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';

class UserDto {
  const UserDto({
    required this.id,
    required this.phone,
    required this.roles,
    this.displayName,
    this.activeRole,
    this.email,
  });

  final String id;
  final String phone;
  final List<String> roles;
  final String? displayName;
  final String? activeRole;
  final String? email;

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
    id: json['id'] as String,
    phone: json['phone'] as String,
    roles: (json['roles'] as List<dynamic>? ?? const [])
        .map((e) => '$e')
        .toList(),
    displayName: (json['displayName'] ?? json['display_name']) as String?,
    activeRole: (json['activeRole'] ?? json['active_role']) as String?,
    email: json['email'] as String?,
  );

  User toEntity() {
    final parsedRoles = roles
        .map(UserRole.tryParse)
        .whereType<UserRole>()
        .toList();
    final rolesOrDefault = parsedRoles.isEmpty
        ? const [UserRole.patient]
        : parsedRoles;
    final active = UserRole.tryParse(activeRole) ?? rolesOrDefault.first;
    return User(
      id: id,
      phone: phone,
      roles: rolesOrDefault,
      activeRole: active,
      displayName: displayName,
      email: email,
    );
  }
}
