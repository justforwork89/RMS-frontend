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

  /// 제출 성공 시 서버가 돌려준 제출 내역(제출 번호 포함), 실패 시 null.
  /// 첨부 파일은 이 제출 번호로 따로 올린다 (SubmissionFileViewModel).
  Future<Submission?> submit(String content) async {
    if (content.trim().isEmpty) {
      _errorMessage = '제출 내용을 입력하세요.';
      notifyListeners();
      return null;
    }
    _saving = true;
    _errorMessage = null;
    notifyListeners();
    Submission? saved;
    try {
      saved = await _repository.submit(
        assignmentId: assignment.id!,
        studentId: _student.id,
        content: content,
      );
    } on BusinessException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = '제출 중 오류가 발생했습니다.';
    }
    _saving = false;
    notifyListeners();
    return saved;
  }
}
