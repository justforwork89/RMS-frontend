import 'package:flutter/material.dart';
import '../models/code_group.dart';

import '../app_dependencies.dart';
import '../models/common_code.dart';
import '../viewmodels/common_code_names_viewmodel.dart';
import '../viewmodels/common_code_viewmodel.dart';
import 'dialogs.dart';

/// 공통코드 관리 (LMS-M003, 관리자). 코드 그룹별 조회/등록/수정/삭제.
class CommonCodeView extends StatefulWidget {
  const CommonCodeView({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<CommonCodeView> createState() => _CommonCodeViewState();
}

class _CommonCodeViewState extends State<CommonCodeView> {
  late final CommonCodeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CommonCodeViewModel(widget.dependencies)..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  /// code가 null이면 새 코드 등록. group을 주면 그 그룹이 미리 채워진다.
  Future<void> _edit(CommonCode? code, {String? group}) async {
    final result = await showDialog<CommonCode>(
      context: context,
      builder: (_) => _CodeFormDialog(code: code, defaultGroup: group),
    );
    if (result == null) return;
    final error = await _viewModel.save(result, isNew: code == null);
    if (!mounted) return;
    if (error == null) {
      CodeNamesScope.of(context).load(widget.dependencies.commonCodes, [
        CodeGroup.courseStatus,
        CodeGroup.enrollStatus,
        CodeGroup.role,
        CodeGroup.major,
      ]);
      widget.dependencies.courses.loadMajors();
    }
    showToast(context, error ?? '저장되었습니다.');
  }

  Future<void> _delete(CommonCode code) async {
    final ok = await showConfirmDialog(
      context,
      title: '코드 삭제',
      message:
          code.groupCd +
          ' / ' +
          code.code +
          ' (' +
          code.codeName +
          ') 을(를) 삭제할까요?',
      okLabel: '삭제',
    );
    if (!ok) return;
    final error = await _viewModel.delete(code);
    if (!mounted) return;
    if (error == null) {
      CodeNamesScope.of(context).load(widget.dependencies.commonCodes, [
        CodeGroup.courseStatus,
        CodeGroup.enrollStatus,
        CodeGroup.role,
        CodeGroup.major,
      ]);
      widget.dependencies.courses.loadMajors();
    }
    showToast(context, error ?? '삭제되었습니다.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null),
        icon: const Icon(Icons.add),
        label: const Text('코드 등록'),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final tree = _viewModel.tree;
          if (_viewModel.loading && tree.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final error = _viewModel.errorMessage;
          if (error != null) return Center(child: Text(error));
          if (tree.isEmpty) {
            return const Center(child: Text('등록된 코드가 없습니다.'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            children: [
              // 상위: 코드 그룹 (눌러서 펼치기/접기)
              for (final entry in tree.entries)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    key: PageStorageKey(entry.key), // 새로고침해도 펼침 상태 유지
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(CodeGroup.label(entry.key)),
                    subtitle: Text('${entry.key}  ·  ${entry.value.length}개'),
                    childrenPadding: const EdgeInsets.fromLTRB(24, 0, 8, 8),
                    children: [
                      // 하위: 그 그룹의 코드들
                      for (final c in entry.value)
                        ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.subdirectory_arrow_right,
                            size: 18,
                          ),
                          title: Text(c.codeName),
                          subtitle: Text('코드 ${c.code}  |  정렬 ${c.sortOrder}'),
                          onTap: () => _edit(c),
                          trailing: IconButton(
                            tooltip: '삭제',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(c),
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _edit(null, group: entry.key),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('이 그룹에 코드 추가'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CodeFormDialog extends StatefulWidget {
  const _CodeFormDialog({required this.code, required this.defaultGroup});

  final CommonCode? code;
  final String? defaultGroup;

  @override
  State<_CodeFormDialog> createState() => _CodeFormDialogState();
}

class _CodeFormDialogState extends State<_CodeFormDialog> {
  late final TextEditingController _group;
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _order;

  bool get _isNew => widget.code == null;

  @override
  void initState() {
    super.initState();
    final c = widget.code;
    _group = TextEditingController(
      text: c?.groupCd ?? widget.defaultGroup ?? '',
    );
    _code = TextEditingController(text: c?.code ?? '');
    _name = TextEditingController(text: c?.codeName ?? '');
    _order = TextEditingController(text: (c?.sortOrder ?? 0).toString());
  }

  @override
  void dispose() {
    _group.dispose();
    _code.dispose();
    _name.dispose();
    _order.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      CommonCode(
        groupCd: _group.text.trim(),
        code: _code.text.trim(),
        codeName: _name.text.trim(),
        sortOrder: int.tryParse(_order.text.trim()) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isNew ? '코드 등록' : '코드 수정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _group,
              enabled: _isNew,
              decoration: const InputDecoration(labelText: '그룹 코드'),
            ),
            TextField(
              controller: _code,
              enabled: _isNew,
              decoration: const InputDecoration(labelText: '코드 값'),
            ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '코드명'),
            ),
            TextField(
              controller: _order,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '정렬 순서'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('저장')),
      ],
    );
  }
}
