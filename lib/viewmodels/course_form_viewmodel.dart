import 'package:flutter/foundation.dart';

import '../models/course.dart';
import '../repositories/course_repository.dart';

/// 과정 등록/수정 화면의 ViewModel. 입력값 보관, 검증, 저장을 담당한다.
class CourseFormViewModel extends ChangeNotifier {
  CourseFormViewModel(this._repository, {Course? course}) : _original = course {
    final c = course;
    instructor = c?.instructor ?? _repository.instructors.first;
    if (c != null) {
      name = c.name;
      description = c.description;
      startDate = c.startDate;
      endDate = c.endDate;
      capacityText = c.capacity.toString();
      status = c.status;
    }
  }

  final CourseRepository _repository;
  final Course? _original;

  String name = '';
  String description = '';
  late String instructor;
  DateTime? startDate;
  DateTime? endDate;
  String capacityText = '';
  CourseStatus status = CourseStatus.preparing;

  bool _saving = false;
  String? _errorMessage;

  bool get isEdit => _original != null;

  /// 종료된 과정은 수정할 수 없다.
  bool get isReadOnly => _original?.status == CourseStatus.closed;

  bool get saving => _saving;
  String? get errorMessage => _errorMessage;
  List<String> get instructors => _repository.instructors;

  /// 현재 상태 + 다음 단계만 선택 가능 (역방향 불가).
  List<CourseStatus> get selectableStatuses {
    final base = _original?.status ?? CourseStatus.preparing;
    return CourseStatus.values
        .where((s) => s == base || base.canChangeTo(s))
        .toList();
  }

  void setInstructor(String value) {
    instructor = value;
    notifyListeners();
  }

  void setStartDate(DateTime value) {
    startDate = value;
    notifyListeners();
  }

  void setEndDate(DateTime value) {
    endDate = value;
    notifyListeners();
  }

  void setStatus(CourseStatus value) {
    status = value;
    notifyListeners();
  }

  String? validateName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return '과정명은 필수입니다.';
    if (v.length > 100) return '과정명은 100자 이내로 입력하세요.';
    return null;
  }

  String? validateDescription(String? value) {
    if ((value ?? '').length > 2000) return '과정 설명은 2000자 이내로 입력하세요.';
    return null;
  }

  String? validateCapacity(String? value) {
    final n = int.tryParse((value ?? '').trim());
    if (n == null || n < 1) return '정원은 1 이상의 정수여야 합니다.';
    final enrolled = _original?.enrolled ?? 0;
    if (n < enrolled) return '현재 신청 인원($enrolled명)보다 작을 수 없습니다.';
    return null;
  }

  /// 시작일/종료일 검증 메시지 (없으면 null).
  String? get dateError {
    final s = startDate;
    final e = endDate;
    if (s == null || e == null) return '교육 시작일과 종료일을 선택하세요.';
    if (e.isBefore(s)) return '종료일은 시작일보다 빠를 수 없습니다.';
    return null;
  }

  String? _validateAll() {
    return validateName(name) ??
        validateDescription(description) ??
        validateCapacity(capacityText) ??
        dateError;
  }

  /// 저장 성공 시 true. 실패 시 errorMessage에 사유가 설정된다.
  Future<bool> save() async {
    if (isReadOnly) {
      _errorMessage = '종료된 과정은 수정할 수 없습니다.';
      notifyListeners();
      return false;
    }
    _errorMessage = _validateAll();
    if (_errorMessage != null) {
      notifyListeners();
      return false;
    }
    _saving = true;
    notifyListeners();
    try {
      await _repository.save(
        Course(
          id: _original?.id,
          name: name.trim(),
          description: description,
          instructor: instructor,
          startDate: startDate!,
          endDate: endDate!,
          capacity: int.parse(capacityText.trim()),
          enrolled: _original?.enrolled ?? 0,
          status: status,
        ),
      );
      _saving = false;
      notifyListeners();
      return true;
    } catch (_) {
      _saving = false;
      _errorMessage = '저장 중 오류가 발생했습니다.';
      notifyListeners();
      return false;
    }
  }
}
