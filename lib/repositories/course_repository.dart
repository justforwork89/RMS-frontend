import '../models/course.dart';

/// 과정(과목) 데이터 접근 계약. 백엔드(Spring Boot) 연동 시 이 인터페이스의
/// HTTP 구현체(GET/POST/PUT/DELETE /api/courses)를 만들어 주입한다.
/// (임시 구현: lib/mock/mock_course_repository.dart)
abstract class CourseRepository {
  /// 담당 강사 선택지 (추후 강사 목록 API로 대체).
  List<String> get instructors;

  /// 전공 선택지 (추후 전공 코드 API로 대체).
  List<String> get majors;

  Future<List<Course>> fetchCourses({String keyword = '', CourseStatus? status});

  /// id가 null이면 등록, 아니면 수정.
  Future<Course> save(Course course);

  Future<void> delete(int id);
}
