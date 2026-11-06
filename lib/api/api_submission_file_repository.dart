import 'package:http/http.dart' as http;
import '../models/course_file.dart';
import '../models/submission_file.dart';
import '../repositories/submission_file_repository.dart';
import 'api_client.dart';
import 'save_file.dart';

class ApiSubmissionFileRepository implements SubmissionFileRepository {
  ApiSubmissionFileRepository(this._api);
  final ApiClient _api;
  @override
  Future<List<SubmissionFile>> fetchFiles(int submissionId) async {
    final data =
        await _api.call('GET', '/api/submissions/$submissionId/files')
            as List<dynamic>;
    return [
      for (final e in data) SubmissionFile.fromJson(e as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<SubmissionFile>> upload(
    int submissionId,
    List<UploadFile> files, {
    void Function(double progress)? onProgress,
  }) async {
    final parts = [
      // 'files' = 서버 @RequestPart("files")와 같은 이름
      for (final f in files)
        http.MultipartFile('files', f.stream, f.size, filename: f.name),
    ];
    final data =
        await _api.upload(
              '/api/submissions/$submissionId/files',
              parts,
              onProgress: (sent, total) {
                if (total > 0) onProgress?.call(sent / total);
              },
            )
            as List<dynamic>;
    return [
      for (final e in data) SubmissionFile.fromJson(e as Map<String, dynamic>),
    ];
  }

  @override
  Future<String> download(SubmissionFile file) async {
    final bytes = await _api.download(
      '/api/submission-files/${file.id}/download',
    );
    return saveBytes(file.name, bytes);
  }

  @override
  Future<void> delete(int fileId) async {
    await _api.call('DELETE', '/api/submission-files/$fileId');
  }
}
