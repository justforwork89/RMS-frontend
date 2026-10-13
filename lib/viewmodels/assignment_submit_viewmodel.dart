import 'package:flutter/foundation.dart';

import '../models/assignment.dart';
import '../models/user.dart';
import '../repositories/assignment_repository.dart';
import '../repositories/business_exception.dart';

/// 과제 제출(LMS-A002)의 ViewModel. 내용 검증과 제출을 담당한다.
class AssignmentSubmitViewModel extends ChangeNotifier {
  AssignmentSubmitViewModel(
    this._repository,
    this.assignment,
    this._student,
    this.existing,
  );

  final AssignmentRepository _repository;
  final Assignment assignment;
  final AppUser _student;

  /// 이미 제출한 내역 (없으면 null).
  final Submission? existing;

  bool _saving = false;
  String? _errorMessage;

  bool get saving => _saving;
  String? get errorMessage => _errorMessage;
  bool get isOverdue => DateTime.now().isAfter(assignment.dueDate);
  bool get isGraded => existing?.graded ?? false;

  /// 마감 후이거나 채점이 끝나면 수정할 수 없다.
  bool get readOnly => isGraded || isOverdue;

  /// 제출 성공 시 true. 실패 시 errorMessage에 사유가 설정된다.
  Future<bool> submit(String content, String fileName) async {
    if (content.trim().isEmpty) {
      _errorMessage = '제출 내용을 입력하세요.';
      notifyListeners();
      return false;
    }
    _saving = true;
    _errorMessage = null;
    notifyListeners();
    var ok = false;
    try {
      final name = fileName.trim();
      await _repository.submit(
        assignmentId: assignment.id!,
        studentId: _student.id,
        content: content,
        fileName: name.isEmpty ? null : name,
      );
      ok = true;
    } on BusinessException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = '제출 중 오류가 발생했습니다.';
    }
    _saving = false;
    notifyListeners();
    return ok;
  }
}
