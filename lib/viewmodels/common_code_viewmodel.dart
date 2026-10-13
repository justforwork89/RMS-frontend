import 'package:flutter/foundation.dart';

import '../app_dependencies.dart';
import '../models/common_code.dart';
import 'viewmodel_support.dart';

/// 공통코드 관리(LMS-M003)의 ViewModel. 그룹별 조회, 등록, 수정, 삭제.
class CommonCodeViewModel extends ChangeNotifier with ActionRunner {
  CommonCodeViewModel(this._deps);

  final AppDependencies _deps;

  List<CommonCode> _all = const [];
  String? _group;
  bool _loading = false;
  String? _errorMessage;

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  /// 선택한 코드 그룹. null이면 전체.
  String? get group => _group;

  List<String> get groups => ({for (final c in _all) c.groupCd}).toList()..sort();

  List<CommonCode> get codes => _group == null
      ? _all
      : [
          for (final c in _all)
            if (c.groupCd == _group) c,
        ];

  void setGroup(String? group) {
    _group = group;
    notifyListeners();
  }

  @override
  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final list = await _deps.commonCodes.fetchAll();
      _all = [...list]..sort((a, b) {
          final g = a.groupCd.compareTo(b.groupCd);
          return g != 0 ? g : a.sortOrder.compareTo(b.sortOrder);
        });
      if (_group != null && !_all.any((c) => c.groupCd == _group)) {
        _group = null;
      }
    } catch (_) {
      _errorMessage = '공통코드를 불러오지 못했습니다.';
    }
    _loading = false;
    notifyListeners();
  }

  /// 성공 시 null, 실패 시 사용자에게 보여줄 메시지를 반환한다.
  Future<String?> save(CommonCode code, {required bool isNew}) {
    if (code.groupCd.trim().isEmpty || code.code.trim().isEmpty) {
      return Future.value('그룹 코드와 코드 값을 입력하세요.');
    }
    if (code.codeName.trim().isEmpty) return Future.value('코드명을 입력하세요.');
    return runAction(() async {
      await _deps.commonCodes.save(code, isNew: isNew);
    });
  }

  Future<String?> delete(CommonCode code) {
    return runAction(() async {
      await _deps.commonCodes.delete(code.groupCd, code.code);
    });
  }
}
