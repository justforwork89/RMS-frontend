import 'package:flutter/material.dart';

import '../models/course.dart';
import '../repositories/course_repository.dart';
import '../viewmodels/course_list_viewmodel.dart';
import 'course_form_view.dart';

/// 과정 관리 - 목록/조회 화면 (LMS-C003). 상태·로직은 ViewModel이 담당한다.
class CourseListView extends StatefulWidget {
  const CourseListView({super.key, required this.repository});

  final CourseRepository repository;

  @override
  State<CourseListView> createState() => _CourseListViewState();
}

class _CourseListViewState extends State<CourseListView> {
  late final CourseListViewModel _viewModel;
  final TextEditingController _keywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = CourseListViewModel(widget.repository)..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _openForm({Course? course}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CourseFormView(
          repository: widget.repository,
          course: course,
        ),
      ),
    );
    if (saved == true) {
      await _viewModel.load();
    }
  }

  Future<void> _confirmDelete(Course course) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('과정 삭제'),
        content: Text('"' + course.name + '" 과정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final error = await _viewModel.delete(course);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? '삭제되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('과정 관리')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('과정 등록'),
      ),
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
          Expanded(
            child: TextField(
              controller: _keywordController,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: '과정명',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: _viewModel.search,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) => InputDecorator(
                decoration: const InputDecoration(
                  labelText: '상태',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CourseStatus?>(
                    value: _viewModel.statusFilter,
                    isDense: true,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<CourseStatus?>(
                        value: null,
                        child: Text('전체'),
                      ),
                      for (final s in CourseStatus.values)
                        DropdownMenuItem<CourseStatus?>(
                          value: s,
                          child: Text(s.label),
                        ),
                    ],
                    onChanged: _viewModel.filterByStatus,
                  ),
                ),
              ),
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
    if (error != null) {
      return Center(child: Text(error));
    }
    final courses = _viewModel.courses;
    if (courses.isEmpty) {
      return const Center(child: Text('조회된 과정이 없습니다.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: courses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _CourseCard(
        course: courses[i],
        onTap: () => _openForm(course: courses[i]),
        onDelete: () => _confirmDelete(courses[i]),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.onTap,
    required this.onDelete,
  });

  final Course course;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final period = formatDate(course.startDate) + ' ~ ' + formatDate(course.endDate);
    final headcount = course.enrolled.toString() + ' / ' + course.capacity.toString() + '명';
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('강사 ' + course.instructor + '  |  ' + period),
                    const SizedBox(height: 2),
                    Text('정원/신청 ' + headcount),
                  ],
                ),
              ),
              _StatusChip(status: course.status),
              IconButton(
                tooltip: '삭제',
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

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
