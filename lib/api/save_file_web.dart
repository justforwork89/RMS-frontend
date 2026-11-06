import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// 브라우저 다운로드를 띄운다.
Future<String> saveBytes(String fileName, Uint8List bytes) async {
  final blob = web.Blob(<JSAny>[bytes.toJS].toJS);
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  a.click();
  Future.delayed(
    const Duration(seconds: 5),
    () => web.URL.revokeObjectURL(url),
  );
  return '브라우저 다운로드 폴더';
}
