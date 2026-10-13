import 'package:flutter/foundation.dart';

import '../repositories/business_exception.dart';

/// 쓰기 동작을 실행하고 결과 메시지를 돌려주는 ViewModel 공통 로직.
/// 동작이 끝나면(성공/실패 모두) 목록을 다시 불러온다.
mixin ActionRunner on ChangeNotifier {
  Future<void> load();

  /// 성공 시 null, 실패 시 사용자에게 보여줄 메시지를 반환한다.
  Future<String?> runAction(Future<void> Function() action) async {
    String? error;
    try {
      await action();
    } on BusinessException catch (e) {
      error = e.message;
    } catch (_) {
      error = '처리 중 오류가 발생했습니다.';
    }
    await load();
    return error;
  }
}
