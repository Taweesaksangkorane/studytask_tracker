import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';
import 'google_auth_service.dart';
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

  Future<List<Map<String, dynamic>>> uploadTaskFiles(
    String taskId,
    List<PlatformFile> files,
    {
      void Function(double progress)? onProgress,
    }
  ) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final uploadedFiles = <Map<String, dynamic>>[];
    final authHeaders = await _getDriveAuthHeaders(uid);
    final folderId = await _getOrCreateTaskUploadsFolder(authHeaders);

    if (files.isEmpty) {
      onProgress?.call(1.0);
      return uploadedFiles;
    }

    onProgress?.call(0.0);

    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      final Uint8List? bytes = file.bytes;
      if (bytes == null) {
        throw Exception('Cannot read bytes for file: ${file.name}');
      }

      final fileName = file.name.replaceAll('/', '_');
      final uploadResult = await _uploadFileToDrive(
        fileName: fileName,
        bytes: bytes,
        contentType: _getContentType(file.extension),
        authHeaders: authHeaders,
        parentFolderId: folderId,
      );

      uploadedFiles.add({
        'name': file.name,
        'size': file.size,
        'extension': file.extension ?? 'unknown',
        'downloadUrl': uploadResult['webViewLink'] ?? uploadResult['webContentLink'] ?? '',
        'driveFileId': uploadResult['id'] ?? '',
        'type': 'drive',
      });

      final overallProgress = ((index + 1) / files.length).clamp(0.0, 1.0);
      onProgress?.call(overallProgress.toDouble());
    }

    onProgress?.call(1.0);

    return uploadedFiles;
  }

  Future<Map<String, String>> _getDriveAuthHeaders(String uid) async {
    final authService = GoogleAuthService();
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final expectedEmail = (firebaseUser?.email ?? '').toLowerCase().trim();

    if (kIsWeb) {
      final webAccessToken = authService.getValidWebAccessToken(uid);
      if (webAccessToken == null || webAccessToken.isEmpty) {
        throw Exception('Google authorization missing on web. Please sign out and sign in again, then allow Google Drive permission.');
      }
      return {'Authorization': 'Bearer $webAccessToken'};
    }

    final account = authService.currentAccount ?? await authService.signInSilently();

    if (account != null) {
      final googleEmail = account.email.toLowerCase().trim();
      if (expectedEmail.isNotEmpty && googleEmail != expectedEmail) {
        throw Exception('Google Drive account mismatch. Logged in as $expectedEmail but Google Sign-In account is $googleEmail. Please sign out and sign in with the same account.');
      }

      final headers = await account.authHeaders;
      if (headers['Authorization'] != null && headers['Authorization']!.isNotEmpty) {
        return headers;
      }
    }

    throw Exception('Google authorization missing. Please sign out and sign in again, then allow Google Drive permission.');
  }

  Future<String> _getOrCreateTaskUploadsFolder(Map<String, String> authHeaders) async {
    const folderName = 'StudyTask Tracker Uploads';
    final query = "name = '$folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";

    final listUri = Uri.https(
      'www.googleapis.com',
      '/drive/v3/files',
      {
        'q': query,
        'spaces': 'drive',
        'fields': 'files(id,name)',
        'pageSize': '1',
      },
    );

    final listResponse = await http.get(listUri, headers: authHeaders);
    if (listResponse.statusCode == 200) {
      final json = jsonDecode(listResponse.body) as Map<String, dynamic>;
      final files = (json['files'] as List<dynamic>? ?? const []);
      if (files.isNotEmpty) {
        return (files.first as Map<String, dynamic>)['id'] as String;
      }
    } else {
      throw Exception(_buildDriveApiErrorMessage(
        'Unable to access Google Drive folder list',
        listResponse.statusCode,
        listResponse.body,
      ));
    }

    final createResponse = await http.post(
      Uri.parse('https://www.googleapis.com/drive/v3/files'),
      headers: {
        ...authHeaders,
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'name': folderName,
        'mimeType': 'application/vnd.google-apps.folder',
      }),
    );

    if (createResponse.statusCode < 200 || createResponse.statusCode >= 300) {
      throw Exception(_buildDriveApiErrorMessage(
        'Unable to create Google Drive folder',
        createResponse.statusCode,
        createResponse.body,
      ));
    }

    final json = jsonDecode(createResponse.body) as Map<String, dynamic>;
    final folderId = (json['id'] ?? '').toString();
    if (folderId.isEmpty) {
      throw Exception('Drive folder ID missing from response');
    }
    return folderId;
  }

  Future<Map<String, dynamic>> _uploadFileToDrive({
    required String fileName,
    required Uint8List bytes,
    required String contentType,
    required Map<String, String> authHeaders,
    required String parentFolderId,
  }) async {
    const boundary = 'studytask_upload_boundary';

    final metadata = {
      'name': fileName,
      'parents': [parentFolderId],
    };

    final body = BytesBuilder()
      ..add(utf8.encode('--$boundary\r\n'))
      ..add(utf8.encode('Content-Type: application/json; charset=UTF-8\r\n\r\n'))
      ..add(utf8.encode(jsonEncode(metadata)))
      ..add(utf8.encode('\r\n--$boundary\r\n'))
      ..add(utf8.encode('Content-Type: $contentType\r\n\r\n'))
      ..add(bytes)
      ..add(utf8.encode('\r\n--$boundary--\r\n'));

    final uploadUri = Uri.parse(
      'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name,webViewLink,webContentLink',
    );

    final response = await http.post(
      uploadUri,
      headers: {
        ...authHeaders,
        'Content-Type': 'multipart/related; boundary=$boundary',
      },
      body: body.toBytes(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_buildDriveApiErrorMessage(
        'Google Drive upload failed',
        response.statusCode,
        response.body,
      ));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final fileId = (json['id'] ?? '').toString();
    if (fileId.isEmpty) {
      throw Exception('Drive file ID missing from upload response');
    }

    await _setPublicReadPermission(fileId, authHeaders);
    return json;
  }

  Future<void> _setPublicReadPermission(String fileId, Map<String, String> authHeaders) async {
    final response = await http.post(
      Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId/permissions'),
      headers: {
        ...authHeaders,
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'role': 'reader',
        'type': 'anyone',
      }),
    );

    // If permission update fails due to policy, keep file uploaded and continue.
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return;
    }
  }

  String _buildDriveApiErrorMessage(String prefix, int statusCode, String responseBody) {
    final apiMessage = _extractGoogleApiMessage(responseBody);

    if (statusCode == 401) {
      return '$prefix (401): authorization expired. Please sign out and sign in again.';
    }

    if (statusCode == 403) {
      final lower = apiMessage.toLowerCase();
      if (lower.contains('access_not_configured') || lower.contains('api has not been used') || lower.contains('service_disabled')) {
        return '$prefix (403): Google Drive API is not enabled. Please enable Drive API in Google Cloud Console.';
      }
      if (lower.contains('insufficient') || lower.contains('permission')) {
        return '$prefix (403): permission denied. Please sign in again and allow Google Drive access.';
      }
      return '$prefix (403): $apiMessage';
    }

    return '$prefix ($statusCode): $apiMessage';
  }

  String _extractGoogleApiMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.isNotEmpty) {
            return message;
          }
        }
      }
    } catch (_) {
      // Ignore parse errors and fallback to raw body.
    }

    final compact = responseBody.replaceAll('\n', ' ').trim();
    if (compact.isEmpty) {
      return 'Unknown Google API error';
    }
    return compact;
  }

  String _getContentType(String? extension) {
    switch ((extension ?? '').toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
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
          doc.data(),
        );
      }).toList();
    });
  }
}
