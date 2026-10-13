import '../models/course.dart';

/// 과정 데이터 접근 계약. 백엔드(Spring Boot) 연동 시 이 인터페이스의
/// HTTP 구현체(GET/POST/PUT/DELETE /api/courses)로 교체한다.
abstract class CourseRepository {
  /// 담당 강사 선택지 (추후 강사 목록 API로 대체).
  List<String> get instructors;

  Future<List<Course>> fetchCourses({String keyword = '', CourseStatus? status});

  /// id가 null이면 등록, 아니면 수정.
  Future<Course> save(Course course);

  Future<void> delete(int id);
}

/// 백엔드 구현 전까지 사용하는 메모리 기반 목 저장소.
class InMemoryCourseRepository implements CourseRepository {
  InMemoryCourseRepository() {
    _items.addAll([
      Course(
        id: 1,
        name: 'Flutter 모바일 앱 개발',
        description: 'Dart 문법부터 Flutter 위젯, 상태 관리까지 학습합니다.',
        instructor: '김강사',
        startDate: DateTime(2026, 10, 5),
        endDate: DateTime(2026, 11, 27),
        capacity: 20,
        enrolled: 15,
        status: CourseStatus.inProgress,
      ),
      Course(
        id: 2,
        name: 'Spring Boot 백엔드 개발',
        description: 'REST API 설계와 JPA, 보안을 다룹니다.',
        instructor: '이강사',
        startDate: DateTime(2026, 12, 1),
        endDate: DateTime(2027, 1, 22),
        capacity: 25,
        enrolled: 8,
        status: CourseStatus.recruiting,
      ),
      Course(
        id: 3,
        name: 'Oracle SQL 기초',
        description: 'SQL 기본 문법과 데이터 모델링 입문.',
        instructor: '박강사',
        startDate: DateTime(2027, 2, 2),
        endDate: DateTime(2027, 2, 27),
        capacity: 30,
        status: CourseStatus.preparing,
      ),
      Course(
        id: 4,
        name: 'Git 협업 워크플로우',
        description: '브랜치 전략과 Pull Request 기반 협업.',
        instructor: '김강사',
        startDate: DateTime(2026, 8, 3),
        endDate: DateTime(2026, 8, 14),
        capacity: 20,
        enrolled: 18,
        status: CourseStatus.closed,
      ),
    ]);
  }

  final List<Course> _items = [];
  int _nextId = 5;

  @override
  List<String> get instructors => const ['김강사', '이강사', '박강사'];

  @override
  Future<List<Course>> fetchCourses({
    String keyword = '',
    CourseStatus? status,
  }) async {
    await _latency();
    final k = keyword.trim().toLowerCase();
    return _items
        .where((c) => k.isEmpty || c.name.toLowerCase().contains(k))
        .where((c) => status == null || c.status == status)
        .toList();
  }

  @override
  Future<Course> save(Course course) async {
    await _latency();
    final id = course.id;
    if (id == null) {
      final created = course.copyWith(id: _nextId++);
      _items.add(created);
      return created;
    }
    final index = _items.indexWhere((c) => c.id == id);
    if (index < 0) {
      throw StateError('존재하지 않는 과정입니다.');
    }
    _items[index] = course;
    return course;
  }

  @override
  Future<void> delete(int id) async {
    await _latency();
    _items.removeWhere((c) => c.id == id);
  }

  Future<void> _latency() => Future<void>.delayed(const Duration(milliseconds: 150));
}
