import '../models/common_code.dart';

/// 공통코드 데이터 접근 계약. 백엔드 연동 시 공통코드 API 구현체를 주입한다.
/// (임시 구현: lib/mock/mock_common_code_repository.dart)
abstract class CommonCodeRepository {
  Future<List<CommonCode>> fetchAll();

  /// isNew이면 등록(키 중복 시 [BusinessException]), 아니면 수정.
  Future<void> save(CommonCode code, {required bool isNew});

  Future<void> delete(String groupCd, String code);
}
