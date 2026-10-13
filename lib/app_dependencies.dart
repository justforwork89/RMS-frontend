import 'repositories/assignment_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/common_code_repository.dart';
import 'repositories/course_repository.dart';
import 'repositories/enrollment_repository.dart';
import 'repositories/user_repository.dart';

/// 앱이 사용하는 데이터 소스 묶음. 임시(mock) 구현과 실제(API) 구현을
/// 이 객체 하나로 바꿔 끼운다. (생성 위치: lib/main.dart)
class AppDependencies {
  const AppDependencies({
    required this.auth,
    required this.users,
    required this.courses,
    required this.enrollments,
    required this.assignments,
    required this.commonCodes,
  });

  final AuthRepository auth;
  final UserRepository users;
  final CourseRepository courses;
  final EnrollmentRepository enrollments;
  final AssignmentRepository assignments;
  final CommonCodeRepository commonCodes;
}
