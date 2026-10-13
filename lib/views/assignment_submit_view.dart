import 'package:flutter/material.dart';

import '../models/assignment.dart';
import '../models/course.dart';
import '../models/user.dart';
import '../repositories/assignment_repository.dart';
import '../viewmodels/assignment_submit_viewmodel.dart';
import 'dialogs.dart';

/// 과제 제출 (LMS-A002). 내용 입력 후 제출하고, 채점이 끝나면 점수/피드백을 보여준다.
/// 제출에 성공하면 true를 반환하며 닫힌다.
class AssignmentSubmitView extends StatefulWidget {
  const AssignmentSubmitView({
    super.key,
    required this.repository,
    required this.assignment,
    required this.courseName,
    required this.student,
    this.existing,
  });

  final AssignmentRepository repository;
  final Assignment assignment;
  final String courseName;
  final AppUser student;
  final Submission? existing;

  @override
  State<AssignmentSubmitView> createState() => _AssignmentSubmitViewState();
}

class _AssignmentSubmitViewState extends State<AssignmentSubmitView> {
  late final AssignmentSubmitViewModel _viewModel;
  late final TextEditingController _content;
  late final TextEditingController _fileName;

  @override
  void initState() {
    super.initState();
    _viewModel = AssignmentSubmitViewModel(
      widget.repository,
      widget.assignment,
      widget.student,
      widget.existing,
    );
    _content = TextEditingController(text: widget.existing?.content ?? '');
    _fileName = TextEditingController(text: widget.existing?.fileName ?? '');
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _content.dispose();
    _fileName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await _viewModel.submit(_content.text, _fileName.text);
    if (ok && mounted) {
      showToast(context, '과제가 제출되었습니다.');
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    final existing = widget.existing;
    return Scaffold(
      appBar: AppBar(title: const Text('과제 제출')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final readOnly = _viewModel.readOnly;
          final error = _viewModel.errorMessage;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(a.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(widget.courseName + '  |  마감 ' + formatDate(a.dueDate)),
              if (a.content.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(a.content),
              ],
              const SizedBox(height: 16),
              if (existing != null && existing.graded)
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '채점 결과: ' + existing.score.toString() + '점',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (existing.feedback.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('피드백: ' + existing.feedback),
                        ],
                      ],
                    ),
                  ),
                )
              else if (_viewModel.isOverdue)
                const Text('제출 마감일이 지났습니다.'),
              const SizedBox(height: 12),
              TextField(
                controller: _content,
                enabled: !readOnly,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: '제출 내용 *',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _fileName,
                enabled: !readOnly,
                decoration: const InputDecoration(
                  labelText: '첨부 파일명 (선택)',
                  helperText: '파일 업로드는 백엔드 연동 후 지원됩니다. 지금은 파일명만 기록합니다.',
                  border: OutlineInputBorder(),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: (readOnly || _viewModel.saving) ? null : _submit,
                child: Text(
                  _viewModel.saving
                      ? '제출 중...'
                      : (existing == null ? '제출' : '다시 제출'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
