/// 로그인 사용자 역할.
enum UserRole {
  student('학생'),
  instructor('강사'),
  admin('관리자');

  const UserRole(this.label);

  final String label;
}

/// 로그인한 사용자 Model.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.major,
  });

  /// 로그인 아이디.
  final String id;
  final String name;
  final UserRole role;

  /// 학생의 소속 전공 (학생만 사용).
  final String? major;
}
