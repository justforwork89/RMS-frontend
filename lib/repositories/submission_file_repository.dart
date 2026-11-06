import '../models/course_file.dart';
import '../models/submission_file.dart';

/// 과제 제출 첨부파일 데이터 접근 계약.
/// 실제: lib/api/api_submission_file_repository.dart
abstract class SubmissionFileRepository {
  Future<List<SubmissionFile>> fetchFiles(int submissionId);

  /// onProgress: 0.0 ~ 1.0
  Future<List<SubmissionFile>> upload(
    int submissionId,
    List<UploadFile> files, {
    void Function(double progress)? onProgress,
  });

  /// 저장한 위치를 돌려준다.
  Future<String> download(SubmissionFile file);
  Future<void> delete(int fileId);
}
