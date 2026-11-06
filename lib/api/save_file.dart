// 웹이면 save_file_web.dart, 앱이면 save_file_io.dart를 자동으로 고른다.
export 'save_file_io.dart' if (dart.library.js_interop) 'save_file_web.dart';
