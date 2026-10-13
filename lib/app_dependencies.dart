import 'repositories/auth_repository.dart';
import 'repositories/course_repository.dart';
import 'repositories/enrollment_repository.dart';

/// 앱이 사용하는 데이터 소스 묶음. 임시(mock) 구현과 실제(API) 구현을
/// 이 객체 하나로 바꿔 끼운다. (생성 위치: lib/main.dart)
class AppDependencies {
  const AppDependencies({
    required this.auth,
    required this.courses,
    required this.enrollments,
  });

  final AuthRepository auth;
  final CourseRepository courses;
  final EnrollmentRepository enrollments;
}
