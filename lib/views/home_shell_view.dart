import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../models/user.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'course_list_view.dart';
import 'enrollment_manage_view.dart';
import 'subject_info_view.dart';

enum _Menu {
  subjectInfo('과목/교수 정보', Icons.menu_book_outlined),
  enrollment('수강신청 관리', Icons.edit_calendar_outlined),
  courseManage('과정 관리', Icons.school_outlined);

  const _Menu(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// 역할별로 노출할 메뉴. 학생: 과목/교수 정보, 수강신청 관리. 강사/관리자: 과정 관리.
List<_Menu> _menusFor(UserRole role) {
  switch (role) {
    case UserRole.student:
      return const [_Menu.subjectInfo, _Menu.enrollment];
    case UserRole.instructor:
    case UserRole.admin:
      return const [_Menu.courseManage];
  }
}

/// 로그인 후 메인 레이아웃. 좌측 메뉴(Drawer)에 사용자 정보와 로그아웃을 제공한다.
class HomeShellView extends StatefulWidget {
  const HomeShellView({
    super.key,
    required this.dependencies,
    required this.authViewModel,
  });

  final AppDependencies dependencies;
  final AuthViewModel authViewModel;

  @override
  State<HomeShellView> createState() => _HomeShellViewState();
}

class _HomeShellViewState extends State<HomeShellView> {
  _Menu? _selected;

  AppUser get _user => widget.authViewModel.user!;

  @override
  Widget build(BuildContext context) {
    final menus = _menusFor(_user.role);
    final current = _selected ?? menus.first;
    final drawer = _AppDrawer(
      user: _user,
      menus: menus,
      selected: current,
      onSelect: (m) => setState(() => _selected = m),
      onLogout: widget.authViewModel.logout,
    );
    final actions = <Widget>[
      Center(
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Text(
            _user.name + ' (' + _user.role.label + ')',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    ];
    switch (current) {
      case _Menu.subjectInfo:
        return SubjectInfoView(
          key: ValueKey(current),
          repository: widget.dependencies.courses,
          drawer: drawer,
          actions: actions,
        );
      case _Menu.enrollment:
        return EnrollmentManageView(
          key: ValueKey(current),
          enrollments: widget.dependencies.enrollments,
          courses: widget.dependencies.courses,
          student: _user,
          drawer: drawer,
          actions: actions,
        );
      case _Menu.courseManage:
        return CourseListView(
          key: ValueKey(current),
          repository: widget.dependencies.courses,
          drawer: drawer,
          actions: actions,
        );
    }
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.user,
    required this.menus,
    required this.selected,
    required this.onSelect,
    required this.onLogout,
  });

  final AppUser user;
  final List<_Menu> menus;
  final _Menu selected;
  final ValueChanged<_Menu> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final major = user.major;
    final account = user.role.label + ' · ' + user.id;
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user.name),
            accountEmail: Text(major == null ? account : account + ' · ' + major),
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.person),
            ),
          ),
          for (final m in menus)
            ListTile(
              leading: Icon(m.icon),
              title: Text(m.label),
              selected: m == selected,
              onTap: () {
                Navigator.of(context).pop();
                onSelect(m);
              },
            ),
          const Spacer(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () {
              Navigator.of(context).pop();
              onLogout();
            },
          ),
        ],
      ),
    );
  }
}
