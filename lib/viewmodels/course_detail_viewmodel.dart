import 'package:flutter/foundation.dart';

import '../app_dependencies.dart';
import '../models/course.dart';
import '../models/user.dart';
import '../repositories/business_exception.dart';

/// 과정 상세(LMS-C002) ViewModel. 과정 정보와 (학생의) 수강신청 가능 여부를 관리한다.
class CourseDetailViewModel extends ChangeNotifier {
  CourseDetailViewModel(this._deps, this._course, this._user);

  final AppDependencies _deps;
  final AppUser _user;
  Course _course;
  bool _enrolled = false;
  bool _loading = false;
  String? _errorMessage;

  Course get course => _course;
  bool get enrolled => _enrolled;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  bool get isStudent => _user.role == UserRole.student;

  /// 학생이 모집 기간 안이고 정원이 남은 과정을 아직 신청하지 않은 경우.
  bool get canEnroll =>
      isStudent &&
      _course.isRecruitOpen &&
      !_course.isFull &&
      !_enrolled;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final all = await _deps.courses.fetchCourses();
      for (final c in all) {
        if (c.id == _course.id) _course = c;
      }
      if (isStudent) {
        final mine = await _deps.enrollments.fetchByStudent(_user.id);
        _enrolled = mine.any((e) => e.courseId == _course.id);
      }
    } catch (_) {
      _errorMessage = '과정 정보를 불러오지 못했습니다.';
    }
    _loading = false;
    notifyListeners();
  }

  /// 성공 시 null, 실패 시 사용자에게 보여줄 메시지.
  Future<String?> enroll() async {
    String? error;
    try {
      await _deps.enrollments.enroll(_user.id, _course.id!);
    } on BusinessException catch (e) {
      error = e.message;
    } catch (_) {
      error = '처리 중 오류가 발생했습니다.';
    }
    await load();
    return error;
  }
}
