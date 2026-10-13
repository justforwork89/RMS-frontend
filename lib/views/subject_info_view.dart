import 'package:flutter/material.dart';

import '../models/course.dart';
import '../repositories/course_repository.dart';
import '../viewmodels/subject_info_viewmodel.dart';
import 'course_status_chip.dart';

/// 과목/교수 정보 목록 (조회 전용). 검색 조건: 전공, 과목명.
class SubjectInfoView extends StatefulWidget {
  const SubjectInfoView({
    super.key,
    required this.repository,
    this.drawer,
    this.actions,
    this.onTapCourse,
  });

  final CourseRepository repository;

  /// 과목 카드를 눌렀을 때 호출 (과정 상세 화면 이동 등).
  final void Function(Course course)? onTapCourse;
  final Widget? drawer;
  final List<Widget>? actions;

  @override
  State<SubjectInfoView> createState() => _SubjectInfoViewState();
}

class _SubjectInfoViewState extends State<SubjectInfoView> {
  late final SubjectInfoViewModel _viewModel;
  final TextEditingController _keywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = SubjectInfoViewModel(widget.repository)..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('과목/교수 정보'),
        actions: widget.actions,
      ),
      drawer: widget.drawer,
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) => _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) => InputDecorator(
                decoration: const InputDecoration(
                  labelText: '전공',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _viewModel.major,
                    isDense: true,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('전체'),
                      ),
                      for (final m in _viewModel.majors)
                        DropdownMenuItem<String?>(value: m, child: Text(m)),
                    ],
                    onChanged: _viewModel.filterByMajor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _keywordController,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: '과목명',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: _viewModel.search,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => _viewModel.search(_keywordController.text),
            child: const Text('조회'),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_viewModel.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _viewModel.errorMessage;
    if (error != null) return Center(child: Text(error));
    final courses = _viewModel.courses;
    if (courses.isEmpty) {
      return const Center(child: Text('조회된 과목이 없습니다.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: courses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _SubjectCard(
        course: courses[i],
        onTap: widget.onTapCourse == null
            ? null
            : () => widget.onTapCourse!(courses[i]),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.course, this.onTap});

  final Course course;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final period =
        formatDate(course.startDate) + ' ~ ' + formatDate(course.endDate);
    final headcount = course.enrolled.toString() +
        ' / ' +
        course.capacity.toString() +
        '명';
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    course.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                CourseStatusChip(status: course.status),
              ],
            ),
            const SizedBox(height: 6),
            Text('전공 ' + course.major + '  |  교수 ' + course.instructor),
            const SizedBox(height: 2),
            Text('교육기간 ' + period),
            const SizedBox(height: 2),
            Text('정원/신청 ' + headcount),
            if (course.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                course.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}
