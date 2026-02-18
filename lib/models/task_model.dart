enum TaskStatus { pending, submitted }

class TaskModel {
  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final TaskStatus status;
  final String source; // 'classroom' or 'manual'

  TaskModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.status,
    this.source = 'manual',
  });

  factory TaskModel.fromFirestore(String id, Map<String, dynamic> data) {
    return TaskModel(
      id: id,
      title: data['title'] ?? '',
      subject: data['subject'] ?? '',
      dueDate: data['dueDate'] != null
    ? DateTime.parse(data['dueDate'])
    : DateTime.now(),
      status: data['status'] == 'submitted'
          ? TaskStatus.submitted
          : TaskStatus.pending,
      source: data['source'] ?? 'manual',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': subject,
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'source': source,
    };
  }

  /// Check if task is expired (past due date and not submitted)
  bool get isExpired {
    return status == TaskStatus.pending && dueDate.isBefore(DateTime.now()) && !isNoDeadline;
  }

  /// Check if task has no deadline (set to year 2099)
  bool get isNoDeadline {
    return dueDate.year >= 2099;
  }

  /// Check if task is from classroom (read-only)
  bool get isFromClassroom {
    return source == 'classroom';
  }
}