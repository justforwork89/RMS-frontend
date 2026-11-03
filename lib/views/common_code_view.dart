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

  Future<void> _edit(CommonCode? code) async {
    final result = await showDialog<CommonCode>(
      context: context,
      builder: (_) =>
          _CodeFormDialog(code: code, defaultGroup: _viewModel.group),
    );
    if (result == null) return;
    final error = await _viewModel.save(result, isNew: code == null);
    if (!mounted) return;
    if (error == null) {
      CodeNamesScope.of(context).load(widget.dependencies.commonCodes, [
        CodeGroup.courseStatus,
        CodeGroup.enrollStatus,
      ]);
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
      ]);
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
          final codes = _viewModel.codes;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('전체'),
                      selected: _viewModel.group == null,
                      onSelected: (_) => _viewModel.setGroup(null),
                    ),
                    for (final g in _viewModel.groups)
                      ChoiceChip(
                        label: Text(g),
                        selected: _viewModel.group == g,
                        onSelected: (_) => _viewModel.setGroup(g),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (_viewModel.loading && codes.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final error = _viewModel.errorMessage;
                    if (error != null) return Center(child: Text(error));
                    if (codes.isEmpty) {
                      return const Center(child: Text('등록된 코드가 없습니다.'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemCount: codes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final c = codes[i];
                        return Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            title: Text(c.codeName),
                            subtitle: Text(
                              c.groupCd +
                                  ' / ' +
                                  c.code +
                                  '  |  정렬 ' +
                                  c.sortOrder.toString(),
                            ),
                            onTap: () => _edit(c),
                            trailing: IconButton(
                              tooltip: '삭제',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(c),
                            ),
                          ),
                        );
                      },
                    );
                  },
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
