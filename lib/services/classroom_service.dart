import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'google_auth_service.dart';

class ClassroomTask {
  final String id;
  final String courseId;
  final String courseName;
  final String title;
  final DateTime dueDate;
  final String status;

  const ClassroomTask({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.title,
    required this.dueDate,
    required this.status,
  });

  String get docId => 'classroom_${courseId}_$id';

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': courseName,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'source': 'classroom',
      'sourceId': '$courseId:$id',
    };
  }
}

class ClassroomService {
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  Future<GoogleSignInAuthentication> _getAuth() async {
    // Get current account or try silent sign-in
    GoogleSignInAccount? account = _googleAuthService.currentAccount;
    account ??= await _googleAuthService.signInSilently();

    // If no account, throw exception - user needs to login first
    if (account == null) {
      throw Exception('กรุณาเข้าสู่ระบบด้วย Google ก่อนซิงค์ Classroom');
    }

    // Request classroom scopes (this will prompt only if not already granted)
    final requiredScopes = [
      'https://www.googleapis.com/auth/classroom.courses.readonly',
      'https://www.googleapis.com/auth/classroom.course-work.readonly',
      'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
    ];

    try {
      final googleSignIn = _googleAuthService.instance;
      final success = await googleSignIn.requestScopes(requiredScopes);
      if (!success) {
        throw Exception('กรุณาอนุญาตการเข้าถึง Google Classroom');
      }
    } catch (e) {
      // If requestScopes fails, it might be already granted or network issue
      // Continue anyway and let API call fail if scopes truly missing
      print('Scope request warning: $e');
    }

    return account.authentication;
  }

  Future<List<dynamic>> fetchCourses() async {
    final auth = await _getAuth();
    return _fetchCoursesWithAuth(auth);
  }

  Future<List<dynamic>> _fetchCoursesWithAuth(
    GoogleSignInAuthentication auth,
  ) async {
    final response = await http.get(
      Uri.parse(
        'https://classroom.googleapis.com/v1/courses?courseStates=ACTIVE',
      ),
      headers: {
        'Authorization': 'Bearer ${auth.accessToken}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load courses');
    }

    final data = json.decode(response.body);
    return data['courses'] ?? [];
  }

  Future<List<ClassroomTask>> fetchCourseWorkTasks() async {
    final auth = await _getAuth();
    final headers = {
      'Authorization': 'Bearer ${auth.accessToken}',
    };
    final courses = await _fetchCoursesWithAuth(auth);
    final tasks = <ClassroomTask>[];

    for (final course in courses) {
      final courseId = course['id']?.toString();
      if (courseId == null || courseId.isEmpty) {
        continue;
      }

      final courseName = (course['name'] ?? 'Classroom').toString();
      final response = await http.get(
        Uri.parse(
          'https://classroom.googleapis.com/v1/courses/$courseId/courseWork?courseWorkStates=PUBLISHED',
        ),
        headers: headers,
      );

      if (response.statusCode != 200) {
        continue;
      }

      final data = json.decode(response.body);
      final courseWork = (data['courseWork'] ?? []) as List<dynamic>;

      for (final work in courseWork) {
        final dueDateMap = work['dueDate'] as Map<String, dynamic>?;
        final dueTimeMap = work['dueTime'] as Map<String, dynamic>?;
        final dueDate = _parseDueDate(dueDateMap, dueTimeMap);
        // If no due date, set to far future (year 2099) so it won't be marked as expired
        final finalDueDate = dueDate ?? DateTime(2099, 12, 31, 23, 59);

        final title = (work['title'] ?? 'Untitled').toString();
        final workId = work['id']?.toString();
        if (workId == null || workId.isEmpty) {
          continue;
        }

        final status = await _fetchSubmissionStatus(
          courseId,
          workId,
          headers,
        );

        tasks.add(ClassroomTask(
          id: workId,
          courseId: courseId,
          courseName: courseName,
          title: title,
          dueDate: finalDueDate,
          status: status,
        ));
      }
    }

    return tasks;
  }

  Future<String> _fetchSubmissionStatus(
    String courseId,
    String workId,
    Map<String, String> headers,
  ) async {
    final response = await http.get(
      Uri.parse(
        'https://classroom.googleapis.com/v1/courses/$courseId/courseWork/$workId/studentSubmissions?userId=me',
      ),
      headers: headers,
    );

    if (response.statusCode != 200) {
      return 'pending';
    }

    final data = json.decode(response.body);
    final submissions = (data['studentSubmissions'] ?? []) as List<dynamic>;
    if (submissions.isEmpty) {
      return 'pending';
    }

    final state = submissions.first['state']?.toString();
    if (state == 'TURNED_IN' || state == 'RETURNED') {
      return 'submitted';
    }

    return 'pending';
  }

  DateTime? _parseDueDate(
    Map<String, dynamic>? dueDate,
    Map<String, dynamic>? dueTime,
  ) {
    if (dueDate == null) {
      return null;
    }

    final year = dueDate['year'] ?? 0;
    final month = dueDate['month'] ?? 1;
    final day = dueDate['day'] ?? 1;
    if (year == 0) {
      return null;
    }

    final hour = dueTime?['hours'] ?? 23;
    final minute = dueTime?['minutes'] ?? 59;
    return DateTime(year, month, day, hour, minute);
  }
}
