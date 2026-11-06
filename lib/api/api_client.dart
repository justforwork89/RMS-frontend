import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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
        case 'PATCH':
          res = await http.patch(uri, headers: headers, body: encoded);
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

    return _toResult(res);
  }

  /// 성공이면 data를, 실패면 서버 메시지로 [BusinessException]을 던진다.
  Future<dynamic> call(String method, String path, {Object? body}) async {
    final r = await raw(method, path, body: body);
    if (!r.success) {
      throw BusinessException(r.message ?? '요청을 처리하지 못했습니다.');
    }
    return r.data;
  }

  Map<String, String> get _authHeader => {
    if (token != null) 'Authorization': 'Bearer $token',
  };

  /// 서버 응답을 ApiResult로 해석 (raw, upload, download가 같이 씀)
  ApiResult _toResult(http.Response res) {
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

  /// 파일 업로드 (multipart). onProgress(보낸 byte, 전체 byte)
  Future<dynamic> upload(
    String path,
    List<http.MultipartFile> files, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final req = _ProgressMultipartRequest(
      'POST',
      Uri.parse('$baseUrl$path'),
      onProgress,
    );
    req.headers.addAll(_authHeader); // Content-Type은 자동으로 붙음
    req.files.addAll(files);

    http.Response res;
    try {
      res = await http.Response.fromStream(await req.send());
    } catch (_) {
      throw const BusinessException('서버에 연결할 수 없습니다.');
    }
    final r = _toResult(res);
    if (!r.success) {
      throw BusinessException(
        r.message ??
            (res.statusCode == 413
                ? '한 번에 500MB까지 올릴 수 있습니다.'
                : '파일을 올리지 못했습니다.'),
      );
    }
    return r.data;
  }

  /// 파일 다운로드. 성공하면 파일 내용(bytes)
  Future<Uint8List> download(String path) async {
    http.Response res;
    try {
      res = await http.get(Uri.parse('$baseUrl$path'), headers: _authHeader);
    } catch (_) {
      throw const BusinessException('서버에 연결할 수 없습니다.');
    }
    if (res.statusCode != 200) {
      throw BusinessException(_toResult(res).message ?? '파일을 받지 못했습니다.');
    }
    return res.bodyBytes;
  }
}

/// 업로드할 때 몇 byte 보냈는지 세는 요청 (진행 막대용)
class _ProgressMultipartRequest extends http.MultipartRequest {
  _ProgressMultipartRequest(super.method, super.url, this.onProgress);

  final void Function(int sent, int total)? onProgress;

  @override
  http.ByteStream finalize() {
    final stream = super.finalize();
    final total = contentLength;
    var sent = 0;
    return http.ByteStream(
      stream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (chunk, sink) {
            sent += chunk.length;
            onProgress?.call(sent, total);
            sink.add(chunk);
          },
        ),
      ),
    );
  }
}
