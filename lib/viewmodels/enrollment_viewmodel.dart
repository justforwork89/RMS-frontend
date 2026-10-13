import 'package:flutter/foundation.dart';

import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/user.dart';
import '../repositories/course_repository.dart';
import '../repositories/enrollment_repository.dart';

/// 내 수강신청 한 건 + 해당 과정 정보.
class EnrollmentItem {
  const EnrollmentItem(this.enrollment, this.course);

  final Enrollment enrollment;
  final Course course;

  /// 모집 중일 때만 변경/취소할 수 있다.
  bool get editable => course.status == CourseStatus.recruiting;
}

/// 수강신청 관리 화면(신청 / 신청 내역)의 ViewModel.
class EnrollmentViewModel extends ChangeNotifier {
  EnrollmentViewModel(this._enrollments, this._courses, this._student);

  final EnrollmentRepository _enrollments;
  final CourseRepository _courses;
  final AppUser _student;

  List<Course> _recruiting = const [];
  List<EnrollmentItem> _items = const [];
  Set<int> _enrolledIds = const {};
  String? _major;
  bool _loading = false;
  String? _errorMessage;

  List<String> get majors => _courses.majors;
  String? get major => _major;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  /// 내 신청 내역.
  List<EnrollmentItem> get items => _items;

  /// 신청 가능한 과정 목록 (모집 중, 전공 필터 적용).
  List<Course> get availableCourses =>
      _recruiting.where((c) => _major == null || c.major == _major).toList();

  /// 변경 대상 후보 (모집 중이고 아직 신청하지 않은 과정).
  List<Course> get changeCandidates =>
      _recruiting.where((c) => !isEnrolled(c)).toList();

  bool isEnrolled(Course course) => _enrolledIds.contains(course.id);

  void setMajor(String? major) {
    _major = major;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final courses = await _courses.fetchCourses();
      final mine = await _enrollments.fetchByStudent(_student.id);
      final byId = <int?, Course>{for (final c in courses) c.id: c};
      _items = [
        for (final e in mine)
          if (byId[e.courseId] != null) EnrollmentItem(e, byId[e.courseId]!),
      ];
      _enrolledIds = mine.map((e) => e.courseId).toSet();
      _recruiting =
          courses.where((c) => c.status == CourseStatus.recruiting).toList();
    } catch (_) {
      _errorMessage = '수강신청 정보를 불러오지 못했습니다.';
    }
    _loading = false;
    notifyListeners();
  }

  /// 아래 동작들은 성공 시 null, 실패 시 사용자에게 보여줄 메시지를 반환한다.
  Future<String?> enroll(Course course) =>
      _run(() => _enrollments.enroll(_student.id, course.id!));

  Future<String?> change(EnrollmentItem item, Course target) =>
      _run(() => _enrollments.change(item.enrollment.id, target.id!));

  Future<String?> cancel(EnrollmentItem item) =>
      _run(() => _enrollments.cancel(item.enrollment.id));

  Future<String?> _run(Future<void> Function() action) async {
    String? error;
    try {
      await action();
    } on EnrollmentException catch (e) {
      error = e.message;
    } catch (_) {
      error = '처리 중 오류가 발생했습니다.';
    }
    await load();
    return error;
  }
}
