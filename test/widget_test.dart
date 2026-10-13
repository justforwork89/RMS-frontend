import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/mock/mock_bootstrap.dart';

Future<void> _login(WidgetTester tester, String id, String password) async {
  await tester.enterText(find.byType(TextField).at(0), id);
  await tester.enterText(find.byType(TextField).at(1), password);
  await tester.tap(find.widgetWithText(FilledButton, '로그인'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('학생 로그인 후 홈과 과목/교수 정보 메뉴가 동작한다', (tester) async {
    await tester.pumpWidget(LmsApp(dependencies: createMockDependencies()));

    await _login(tester, 'student1', '1234');

    expect(find.text('홈'), findsWidgets);

    final scaffold = tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffold.openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, '과목/교수 정보'));
    await tester.pumpAndSettle();

    expect(find.text('Spring Boot 백엔드 개발'), findsOneWidget);
  });

  testWidgets('잘못된 비밀번호면 로그인 화면에 머문다', (tester) async {
    await tester.pumpWidget(LmsApp(dependencies: createMockDependencies()));

    await _login(tester, 'student1', 'wrong');

    expect(find.text('아이디 또는 비밀번호가 올바르지 않습니다.'), findsOneWidget);
  });
}
