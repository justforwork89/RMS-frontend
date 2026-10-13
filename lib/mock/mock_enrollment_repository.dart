// [MOCK] 백엔드 연동 시 이 파일은 삭제하고 수강신청 API 구현체로 교체한다.
import '../models/course.dart';
import '../models/enrollment.dart';
import '../repositories/course_repository.dart';
import '../repositories/enrollment_repository.dart';

/// 메모리 기반 임시 수강신청 저장소. 신청/변경/취소 시 과정의 신청 인원도 함께 갱신한다.
/// (실제 백엔드에서는 트랜잭션으로 서버가 처리할 부분)
class MockEnrollmentRepository implements EnrollmentRepository {
  MockEnrollmentRepository(this._courses);

  final CourseRepository _courses;
  final List<Enrollment> _items = [];
  int _nextId = 1;

  Future<Course> _requireCourse(int courseId) async {
    final all = await _courses.fetchCourses();
    for (final c in all) {
      if (c.id == courseId) return c;
    }
    throw const EnrollmentException('존재하지 않는 과정입니다.');
  }

  void _checkOpen(Course course) {
    if (course.status != CourseStatus.recruiting) {
      throw const EnrollmentException('모집 중인 과정만 신청할 수 있습니다.');
    }
    if (course.isFull) {
      throw const EnrollmentException('정원이 마감된 과정입니다.');
    }
  }

  bool _alreadyEnrolled(String studentId, int courseId) {
    return _items.any((e) => e.studentId == studentId && e.courseId == courseId);
  }

  Future<void> _adjustEnrolled(int courseId, int delta) async {
    final course = await _requireCourse(courseId);
    final next = course.enrolled + delta;
    await _courses.save(course.copyWith(enrolled: next < 0 ? 0 : next));
  }

  int _indexOf(int enrollmentId) {
    final index = _items.indexWhere((e) => e.id == enrollmentId);
    if (index < 0) {
      throw const EnrollmentException('수강신청 내역을 찾을 수 없습니다.');
    }
    return index;
  }

  @override
  Future<List<Enrollment>> fetchByStudent(String studentId) async {
    await _latency();
    final mine = _items.where((e) => e.studentId == studentId).toList();
    mine.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
    return mine;
  }

  @override
  Future<Enrollment> enroll(String studentId, int courseId) async {
    await _latency();
    if (_alreadyEnrolled(studentId, courseId)) {
      throw const EnrollmentException('이미 신청한 과정입니다.');
    }
    _checkOpen(await _requireCourse(courseId));
    await _adjustEnrolled(courseId, 1);
    final created = Enrollment(
      id: _nextId++,
      studentId: studentId,
      courseId: courseId,
      appliedAt: DateTime.now(),
    );
    _items.add(created);
    return created;
  }

  @override
  Future<Enrollment> change(int enrollmentId, int newCourseId) async {
    await _latency();
    final index = _indexOf(enrollmentId);
    final old = _items[index];
    if (old.courseId == newCourseId) {
      throw const EnrollmentException('현재 신청한 과정과 같은 과정입니다.');
    }
    if (_alreadyEnrolled(old.studentId, newCourseId)) {
      throw const EnrollmentException('이미 신청한 과정입니다.');
    }
    final oldCourse = await _requireCourse(old.courseId);
    if (oldCourse.status != CourseStatus.recruiting) {
      throw const EnrollmentException('모집이 끝난 과정은 변경할 수 없습니다.');
    }
    _checkOpen(await _requireCourse(newCourseId));
    await _adjustEnrolled(newCourseId, 1);
    await _adjustEnrolled(old.courseId, -1);
    final updated = old.copyWith(
      courseId: newCourseId,
      appliedAt: DateTime.now(),
    );
    _items[index] = updated;
    return updated;
  }

  @override
  Future<void> cancel(int enrollmentId) async {
    await _latency();
    final index = _indexOf(enrollmentId);
    final old = _items[index];
    final oldCourse = await _requireCourse(old.courseId);
    if (oldCourse.status != CourseStatus.recruiting) {
      throw const EnrollmentException('모집이 끝난 과정은 취소할 수 없습니다.');
    }
    await _adjustEnrolled(old.courseId, -1);
    _items.removeAt(index);
  }

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 150));
}
