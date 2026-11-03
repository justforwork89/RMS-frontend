import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../models/code_group.dart';
import '../models/course.dart';
import '../models/user.dart';
import '../viewmodels/common_code_names_viewmodel.dart';
import '../viewmodels/course_detail_viewmodel.dart';
import 'course_status_chip.dart';
import 'dialogs.dart';

/// 과정 상세 (LMS-C002). 과정 정보, 강사, 정원/신청 현황을 보여준다.
/// 학생은 모집 중인 과정을 여기서 바로 수강신청할 수 있다.
class CourseDetailView extends StatefulWidget {
  const CourseDetailView({
    super.key,
    required this.dependencies,
    required this.course,
    required this.user,
  });

  final AppDependencies dependencies;
  final Course course;
  final AppUser user;

  @override
  State<CourseDetailView> createState() => _CourseDetailViewState();
}

class _CourseDetailViewState extends State<CourseDetailView> {
  late final CourseDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CourseDetailViewModel(
      widget.dependencies,
      widget.course,
      widget.user,
    )..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _enroll() async {
    final ok = await showConfirmDialog(
      context,
      title: '수강신청',
      message: '"' + _viewModel.course.name + '" 과정을 신청하시겠습니까?',
      okLabel: '신청',
    );
    if (!ok) return;
    final error = await _viewModel.enroll();
    if (!mounted) return;
    showToast(context, error ?? '수강신청이 완료되었습니다.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('과정 상세')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final c = _viewModel.course;
          final ratio = c.capacity <= 0
              ? 0.0
              : (c.enrolled / c.capacity).clamp(0.0, 1.0);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      c.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  CourseStatusChip(status: c.status),
                ],
              ),
              const SizedBox(height: 16),
              _row(
                '전공',
                CodeNamesScope.of(
                  context,
                ).name(CodeGroup.major, c.major, c.major),
              ),
              _row('담당 강사', c.instructor),
              _row(
                '교육 기간',
                formatDate(c.startDate) + ' ~ ' + formatDate(c.endDate),
              ),
              _row(
                '정원/신청',
                c.enrolled.toString() + ' / ' + c.capacity.toString() + '명',
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: ratio),
              const SizedBox(height: 16),
              Text('과정 설명', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(c.description.isEmpty ? '등록된 설명이 없습니다.' : c.description),
              const SizedBox(height: 24),
              if (_viewModel.isStudent)
                if (_viewModel.enrolled)
                  const OutlinedButton(onPressed: null, child: Text('이미 신청한 과정입니다'))
                else
                  FilledButton(
                    onPressed: _viewModel.canEnroll ? _enroll : null,
                    child: Text(
                      c.status != CourseStatus.recruiting
                          ? '모집 중인 과정이 아닙니다'
                          : (c.isFull ? '정원이 마감되었습니다' : '수강신청'),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
