import '../models/user.dart';

/// 인증 계약. 백엔드 연동 시 로그인 API(예: POST /api/auth/login) 구현체를 주입한다.
/// (임시 구현: lib/mock/mock_auth_repository.dart)
abstract class AuthRepository {
  /// 로그인 화면에 보여줄 안내 문구(임시 계정 안내 등). 운영 구현은 null.
  String? get loginHint;

  /// 성공 시 사용자, 아이디/비밀번호 불일치 시 null.
  Future<AppUser?> login(String loginId, String password);
}
