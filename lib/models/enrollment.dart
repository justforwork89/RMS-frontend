/// 수강신청 Model. 학생(studentId)이 과정(courseId)을 신청한 이력.
class Enrollment {
  const Enrollment({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.appliedAt,
  });

  final int id;
  final String studentId;
  final int courseId;
  final DateTime appliedAt;

  Enrollment copyWith({int? courseId, DateTime? appliedAt}) {
    return Enrollment(
      id: id,
      studentId: studentId,
      courseId: courseId ?? this.courseId,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }
}
