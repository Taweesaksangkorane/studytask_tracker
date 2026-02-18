enum TaskStatus { pending, submitted }

class TaskModel {
  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final TaskStatus status;

  TaskModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.status,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': subject,
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
    };
  }
}
