// [MOCK] 백엔드 연동 시 이 파일은 삭제하고 실제 로그인 API 구현체로 교체한다.
import '../models/user.dart';
import '../repositories/auth_repository.dart';

class _MockAccount {
  const _MockAccount(this.password, this.user);

  final String password;
  final AppUser user;
}

/// 임시 계정 기반 로그인. 관리자 1명, 강사 2명, 학생 5명 (비밀번호 모두 1234).
class MockAuthRepository implements AuthRepository {
  static const Map<String, _MockAccount> _accounts = {
    'admin': _MockAccount(
      '1234',
      AppUser(id: 'admin', name: '관리자', role: UserRole.admin),
    ),
    'teacher1': _MockAccount(
      '1234',
      AppUser(id: 'teacher1', name: '김강사', role: UserRole.instructor),
    ),
    'teacher2': _MockAccount(
      '1234',
      AppUser(id: 'teacher2', name: '이강사', role: UserRole.instructor),
    ),
    'student1': _MockAccount(
      '1234',
      AppUser(
        id: 'student1',
        name: '김민준',
        role: UserRole.student,
        major: '컴퓨터공학',
      ),
    ),
    'student2': _MockAccount(
      '1234',
      AppUser(
        id: 'student2',
        name: '이서연',
        role: UserRole.student,
        major: '컴퓨터공학',
      ),
    ),
    'student3': _MockAccount(
      '1234',
      AppUser(
        id: 'student3',
        name: '박지호',
        role: UserRole.student,
        major: '정보보안',
      ),
    ),
    'student4': _MockAccount(
      '1234',
      AppUser(
        id: 'student4',
        name: '최유나',
        role: UserRole.student,
        major: '데이터분석',
      ),
    ),
    'student5': _MockAccount(
      '1234',
      AppUser(
        id: 'student5',
        name: '정하준',
        role: UserRole.student,
        major: '컴퓨터공학',
      ),
    ),
  };

  @override
  String? get loginHint =>
      '임시 계정 (비밀번호 1234)\n학생: student1 ~ student5\n강사: teacher1, teacher2\n관리자: admin';

  @override
  Future<AppUser?> login(String loginId, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final account = _accounts[loginId.trim()];
    if (account == null || account.password != password) return null;
    return account.user;
  }
}
