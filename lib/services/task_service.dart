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
    final currentUser = FirebaseAuth.instance.currentUser!;
    final uid = currentUser.uid;
    final email = currentUser.email ?? '';
    final batch = _firestore.batch();
    var writeCount = 0;
    final taskCollection =
        _firestore.collection('users').doc(uid).collection('tasks');
    final syncedDocIds = tasks.map((task) => task.docId).toSet();

    for (final task in tasks) {
      final docRef = taskCollection.doc(task.docId);
      batch.set(
        docRef,
        {
          ...task.toMap(),
          'classroomOwnerUid': uid,
          'classroomOwnerEmail': email,
        },
        SetOptions(merge: true),
      );
      writeCount++;
    }

    if (writeCount > 0) {
      await batch.commit();
    }

    final classroomDocs = await taskCollection
        .where('source', isEqualTo: 'classroom')
        .get();

    final deleteBatch = _firestore.batch();
    var deleteCount = 0;

    for (final doc in classroomDocs.docs) {
      final data = doc.data();
      final ownerUid = (data['classroomOwnerUid'] ?? '').toString();
      final isNotInCurrentSync = !syncedDocIds.contains(doc.id);
      final isDifferentOwner = ownerUid.isNotEmpty && ownerUid != uid;
      final isLegacyWithoutOwner = ownerUid.isEmpty;

      if (isNotInCurrentSync || isDifferentOwner || isLegacyWithoutOwner) {
        deleteBatch.delete(doc.reference);
        deleteCount++;
      }
    }

    if (deleteCount > 0) {
      await deleteBatch.commit();
    }

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

  Future<void> submitTask(String taskId, List<Map<String, dynamic>> fileMetadata) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .doc(taskId)
        .update({
          'status': 'submitted',
          'submittedFiles': fileMetadata,
        });
  }

  Future<void> deleteTask(String taskId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    
    // Fetch task to check if it's from classroom
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .doc(taskId)
        .get();
    
    final source = doc.get('source') ?? 'manual';
    if (source == 'classroom') {
      throw Exception('Cannot delete classroom tasks. Delete from Google Classroom instead.');
    }
    
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  Stream<List<TaskModel>> getTasks() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    // ถ้า user logout ให้ return empty stream
    if (uid == null) {
      return Stream.value([]);
    }

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
