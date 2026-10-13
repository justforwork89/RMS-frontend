// [MOCK] 백엔드 연동 시 이 파일은 삭제하고 과제 API 구현체로 교체한다.
import '../models/assignment.dart';
import '../repositories/assignment_repository.dart';
import '../repositories/business_exception.dart';

/// 메모리 기반 임시 과제/제출 저장소. 마감일은 실행 시점 기준 상대 날짜로 만든다.
class MockAssignmentRepository implements AssignmentRepository {
  MockAssignmentRepository() {
    final now = DateTime.now();
    _assignments.addAll([
      Assignment(
        id: 1,
        courseId: 1,
        title: 'Dart 문법 퀴즈 과제',
        content: '변수, 함수, 클래스, 비동기(Future) 문제를 풀고 답안을 제출하세요.',
        dueDate: now.add(const Duration(days: 5)),
      ),
      Assignment(
        id: 2,
        courseId: 1,
        title: '위젯 트리 실습',
        content: 'Column/Row/ListView를 사용해 상품 목록 화면을 만들어 보세요.',
        dueDate: now.add(const Duration(days: 12)),
      ),
      Assignment(
        id: 3,
        courseId: 2,
        title: 'REST API 설계서 작성',
        content: '과정 관리 API(GET/POST/PUT/DELETE)의 요청/응답 명세를 작성하세요.',
        dueDate: now.add(const Duration(days: 20)),
      ),
    ]);
    _submissions.add(
      Submission(
        id: 1,
        assignmentId: 1,
        studentId: 'student2',
        content: '1번: var/final/const 차이를 정리했습니다. 2번: ...',
        fileName: 'quiz_answers.pdf',
        submittedAt: now.subtract(const Duration(days: 1)),
      ),
    );
  }

  final List<Assignment> _assignments = [];
  final List<Submission> _submissions = [];
  int _nextAssignmentId = 4;
  int _nextSubmissionId = 2;

  @override
  Future<List<Assignment>> fetchAssignments({Set<int>? courseIds}) async {
    await _latency();
    final list = _assignments
        .where((a) => courseIds == null || courseIds.contains(a.courseId))
        .toList();
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  @override
  Future<Assignment> createAssignment(Assignment assignment) async {
    await _latency();
    if (assignment.title.trim().isEmpty) {
      throw const BusinessException('과제 제목은 필수입니다.');
    }
    if (assignment.dueDate.isBefore(DateTime.now())) {
      throw const BusinessException('마감일은 현재 이후여야 합니다.');
    }
    final created = Assignment(
      id: _nextAssignmentId++,
      courseId: assignment.courseId,
      title: assignment.title.trim(),
      content: assignment.content,
      dueDate: assignment.dueDate,
    );
    _assignments.add(created);
    return created;
  }

  @override
  Future<List<Submission>> fetchSubmissions({
    int? assignmentId,
    String? studentId,
  }) async {
    await _latency();
    return _submissions
        .where((s) => assignmentId == null || s.assignmentId == assignmentId)
        .where((s) => studentId == null || s.studentId == studentId)
        .toList();
  }

  @override
  Future<Submission> submit({
    required int assignmentId,
    required String studentId,
    required String content,
    String? fileName,
  }) async {
    await _latency();
    final assignment = _assignments.where((a) => a.id == assignmentId);
    if (assignment.isEmpty) {
      throw const BusinessException('존재하지 않는 과제입니다.');
    }
    if (DateTime.now().isAfter(assignment.first.dueDate)) {
      throw const BusinessException('제출 마감일이 지났습니다.');
    }
    if (content.trim().isEmpty) {
      throw const BusinessException('제출 내용을 입력하세요.');
    }
    final index = _submissions.indexWhere(
      (s) => s.assignmentId == assignmentId && s.studentId == studentId,
    );
    if (index >= 0) {
      final old = _submissions[index];
      if (old.graded) {
        throw const BusinessException('채점이 완료된 과제는 수정할 수 없습니다.');
      }
      final updated = old.copyWith(
        content: content,
        fileName: fileName,
        submittedAt: DateTime.now(),
      );
      _submissions[index] = updated;
      return updated;
    }
    final created = Submission(
      id: _nextSubmissionId++,
      assignmentId: assignmentId,
      studentId: studentId,
      content: content,
      fileName: fileName,
      submittedAt: DateTime.now(),
    );
    _submissions.add(created);
    return created;
  }

  @override
  Future<Submission> grade({
    required int submissionId,
    required int score,
    String feedback = '',
  }) async {
    await _latency();
    if (score < 0 || score > 100) {
      throw const BusinessException('점수는 0~100 사이여야 합니다.');
    }
    final index = _submissions.indexWhere((s) => s.id == submissionId);
    if (index < 0) {
      throw const BusinessException('제출 내역을 찾을 수 없습니다.');
    }
    final graded = _submissions[index].copyWith(
      score: score,
      feedback: feedback,
    );
    _submissions[index] = graded;
    return graded;
  }

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 150));
}
