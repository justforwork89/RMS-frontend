/// 과정(=과목) 상태 (LMS-C003). 준비중 → 모집중 → 진행중 → 종료 순서로만 전이 가능.
enum CourseStatus {
  preparing('준비중'),
  recruiting('모집중'),
  inProgress('진행중'),
  closed('종료');

  const CourseStatus(this.label);

  final String label;

  /// 정방향(다음 단계)으로만 변경할 수 있다.
  bool canChangeTo(CourseStatus next) => next.index == index + 1;
}

/// 과정(과목) Model (TB_COURSE).
class Course {
  const Course({
    this.id,
    required this.name,
    this.description = '',
    required this.instructor,
    this.major = '공통',
    required this.startDate,
    required this.endDate,
    required this.capacity,
    this.enrolled = 0,
    this.status = CourseStatus.preparing,
  });

  final int? id;
  final String name;
  final String description;
  final String instructor;

  /// 전공 구분 (과목/교수 정보 조회 조건).
  final String major;
  final DateTime startDate;
  final DateTime endDate;
  final int capacity;
  final int enrolled;
  final CourseStatus status;

  bool get isFull => enrolled >= capacity;

  Course copyWith({
    int? id,
    String? name,
    String? description,
    String? instructor,
    String? major,
    DateTime? startDate,
    DateTime? endDate,
    int? capacity,
    int? enrolled,
    CourseStatus? status,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      instructor: instructor ?? this.instructor,
      major: major ?? this.major,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      capacity: capacity ?? this.capacity,
      enrolled: enrolled ?? this.enrolled,
      status: status ?? this.status,
    );
  }
}

/// yyyy-MM-dd 형식 문자열.
String formatDate(DateTime? date) {
  if (date == null) return '';
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}
