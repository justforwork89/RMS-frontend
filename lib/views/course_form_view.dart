import 'package:flutter/material.dart';

import '../models/code_group.dart';
import '../models/course.dart';
import '../repositories/course_repository.dart';
import '../viewmodels/common_code_names_viewmodel.dart';
import '../viewmodels/course_form_viewmodel.dart';

/// 과정 등록/수정 화면. course가 null이면 등록, 아니면 수정.
/// 저장에 성공하면 true를 반환하며 닫힌다.
class CourseFormView extends StatefulWidget {
  const CourseFormView({super.key, required this.repository, this.course});

  final CourseRepository repository;
  final Course? course;

  @override
  State<CourseFormView> createState() => _CourseFormViewState();
}

class _CourseFormViewState extends State<CourseFormView> {
  late final CourseFormViewModel _viewModel;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _capacityController;

  @override
  void initState() {
    super.initState();
    _viewModel = CourseFormViewModel(widget.repository, course: widget.course);
    _nameController = TextEditingController(text: _viewModel.name);
    _descriptionController = TextEditingController(
      text: _viewModel.description,
    );
    _capacityController = TextEditingController(text: _viewModel.capacityText);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial =
        (isStart ? _viewModel.startDate : _viewModel.endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    if (isStart) {
      _viewModel.setStartDate(picked);
    } else {
      _viewModel.setEndDate(picked);
    }
  }

  Future<void> _submit() async {
    _viewModel.name = _nameController.text;
    _viewModel.description = _descriptionController.text;
    _viewModel.capacityText = _capacityController.text;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await _viewModel.save();
    if (ok && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final readOnly = _viewModel.isReadOnly;
        return Scaffold(
          appBar: AppBar(title: Text(_viewModel.isEdit ? '과정 수정' : '과정 등록')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (readOnly)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('종료된 과정은 수정할 수 없습니다.'),
                  ),
                TextFormField(
                  controller: _nameController,
                  enabled: !readOnly,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: '과정명 *',
                    border: OutlineInputBorder(),
                  ),
                  validator: _viewModel.validateName,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !readOnly,
                  maxLength: 2000,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '과정 설명',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: _viewModel.validateDescription,
                ),
                const SizedBox(height: 12),
                _dropdown<String>(
                  label: '전공',
                  value: _viewModel.major,
                  items: _viewModel.majors,
                  text: (v) => v,
                  onChanged: readOnly ? null : _viewModel.setMajor,
                ),
                const SizedBox(height: 12),
                _dropdown<String>(
                  label: '담당 강사',
                  value: _viewModel.instructor,
                  items: _viewModel.instructors,
                  text: (v) => v,
                  onChanged: readOnly ? null : _viewModel.setInstructor,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _dateField(
                        label: '교육 시작일 *',
                        value: _viewModel.startDate,
                        onTap: readOnly ? null : () => _pickDate(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dateField(
                        label: '교육 종료일 *',
                        value: _viewModel.endDate,
                        onTap: readOnly
                            ? null
                            : () => _pickDate(isStart: false),
                      ),
                    ),
                  ],
                ),
                if (_viewModel.startDate != null &&
                    _viewModel.endDate != null &&
                    _viewModel.dateError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _viewModel.dateError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _capacityController,
                  enabled: !readOnly,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '정원 *',
                    suffixText: '명',
                    border: OutlineInputBorder(),
                  ),
                  validator: _viewModel.validateCapacity,
                ),
                const SizedBox(height: 12),
                _dropdown<CourseStatus>(
                  label: '상태',
                  value: _viewModel.status,
                  items: _viewModel.selectableStatuses,
                  text: (v) => CodeNamesScope.of(
                    context,
                  ).name(CodeGroup.courseStatus, v.code, v.label),
                  onChanged: readOnly ? null : _viewModel.setStatus,
                ),
                if (_viewModel.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _viewModel.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: (readOnly || _viewModel.saving)
                            ? null
                            : _submit,
                        child: Text(_viewModel.saving ? '저장 중...' : '저장'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(value == null ? '선택' : formatDate(value)),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) text,
    required ValueChanged<T>? onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          items: [
            for (final item in items)
              DropdownMenuItem<T>(value: item, child: Text(text(item))),
          ],
          onChanged: onChanged == null
              ? null
              : (v) {
                  if (v != null) onChanged(v);
                },
        ),
      ),
    );
  }
}
