import 'package:flutter/material.dart';

import '../models/course.dart';

/// 과정 상태 뱃지 (여러 화면 공용).
class CourseStatusChip extends StatelessWidget {
  const CourseStatusChip({super.key, required this.status});

  final CourseStatus status;

  Color get _color {
    switch (status) {
      case CourseStatus.preparing:
        return Colors.grey;
      case CourseStatus.recruiting:
        return Colors.blue;
      case CourseStatus.inProgress:
        return Colors.green;
      case CourseStatus.closed:
        return Colors.brown;
      case CourseStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: _color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: _color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
