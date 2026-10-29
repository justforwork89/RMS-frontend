import 'package:flutter/foundation.dart';

import '../app_dependencies.dart';
import '../models/assignment.dart';
import 'viewmodel_support.dart';

/// 제출물 한 건 + 제출한 학생 이름.
class GradingItem {
  const GradingItem(this.submission, this.studentName);

  final Submission submission;
  final String studentName;
}

/// 과제 채점(LMS-A003)의 ViewModel. 제출물 목록 조회와 점수/피드백 저장.
class GradingViewModel extends ChangeNotifier with ActionRunner {
  GradingViewModel(this._deps, this.assignment);

  final AppDependencies _deps;
  final Assignment assignment;

  List<GradingItem> _items = const [];
  bool _loading = false;
  String? _errorMessage;

  List<GradingItem> get items => _items;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  @override
  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final subs = await _deps.assignments.fetchSubmissions(
        assignmentId: assignment.id,
      );
      // final users = await _deps.users.fetchUsers();
      // final names = <String, String>{for (final u in users) u.id: u.name};
      _items = [for (final s in subs) GradingItem(s, s.studentName)];
      ;
    } catch (_) {
      _errorMessage = '제출물을 불러오지 못했습니다.';
    }
    _loading = false;
    notifyListeners();
  }

  /// 성공 시 null, 실패 시 사용자에게 보여줄 메시지를 반환한다.
  Future<String?> grade(
    Submission submission,
    String scoreText,
    String feedback,
  ) async {
    final score = int.tryParse(scoreText.trim());
    if (score == null || score < 0 || score > 100) {
      return '점수는 0~100 사이의 정수여야 합니다.';
    }
    return runAction(() async {
      await _deps.assignments.grade(
        submissionId: submission.id,
        score: score,
        feedback: feedback,
      );
    });
  }
}
