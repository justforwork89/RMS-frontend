/// 과정(=과목) 상태 (LMS-C003). 준비중 → 모집중 → 진행중 → 종료 순서로만 전이 가능.
/// 폐강 추가됨
enum CourseStatus {
  preparing('준비중', '10'),
  scheduled('모집예정', '15'),
  recruiting('모집중', '20'),
  recruitClosed('모집마감', '25'),
  inProgress('진행중', '30'),
  closed('종료', '40'),
  cancelled('폐강', '50');

  const CourseStatus(this.label, this.code);

  final String label;
  final String code;

  /// 정방향(다음 단계)으로만 변경할 수 있다.
  bool canChangeTo(CourseStatus next) => next.index == index + 1;
}

/// 전공 미지정 시 기본값 (공통코드 MAJOR의 '공통').
const defaultMajorCode = '40';

/// 과정(과목) Model (TB_COURSE).
class Course {
  const Course({
    this.id,
    required this.name,
    this.description = '',
    required this.instructor,
    this.instructorId,
    this.major = defaultMajorCode,
    this.recruitStartDate,
    this.recruitEndDate,
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

  /// 담당 강사 로그인 아이디 (참고자료 권한 확인용).
  final String? instructorId;

  /// 전공 코드 (공통코드 MAJOR). 과목/교수 정보 조회 조건.
  final String major;

  /// 모집 기간 (이 안에서만 수강신청 가능, 교육 기간과 겹쳐도 됨)
  final DateTime? recruitStartDate;
  final DateTime? recruitEndDate;
  final DateTime startDate;
  final DateTime endDate;
  final int capacity;
  final int enrolled;
  final CourseStatus status;

  bool get isFull => enrolled >= capacity;

  /// 지금 수강신청할 수 있는지: 승인된 과정 + 오늘이 모집 기간 안
  bool get isRecruitOpen {
    final s = recruitStartDate;
    final e = recruitEndDate;
    if (s == null || e == null) return false;
    if (status == CourseStatus.preparing ||
        status == CourseStatus.closed ||
        status == CourseStatus.cancelled) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !today.isBefore(s) && !today.isAfter(e);
  }

  Course copyWith({
    int? id,
    String? name,
    String? description,
    String? instructor,
    String? instructorId,
    String? major,
    DateTime? recruitStartDate,
    DateTime? recruitEndDate,
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
      instructorId: instructorId ?? this.instructorId,
      major: major ?? this.major,
      recruitStartDate: recruitStartDate ?? this.recruitStartDate,
      recruitEndDate: recruitEndDate ?? this.recruitEndDate,
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
