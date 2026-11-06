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

  /// 트리 모양: 그룹 코드(상위) → 그 그룹의 코드들(하위, 정렬 순서대로)
  /// 예) {'COURSE_STATUS': [준비중, 모집예정, ...], 'ROLE': [학생, 강사, 관리자]}
  Map<String, List<CommonCode>> get tree {
    final map = <String, List<CommonCode>>{};
    for (final c in _all) {
      map.putIfAbsent(c.groupCd, () => []).add(c);
    }
    return map;
  }

  @override
  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final list = await _deps.commonCodes.fetchAll();
      _all = [...list]
        ..sort((a, b) {
          final g = a.groupCd.compareTo(b.groupCd);
          return g != 0 ? g : a.sortOrder.compareTo(b.sortOrder);
        });
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
