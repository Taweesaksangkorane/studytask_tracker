import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskDetailPage extends StatefulWidget {
  final TaskModel task;
  const TaskDetailPage({super.key, required this.task});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  var _attachments = <PlatformFile>[];
  final _linkController = TextEditingController();
  var _linkAttachments = <Map<String, dynamic>>[];
  var _submittedFiles = <Map<String, dynamic>>[];
  late TaskStatus _currentStatus;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;
  final Stopwatch _uploadStopwatch = Stopwatch();
  Timer? _uploadTicker;
  String _uploadElapsedLabel = '0s';
  String? _classroomLink;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.task.status; // Initialize from widget
    _classroomLink = widget.task.classroomLink;
    _animationController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
    
    // Load latest task data from Firestore
    _loadTaskData();
  }

  Future<void> _loadTaskData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || !mounted) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .doc(widget.task.id)
          .get();

      if (mounted && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final submittedFilesList = (data['submittedFiles'] ?? []) as List;
        final statusStr = data['status'] ?? 'pending';
        final newStatus = statusStr == 'submitted' 
            ? TaskStatus.submitted 
            : TaskStatus.pending;
        
        // Properly convert Firestore list to List<Map<String, dynamic>>
        final files = submittedFilesList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        
        debugPrint('✅ Loaded: status=$statusStr, files=${files.length}');
        
        setState(() {
          _currentStatus = newStatus;
          _submittedFiles = files;
          _classroomLink = data['classroomLink'] as String? ?? _classroomLink;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading task: $e');
    }
  }

  @override
  void dispose() {
    _uploadTicker?.cancel();
    _uploadStopwatch.stop();
    _linkController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachments.addAll(result.files);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ ${result.files.length} file(s) added'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _removeLinkAttachment(int index) {
    setState(() {
      _linkAttachments.removeAt(index);
    });
  }

  bool get _hasDraftSubmission {
    return _attachments.isNotEmpty || _linkAttachments.isNotEmpty;
  }

  bool get _canSubmitDraft {
    return _hasDraftSubmission && !_isSubmitting && !_isExpired;
  }

  bool _isValidHttpUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
  }

  String _normalizeLinkInput(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;

    final hasScheme = trimmed.startsWith('http://') || trimmed.startsWith('https://');
    if (hasScheme) return trimmed;

    if (trimmed.startsWith('drive.google.com') || trimmed.startsWith('docs.google.com')) {
      return 'https://$trimmed';
    }

    return trimmed;
  }

  String _formatElapsed(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes <= 0) return '${seconds}s';
    return '${minutes}m ${seconds}s';
  }

  Duration _calculateUploadTimeout() {
    final totalBytes = _attachments.fold<int>(0, (acc, file) => acc + file.size);
    final totalMb = totalBytes / (1024 * 1024);

    // Add fixed overhead for auth/network latency and a generous per-MB budget.
    // This prevents small files on slow mobile networks from timing out too early.
    final seconds = 120 + (totalMb * 30).ceil();
    final clamped = seconds.clamp(120, 900);
    return Duration(seconds: clamped);
  }

  String _extractDriveFileId(Uri uri) {
    final queryId = uri.queryParameters['id'];
    if (queryId != null && queryId.isNotEmpty) {
      return queryId;
    }

    final segments = uri.pathSegments;
    final fileIndex = segments.indexOf('d');
    if (fileIndex != -1 && fileIndex + 1 < segments.length) {
      return segments[fileIndex + 1];
    }

    return '';
  }

  String _deriveLinkDisplayName(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return 'External Link';

    final host = uri.host.toLowerCase();
    final isDriveHost = host.contains('drive.google.com') || host.contains('docs.google.com');
    if (isDriveHost) {
      final fileId = _extractDriveFileId(uri);
      if (fileId.isNotEmpty) {
        final shortId = fileId.length > 8 ? fileId.substring(0, 8) : fileId;
        return 'Google Drive File ($shortId)';
      }
      return 'Google Drive File';
    }

    if (uri.pathSegments.isNotEmpty && uri.pathSegments.last.isNotEmpty) {
      return Uri.decodeComponent(uri.pathSegments.last);
    }
    return uri.host;
  }

  void _startUploadTicker() {
    _uploadTicker?.cancel();
    _uploadStopwatch
      ..reset()
      ..start();
    _uploadTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _uploadElapsedLabel = _formatElapsed(_uploadStopwatch.elapsed);
      });
    });
  }

  void _stopUploadTicker() {
    _uploadTicker?.cancel();
    _uploadTicker = null;
    _uploadStopwatch.stop();
  }

  Future<void> _showAddLinkDialog() async {
    _linkController.clear();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Attach Google Drive Link'),
          content: TextField(
            controller: _linkController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'https://drive.google.com/...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = _normalizeLinkInput(_linkController.text);
                if (!_isValidHttpUrl(value)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid link (http/https)')),
                  );
                  return;
                }

                final name = _deriveLinkDisplayName(value);

                setState(() {
                  _linkAttachments.add({
                    'name': name,
                    'size': 0,
                    'extension': '',
                    'downloadUrl': value,
                    'type': 'link',
                  });
                });

                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link attached. Make sure link sharing allows access.'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Attach'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openFilePath(String? path, {String? url}) async {
    if (url != null && url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        final canLaunch = await canLaunchUrl(uri);
        if (!canLaunch) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to open file URL')),
            );
          }
          return;
        }

        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to open file URL: $e')),
          );
        }
        return;
      }
    }

    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This file has no downloadable URL yet. Please re-submit to enable opening.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (path == null || path.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File path not available on this device. Please re-submit to enable URL opening.')),
        );
      }
      return;
    }

    try {
      await OpenFilex.open(path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open file: $e')),
        );
      }
    }
  }

  bool get _isExpired {
    if (_currentStatus == TaskStatus.submitted) return false;
    return widget.task.isExpired;
  }

  bool get _isClassroomTask {
    return widget.task.isFromClassroom;
  }

  bool get _hasLegacySubmittedFiles {
    return _submittedFiles.any((file) {
      final url = (file['downloadUrl'] ?? '').toString().trim();
      return url.isEmpty;
    });
  }

  Future<void> _openClassroomAssignment() async {
    const classroomHomeUrl = 'https://classroom.google.com/u/0/h';
    final link = (_classroomLink ?? '').trim();
    final urlToLaunch = link.isEmpty ? classroomHomeUrl : link;
    
    try {
      final uri = Uri.parse(urlToLaunch);
      final canLaunch = await canLaunchUrl(uri);
      
      if (!canLaunch) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open Google Classroom')),
          );
        }
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Color _getStatusColor() {
    if (_isExpired) {
      return Colors.red;
    }
    switch (_currentStatus) {
      case TaskStatus.submitted:
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String _getStatusLabel() {
    if (_isExpired) {
      return 'Overdue';
    }
    switch (_currentStatus) {
      case TaskStatus.submitted:
        return 'Submitted';
      default:
        return 'In Progress';
    }
  }

  IconData _getStatusIcon() {
    if (_isExpired) {
      return Icons.warning_rounded;
    }
    switch (_currentStatus) {
      case TaskStatus.submitted:
        return Icons.check_circle_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade600, Colors.blue.shade400],
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Task Details',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            if (!widget.task.isFromClassroom)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: () => _showDeleteDialog(context),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Colors.blue.shade50],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor().withValues(alpha: 0.8),
                            _getStatusColor(),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor().withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(),
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusLabel(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      widget.task.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Subject Card
              _buildEnhancedCard(
                icon: Icons.book_rounded,
                iconColor: Colors.blue.shade600,
                iconBg: Colors.blue.shade50,
                label: 'Subject',
                value: widget.task.subject,
              ),
              const SizedBox(height: 12),

              // Due Date & Time
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedCard(
                      icon: Icons.calendar_month_rounded,
                      iconColor: Colors.orange.shade600,
                      iconBg: Colors.orange.shade50,
                      label: 'Due Date',
                      value: widget.task.isNoDeadline
                          ? 'No deadline'
                          : '${widget.task.dueDate.day}/${widget.task.dueDate.month}/${widget.task.dueDate.year}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildEnhancedCard(
                      icon: Icons.access_time_rounded,
                      iconColor: Colors.purple.shade600,
                      iconBg: Colors.purple.shade50,
                      label: 'Due Time',
                      value: widget.task.isNoDeadline
                          ? '--:--'
                          : '${widget.task.dueDate.hour.toString().padLeft(2, '0')}:${widget.task.dueDate.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Late Submission Alert
              if (_isExpired)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: Colors.red.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Late Submission',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'This assignment is past the due date. You can view the details but cannot submit new files.',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Description
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Colors.grey.shade50],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.description_rounded,
                            size: 20,
                            color: Colors.indigo.shade600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.task.description.isEmpty ? 'No description available' : widget.task.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF475569),
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Submission Proof Section
              _buildSectionCard(
                title: 'Submission Proof',
                icon: Icons.check_circle_outline,
                child: Builder(
                  builder: (context) {
                    debugPrint('🔍 UI State: status=$_currentStatus, submittedFiles=${_submittedFiles.length}, attachments=${_attachments.length}');
                    if (_isClassroomTask) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.school, color: Colors.blue.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _currentStatus == TaskStatus.submitted
                                        ? 'Submitted in Google Classroom'
                                        : 'Submit this assignment in Google Classroom',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Files from Classroom are not synced yet.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _openClassroomAssignment,
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Go to Classroom'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_currentStatus == TaskStatus.submitted)
                      // Show submitted files
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  _submittedFiles.isEmpty
                                      ? 'Task submitted (no files)'
                                      : '${_submittedFiles.length} file(s) submitted',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_submittedFiles.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ..._submittedFiles.map((fileData) {
                              final filePath = fileData['path'] as String?;
                              final downloadUrl = fileData['downloadUrl'] as String?;
                              final isLink = (fileData['type'] ?? '').toString() == 'link';
                              final rawName = (fileData['name'] ?? 'Unknown').toString();
                              final effectiveName = isLink && downloadUrl != null && downloadUrl.isNotEmpty
                                  ? _deriveLinkDisplayName(downloadUrl)
                                  : rawName;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () => _openFilePath(filePath, url: downloadUrl),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(isLink ? Icons.link_rounded : _getFileIcon(fileData['extension'] ?? ''), size: 24, color: Colors.blue),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                effectiveName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                              Text(
                                                isLink
                                                    ? 'External link'
                                                    : '${((fileData['size'] ?? 0) / 1024).toStringAsFixed(2)} KB',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.open_in_new, size: 18, color: Colors.grey.shade600),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                          if (_hasLegacySubmittedFiles) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade300),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Some older submitted files have no URL, so they cannot be opened. Please attach files again and resubmit.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isSubmitting ? null : _pickFile,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Attach Files to Resubmit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                    else if (_hasDraftSubmission)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${_attachments.length + _linkAttachments.length} item(s) attached',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_attachments.isNotEmpty)
                            ..._attachments.asMap().entries.map((entry) {
                              int index = entry.key;
                              PlatformFile file = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: kIsWeb ? () => _openFilePath(null) : () => _openFilePath(file.path),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(_getFileIcon(file.extension ?? ''), size: 24, color: Colors.blue),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                file.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                              Text(
                                                '${(file.size / 1024).toStringAsFixed(2)} KB',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _removeAttachment(index),
                                          icon: const Icon(Icons.close, size: 20, color: Colors.red),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          if (_linkAttachments.isNotEmpty)
                            ..._linkAttachments.asMap().entries.map((entry) {
                              final index = entry.key;
                              final linkData = entry.value;
                              final linkName = (linkData['name'] ?? 'Drive Link').toString();
                              final linkUrl = (linkData['downloadUrl'] ?? '').toString();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () => _openFilePath(null, url: linkUrl),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.link_rounded, size: 24, color: Colors.blue),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                linkName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                              Text(
                                                linkUrl,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _removeLinkAttachment(index),
                                          icon: const Icon(Icons.close, size: 20, color: Colors.red),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isExpired ? null : () => _pickFile(),
                                  icon: Icon(
                                    _isExpired ? Icons.lock_rounded : Icons.add,
                                    color: _isExpired ? Colors.grey.shade600 : Colors.white,
                                  ),
                                  label: Text(
                                    _isExpired ? 'Cannot Add Files (Late)' : 'Add File',
                                    style: TextStyle(
                                      color: _isExpired ? Colors.grey.shade600 : Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isExpired ? Colors.grey.shade300 : Colors.blue.shade500,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    disabledBackgroundColor: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isExpired ? null : _showAddLinkDialog,
                                  icon: Icon(
                                    _isExpired ? Icons.lock_rounded : Icons.link,
                                    color: _isExpired ? Colors.grey.shade500 : Colors.blue.shade600,
                                  ),
                                  label: Text(
                                    _isExpired ? 'Cannot Add Link' : 'Add Drive Link',
                                    style: TextStyle(
                                      color: _isExpired ? Colors.grey.shade500 : Colors.blue.shade700,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: _isExpired ? Colors.grey.shade300 : Colors.blue.shade300),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      // Show upload box when not submitted and no attachments
                      GestureDetector(
                        onTap: _isExpired ? null : () => _pickFile(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isExpired ? Colors.grey.shade300 : Colors.blue.shade300,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: _isExpired ? Colors.grey.shade100 : Colors.blue.shade50,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _isExpired ? Icons.lock_rounded : Icons.cloud_upload_outlined,
                                size: 40,
                                color: _isExpired ? Colors.grey.shade500 : Colors.blue,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isExpired ? 'Cannot Upload (Late)' : 'Upload Files or Attach Drive Link',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _isExpired ? Colors.grey.shade600 : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isExpired ? 'This assignment has passed the deadline' : 'PDF, Word, Image, Excel or Google Drive link',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _isExpired ? Colors.grey.shade500 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!_hasDraftSubmission && _submittedFiles.isEmpty)
                      ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isExpired ? null : () => _pickFile(),
                                icon: Icon(
                                  _isExpired ? Icons.lock_rounded : Icons.add,
                                  color: _isExpired ? Colors.grey.shade600 : Colors.white,
                                ),
                                label: Text(
                                  _isExpired ? 'Cannot Choose File (Late)' : 'Choose File',
                                  style: TextStyle(
                                    color: _isExpired ? Colors.grey.shade600 : Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isExpired ? Colors.grey.shade300 : Colors.blue.shade500,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  disabledBackgroundColor: Colors.grey.shade300,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isExpired ? null : _showAddLinkDialog,
                                icon: Icon(
                                  _isExpired ? Icons.lock_rounded : Icons.link,
                                  color: _isExpired ? Colors.grey.shade500 : Colors.blue.shade600,
                                ),
                                label: Text(
                                  _isExpired ? 'Cannot Add Link' : 'Add Drive Link',
                                  style: TextStyle(
                                    color: _isExpired ? Colors.grey.shade500 : Colors.blue.shade700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: _isExpired ? Colors.grey.shade300 : Colors.blue.shade300),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                  ],
                );
                  },
                ),
              ),
              const SizedBox(height: 20),

              if (_isSubmitting)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: _uploadProgress > 0 ? _uploadProgress : null,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                        backgroundColor: Colors.grey.shade200,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _uploadProgress > 0
                            ? 'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}% (${_uploadElapsedLabel})'
                            : 'Uploading files... (${_uploadElapsedLabel})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: _isClassroomTask
                        ? ElevatedButton.icon(
                            onPressed: _openClassroomAssignment,
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Go to Classroom'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _canSubmitDraft ? () => _submitTask(context) : null,
                            icon: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))) : Icon(
                              _isExpired ? Icons.lock_rounded : Icons.check,
                              color: _isExpired ? Colors.grey.shade600 : Colors.white,
                            ),
                            label: Text(
                              _isExpired 
                                ? 'Cannot Submit (Late)' 
                                : (_currentStatus == TaskStatus.submitted ? 'Resubmit' : 'Submit'),
                              style: TextStyle(
                                color: _isExpired ? Colors.grey.shade600 : Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isExpired 
                                ? Colors.grey.shade300
                                : (_canSubmitDraft ? Colors.green : Colors.grey),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              disabledBackgroundColor: Colors.grey.shade300,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.blue),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.attachment;
    }
  }

  Future<void> _submitTask(BuildContext context) async {
    if (_attachments.isEmpty && _linkAttachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach at least one file or link before submitting')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
      _uploadElapsedLabel = '0s';
    });
    _startUploadTicker();

    try {
      final submittedItems = <Map<String, dynamic>>[];

      if (_attachments.isNotEmpty) {
        try {
          final timeoutDuration = _calculateUploadTimeout();
          debugPrint('📤 Uploading ${_attachments.length} file(s)...');
          final uploadedFiles = await TaskService().uploadTaskFiles(
            widget.task.id,
            _attachments,
            onProgress: (progress) {
              if (!mounted) return;
              setState(() {
                _uploadProgress = progress;
              });
            },
          ).timeout(
            timeoutDuration,
            onTimeout: () {
              throw TimeoutException('File upload timed out after ${timeoutDuration.inSeconds}s');
            },
          );
          submittedItems.addAll(uploadedFiles);
        } catch (uploadError) {
          if (_linkAttachments.isEmpty) {
            rethrow;
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('File upload is taking too long. Continuing with attached links only.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }

      submittedItems.addAll(_linkAttachments);

      if (submittedItems.isEmpty) {
        throw Exception('No valid file or link to submit');
      }

      debugPrint('📤 Saving submission metadata...');
      await TaskService().submitTask(widget.task.id, submittedItems);
      if (!mounted) return;
      
      debugPrint('✅ Submitted successfully');
      
      setState(() {
        _currentStatus = TaskStatus.submitted;
        _submittedFiles = submittedItems;
        _attachments.clear(); // Clear temporary attachments
        _linkAttachments.clear();
        _uploadProgress = 1.0;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Task submitted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Keep page open to show files, user presses back to go home
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      _stopUploadTicker();
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await TaskService().deleteTask(widget.task.id);
                if (!mounted) return;
                Navigator.pop(context);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
