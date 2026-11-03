import 'package:flutter/foundation.dart';

import '../app_dependencies.dart';
import '../models/code_group.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/user.dart';
import 'common_code_names_viewmodel.dart';

/// 대시보드 카드 한 장: 제목 + 요약 줄들.
class DashboardSection {
  const DashboardSection(this.title, this.lines);

  final String title;
  final List<String> lines;
}

/// 홈 대시보드(LMS-H001) ViewModel. 역할(학생/강사/관리자)별로 요약 카드를 만든다.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._deps, this._user, this._codeNames) {
    _codeNames.addListener(load);
  }

  @override
  void dispose() {
    _codeNames.removeListener(load);
    super.dispose();
  }

  final AppDependencies _deps;
  final AppUser _user;
  final CodeNames _codeNames;

  List<DashboardSection> _sections = const [];
  bool _loading = false;
  String? _errorMessage;

  List<DashboardSection> get sections => _sections;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      switch (_user.role) {
        case UserRole.student:
          _sections = await _studentSections();
        case UserRole.instructor:
          _sections = await _instructorSections();
        case UserRole.admin:
          _sections = await _adminSections();
      }
    } catch (_) {
      _errorMessage = '대시보드를 불러오지 못했습니다.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<List<DashboardSection>> _studentSections() async {
    final courses = await _deps.courses.fetchCourses();
    final byId = <int?, Course>{for (final c in courses) c.id: c};
    final mine = await _deps.enrollments.fetchByStudent(_user.id);
    final approvedIds = <int>{
      for (final e in mine)
        if (e.status == EnrollStatus.approved) e.courseId,
    };
    final assignments = await _deps.assignments.fetchAssignments(
      courseIds: approvedIds,
    );
    final submissions = await _deps.assignments.fetchSubmissions(
      studentId: _user.id,
    );
    final submittedIds = submissions.map((s) => s.assignmentId).toSet();
    final now = DateTime.now();
    final upcoming = assignments
        .where((a) => !submittedIds.contains(a.id) && a.dueDate.isAfter(now))
        .toList();
    return [
      DashboardSection('내 수강 과정', [
        if (mine.isEmpty) '신청한 과정이 없습니다.',
        for (final e in mine)
          (byId[e.courseId]?.name ?? '-') +
              ' (' +
              _codeNames.name(
                CodeGroup.enrollStatus,
                e.status.code,
                e.status.label,
              ) +
              ')',
      ]),
      DashboardSection('마감 임박 과제', [
        if (upcoming.isEmpty) '마감이 다가온 미제출 과제가 없습니다.',
        for (final a in upcoming.take(3))
          a.title + ' · 마감 ' + formatDate(a.dueDate),
      ]),
    ];
  }

  Future<List<DashboardSection>> _instructorSections() async {
    final all = await _deps.courses.fetchCourses();
    final courses = all.where((c) => c.instructor == _user.name).toList();
    final ids = <int>{for (final c in courses) c.id!};
    final assignments = await _deps.assignments.fetchAssignments(
      courseIds: ids,
    );
    final assignmentIds = assignments.map((a) => a.id).toSet();
    final submissions = await _deps.assignments.fetchSubmissions();
    final pending = submissions
        .where((s) => assignmentIds.contains(s.assignmentId) && !s.graded)
        .length;
    return [
      DashboardSection('담당 과정', [
        if (courses.isEmpty) '담당 과정이 없습니다.',
        for (final c in courses)
          c.name +
              ' (' +
              _codeNames.name(
                CodeGroup.courseStatus,
                c.status.code,
                c.status.label,
              ) +
              ', ' +
              c.enrolled.toString() +
              '/' +
              c.capacity.toString() +
              '명)',
      ]),
      DashboardSection('채점 대기', ['채점 대기 제출물 ' + pending.toString() + '건']),
    ];
  }

  Future<List<DashboardSection>> _adminSections() async {
    final users = await _deps.users.fetchUsers();
    final courses = await _deps.courses.fetchCourses();
    final enrollments = await _deps.enrollments.fetchAll();
    final pending = enrollments
        .where((e) => e.status == EnrollStatus.applied)
        .length;
    return [
      DashboardSection('운영 현황', [
        '전체 사용자 ' + users.length.toString() + '명',
        '전체 과정 ' + courses.length.toString() + '개',
      ]),
      DashboardSection('승인 대기', ['수강 승인 대기 ' + pending.toString() + '건']),
    ];
  }
}
