import 'package:flutter/foundation.dart';

import '../models/course.dart';
import '../repositories/course_repository.dart';

/// 과정 목록 화면(LMS-C003)의 ViewModel.
/// 조회 조건(과정명/상태)과 목록 상태를 보관하고 View는 이를 구독만 한다.
class CourseListViewModel extends ChangeNotifier {
  CourseListViewModel(this._repository);

  final CourseRepository _repository;

  List<Course> _courses = const [];
  String _keyword = '';
  CourseStatus? _statusFilter;
  bool _loading = false;
  String? _errorMessage;

  List<Course> get courses => _courses;
  String get keyword => _keyword;
  CourseStatus? get statusFilter => _statusFilter;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _courses = await _repository.fetchCourses(
        keyword: _keyword,
        status: _statusFilter,
      );
    } catch (_) {
      _errorMessage = '과정 목록을 불러오지 못했습니다.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> search(String keyword) {
    _keyword = keyword;
    return load();
  }

  Future<void> filterByStatus(CourseStatus? status) {
    _statusFilter = status;
    return load();
  }

  /// 삭제 성공 시 null, 실패 시 사용자에게 보여줄 메시지를 반환한다.
  Future<String?> delete(Course course) async {
    final id = course.id;
    if (id == null) return '삭제할 수 없는 과정입니다.';
    if (course.enrolled > 0) {
      return '수강 신청 이력이 있는 과정은 삭제할 수 없습니다.';
    }
    try {
      await _repository.delete(id);
    } catch (_) {
      return '삭제 중 오류가 발생했습니다.';
    }
    await load();
    return null;
  }
}
