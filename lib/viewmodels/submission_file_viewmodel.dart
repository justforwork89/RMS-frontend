import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/course_file.dart';
import '../models/submission_file.dart';
import '../repositories/business_exception.dart';
import '../repositories/submission_file_repository.dart';

/// 제출 버튼을 누르기 전까지 기다리는 파일 하나 (아직 서버에 없음)
class PendingFile {
  const PendingFile(this.name, this.size, this.open);
  final String name;
  final int size;
  final Stream<List<int>> Function() open; // 올릴 때 파일 내용을 읽는 방법
}

/// 과제 제출 첨부파일 ViewModel.
/// files = 이미 서버에 올라간 파일, pending = 제출을 누르면 올라갈 파일
class SubmissionFileViewModel extends ChangeNotifier {
  SubmissionFileViewModel(
    this._repo, {
    this.submissionId,
    this.editable = false,
  });
  final SubmissionFileRepository _repo;
  int? submissionId; // 아직 한 번도 제출 안 했으면 null
  final bool editable; // 학생 본인 + 마감 전 + 채점 전일 때만 true
  List<SubmissionFile> _files = const [];
  List<PendingFile> _pending = const [];
  bool _loading = false;
  double? _progress; // null이면 올리는 중이 아님
  String? _errorMessage;
  List<SubmissionFile> get files => _files;
  List<PendingFile> get pending => _pending;
  bool get loading => _loading;
  double? get progress => _progress;
  bool get busy => _progress != null;
  String? get errorMessage => _errorMessage;
  bool get hasPending => _pending.isNotEmpty;
  int get totalCount => _files.length + _pending.length;
  int get totalBytes =>
      _files.fold(0, (sum, f) => sum + f.size) +
      _pending.fold(0, (sum, p) => sum + p.size);

  /// 이미 올린 파일 목록 불러오기 (제출 전이면 할 일 없음)
  Future<void> load() async {
    final id = submissionId;
    if (id == null) return;
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _files = await _repo.fetchFiles(id);
    } on BusinessException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = '첨부 파일을 불러오지 못했습니다.';
    }
    _loading = false;
    notifyListeners();
  }

  /// 파일 고르기: 바로 올리지 않고 '올릴 목록'에 담는다. 문제가 있으면 메시지, 괜찮으면 null.
  Future<String?> pick() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedFileExtensions,
    );
    if (picked.isEmpty) return null; // 취소
    if (totalCount + picked.length > maxSubmissionFiles) {
      return '파일은 최대 $maxSubmissionFiles개까지 붙일 수 있어요. (지금 $totalCount개)';
    }
    final added = <PendingFile>[];
    var bytes = totalBytes;
    for (final f in picked) {
      final size = await f.length();
      if (size == null) return '"${f.name}" 파일 크기를 알 수 없어요.';
      bytes += size;
      added.add(PendingFile(f.name, size, f.readAsByteStream));
    }
    if (bytes > maxSubmissionBytes) {
      return '합쳐서 50MB까지 붙일 수 있어요. (선택하면 ${formatBytes(bytes)})';
    }
    _pending = [..._pending, ...added];
    notifyListeners();
    return null;
  }

  void removePending(PendingFile p) {
    _pending = _pending.where((e) => e != p).toList();
    notifyListeners();
  }

  /// 제출(본문 저장)이 끝난 뒤 부른다: 올릴 목록을 서버에 올린다. 성공하면 null.
  Future<String?> uploadPending(int id) async {
    submissionId = id;
    if (_pending.isEmpty) return null;
    _progress = 0;
    notifyListeners();
    try {
      final added = await _repo.upload(
        id,
        [
          for (final p in _pending)
            UploadFile(name: p.name, size: p.size, stream: p.open()),
        ],
        onProgress: (v) {
          _progress = v;
          notifyListeners();
        },
      );
      _files = [..._files, ...added];
      _pending = const [];
      return null;
    } on BusinessException catch (e) {
      return e.message;
    } catch (_) {
      return '파일을 올리지 못했습니다.';
    } finally {
      _progress = null;
      notifyListeners();
    }
  }

  Future<String> download(SubmissionFile file) async {
    try {
      final where = await _repo.download(file);
      return '저장했습니다: $where';
    } on BusinessException catch (e) {
      return e.message;
    } catch (_) {
      return '파일을 받지 못했습니다.';
    }
  }

  Future<String> delete(SubmissionFile file) async {
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
