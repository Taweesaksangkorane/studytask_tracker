import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus { pending, submitted }

class TaskModel {
  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final TaskStatus status;
  final String source; // 'classroom' or 'manual'
  final String description;
  final List<Map<String, dynamic>> submittedFiles;
  final String? classroomLink;

  TaskModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.status,
    this.source = 'manual',
    this.description = '',
    this.submittedFiles = const [],
    this.classroomLink,
  });

  factory TaskModel.fromFirestore(String id, Map<String, dynamic> data) {
    return TaskModel(
      id: id,
      title: data['title'] ?? '',
      subject: data['subject'] ?? '',
      dueDate: _parseDueDateValue(data['dueDate']),
      status: data['status'] == 'submitted'
          ? TaskStatus.submitted
          : TaskStatus.pending,
      source: data['source'] ?? 'manual',
      description: data['description'] ?? '',
      submittedFiles: List<Map<String, dynamic>>.from(
        (data['submittedFiles'] ?? []) as List,
      ),
      classroomLink: data['classroomLink'],
    );
  }

  static DateTime _parseDueDateValue(dynamic rawDueDate) {
    if (rawDueDate is Timestamp) {
      return rawDueDate.toDate().toLocal();
    }

    if (rawDueDate is DateTime) {
      return rawDueDate.isUtc ? rawDueDate.toLocal() : rawDueDate;
    }

    if (rawDueDate is String && rawDueDate.isNotEmpty) {
      try {
        final parsed = DateTime.parse(rawDueDate);
        return parsed.isUtc ? parsed.toLocal() : parsed;
      } catch (_) {
        return DateTime.now();
      }
    }

    if (rawDueDate is int) {
      return DateTime.fromMillisecondsSinceEpoch(rawDueDate, isUtc: true)
          .toLocal();
    }

    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': subject,
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'source': source,
      'description': description,
      'submittedFiles': submittedFiles,
      'classroomLink': classroomLink,
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