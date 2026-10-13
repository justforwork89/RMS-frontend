/// 수강신청 처리 상태. 학생이 신청하면 [applied], 관리자가 승인/반려한다.
enum EnrollStatus {
  applied('신청'),
  approved('승인'),
  rejected('반려');

  const EnrollStatus(this.label);

  final String label;
}

/// 수강신청 Model (TB_ENROLL). 학생(studentId)이 과정(courseId)을 신청한 이력.
class Enrollment {
  const Enrollment({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.appliedAt,
    this.status = EnrollStatus.applied,
  });

  final int id;
  final String studentId;
  final int courseId;
  final DateTime appliedAt;
  final EnrollStatus status;

  Enrollment copyWith({
    int? courseId,
    DateTime? appliedAt,
    EnrollStatus? status,
  }) {
    return Enrollment(
      id: id,
      studentId: studentId,
      courseId: courseId ?? this.courseId,
      appliedAt: appliedAt ?? this.appliedAt,
      status: status ?? this.status,
    );
  }
}
