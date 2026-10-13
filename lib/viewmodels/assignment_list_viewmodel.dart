import 'package:flutter/foundation.dart';

import '../app_dependencies.dart';
import '../models/assignment.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/user.dart';
import 'viewmodel_support.dart';

/// 과제 한 건 + 과정 + (학생) 내 제출 / (강사) 제출 현황.
class AssignmentItem {
  const AssignmentItem({
    required this.assignment,
    required this.course,
    this.submission,
    this.submittedCount = 0,
    this.gradedCount = 0,
  });

  final Assignment assignment;
  final Course course;

  /// 학생 화면에서만 사용: 내 제출 내역.
  final Submission? submission;

  /// 강사 화면에서만 사용: 제출 건수 / 채점 완료 건수.
  final int submittedCount;
  final int gradedCount;

  String get studentStatus {
    final s = submission;
    if (s == null) return '미제출';
    if (s.graded) return '채점완료 (' + s.score.toString() + '점)';
    return '제출완료';
  }
}

/// 과제 목록(LMS-A001)의 ViewModel. 학생은 승인된 과정의 과제를, 강사는 담당 과정의 과제를 본다.
class AssignmentListViewModel extends ChangeNotifier with ActionRunner {
  AssignmentListViewModel(this._deps, this._user);

  final AppDependencies _deps;
  final AppUser _user;

  List<AssignmentItem> _items = const [];
  List<Course> _myCourses = const [];
  bool _loading = false;
  String? _errorMessage;

  List<AssignmentItem> get items => _items;

  /// 강사의 담당 과정 (과제 출제 대상).
  List<Course> get myCourses => _myCourses;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  bool get isInstructor => _user.role == UserRole.instructor;

  @override
  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final courses = await _deps.courses.fetchCourses();
      final byId = <int?, Course>{for (final c in courses) c.id: c};
      if (isInstructor) {
        _myCourses = courses.where((c) => c.instructor == _user.name).toList();
        final ids = <int>{for (final c in _myCourses) c.id!};
        final assignments = await _deps.assignments.fetchAssignments(
          courseIds: ids,
        );
        final subs = await _deps.assignments.fetchSubmissions();
        _items = [
          for (final a in assignments)
            if (byId[a.courseId] != null)
              AssignmentItem(
                assignment: a,
                course: byId[a.courseId]!,
                submittedCount:
                    subs.where((s) => s.assignmentId == a.id).length,
                gradedCount: subs
                    .where((s) => s.assignmentId == a.id && s.graded)
                    .length,
              ),
        ];
      } else {
        final mine = await _deps.enrollments.fetchByStudent(_user.id);
        final ids = <int>{
          for (final e in mine)
            if (e.status == EnrollStatus.approved) e.courseId,
        };
        final assignments = await _deps.assignments.fetchAssignments(
          courseIds: ids,
        );
        final subs = await _deps.assignments.fetchSubmissions(
          studentId: _user.id,
        );
        final byAssignment = <int, Submission>{
          for (final s in subs) s.assignmentId: s,
        };
        _items = [
          for (final a in assignments)
            if (byId[a.courseId] != null)
              AssignmentItem(
                assignment: a,
                course: byId[a.courseId]!,
                submission: byAssignment[a.id],
              ),
        ];
      }
    } catch (_) {
      _errorMessage = '과제 목록을 불러오지 못했습니다.';
    }
    _loading = false;
    notifyListeners();
  }

  /// 과제 출제 (강사). 성공 시 null, 실패 시 메시지.
  Future<String?> createAssignment({
    required Course course,
    required String title,
    required String content,
    required DateTime dueDate,
  }) {
    return runAction(() async {
      await _deps.assignments.createAssignment(
        Assignment(
          courseId: course.id!,
          title: title,
          content: content,
          dueDate: dueDate,
        ),
      );
    });
  }
}
