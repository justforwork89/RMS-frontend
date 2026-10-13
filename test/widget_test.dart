import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/repositories/course_repository.dart';

void main() {
  testWidgets('과정 목록 화면이 샘플 과정을 보여준다', (tester) async {
    await tester.pumpWidget(LmsApp(repository: InMemoryCourseRepository()));
    await tester.pumpAndSettle();

    expect(find.text('과정 관리'), findsOneWidget);
    expect(find.text('Flutter 모바일 앱 개발'), findsOneWidget);
  });
}
