import 'package:flutter/foundation.dart';

import '../app_dependencies.dart';
import '../models/user.dart';
import 'viewmodel_support.dart';

/// 사용자 관리(LMS-M001)의 ViewModel. 역할별 조회, 등록, 수정.
class UserManagementViewModel extends ChangeNotifier with ActionRunner {
  UserManagementViewModel(this._deps);

  final AppDependencies _deps;

  List<AppUser> _all = const [];
  UserRole? _roleFilter;
  bool _loading = false;
  String? _errorMessage;

  UserRole? get roleFilter => _roleFilter;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  /// 학생 소속 전공 선택지.
  List<String> get majors => _deps.courses.majors;

  List<AppUser> get users => _roleFilter == null
      ? _all
      : [
          for (final u in _all)
            if (u.role == _roleFilter) u,
        ];

  void setRoleFilter(UserRole? role) {
    _roleFilter = role;
    notifyListeners();
  }

  @override
  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _all = await _deps.users.fetchUsers();
    } catch (_) {
      _errorMessage = '사용자 목록을 불러오지 못했습니다.';
    }
    _loading = false;
    notifyListeners();
  }

  /// 성공 시 null, 실패 시 사용자에게 보여줄 메시지를 반환한다.
  Future<String?> save(AppUser user, {String? password, required bool isNew}) {
    final id = user.id.trim();
    if (id.isEmpty) return Future.value('아이디를 입력하세요.');
    if (user.name.trim().isEmpty) return Future.value('이름을 입력하세요.');
    if (isNew && (password == null || password.isEmpty)) {
      return Future.value('비밀번호를 입력하세요.');
    }
    if (isNew && _all.any((u) => u.id == id)) {
      return Future.value('이미 사용 중인 아이디입니다.');
    }
    final pw = (password == null || password.isEmpty) ? null : password;
    return runAction(() async {
      await _deps.users.save(user, password: pw, isNew: isNew);
    });
  }
}
