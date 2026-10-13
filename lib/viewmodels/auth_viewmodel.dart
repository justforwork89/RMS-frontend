import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../repositories/auth_repository.dart';

/// 로그인 세션 상태. 앱 전체에서 현재 사용자 정보를 공유한다.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository);

  final AuthRepository _repository;

  AppUser? _user;
  bool _loading = false;
  String? _errorMessage;

  AppUser? get user => _user;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  String? get loginHint => _repository.loginHint;

  Future<void> login(String loginId, String password) async {
    if (loginId.trim().isEmpty || password.isEmpty) {
      _errorMessage = '아이디와 비밀번호를 입력하세요.';
      notifyListeners();
      return;
    }
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.login(loginId, password);
      if (result == null) {
        _errorMessage = '아이디 또는 비밀번호가 올바르지 않습니다.';
      } else {
        _user = result;
      }
    } catch (_) {
      _errorMessage = '로그인 중 오류가 발생했습니다.';
    }
    _loading = false;
    notifyListeners();
  }

  void logout() {
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }
}
