import '../models/enrollment.dart';

/// 수강신청 업무 규칙 위반 시 던지는 예외. message는 사용자에게 그대로 보여준다.
class EnrollmentException implements Exception {
  const EnrollmentException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 수강신청 데이터 접근 계약. 백엔드 연동 시 수강신청 API 구현체를 주입한다.
/// (임시 구현: lib/mock/mock_enrollment_repository.dart)
abstract class EnrollmentRepository {
  Future<List<Enrollment>> fetchByStudent(String studentId);

  /// 신청. 중복/마감/모집 상태 위반 시 [EnrollmentException].
  Future<Enrollment> enroll(String studentId, int courseId);

  /// 신청한 과정을 다른 과정으로 변경 (수정).
  Future<Enrollment> change(int enrollmentId, int newCourseId);

  Future<void> cancel(int enrollmentId);
}
