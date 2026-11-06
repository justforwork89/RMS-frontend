import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../models/course_file.dart';
import '../models/user.dart';
import '../viewmodels/course_file_viewmodel.dart';
import 'dialogs.dart';

/// 과정 상세 화면 안에 들어가는 "참고자료" 영역.
class CourseFileSection extends StatefulWidget {
  const CourseFileSection({
    super.key,
    required this.dependencies,
    required this.courseId,
    required this.user,
    this.instructorId,
  });

  final AppDependencies dependencies;
  final int courseId;
  final AppUser user;
  final String? instructorId;

  @override
  State<CourseFileSection> createState() => _CourseFileSectionState();
}

class _CourseFileSectionState extends State<CourseFileSection> {
  late final CourseFileViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = CourseFileViewModel(
      widget.dependencies.courseFiles,
      widget.courseId,
      widget.user,
      widget.instructorId,
    )..load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _show(Future<String?> action) async {
    final message = await action;
    if (!mounted || message == null) return;
    showToast(context, message);
  }

  Future<void> _delete(CourseFile f) async {
    final ok = await showConfirmDialog(
      context,
      title: '파일 삭제',
      message: '"${f.name}"을(를) 삭제하시겠습니까?',
      okLabel: '삭제',
    );
    if (ok) await _show(_vm.delete(f));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '참고자료 ${_vm.files.length}개',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                Text(
                  formatBytes(_vm.totalBytes),
                  style: const TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                if (_vm.canManage)
                  FilledButton.icon(
                    onPressed: _vm.busy
                        ? null
                        : () => _show(_vm.pickAndUpload()),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('파일 첨부'),
                  ),
              ],
            ),
            if (_vm.canManage)
              const Text(
                '한 번에 최대 20개, 500MB까지',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            if (_vm.busy) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _vm.progress),
              Text('업로드 중 ${((_vm.progress ?? 0) * 100).round()}%'),
            ],
            const SizedBox(height: 8),
            if (_vm.loading)
              const Center(child: CircularProgressIndicator())
            else if (_vm.errorMessage != null)
              Text(
                _vm.errorMessage!,
                style: const TextStyle(color: Colors.grey),
              )
            else if (_vm.files.isEmpty)
              const Text('등록된 참고자료가 없습니다.')
            else
              for (final f in _vm.files)
                ListTile(
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
                        onPressed: _vm.busy
                            ? null
                            : () => _show(_vm.download(f)),
                      ),
                      if (_vm.canManage)
                        IconButton(
                          tooltip: '삭제',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: _vm.busy ? null : () => _delete(f),
                        ),
                    ],
                  ),
                ),
          ],
        );
      },
    );
  }
}
