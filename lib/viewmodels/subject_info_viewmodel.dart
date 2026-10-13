import 'package:flutter/foundation.dart';

import '../models/course.dart';
import '../repositories/course_repository.dart';

/// 과목/교수 정보 조회 화면의 ViewModel. 조회 조건: 전공 + 과목명.
class SubjectInfoViewModel extends ChangeNotifier {
  SubjectInfoViewModel(this._repository);

  final CourseRepository _repository;

  List<Course> _courses = const [];
  String? _major;
  String _keyword = '';
  bool _loading = false;
  String? _errorMessage;

  List<Course> get courses => _courses;
  List<String> get majors => _repository.majors;
  String? get major => _major;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final all = await _repository.fetchCourses(keyword: _keyword);
      _courses = all.where((c) => _major == null || c.major == _major).toList();
    } catch (_) {
      _errorMessage = '과목 정보를 불러오지 못했습니다.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> search(String keyword) {
    _keyword = keyword;
    return load();
  }

  Future<void> filterByMajor(String? major) {
    _major = major;
    return load();
  }
}
