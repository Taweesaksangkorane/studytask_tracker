import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import 'classroom_service.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addTask(TaskModel task) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .add(task.toMap());
  }

  Future<int> upsertClassroomTasks(List<ClassroomTask> tasks) async {
    if (tasks.isEmpty) {
      return 0;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final batch = _firestore.batch();
    final taskCollection =
        _firestore.collection('users').doc(uid).collection('tasks');

    for (final task in tasks) {
      final docRef = taskCollection.doc(task.docId);
      batch.set(docRef, task.toMap(), SetOptions(merge: true));
    }

    await batch.commit();
    return tasks.length;
  }

  Future<void> updateStatus(String taskId, TaskStatus status) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .doc(taskId)
        .update({'status': status.name});
  }

  Future<void> deleteTask(String taskId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  Stream<List<TaskModel>> getTasks() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TaskModel.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }
}
