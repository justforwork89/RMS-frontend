import 'package:http/http.dart' as http;

import '../models/course_file.dart';
import '../repositories/course_file_repository.dart';
import 'api_client.dart';
import 'save_file.dart';

class ApiCourseFileRepository implements CourseFileRepository {
  ApiCourseFileRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<CourseFile>> fetchFiles(int courseId) async {
    final data =
        await _api.call('GET', '/api/courses/$courseId/files') as List<dynamic>;
    return [
      for (final e in data) CourseFile.fromJson(e as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<CourseFile>> upload(
    int courseId,
    List<UploadFile> files, {
    void Function(double progress)? onProgress,
  }) async {
    final parts = [
      // 'files' = 서버 @RequestPart("files")와 같은 이름 (curl의 -F "files=@...")
      for (final f in files)
        http.MultipartFile('files', f.stream, f.size, filename: f.name),
    ];
    final data =
        await _api.upload(
              '/api/courses/$courseId/files',
              parts,
              onProgress: (sent, total) {
                if (total > 0) onProgress?.call(sent / total);
              },
            )
            as List<dynamic>;
    return [
      for (final e in data) CourseFile.fromJson(e as Map<String, dynamic>),
    ];
  }

  @override
  Future<String> download(CourseFile file) async {
    final bytes = await _api.download('/api/files/${file.id}/download');
    return saveBytes(file.name, bytes);
  }

  @override
  Future<void> delete(int fileId) async {
    await _api.call('DELETE', '/api/files/$fileId');
  }
}
