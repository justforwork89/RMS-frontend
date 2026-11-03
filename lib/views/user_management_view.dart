import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../models/code_group.dart';
import '../models/user.dart';
import '../viewmodels/common_code_names_viewmodel.dart';
import '../viewmodels/user_management_viewmodel.dart';
import 'dialogs.dart';

/// 사용자 관리 (LMS-M001, 관리자). 사용자 조회/등록/수정.
class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  late final UserManagementViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = UserManagementViewModel(widget.dependencies)..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _edit(AppUser? user) async {
    final result = await showDialog<_UserFormResult>(
      context: context,
      builder: (_) => _UserFormDialog(user: user, majors: _viewModel.majors),
    );
    if (result == null) return;
    final error = await _viewModel.save(
      result.user,
      password: result.password,
      isNew: user == null,
    );
    if (!mounted) return;
    showToast(context, error ?? '저장되었습니다.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null),
        icon: const Icon(Icons.person_add),
        label: const Text('사용자 등록'),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final users = _viewModel.users;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('전체'),
                      selected: _viewModel.roleFilter == null,
                      onSelected: (_) => _viewModel.setRoleFilter(null),
                    ),
                    for (final r in UserRole.values)
                      ChoiceChip(
                        label: Text(
                          CodeNamesScope.of(
                            context,
                          ).name(CodeGroup.role, r.code, r.label),
                        ),
                        selected: _viewModel.roleFilter == r,
                        onSelected: (_) => _viewModel.setRoleFilter(r),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (_viewModel.loading && users.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final error = _viewModel.errorMessage;
                    if (error != null) return Center(child: Text(error));
                    if (users.isEmpty) {
                      return const Center(child: Text('사용자가 없습니다.'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final u = users[i];
                        return Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            title: Text(u.name + ' (' + u.id + ')'),
                            subtitle: Text(
                              CodeNamesScope.of(context).name(
                                    CodeGroup.role,
                                    u.role.code,
                                    u.role.label,
                                  ) +
                                  (u.major != null
                                      ? '  |  ' +
                                            CodeNamesScope.of(context).name(
                                              CodeGroup.major,
                                              u.major!,
                                              u.major!,
                                            )
                                      : '') +
                                  (u.active ? '' : '  |  사용 안 함'),
                            ),
                            trailing: const Icon(Icons.edit),
                            onTap: () => _edit(u),
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

class _UserFormResult {
  const _UserFormResult(this.user, this.password);

  final AppUser user;
  final String? password;
}

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({required this.user, required this.majors});

  final AppUser? user;
  final List<String> majors;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  late final TextEditingController _id;
  late final TextEditingController _name;
  final TextEditingController _password = TextEditingController();
  late UserRole _role;
  String? _major;
  late bool _active;

  bool get _isNew => widget.user == null;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _id = TextEditingController(text: u?.id ?? '');
    _name = TextEditingController(text: u?.name ?? '');
    _role = u?.role ?? UserRole.student;
    _major =
        u?.major ?? (widget.majors.isNotEmpty ? widget.majors.first : null);
    _active = u?.active ?? true;
  }

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final user = AppUser(
      id: _id.text.trim(),
      name: _name.text.trim(),
      role: _role,
      major: _role == UserRole.student ? _major : null,
      active: _active,
    );
    Navigator.of(context).pop(_UserFormResult(user, _password.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isNew ? '사용자 등록' : '사용자 수정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _id,
              enabled: _isNew,
              decoration: const InputDecoration(labelText: '아이디'),
            ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '이름'),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: _isNew ? '비밀번호' : '비밀번호 (변경할 때만 입력)',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<UserRole>(
              value: _role,
              decoration: const InputDecoration(labelText: '역할'),
              items: [
                for (final r in UserRole.values)
                  DropdownMenuItem(
                    value: r,
                    child: Text(
                      CodeNamesScope.of(
                        context,
                      ).name(CodeGroup.role, r.code, r.label),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
            if (_role == UserRole.student && widget.majors.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _major,
                decoration: const InputDecoration(labelText: '전공'),
                items: [
                  // 저장된 전공이 목록에 없어도(삭제된 코드 등) 드롭다운이 깨지지 않게 포함한다.
                  for (final m in [
                    ...widget.majors,
                    if (_major != null && !widget.majors.contains(_major))
                      _major!,
                  ])
                    DropdownMenuItem(
                      value: m,
                      child: Text(
                        CodeNamesScope.of(
                          context,
                        ).name(CodeGroup.major, m, m),
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _major = v),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('사용 여부'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
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
