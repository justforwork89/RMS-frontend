// [MOCK] 백엔드 연동 시 이 파일은 삭제하고 실제 API 구현체로 교체한다.
import '../models/course.dart';
import '../repositories/course_repository.dart';

/// 메모리 기반 임시 과정(과목) 저장소.
class MockCourseRepository implements CourseRepository {
  MockCourseRepository() {
    _items.addAll([
      Course(
        id: 1,
        name: 'Flutter 모바일 앱 개발',
        description: 'Dart 문법부터 Flutter 위젯, 상태 관리까지 학습합니다.',
        instructor: '김강사',
        major: '컴퓨터공학',
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
        major: '컴퓨터공학',
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
        instructor: '이강사',
        major: '데이터분석',
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
        major: '컴퓨터공학',
        startDate: DateTime(2026, 8, 3),
        endDate: DateTime(2026, 8, 14),
        capacity: 20,
        enrolled: 18,
        status: CourseStatus.closed,
      ),
      Course(
        id: 5,
        name: '웹 보안 기초',
        description: 'OWASP Top 10 중심의 웹 취약점 이해와 방어.',
        instructor: '김강사',
        major: '정보보안',
        startDate: DateTime(2026, 12, 7),
        endDate: DateTime(2027, 1, 29),
        capacity: 15,
        enrolled: 14,
        status: CourseStatus.recruiting,
      ),
      Course(
        id: 6,
        name: '파이썬 데이터 분석',
        description: 'pandas를 이용한 데이터 정제와 시각화.',
        instructor: '이강사',
        major: '데이터분석',
        startDate: DateTime(2026, 12, 14),
        endDate: DateTime(2027, 2, 5),
        capacity: 20,
        enrolled: 5,
        status: CourseStatus.recruiting,
      ),
      Course(
        id: 7,
        name: '네트워크 보안 실무',
        description: '방화벽, IDS/IPS 구성과 로그 분석 실습.',
        instructor: '이강사',
        major: '정보보안',
        startDate: DateTime(2027, 1, 4),
        endDate: DateTime(2027, 2, 26),
        capacity: 10,
        enrolled: 10,
        status: CourseStatus.recruiting,
      ),
    ]);
  }

  final List<Course> _items = [];
  int _nextId = 8;

  @override
  List<String> get instructors => const ['김강사', '이강사'];

  @override
  List<String> get majors => const ['컴퓨터공학', '정보보안', '데이터분석'];

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

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 150));
}
