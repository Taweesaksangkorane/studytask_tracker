import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../services/task_service.dart';

class NewTaskPage extends StatefulWidget {
  const NewTaskPage({super.key});

  @override
  State<NewTaskPage> createState() => _NewTaskPageState();
}

class _NewTaskPageState extends State<NewTaskPage> {
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  bool _isSaving = false;

  final TaskService _taskService = TaskService();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = DateTime(picked.year, picked.month, picked.day, _dueDate.hour, _dueDate.minute));
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final subject = _subjectCtrl.text.trim();
    if (title.isEmpty || subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')));
      return;
    }

    setState(() => _isSaving = true);

    final task = TaskModel(
      id: '',
      title: title,
      subject: subject,
      dueDate: _dueDate,
      status: TaskStatus.pending,
    );

    try {
      await _taskService.addTask(task);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Task'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(hintText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(hintText: 'Subject'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Due: ${_dueDate.day}/${_dueDate.month}/${_dueDate.year}'),
                const Spacer(),
                TextButton(onPressed: _pickDate, child: const Text('Pick Date')),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Task'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
