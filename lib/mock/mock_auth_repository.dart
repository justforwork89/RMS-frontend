// [MOCK] 백엔드 연동 시 이 파일은 삭제하고 로그인/사용자 API 구현체로 교체한다.
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/business_exception.dart';
import '../repositories/user_repository.dart';

class _Account {
  _Account(this.user, this.password);

  AppUser user;
  String password;
}

/// 임시 계정 기반 로그인 + 사용자 관리. 관리자 1명, 강사 2명, 학생 5명 (비밀번호 모두 1234).
class MockAuthRepository implements AuthRepository, UserRepository {
  final List<_Account> _accounts = [
    _Account(
      const AppUser(id: 'admin', name: '관리자', role: UserRole.admin),
      '1234',
    ),
    _Account(
      const AppUser(id: 'teacher1', name: '김강사', role: UserRole.instructor),
      '1234',
    ),
    _Account(
      const AppUser(id: 'teacher2', name: '이강사', role: UserRole.instructor),
      '1234',
    ),
    _Account(
      const AppUser(
        id: 'student1',
        name: '김민준',
        role: UserRole.student,
        major: '컴퓨터공학',
      ),
      '1234',
    ),
    _Account(
      const AppUser(
        id: 'student2',
        name: '이서연',
        role: UserRole.student,
        major: '컴퓨터공학',
      ),
      '1234',
    ),
    _Account(
      const AppUser(
        id: 'student3',
        name: '박지호',
        role: UserRole.student,
        major: '정보보안',
      ),
      '1234',
    ),
    _Account(
      const AppUser(
        id: 'student4',
        name: '최유나',
        role: UserRole.student,
        major: '데이터분석',
      ),
      '1234',
    ),
    _Account(
      const AppUser(
        id: 'student5',
        name: '정하준',
        role: UserRole.student,
        major: '컴퓨터공학',
      ),
      '1234',
    ),
  ];

  int _indexOf(String id) => _accounts.indexWhere((a) => a.user.id == id);

  @override
  String? get loginHint =>
      '임시 계정 (비밀번호 1234)\n학생: student1 ~ student5\n강사: teacher1, teacher2\n관리자: admin';

  @override
  Future<AppUser?> login(String loginId, String password) async {
    await _latency();
    final index = _indexOf(loginId.trim());
    if (index < 0) return null;
    final account = _accounts[index];
    if (account.password != password || !account.user.active) return null;
    return account.user;
  }

  @override
  Future<List<AppUser>> fetchUsers() async {
    await _latency();
    return _accounts.map((a) => a.user).toList();
  }

  @override
  Future<AppUser> save(
    AppUser user, {
    String? password,
    required bool isNew,
  }) async {
    await _latency();
    if (user.id.trim().isEmpty) {
      throw const BusinessException('아이디는 필수입니다.');
    }
    if (user.name.trim().isEmpty) {
      throw const BusinessException('이름은 필수입니다.');
    }
    final index = _indexOf(user.id);
    if (isNew) {
      if (index >= 0) {
        throw const BusinessException('이미 사용 중인 아이디입니다.');
      }
      if (password == null || password.isEmpty) {
        throw const BusinessException('비밀번호는 필수입니다.');
      }
      _accounts.add(_Account(user, password));
      return user;
    }
    if (index < 0) {
      throw const BusinessException('존재하지 않는 사용자입니다.');
    }
    _accounts[index].user = user;
    if (password != null && password.isNotEmpty) {
      _accounts[index].password = password;
    }
    return user;
  }

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 200));
}
