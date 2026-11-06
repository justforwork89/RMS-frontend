import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// 다운로드 폴더에 저장하고, 저장한 위치를 돌려준다.
Future<String> saveBytes(String fileName, Uint8List bytes) async {
  final dir =
      await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes);
  return file.path;
}
