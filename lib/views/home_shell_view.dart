import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../models/code_group.dart';
import '../models/course.dart';
import '../models/user.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/common_code_names_viewmodel.dart';
import 'assignment_list_view.dart';
import 'common_code_view.dart';
import 'course_detail_view.dart';
import 'course_list_view.dart';
import 'enrollment_approval_view.dart';
import 'enrollment_manage_view.dart';
import 'home_dashboard_view.dart';
import 'subject_info_view.dart';
import 'user_management_view.dart';

enum _Menu {
  home('홈', Icons.home_outlined),
  subjectInfo('과목/교수 정보', Icons.menu_book_outlined),
  enrollment('수강신청 관리', Icons.edit_calendar_outlined),
  courseManage('과정 관리', Icons.school_outlined),
  assignment('과제', Icons.assignment_outlined),
  approval('수강 승인', Icons.how_to_reg_outlined),
  userManage('사용자 관리', Icons.people_outline),
  commonCode('공통코드 관리', Icons.tune);

  const _Menu(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// 역할별로 노출할 메뉴. 첫 번째 메뉴(홈)가 로그인 직후 화면이다.
List<_Menu> _menusFor(UserRole role) {
  switch (role) {
    case UserRole.student:
      return const [
        _Menu.home,
        _Menu.subjectInfo,
        _Menu.enrollment,
        _Menu.assignment,
      ];
    case UserRole.instructor:
      return const [
        _Menu.home,
        _Menu.subjectInfo,
        _Menu.courseManage,
        _Menu.assignment,
      ];
    case UserRole.admin:
      return const [
        _Menu.home,
        _Menu.subjectInfo,
        _Menu.courseManage,
        _Menu.approval,
        _Menu.userManage,
        _Menu.commonCode,
      ];
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

  void _openCourse(Course course) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CourseDetailView(
          dependencies: widget.dependencies,
          course: course,
          user: _user,
        ),
      ),
    );
  }

  /// 자체 Scaffold가 없는 화면을 앱바/메뉴와 함께 감싼다.
  Widget _page(String title, Widget body, Widget drawer, List<Widget> actions) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: drawer,
      body: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    final menus = _menusFor(_user.role);
    final current = (_selected != null && menus.contains(_selected))
        ? _selected!
        : menus.first;
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
            _user.name +
                ' (' +
                CodeNamesScope.of(
                  context,
                ).name(CodeGroup.role, _user.role.code, _user.role.label) +
                ')',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    ];
    final deps = widget.dependencies;
    final key = ValueKey(current);
    switch (current) {
      case _Menu.home:
        return HomeDashboardView(
          key: key,
          dependencies: deps,
          user: _user,
          drawer: drawer,
          actions: actions,
        );
      case _Menu.subjectInfo:
        return SubjectInfoView(
          key: key,
          repository: deps.courses,
          drawer: drawer,
          actions: actions,
          onTapCourse: _openCourse,
        );
      case _Menu.enrollment:
        return EnrollmentManageView(
          key: key,
          enrollments: deps.enrollments,
          courses: deps.courses,
          student: _user,
          drawer: drawer,
          actions: actions,
        );
      case _Menu.courseManage:
        return CourseListView(
          key: key,
          repository: deps.courses,
          user: _user,
          drawer: drawer,
          actions: actions,
        );
      case _Menu.assignment:
        return AssignmentListView(
          key: key,
          dependencies: deps,
          user: _user,
          drawer: drawer,
          actions: actions,
        );
      case _Menu.approval:
        return _page(
          current.label,
          EnrollmentApprovalView(key: key, dependencies: deps),
          drawer,
          actions,
        );
      case _Menu.userManage:
        return _page(
          current.label,
          UserManagementView(key: key, dependencies: deps),
          drawer,
          actions,
        );
      case _Menu.commonCode:
        return _page(
          current.label,
          CommonCodeView(key: key, dependencies: deps),
          drawer,
          actions,
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
    final major = user.major == null
        ? null
        : CodeNamesScope.of(
            context,
          ).name(CodeGroup.major, user.major!, user.major!);
    final account =
        CodeNamesScope.of(
          context,
        ).name(CodeGroup.role, user.role.code, user.role.label) +
        ' · ' +
        user.id;
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user.name),
            accountEmail: Text(
              major == null ? account : account + ' · ' + major,
            ),
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
