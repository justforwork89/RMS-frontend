import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../models/assignment.dart';
import '../models/course.dart';
import '../models/user.dart';
import '../viewmodels/assignment_list_viewmodel.dart';
import 'assignment_grade_view.dart';
import 'assignment_submit_view.dart';
import 'dialogs.dart';

/// 과제 목록 (LMS-A001). 학생: 제출 상태 조회/제출, 강사: 출제/채점 진입.
class AssignmentListView extends StatefulWidget {
  const AssignmentListView({
    super.key,
    required this.dependencies,
    required this.user,
    this.drawer,
    this.actions,
  });

  final AppDependencies dependencies;
  final AppUser user;
  final Widget? drawer;
  final List<Widget>? actions;

  @override
  State<AssignmentListView> createState() => _AssignmentListViewState();
}

class _AssignmentListViewState extends State<AssignmentListView> {
  late final AssignmentListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AssignmentListViewModel(widget.dependencies, widget.user)
      ..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _open(AssignmentItem item) async {
    final Widget page = _viewModel.isInstructor
        ? AssignmentGradeView(
            dependencies: widget.dependencies,
            assignment: item.assignment,
            courseName: item.course.name,
          )
        : AssignmentSubmitView(
            repository: widget.dependencies.assignments,
            submissionFiles: widget.dependencies.submissionFiles,
            assignment: item.assignment,
            courseName: item.course.name,
            student: widget.user,
            existing: item.submission,
          );
    await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute<bool>(builder: (_) => page));
    await _viewModel.load();
  }

  Future<void> _create() async {
    final courses = _viewModel.myCourses;
    if (courses.isEmpty) {
      showToast(context, '담당 과정이 없어 과제를 출제할 수 없습니다.');
      return;
    }
    final result = await showDialog<_NewAssignment>(
      context: context,
      builder: (_) => _NewAssignmentDialog(courses: courses),
    );
    if (result == null) return;
    final error = await _viewModel.createAssignment(
      course: result.course,
      title: result.title,
      content: result.content,
      dueDate: result.dueDate,
    );
    if (!mounted) return;
    showToast(context, error ?? '과제가 출제되었습니다.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('과제'), actions: widget.actions),
      drawer: widget.drawer,
      floatingActionButton: widget.user.role == UserRole.instructor
          ? FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('과제 출제'),
            )
          : null,
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.loading && _viewModel.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final error = _viewModel.errorMessage;
          if (error != null) return Center(child: Text(error));
          final items = _viewModel.items;
          if (items.isEmpty) {
            return Center(
              child: Text(
                _viewModel.isInstructor
                    ? '출제한 과제가 없습니다.\n"과제 출제"로 새 과제를 만드세요.'
                    : '표시할 과제가 없습니다.\n수강 승인된 과정의 과제만 보입니다.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _card(items[i]),
          );
        },
      ),
    );
  }

  Widget _card(AssignmentItem item) {
    final due = '마감 ' + formatDate(item.assignment.dueDate);
    final status = _viewModel.isInstructor
        ? '제출 ' +
              item.submittedCount.toString() +
              '건 / 채점 ' +
              item.gradedCount.toString() +
              '건'
        : item.studentStatus;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () => _open(item),
        title: Text(item.assignment.title),
        subtitle: Text(item.course.name + '\n' + due + '  |  ' + status),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _NewAssignment {
  const _NewAssignment(this.course, this.title, this.content, this.dueDate);

  final Course course;
  final String title;
  final String content;
  final DateTime dueDate;
}

class _NewAssignmentDialog extends StatefulWidget {
  const _NewAssignmentDialog({required this.courses});

  final List<Course> courses;

  @override
  State<_NewAssignmentDialog> createState() => _NewAssignmentDialogState();
}

class _NewAssignmentDialogState extends State<_NewAssignmentDialog> {
  late Course _course = widget.courses.first;
  final TextEditingController _title = TextEditingController();
  final TextEditingController _content = TextEditingController();
  DateTime? _due;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(
      () => _due = DateTime(picked.year, picked.month, picked.day, 23, 59),
    );
  }

  void _submit() {
    final due = _due;
    if (_title.text.trim().isEmpty) {
      setState(() => _error = '과제 제목을 입력하세요.');
      return;
    }
    if (due == null) {
      setState(() => _error = '마감일을 선택하세요.');
      return;
    }
    Navigator.of(
      context,
    ).pop(_NewAssignment(_course, _title.text.trim(), _content.text, due));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('과제 출제'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InputDecorator(
              decoration: const InputDecoration(
                labelText: '과정',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Course>(
                  value: _course,
                  isDense: true,
                  isExpanded: true,
                  items: [
                    for (final c in widget.courses)
                      DropdownMenuItem<Course>(value: c, child: Text(c.name)),
                  ],
                  onChanged: (c) {
                    if (c != null) setState(() => _course = c);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: '과제 제목 *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _content,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '과제 내용',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(_due == null ? '마감일 선택 *' : '마감 ' + formatDate(_due)),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('출제')),
      ],
    );
  }
}
