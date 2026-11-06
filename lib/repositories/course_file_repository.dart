import '../models/course_file.dart';

/// 과정 첨부파일 데이터 접근 계약.
/// 실제: lib/api/api_course_file_repository.dart / 임시: lib/mock/mock_course_file_repository.dart
abstract class CourseFileRepository {
  Future<List<CourseFile>> fetchFiles(int courseId);

  /// onProgress: 0.0 ~ 1.0
  Future<List<CourseFile>> upload(
    int courseId,
    List<UploadFile> files, {
    void Function(double progress)? onProgress,
  });

  /// 저장한 위치를 돌려준다.
  Future<String> download(CourseFile file);

  Future<void> delete(int fileId);
}
