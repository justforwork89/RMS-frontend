import '../models/assignment.dart';

/// 과제/제출 데이터 접근 계약. 백엔드 연동 시 과제 API 구현체를 주입한다.
/// (임시 구현: lib/mock/mock_assignment_repository.dart)
abstract class AssignmentRepository {
  /// courseIds가 null이면 전체, 아니면 해당 과정의 과제만 (마감일 오름차순).
  Future<List<Assignment>> fetchAssignments({Set<int>? courseIds});

  Future<Assignment> createAssignment(Assignment assignment);

  /// assignmentId / studentId로 좁혀서 조회 (둘 다 null이면 전체).
  Future<List<Submission>> fetchSubmissions({
    int? assignmentId,
    String? studentId,
  });

  /// 제출 또는 재제출. 마감 후, 채점 완료 후에는 [BusinessException].
  Future<Submission> submit({
    required int assignmentId,
    required String studentId,
    required String content,
    String? fileName,
  });

  /// 채점. 점수는 0~100.
  Future<Submission> grade({
    required int submissionId,
    required int score,
    String feedback = '',
  });
}
