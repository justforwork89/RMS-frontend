import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../models/user.dart';
import '../viewmodels/dashboard_viewmodel.dart';

/// 홈 대시보드 (LMS-H001). 로그인한 역할에 맞는 요약 카드를 보여준다.
class HomeDashboardView extends StatefulWidget {
  const HomeDashboardView({
    super.key,
    required this.dependencies,
    required this.user,
    this.drawer,
    this.actions,
  });

  final AppDependencies dependencies;
  final AppUser user;
  final Widget? drawer;
  final List<Widget>? actions;

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  late final DashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardViewModel(widget.dependencies, widget.user)..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('홈'), actions: widget.actions),
      drawer: widget.drawer,
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.loading && _viewModel.sections.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final error = _viewModel.errorMessage;
          if (error != null) return Center(child: Text(error));
          return RefreshIndicator(
            onRefresh: _viewModel.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.user.name + '님, 환영합니다.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(widget.user.role.label + ' 계정으로 로그인했습니다.'),
                const SizedBox(height: 16),
                for (final s in _viewModel.sections) ...[
                  _SectionCard(section: s),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final DashboardSection section;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final line in section.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(line),
              ),
          ],
        ),
      ),
    );
  }
}
