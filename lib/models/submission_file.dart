/// 과제 제출 첨부파일 Model (TB_SUBMISSION_FILE). 서버 SubmissionFileResponse와 짝.
class SubmissionFile {
  const SubmissionFile({
    required this.id,
    required this.submissionId,
    required this.name,
    required this.size,
    this.contentType,
    this.regDt,
  });
  final int id;
  final int submissionId;
  final String name;
  final int size;
  final String? contentType;
  final DateTime? regDt;
  factory SubmissionFile.fromJson(Map<String, dynamic> j) => SubmissionFile(
    id: (j['id'] as num).toInt(),
    submissionId: (j['submissionId'] as num).toInt(),
    name: j['name'] as String,
    size: (j['size'] as num).toInt(),
    contentType: j['contentType'] as String?,
    regDt: j['regDt'] == null ? null : DateTime.tryParse(j['regDt'].toString()),
  );
}

/// 서버(application.yml)와 같은 규칙: 제출 1건에 최대 5개, 합쳐서 50MB
const maxSubmissionFiles = 5;
const maxSubmissionBytes = 50 * 1024 * 1024;
