import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/course_file.dart';
import '../models/user.dart';
import '../repositories/business_exception.dart';
import '../repositories/course_file_repository.dart';

/// 과정 참고자료 ViewModel. 목록, 업로드 진행률, 권한을 관리한다.
class CourseFileViewModel extends ChangeNotifier {
  CourseFileViewModel(this._repo, this.courseId, this._user, this._instructorId);

  final CourseFileRepository _repo;
  final int courseId;
  final AppUser _user;
  final String? _instructorId; // 이 강의를 맡은 강사 아이디

  List<CourseFile> _files = const [];
  bool _loading = false;
  double? _progress; // null이면 올리는 중이 아님
  String? _errorMessage;

  List<CourseFile> get files => _files;
  bool get loading => _loading;
  double? get progress => _progress;
  bool get busy => _progress != null;
  String? get errorMessage => _errorMessage;
  int get totalBytes => _files.fold(0, (sum, f) => sum + f.size);

  /// 올리기·삭제는 관리자 또는 "이 강의 담당 강사"만 (최종 판단은 서버가 한 번 더 함)
  bool get canManage =>
      _user.role == UserRole.admin ||
      (_user.role == UserRole.instructor && _user.id == _instructorId);

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _files = await _repo.fetchFiles(courseId);
    } on BusinessException catch (e) {
      _errorMessage = e.message; // 예: 수강 승인된 강의의 자료만 볼 수 있습니다.
    } catch (_) {
      _errorMessage = '참고자료를 불러오지 못했습니다.';
    }
    _loading = false;
    notifyListeners();
  }

  /// 파일을 고르고 올린다. 보여줄 메시지를 돌려주고, 취소하면 null.
  Future<String?> pickAndUpload() async {
    // file_picker 13: 기본이 여러 개 선택, 취소하면 빈 목록
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedFileExtensions,
    );
    if (picked.isEmpty) return null;
    if (picked.length > maxFilesPerUpload) {
      return '한 번에 $maxFilesPerUpload개까지 올릴 수 있어요.';
    }

    final uploads = <UploadFile>[];
    var total = 0;
    for (final f in picked) {
      final size = await f.length(); // 13부터 크기를 알 수 없으면 null
      if (size == null) return '"${f.name}" 파일 크기를 알 수 없어요.';
      total += size;
      uploads.add(
        UploadFile(name: f.name, size: size, stream: f.readAsByteStream()),
      );
    }
    if (total > maxUploadBytes) {
      return '한 번에 500MB까지 올릴 수 있어요. (선택한 용량: ${formatBytes(total)})';
    }

    _progress = 0;
    notifyListeners();
    try {
      final added = await _repo.upload(
        courseId,
        uploads,
        onProgress: (p) {
          _progress = p;
          notifyListeners();
        },
      );
      _files = [..._files, ...added];
      return '${added.length}개 파일을 올렸습니다.';
    } on BusinessException catch (e) {
      return e.message;
    } catch (_) {
      return '파일을 올리지 못했습니다.';
    } finally {
      _progress = null;
      notifyListeners();
    }
  }

  Future<String> download(CourseFile file) async {
    try {
      final where = await _repo.download(file);
      return '저장했습니다: $where';
    } on BusinessException catch (e) {
      return e.message;
    } catch (_) {
      return '파일을 받지 못했습니다.';
    }
  }

  Future<String> delete(CourseFile file) async {
    try {
      await _repo.delete(file.id);
      _files = _files.where((f) => f.id != file.id).toList();
      notifyListeners();
      return '"${file.name}"을(를) 삭제했습니다.';
    } on BusinessException catch (e) {
      return e.message;
    } catch (_) {
      return '삭제하지 못했습니다.';
    }
  }
}
