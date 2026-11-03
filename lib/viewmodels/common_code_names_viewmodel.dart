import 'package:flutter/material.dart';
import '../repositories/common_code_repository.dart';

class CodeNames extends ChangeNotifier {
  final Map<String, Map<String, String>> _names = {}; // group -> code -> name

  Future<void> load(CommonCodeRepository repo, List<String> groups) async {
    for (final g in groups) {
      try {
        final list = await repo.fetchByGroup(g);
        _names[g] = {for (final c in list) c.code: c.codeName};
      } catch (_) {}
    }
    notifyListeners();
  }

  String name(String group, String code, String fallback) =>
      _names[group]?[code] ?? fallback;
}

class CodeNamesScope extends InheritedNotifier<CodeNames> {
  const CodeNamesScope({
    super.key,
    required CodeNames names,
    required super.child,
  }) : super(notifier: names);

  static CodeNames of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CodeNamesScope>()!
        .notifier!;
  }
}
