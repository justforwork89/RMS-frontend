import 'package:flutter/material.dart';

import 'app_dependencies.dart';
//mport 'mock/mock_bootstrap.dart';
import 'api/api_bootstrap.dart';
import 'models/code_group.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/common_code_names_viewmodel.dart';
import 'views/home_shell_view.dart';
import 'views/login_view.dart';

void main() {
  // [MOCK] 백엔드 연동 시 이 한 줄을 실제 구현 주입으로 교체하고 lib/mock 폴더를 삭제한다.
  //runApp(LmsApp(dependencies: createMockDependencies()));
  runApp(LmsApp(dependencies: createApiDependencies()));
}

class LmsApp extends StatefulWidget {
  const LmsApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<LmsApp> createState() => _LmsAppState();
}

class _LmsAppState extends State<LmsApp> {
  late final AuthViewModel _auth = AuthViewModel(widget.dependencies.auth);
  final CodeNames _names = CodeNames();

  @override
  void dispose() {
    _auth.dispose();
    _names.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _auth.addListener(() {
      if (_auth.user != null) {
        _names.load(widget.dependencies.commonCodes, [
          CodeGroup.courseStatus,
          CodeGroup.enrollStatus,
          CodeGroup.role,
        ]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CodeNamesScope(
      names: _names,
      child: MaterialApp(
        title: 'LMS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF2F5BEA),
          useMaterial3: true,
        ),
        // 로그인 여부에 따라 로그인 화면 / 메인 화면으로 전환된다.
        home: ListenableBuilder(
          listenable: _auth,
          builder: (context, _) {
            final user = _auth.user;
            if (user == null) return LoginView(viewModel: _auth);
            return HomeShellView(
              key: ValueKey(user.id),
              dependencies: widget.dependencies,
              authViewModel: _auth,
            );
          },
        ),
      ),
    );
  }
}
