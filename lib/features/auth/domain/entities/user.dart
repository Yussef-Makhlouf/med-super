import 'user_role.dart';

/// Authenticated account — pure domain, no Flutter/Dio imports.
class User {
  const User({
    required this.id,
    required this.phone,
    required this.roles,
    required this.activeRole,
    this.displayName,
    this.email,
  });

  final String id;
  final String phone;
  final List<UserRole> roles;
  final UserRole activeRole;
  final String? displayName;
  final String? email;

  bool get profileComplete =>
      displayName != null && displayName!.trim().isNotEmpty;

  bool get isPatient => activeRole == UserRole.patient;

  /// True for all provider-side roles including clinic assistants — all are
  /// routed to the `/provider/*` branch of the app.
  bool get isProvider =>
      activeRole == UserRole.doctor ||
      activeRole == UserRole.clinic ||
      activeRole == UserRole.pharmacy ||
      activeRole == UserRole.lab ||
      activeRole == UserRole.clinicStaff;

  /// True only for clinic assistants (`CLINIC_STAFF`). A subset of
  /// [isProvider] — used to hide Doctor-only screens (assistant management,
  /// clinic settings, schedule editor, wallet) from assistant sessions.
  bool get isAssistant => activeRole == UserRole.clinicStaff;

  /// True only for the Doctor role — used to show Doctor-only management
  /// features that assistants must not see.
  bool get isDoctor => activeRole == UserRole.doctor;

  User copyWith({
    String? id,
    String? phone,
    List<UserRole>? roles,
    UserRole? activeRole,
    String? displayName,
    String? email,
  }) => User(
    id: id ?? this.id,
    phone: phone ?? this.phone,
    roles: roles ?? this.roles,
    activeRole: activeRole ?? this.activeRole,
    displayName: displayName ?? this.displayName,
    email: email ?? this.email,
  );
}
