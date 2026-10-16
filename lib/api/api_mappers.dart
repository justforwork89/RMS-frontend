import '../models/user.dart';

/// 서버 사용자 JSON(id, name, role, major, active) → [AppUser].
/// 서버 역할(STUDENT/INSTRUCTOR/ADMIN)은 소문자로 바꿔 enum 이름과 맞춘다.
AppUser userFromJson(Map<String, dynamic> j) {
  return AppUser(
    id: j['id'] as String,
    name: j['name'] as String,
    role: UserRole.values.byName((j['role'] as String).toLowerCase()),
    major: j['major'] as String?,
    active: j['active'] as bool,
  );
}

String roleToServer(UserRole role) => role.name.toUpperCase();
