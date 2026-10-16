import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/business_exception.dart';
import 'api_client.dart';
import 'api_mappers.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api, {this.onLoggedIn});

  final ApiClient _api;

  /// 로그인 성공 직후 실행할 작업 (예: 강사 선택지 로드).
  final Future<void> Function()? onLoggedIn;

  @override
  String? get loginHint => null;

  @override
  Future<AppUser?> login(String loginId, String password) async {
    final r = await _api.raw(
      'POST',
      '/api/auth/login',
      body: {'userId': loginId, 'password': password},
    );
    if (r.status == 401) return null; // 아이디/비밀번호 불일치
    if (!r.success) {
      throw BusinessException(r.message ?? '로그인에 실패했습니다.');
    }
    final data = r.data as Map<String, dynamic>;
    _api.token = data['token'] as String;
    try {
      await onLoggedIn?.call();
    } catch (_) {}
    return userFromJson(data['user'] as Map<String, dynamic>);
  }
}
