import 'package:flutter/material.dart';

import 'repositories/course_repository.dart';
import 'views/course_list_view.dart';

void main() {
  // 백엔드(Spring Boot) 연동 전까지는 메모리 목 저장소를 사용한다.
  runApp(LmsApp(repository: InMemoryCourseRepository()));
}

class LmsApp extends StatelessWidget {
  const LmsApp({super.key, required this.repository});

  final CourseRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2F5BEA),
        useMaterial3: true,
      ),
      home: CourseListView(repository: repository),
    );
  }
}
