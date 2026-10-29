import '../models/assignment.dart';
import '../repositories/assignment_repository.dart';
import 'api_client.dart';

class ApiAssignmentRepository implements AssignmentRepository {
  ApiAssignmentRepository(this._api);
  final ApiClient _api;

  @override
  Future<Assignment> createAssignment(Assignment assignment) async {
    final data = await _api.call(
      'POST',
      '/api/assignments',
      body: {
        "courseId": assignment.courseId,
        "title": assignment.title,
        "content": assignment.content,
        "dueDate": assignment.dueDate.toIso8601String(),
      },
    );
    return _fromAssignmentJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<Assignment>> fetchAssignments({Set<int>? courseIds}) async {
    if (courseIds != null && courseIds.isEmpty) return [];
    final query = courseIds == null ? '' : '?courseIds=${courseIds.join(',')}';

    final data =
        await _api.call('GET', '/api/assignments$query') as List<dynamic>;
    return [
      for (final e in data) _fromAssignmentJson(e as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<Submission>> fetchSubmissions({
    int? assignmentId,
    String? studentId,
  }) async {
    final params = [
      if (assignmentId != null) 'assignmentId=$assignmentId',
      if (studentId != null) 'studentId=$studentId',
    ];
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    final data =
        await _api.call('GET', '/api/submissions$query') as List<dynamic>;
    return [
      for (final e in data) _fromSubmissionJson(e as Map<String, dynamic>),
    ];
  }

  @override
  Future<Submission> grade({
    required int submissionId,
    required int score,
    String feedback = '',
  }) async {
    final data = await _api.call(
      'PATCH',
      '/api/submissions/$submissionId',
      body: {"score": score, "feedback": feedback},
    );
    return _fromSubmissionJson(data as Map<String, dynamic>);
  }

  @override
  Future<Submission> submit({
    required int assignmentId,
    required String studentId,
    required String content,
    String? fileName,
  }) async {
    final list = await fetchSubmissions(assignmentId: assignmentId);
    final existing = list.firstOrNull;

    if (existing != null) {
      final data = await _api.call(
        'PUT',
        '/api/submissions/${existing.id}',
        body: {"content": content, "fileName": fileName},
      );
      return _fromSubmissionJson(data as Map<String, dynamic>);
    }
    final data = await _api.call(
      'POST',
      '/api/submissions',
      body: {
        "assignmentId": assignmentId,
        "content": content,
        "fileName": fileName,
      },
    );
    return _fromSubmissionJson(data as Map<String, dynamic>);
  }

  Submission _fromSubmissionJson(Map<String, dynamic> j) {
    return Submission(
      id: (j['id'] as num).toInt(),
      assignmentId: (j['assignmentId'] as num).toInt(),
      studentId: j['studentId'] as String,
      content: j['content'] as String,
      fileName: j['fileName'] as String?,
      submittedAt: DateTime.parse(j['submittedAt']),
      score: (j['score'] as num?)?.toInt(),
      feedback: (j['feedback'] as String?) ?? '',
      studentName: (j['studentName'] as String?) ?? '',
    );
  }

  Assignment _fromAssignmentJson(Map<String, dynamic> j) {
    return Assignment(
      id: (j['id'] as num).toInt(),
      content: (j['content'] as String?) ?? '',
      courseId: (j['courseId'] as num).toInt(),
      title: j['title'] as String,
      dueDate: DateTime.parse(j['dueDate']),
    );
  }
}
