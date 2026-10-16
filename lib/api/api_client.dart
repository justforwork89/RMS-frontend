import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../repositories/business_exception.dart';

/// 서버 응답(ApiResponse) 해석 결과.
class ApiResult {
  const ApiResult(this.status, this.success, this.message, this.data);

  final int status;
  final bool success;
  final String? message;
  final dynamic data;
}

/// Spring Boot 서버 호출 공통 클라이언트. 로그인 후 받은 토큰을 보관해 요청마다 붙인다.
class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl();

  final String baseUrl;
  String? token;

  static String _defaultBaseUrl() {
    // 안드로이드 에뮬레이터에서 PC의 localhost는 10.0.2.2
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  /// 상태 코드와 본문을 그대로 돌려준다 (로그인처럼 401을 직접 처리할 때 사용).
  Future<ApiResult> raw(String method, String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final encoded = body == null ? null : jsonEncode(body);

    http.Response res;
    try {
      switch (method) {
        case 'GET':
          res = await http.get(uri, headers: headers);
        case 'POST':
          res = await http.post(uri, headers: headers, body: encoded);
        case 'PUT':
          res = await http.put(uri, headers: headers, body: encoded);
        case 'DELETE':
          res = await http.delete(uri, headers: headers);
        default:
          throw ArgumentError('지원하지 않는 메서드: $method');
      }
    } on ArgumentError {
      rethrow;
    } catch (_) {
      throw const BusinessException('서버에 연결할 수 없습니다.');
    }

    Map<String, dynamic> json = {};
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {}
    return ApiResult(
      res.statusCode,
      json['success'] == true,
      json['message'] as String?,
      json['data'],
    );
  }

  /// 성공이면 data를, 실패면 서버 메시지로 [BusinessException]을 던진다.
  Future<dynamic> call(String method, String path, {Object? body}) async {
    final r = await raw(method, path, body: body);
    if (!r.success) {
      throw BusinessException(r.message ?? '요청을 처리하지 못했습니다.');
    }
    return r.data;
  }
}
