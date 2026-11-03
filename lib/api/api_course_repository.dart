import '../models/code_group.dart';
import '../models/course.dart';
import '../repositories/course_repository.dart';
import 'api_client.dart';
import 'api_common_code_repository.dart';

CourseStatus _statusFromCode(String code) {
  for (final e in CourseStatus.values) {
    if (e.code == code) return e;
  }
  return CourseStatus.preparing;
}

class ApiCourseRepository implements CourseRepository {
  ApiCourseRepository(this._api, this._commonCodes);

  final ApiClient _api;
  final ApiCommonCodeRepository _commonCodes;
  List<({String id, String name})> _instructors = const [];
  List<String> _majors = const [];

  @override
  List<String> get instructors => [for (final i in _instructors) i.name];

  @override
  List<String> get majors => _majors;

  /// 로그인 직후 호출해 강사 선택지를 채운다.
  Future<void> loadInstructors() async {
    final data = await _api.call('GET', '/api/instructors') as List<dynamic>;
    _instructors = [
      for (final e in data)
        (
          id: (e as Map<String, dynamic>)['id'] as String,
          name: e['name'] as String,
        ),
    ];
  }

  @override
  Future<void> loadMajors() async {
    final list = await _commonCodes.fetchByGroup(CodeGroup.major);
    _majors = [for (final c in list) c.code];
  }

  @override
  Future<List<Course>> fetchCourses({
    String keyword = '',
    CourseStatus? status,
  }) async {
    final query = <String, String>{
      if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      if (status != null) 'status': status.code,
    };
    final path = Uri(
      path: '/api/courses',
      queryParameters: query.isEmpty ? null : query,
    ).toString();
    final data = await _api.call('GET', path) as List<dynamic>;
    return [for (final e in data) _fromJson(e as Map<String, dynamic>)];
  }

  @override
  Future<Course> save(Course course) async {
    String? instructorId;
    for (final i in _instructors) {
      if (i.name == course.instructor) instructorId = i.id;
    }
    final body = {
      'courseName': course.name,
      'description': course.description,
      'instructorId': instructorId,
      'major': course.major,
      'startDate': formatDate(course.startDate),
      'endDate': formatDate(course.endDate),
      'capacity': course.capacity,
      'statusCd': course.status.code,
    };
    final id = course.id;
    final data = id == null
        ? await _api.call('POST', '/api/courses', body: body)
        : await _api.call('PUT', '/api/courses/$id', body: body);
    return _fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> delete(int id) async {
    await _api.call('DELETE', '/api/courses/$id');
  }

  Course _fromJson(Map<String, dynamic> j) {
    return Course(
      id: (j['id'] as num).toInt(),
      name: j['name'] as String,
      description: (j['description'] as String?) ?? '',
      instructor: j['instructorName'] as String,
      major: j['major'] as String,
      startDate: DateTime.parse(j['startDate'] as String),
      endDate: DateTime.parse(j['endDate'] as String),
      capacity: (j['capacity'] as num).toInt(),
      enrolled: (j['enrolledCount'] as num).toInt(),
      status: _statusFromCode(j['statusCode'] as String),
    );
  }
}
