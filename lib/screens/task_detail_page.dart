import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskDetailPage extends StatelessWidget {
  final TaskModel task;
  const TaskDetailPage({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final TaskService service = TaskService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Detail'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(task.subject, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Text('Due: ${task.isNoDeadline ? "ไม่มีกำหนด" : "${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year} ${task.dueDate.hour.toString().padLeft(2,'0')}:${task.dueDate.minute.toString().padLeft(2,'0')}"}'),
            const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton(
                onPressed: task.status == TaskStatus.submitted
                    ? null
                    : () async {
                        await service.updateStatus(task.id, TaskStatus.submitted);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as submitted')));
                          Navigator.pop(context);
                        }
                      },
                child: const Text('Mark Submitted'),
              ),
              const SizedBox(width: 12),
              if (!task.isFromClassroom)
                OutlinedButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                      title: const Text('Delete Task'),
                      content: const Text('ต้องการลบงานนี้หรือไม่?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                      ],
                    ));

                    if (ok == true) {
                      await service.deleteTask(task.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task deleted')));
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Delete'),
                )
              else
                OutlinedButton(
                  onPressed: null,
                  child: const Text('Delete (Classroom)'),
                )
            ],
          )
          ],
        ),
      ),
    );
  }
}
