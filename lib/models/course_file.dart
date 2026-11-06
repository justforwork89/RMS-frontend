/// 과정 첨부파일 Model (TB_COURSE_FILE). 서버 CourseFileResponse와 짝.
class CourseFile {
  const CourseFile({
    required this.id,
    required this.courseId,
    required this.name,
    required this.size,
    this.contentType,
    this.uploaderId,
    this.regDt,
  });

  final int id;
  final int courseId;
  final String name;
  final int size;
  final String? contentType;
  final String? uploaderId;
  final DateTime? regDt;

  factory CourseFile.fromJson(Map<String, dynamic> j) => CourseFile(
    id: (j['id'] as num).toInt(),
    courseId: (j['courseId'] as num).toInt(),
    name: j['name'] as String,
    size: (j['size'] as num).toInt(),
    contentType: j['contentType'] as String?,
    uploaderId: j['uploaderId'] as String?,
    regDt: j['regDt'] == null ? null : DateTime.tryParse(j['regDt'].toString()),
  );
}

/// 올릴 파일 하나 (화면이 file_picker 결과를 이 모양으로 바꿔 넘긴다)
class UploadFile {
  const UploadFile({
    required this.name,
    required this.size,
    required this.stream,
  });
  final String name;
  final int size;
  final Stream<List<int>> stream;
}

/// 서버와 같은 규칙
const maxUploadBytes = 500 * 1024 * 1024; // 500MB
const maxFilesPerUpload = 20;
const allowedFileExtensions = [
  'pdf',
  'ppt',
  'pptx',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'hwp',
  'hwpx',
  'txt',
  'md',
  'zip',
  'png',
  'jpg',
  'jpeg',
  'mp4',
];

/// 1536 → "1.5 KB"
String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var i = 0;
  while (size >= 1024 && i < units.length - 1) {
    size /= 1024;
    i++;
  }
  return '${size.toStringAsFixed(i == 0 ? 0 : 1)} ${units[i]}';
}
