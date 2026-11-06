import 'repositories/assignment_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/common_code_repository.dart';
import 'repositories/course_file_repository.dart';
import 'repositories/course_repository.dart';
import 'repositories/enrollment_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/submission_file_repository.dart';

/// 앱이 사용하는 데이터 소스 묶음 (API 구현). 생성 위치: lib/api/api_bootstrap.dart

class AppDependencies {
  const AppDependencies({
    required this.auth,
    required this.users,
    required this.courses,
    required this.enrollments,
    required this.assignments,
    required this.commonCodes,
    required this.courseFiles,
    required this.submissionFiles,
  });

  final AuthRepository auth;
  final UserRepository users;
  final CourseRepository courses;
  final EnrollmentRepository enrollments;
  final AssignmentRepository assignments;
  final CommonCodeRepository commonCodes;
  final CourseFileRepository courseFiles;
  final SubmissionFileRepository submissionFiles;
}
