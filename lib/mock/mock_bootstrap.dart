// [MOCK] lib/mock 폴더 전체가 임시 데이터다. 백엔드 연동 시 폴더째 삭제하고
// main.dart의 createMockDependencies() 호출을 실제 구현 주입으로 교체한다.
import '../app_dependencies.dart';
import 'mock_auth_repository.dart';
import 'mock_course_repository.dart';
import 'mock_enrollment_repository.dart';

AppDependencies createMockDependencies() {
  final courses = MockCourseRepository();
  return AppDependencies(
    auth: MockAuthRepository(),
    courses: courses,
    enrollments: MockEnrollmentRepository(courses),
  );
}
