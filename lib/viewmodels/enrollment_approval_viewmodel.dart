import 'package:flutter/foundation.dart';

import '../app_dependencies.dart';
import '../models/enrollment.dart';
import 'viewmodel_support.dart';

/// 수강 승인 목록의 한 행: 신청 건 + 학생/과정 이름.
class ApprovalItem {
  const ApprovalItem(this.enrollment, this.studentName, this.courseName);

  final Enrollment enrollment;
  final String studentName;
  final String courseName;
}

/// 수강 승인(LMS-M002)의 ViewModel. 전체 신청을 조회하고 승인/반려한다.
class EnrollmentApprovalViewModel extends ChangeNotifier with ActionRunner {
  EnrollmentApprovalViewModel(this._deps);

  final AppDependencies _deps;

  List<ApprovalItem> _all = const [];
  EnrollStatus? _filter = EnrollStatus.applied;
  bool _loading = false;
  String? _errorMessage;

  /// null이면 전체.
  EnrollStatus? get filter => _filter;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  List<ApprovalItem> get items => _filter == null
      ? _all
      : [
          for (final i in _all)
            if (i.enrollment.status == _filter) i,
        ];

  void setFilter(EnrollStatus? status) {
    _filter = status;
    notifyListeners();
  }

  @override
  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final enrollments = await _deps.enrollments.fetchAll();
      final users = await _deps.users.fetchUsers();
      final courses = await _deps.courses.fetchCourses();
      final userNames = <String, String>{for (final u in users) u.id: u.name};
      final courseNames = <int, String>{
        for (final c in courses)
          if (c.id != null) c.id!: c.name,
      };
      _all = [
        for (final e in enrollments)
          ApprovalItem(
            e,
            userNames[e.studentId] ?? e.studentId,
            courseNames[e.courseId] ?? '(삭제된 과정)',
          ),
      ];
    } catch (_) {
      _errorMessage = '수강신청 목록을 불러오지 못했습니다.';
    }
    _loading = false;
    notifyListeners();
  }

  /// 성공 시 null, 실패 시 사용자에게 보여줄 메시지를 반환한다.
  Future<String?> decide(ApprovalItem item, EnrollStatus status) {
    return runAction(() async {
      await _deps.enrollments.setStatus(item.enrollment.id, status);
    });
  }
}
