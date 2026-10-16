import '../app_dependencies.dart';
import '../mock/mock_assignment_repository.dart';
import '../mock/mock_common_code_repository.dart';
import '../mock/mock_course_repository.dart';
import '../mock/mock_enrollment_repository.dart';
import 'api_auth_repository.dart';
import 'api_client.dart';
import 'api_course_repository.dart';
import 'api_user_repository.dart';

/// 실제 서버 연동 구현 주입. 아직 서버가 없는 영역은 mock을 그대로 쓴다.
AppDependencies createApiDependencies() {
  final api = ApiClient();
  // final courses = MockCourseRepository(); // TODO: 강의 API 연동 시 교체
  final courses = ApiCourseRepository(api);
  return AppDependencies(
    auth: ApiAuthRepository(api, onLoggedIn: courses.loadInstructors),
    users: ApiUserRepository(api),
    courses: courses,
    enrollments: MockEnrollmentRepository(courses),
    assignments: MockAssignmentRepository(),
    commonCodes: MockCommonCodeRepository(),
  );
}
