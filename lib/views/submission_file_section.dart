import 'package:flutter/material.dart';
import '../models/course_file.dart';
import '../models/submission_file.dart';
import '../viewmodels/submission_file_viewmodel.dart';
import 'dialogs.dart';

/// 과제 제출 첨부파일 영역 (학생 제출 화면 · 강사 채점 화면 공용).
/// editable이 false면 내려받기만 보인다.
class SubmissionFileSection extends StatelessWidget {
  const SubmissionFileSection({super.key, required this.viewModel});
  final SubmissionFileViewModel viewModel;
  Future<void> _show(BuildContext context, Future<String?> action) async {
    final message = await action;
    if (!context.mounted || message == null) return;
    showToast(context, message);
  }

  Future<void> _delete(BuildContext context, SubmissionFile f) async {
    final ok = await showConfirmDialog(
      context,
      title: '파일 삭제',
      message: '"${f.name}"을(를) 삭제하시겠습니까?',
      okLabel: '삭제',
    );
    if (ok && context.mounted) await _show(context, viewModel.delete(f));
  }

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '첨부 파일 ${vm.totalCount}개',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(width: 8),
                Text(
                  formatBytes(vm.totalBytes),
                  style: const TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                if (vm.editable)
                  OutlinedButton.icon(
                    onPressed: vm.busy ? null : () => _show(context, vm.pick()),
                    icon: const Icon(Icons.attach_file),
                    label: const Text('파일 선택'),
                  ),
              ],
            ),
            if (vm.editable)
              const Text(
                '최대 $maxSubmissionFiles개, 합쳐서 50MB까지 · 제출 버튼을 누르면 함께 올라가요',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            if (vm.busy) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: vm.progress),
              Text('업로드 중 ${((vm.progress ?? 0) * 100).round()}%'),
            ],
            const SizedBox(height: 4),
            if (vm.loading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (vm.errorMessage != null)
              Text(vm.errorMessage!, style: const TextStyle(color: Colors.grey))
            else if (vm.totalCount == 0)
              const Text('첨부 파일이 없습니다.', style: TextStyle(color: Colors.grey)),
            // 이미 올라간 파일
            for (final f in vm.files)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text(f.name, overflow: TextOverflow.ellipsis),
                subtitle: Text(formatBytes(f.size)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '다운로드',
                      icon: const Icon(Icons.download),
                      onPressed: vm.busy
                          ? null
                          : () => _show(context, vm.download(f)),
                    ),
                    if (vm.editable)
                      IconButton(
                        tooltip: '삭제',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: vm.busy ? null : () => _delete(context, f),
                      ),
                  ],
                ),
              ),
            // 제출을 누르면 올라갈 파일
            for (final p in vm.pending)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.upload_file, color: Colors.blue),
                title: Text(p.name, overflow: TextOverflow.ellipsis),
                subtitle: Text('${formatBytes(p.size)} · 제출하면 올라가요'),
                trailing: IconButton(
                  tooltip: '빼기',
                  icon: const Icon(Icons.close),
                  onPressed: vm.busy ? null : () => vm.removePending(p),
                ),
              ),
          ],
        );
      },
    );
  }
}
