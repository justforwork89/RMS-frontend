import '../models/enrollment.dart';
import '../repositories/enrollment_repository.dart';
import 'api_client.dart';

EnrollStatus _statusFromCode(String code) {
  for (final e in EnrollStatus.values) {
    if (e.code == code) return e;
  }
  return EnrollStatus.applied;
}

class ApiEnrollmentRepository implements EnrollmentRepository {
  ApiEnrollmentRepository(this._api);
  final ApiClient _api;

  @override
  Future<void> cancel(int enrollmentId) async {
    await _api.call('DELETE', '/api/enrollments/$enrollmentId');
  }

  @override
  Future<Enrollment> change(int enrollmentId, int newCourseId) async {
    final data = await _api.call(
      'PUT',
      '/api/enrollments/$enrollmentId',
      body: {'courseId': newCourseId},
    );
    return _fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Enrollment> enroll(String studentId, int courseId) async {
    final data = await _api.call(
      'POST',
      '/api/enrollments',
      body: {'courseId': courseId},
    );
    return _fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<Enrollment>> fetchAll() async {
    final data = await _api.call('GET', '/api/enrollments') as List<dynamic>;
    return [for (final e in data) _fromJson(e as Map<String, dynamic>)];
  }

  @override
  Future<List<Enrollment>> fetchByStudent(String studentId) async {
    final data = await _api.call('GET', '/api/enrollments') as List<dynamic>;
    return [for (final e in data) _fromJson(e as Map<String, dynamic>)];
  }

  @override
  Future<Enrollment> setStatus(int enrollmentId, EnrollStatus status) async {
    final data = await _api.call(
      'PATCH',
      '/api/enrollments/$enrollmentId/status',
      body: {'statusCd': status.code},
    );
    return _fromJson(data as Map<String, dynamic>);
  }

  Enrollment _fromJson(Map<String, dynamic> j) {
    return Enrollment(
      id: (j['id'] as num).toInt(),
      studentId: j['studentId'] as String,
      courseId: (j['courseId'] as num).toInt(),
      appliedAt: DateTime.parse(j['appliedAt'] as String),
      status: _statusFromCode(j['statusCode'] as String),
    );
  }
}
