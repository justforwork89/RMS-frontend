import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/course_file.dart';

void main() {
  test('서버 응답 JSON을 CourseFile로 바꾼다', () {
    final f = CourseFile.fromJson({
      'id': 1,
      'courseId': 3,
      'name': 'test1.txt',
      'size': 7,
      'contentType': 'text/plain',
      'uploaderId': 'teacher1',
      'regDt': '2026-11-05T17:40:01',
    });
    expect(f.id, 1);
    expect(f.name, 'test1.txt');
    expect(f.regDt?.hour, 17);
  });

  test('파일 크기를 읽기 쉽게 바꾼다', () {
    expect(formatBytes(7), '7 B');
    expect(formatBytes(1536), '1.5 KB');
    expect(formatBytes(maxUploadBytes), '500.0 MB');
  });
}
