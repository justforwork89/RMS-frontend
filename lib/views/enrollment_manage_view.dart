import 'package:flutter/material.dart';

import '../models/code_group.dart';
import '../models/course.dart';
import '../models/user.dart';
import '../repositories/course_repository.dart';
import '../repositories/enrollment_repository.dart';
import '../viewmodels/common_code_names_viewmodel.dart';
import '../viewmodels/enrollment_viewmodel.dart';
import 'course_status_chip.dart';

/// 수강신청 관리 화면 (학생). 탭 1: 수강신청(과정 선택 후 신청), 탭 2: 신청 내역(변경/취소).
class EnrollmentManageView extends StatefulWidget {
  const EnrollmentManageView({
    super.key,
    required this.enrollments,
    required this.courses,
    required this.student,
    this.drawer,
    this.actions,
  });

  final EnrollmentRepository enrollments;
  final CourseRepository courses;
  final AppUser student;
  final Widget? drawer;
  final List<Widget>? actions;

  @override
  State<EnrollmentManageView> createState() => _EnrollmentManageViewState();
}

class _EnrollmentManageViewState extends State<EnrollmentManageView> {
  late final EnrollmentViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = EnrollmentViewModel(
      widget.enrollments,
      widget.courses,
      widget.student,
    )..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm(String title, String message, String okLabel) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('닫기'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(okLabel),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _enroll(Course course) async {
    final ok = await _confirm(
      '수강신청',
      '"' + course.name + '" 과정을 신청하시겠습니까?',
      '신청',
    );
    if (!ok) return;
    final error = await _viewModel.enroll(course);
    if (!mounted) return;
    _toast(error ?? '수강신청이 완료되었습니다.');
  }

  Future<void> _change(EnrollmentItem item) async {
    final candidates = _viewModel.changeCandidates;
    if (candidates.isEmpty) {
      _toast('변경 가능한 과정이 없습니다.');
      return;
    }
    final target = await showDialog<Course>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('변경할 과정 선택'),
        children: [
          for (final c in candidates)
            ListTile(
              enabled: !c.isFull,
              title: Text(c.name),
              subtitle: Text(
                CodeNamesScope.of(
                      context,
                    ).name(CodeGroup.major, c.major, c.major) +
                    ' | ' +
                    c.instructor +
                    ' | ' +
                    c.enrolled.toString() +
                    '/' +
                    c.capacity.toString() +
                    '명' +
                    (c.isFull ? ' (마감)' : ''),
              ),
              onTap: c.isFull ? null : () => Navigator.of(ctx).pop(c),
            ),
        ],
      ),
    );
    if (target == null) return;
    final error = await _viewModel.change(item, target);
    if (!mounted) return;
    _toast(error ?? '수강신청이 변경되었습니다.');
  }

  Future<void> _cancel(EnrollmentItem item) async {
    final ok = await _confirm(
      '수강신청 취소',
      '"' + item.course.name + '" 신청을 취소하시겠습니까?',
      '취소하기',
    );
    if (!ok) return;
    final error = await _viewModel.cancel(item);
    if (!mounted) return;
    _toast(error ?? '수강신청이 취소되었습니다.');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('수강신청 관리'),
              actions: widget.actions,
              bottom: TabBar(
                tabs: [
                  const Tab(text: '수강신청'),
                  Tab(
                    text: '신청 내역 (' + _viewModel.items.length.toString() + ')',
                  ),
                ],
              ),
            ),
            drawer: widget.drawer,
            body: _viewModel.errorMessage != null
                ? Center(child: Text(_viewModel.errorMessage!))
                : TabBarView(children: [_buildApplyTab(), _buildHistoryTab()]),
          ),
        );
      },
    );
  }

  Widget _buildApplyTab() {
    if (_viewModel.loading && _viewModel.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final courses = _viewModel.availableCourses;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 160,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '전공',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _viewModel.major,
                    isDense: true,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('전체'),
                      ),
                      for (final m in _viewModel.majors)
                        DropdownMenuItem<String?>(
                          value: m,
                          child: Text(
                            CodeNamesScope.of(
                              context,
                            ).name(CodeGroup.major, m, m),
                          ),
                        ),
                    ],
                    onChanged: _viewModel.setMajor,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: courses.isEmpty
              ? const Center(child: Text('신청 가능한 과정이 없습니다.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _applyCard(courses[i]),
                ),
        ),
      ],
    );
  }

  Widget _applyCard(Course course) {
    final enrolled = _viewModel.isEnrolled(course);
    Widget button;
    if (enrolled) {
      button = const OutlinedButton(onPressed: null, child: Text('신청완료'));
    } else if (course.isFull) {
      button = const OutlinedButton(onPressed: null, child: Text('정원마감'));
    } else {
      button = FilledButton(
        onPressed: () => _enroll(course),
        child: const Text('신청'),
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _CourseSummary(course: course)),
            const SizedBox(width: 8),
            button,
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_viewModel.loading && _viewModel.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = _viewModel.items;
    if (items.isEmpty) {
      return const Center(
        child: Text(
          '신청 내역이 없습니다.\n"수강신청" 탭에서 과정을 신청하세요.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _historyCard(items[i]),
    );
  }

  Widget _historyCard(EnrollmentItem item) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CourseSummary(course: item.course),
            const SizedBox(height: 4),
            Text(
              '신청일 ' +
                  formatDate(item.enrollment.appliedAt) +
                  '  |  상태 ' +
                  CodeNamesScope.of(context).name(
                    CodeGroup.enrollStatus,
                    item.enrollment.status.code,
                    item.enrollment.status.label,
                  ),
            ),
            const SizedBox(height: 8),
            if (item.editable)
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => _change(item),
                    child: const Text('변경'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _cancel(item),
                    child: const Text('취소'),
                  ),
                ],
              )
            else
              Text(
                '모집이 끝나 변경/취소할 수 없습니다.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _CourseSummary extends StatelessWidget {
  const _CourseSummary({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final period =
        formatDate(course.startDate) + ' ~ ' + formatDate(course.endDate);
    final recruit = formatDate(course.recruitStartDate) +
        ' ~ ' +
        formatDate(course.recruitEndDate);
    final headcount =
        course.enrolled.toString() + ' / ' + course.capacity.toString() + '명';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                course.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 8),
            CourseStatusChip(status: course.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          CodeNamesScope.of(
                context,
              ).name(CodeGroup.major, course.major, course.major) +
              '  |  교수 ' +
              course.instructor,
        ),
        const SizedBox(height: 2),
        Text('모집 ' + recruit + '  |  교육 ' + period),
        const SizedBox(height: 2),
        Text('정원/신청 ' + headcount),
      ],
    );
  }
}
