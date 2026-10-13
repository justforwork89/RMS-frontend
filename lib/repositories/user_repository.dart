import '../models/user.dart';

/// 사용자 관리 데이터 접근 계약. 백엔드 연동 시 사용자 API 구현체를 주입한다.
/// (임시 구현: lib/mock/mock_auth_repository.dart)
abstract class UserRepository {
  Future<List<AppUser>> fetchUsers();

  /// isNew이면 등록(비밀번호 필수), 아니면 수정(비밀번호는 입력했을 때만 변경).
  Future<AppUser> save(AppUser user, {String? password, required bool isNew});
}
