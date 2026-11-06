import '../app_dependencies.dart';
import 'api_assignment_repository.dart';
import 'api_common_code_repository.dart';
import 'api_course_file_repository.dart';

import 'api_enrollment_repository.dart';
import 'api_auth_repository.dart';
import 'api_client.dart';
import 'api_course_repository.dart';
import 'api_user_repository.dart';

/// 실제 서버 연동 구현 주입. 모든 Repository가 같은 ApiClient(로그인 토큰)를 쓴다.
AppDependencies createApiDependencies() {
  final api = ApiClient();
  final commonCodes = ApiCommonCodeRepository(api);
  final courses = ApiCourseRepository(api, commonCodes);
  return AppDependencies(
    auth: ApiAuthRepository(
      api,
      onLoggedIn: () async {
        await courses.loadInstructors();
        await courses.loadMajors();
      },
    ),
    users: ApiUserRepository(api),
    courses: courses,
    enrollments: ApiEnrollmentRepository(api),
    assignments: ApiAssignmentRepository(api),
    commonCodes: commonCodes,
    courseFiles: ApiCourseFileRepository(api),
  );
}
