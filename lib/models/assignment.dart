/// 과제 Model (TB_ASSIGNMENT).
class Assignment {
  const Assignment({
    this.id,
    required this.courseId,
    required this.title,
    this.content = '',
    required this.dueDate,
  });

  final int? id;
  final int courseId;
  final String title;
  final String content;

  /// 제출 마감 일시.
  final DateTime dueDate;
}

/// 과제 제출 Model (TB_SUBMISSION). 학생은 과제당 한 번 제출(수정은 채점 전까지).
class Submission {
  const Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.content,
    this.fileName,
    required this.submittedAt,
    this.score,
    this.feedback = '',
    this.studentName = '',
  });

  final int id;
  final int assignmentId;
  final String studentId;
  final String content;

  /// 첨부 파일명 (TB_FILE.ORIGIN_NAME). 파일 업로드는 백엔드 연동 후 지원.
  final String? fileName;
  final DateTime submittedAt;

  /// 점수 (0~100). null이면 채점 전.
  final int? score;
  final String feedback;

  final String studentName;

  bool get graded => score != null;

  Submission copyWith({
    String? content,
    String? fileName,
    DateTime? submittedAt,
    int? score,
    String? feedback,
  }) {
    return Submission(
      id: id,
      assignmentId: assignmentId,
      studentId: studentId,
      content: content ?? this.content,
      fileName: fileName ?? this.fileName,
      submittedAt: submittedAt ?? this.submittedAt,
      score: score ?? this.score,
      feedback: feedback ?? this.feedback,
      studentName: studentName,
    );
  }
}
