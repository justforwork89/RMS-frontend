import '../models/common_code.dart';
import '../repositories/common_code_repository.dart';
import 'api_client.dart';

class ApiCommonCodeRepository implements CommonCodeRepository {
  ApiCommonCodeRepository(this._api);
  final ApiClient _api;

  @override
  Future<void> delete(String groupCd, String code) async {
    await _api.call('DELETE', '/api/codes/$groupCd/$code');
    return;
  }

  @override
  Future<List<CommonCode>> fetchAll() async {
    final data = await _api.call('GET', '/api/codes') as List<dynamic>;
    return [for (final e in data) _fromJson(e as Map<String, dynamic>)];
  }

  @override
  Future<void> save(CommonCode code, {required bool isNew}) async {
    if (isNew) {
      await _api.call(
        'POST',
        '/api/codes',
        body: {
          'groupCd': code.groupCd,
          'code': code.code,
          'codeName': code.codeName,
          'sortOrder': code.sortOrder,
        },
      );
      return;
    }
    await _api.call(
      'PUT',
      '/api/codes/${code.groupCd}/${code.code}',
      body: {'codeName': code.codeName, 'sortOrder': code.sortOrder},
    );
    return;
  }

  CommonCode _fromJson(Map<String, dynamic> j) {
    return CommonCode(
      groupCd: j['groupCd'] as String,
      code: j['code'] as String,
      codeName: j['codeName'] as String,
    );
  }
}
