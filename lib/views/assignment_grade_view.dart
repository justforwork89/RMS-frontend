import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../models/assignment.dart';
import '../models/course.dart';
import '../viewmodels/grading_viewmodel.dart';
import 'dialogs.dart';

/// 과제 채점 (LMS-A003). 제출물을 확인하고 점수/피드백을 입력한다.
class AssignmentGradeView extends StatefulWidget {
  const AssignmentGradeView({
    super.key,
    required this.dependencies,
    required this.assignment,
    required this.courseName,
  });

  final AppDependencies dependencies;
  final Assignment assignment;
  final String courseName;

  @override
  State<AssignmentGradeView> createState() => _AssignmentGradeViewState();
}

class _AssignmentGradeViewState extends State<AssignmentGradeView> {
  late final GradingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GradingViewModel(widget.dependencies, widget.assignment)
      ..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _save(GradingItem item, String score, String feedback) async {
    final error = await _viewModel.grade(item.submission, score, feedback);
    if (!mounted) return;
    showToast(context, error ?? '채점 결과가 저장되었습니다.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('과제 채점')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.loading && _viewModel.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final error = _viewModel.errorMessage;
          if (error != null) return Center(child: Text(error));
          final items = _viewModel.items;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.assignment.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                widget.courseName +
                    '  |  마감 ' +
                    formatDate(widget.assignment.dueDate),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: Text('아직 제출된 과제가 없습니다.')),
                ),
              for (final item in items) ...[
                _GradeCard(
                  key: ValueKey(item.submission.id),
                  item: item,
                  onSave: (score, feedback) => _save(item, score, feedback),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _GradeCard extends StatefulWidget {
  const _GradeCard({super.key, required this.item, required this.onSave});

  final GradingItem item;
  final void Function(String score, String feedback) onSave;

  @override
  State<_GradeCard> createState() => _GradeCardState();
}

class _GradeCardState extends State<_GradeCard> {
  late final TextEditingController _score;
  late final TextEditingController _feedback;

  @override
  void initState() {
    super.initState();
    final s = widget.item.submission;
    _score = TextEditingController(text: s.score?.toString() ?? '');
    _feedback = TextEditingController(text: s.feedback);
  }

  @override
  void dispose() {
    _score.dispose();
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.item.submission;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.studentName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(s.graded ? '채점완료' : '채점 대기'),
              ],
            ),
            const SizedBox(height: 4),
            Text('제출일 ' + formatDate(s.submittedAt)),
            const SizedBox(height: 8),
            Text(s.content),
            if (s.fileName != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.attach_file, size: 16),
                  const SizedBox(width: 4),
                  Expanded(child: Text(s.fileName!)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _score,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '점수',
                      suffixText: '점',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _feedback,
                    decoration: const InputDecoration(
                      labelText: '피드백',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => widget.onSave(_score.text, _feedback.text),
                child: const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
