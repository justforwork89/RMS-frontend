import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../models/code_group.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../viewmodels/common_code_names_viewmodel.dart';
import '../viewmodels/enrollment_approval_viewmodel.dart';
import 'dialogs.dart';

/// 수강 승인 (LMS-M002, 관리자). 학생의 수강신청을 승인/반려한다.
class EnrollmentApprovalView extends StatefulWidget {
  const EnrollmentApprovalView({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<EnrollmentApprovalView> createState() => _EnrollmentApprovalViewState();
}

class _EnrollmentApprovalViewState extends State<EnrollmentApprovalView> {
  late final EnrollmentApprovalViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = EnrollmentApprovalViewModel(widget.dependencies)..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _decide(ApprovalItem item, EnrollStatus status) async {
    final statusLable = CodeNamesScope.of(
      context,
    ).name(CodeGroup.enrollStatus, status.code, status.label);
    final ok = await showConfirmDialog(
      context,
      title: '수강 ' + statusLable,
      message:
          item.studentName +
          ' 학생의 "' +
          item.courseName +
          '" 신청을 ' +
          statusLable +
          ' 처리할까요?',
      okLabel: statusLable,
    );
    if (!ok) return;
    final error = await _viewModel.decide(item, status);
    if (!mounted) return;
    showToast(context, error ?? '처리되었습니다.');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final items = _viewModel.items;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('전체'),
                    selected: _viewModel.filter == null,
                    onSelected: (_) => _viewModel.setFilter(null),
                  ),
                  for (final s in EnrollStatus.values)
                    ChoiceChip(
                      label: Text(
                        CodeNamesScope.of(
                          context,
                        ).name(CodeGroup.enrollStatus, s.code, s.label),
                      ),
                      selected: _viewModel.filter == s,
                      onSelected: (_) => _viewModel.setFilter(s),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_viewModel.loading && items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final error = _viewModel.errorMessage;
                  if (error != null) return Center(child: Text(error));
                  if (items.isEmpty) {
                    return const Center(child: Text('해당하는 수강신청이 없습니다.'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _tile(items[i]),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tile(ApprovalItem item) {
    final e = item.enrollment;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.studentName + '  →  ' + item.courseName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '신청일 ' +
                        formatDate(e.appliedAt) +
                        '  |  상태 ' +
                        CodeNamesScope.of(context).name(
                          CodeGroup.enrollStatus,
                          e.status.code,
                          e.status.label,
                        ),
                  ),
                ],
              ),
            ),
            if (e.status == EnrollStatus.applied) ...[
              OutlinedButton(
                onPressed: () => _decide(item, EnrollStatus.rejected),
                child: const Text('반려'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _decide(item, EnrollStatus.approved),
                child: const Text('승인'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
