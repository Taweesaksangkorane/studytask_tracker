import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/classroom_service.dart';
import '../services/google_auth_service.dart';
import 'task_detail_page.dart';
import 'settings_page.dart';
import 'new_task_page.dart';

enum TaskFilter { all, submitted, pending }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TaskFilter _filter = TaskFilter.all;
  DateTime? _lastSyncAt;
  final TaskService _taskService = TaskService();
  List<TaskModel> _allTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _taskService.getTasks().listen((tasks) {
      if (mounted) {
        setState(() {
          _allTasks = tasks;
          _isLoading = false;
        });
      }
    });
  }

  List<TaskModel> get _filteredTasks {
    if (_filter == TaskFilter.all) return _allTasks;
    return _allTasks.where((t) => 
      _filter == TaskFilter.submitted
        ? t.status == TaskStatus.submitted
        : t.status == TaskStatus.pending
    ).toList();
  }

  int get _total => _allTasks.length;
  int get _submitted => _allTasks.where((t) => t.status == TaskStatus.submitted).length;
  int get _pending => _total - _submitted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildAISuggestion(),
                  const SizedBox(height: 20),
                  _buildSyncBar(context),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard("ทั้งหมด", _total.toString(),
                          Icons.grid_view_rounded,
                          _filter == TaskFilter.all,
                          Colors.blueAccent, () {
                        setState(() => _filter = TaskFilter.all);
                      }),
                      _buildStatCard("ส่งแล้ว", _submitted.toString(),
                          Icons.send_rounded,
                          _filter == TaskFilter.submitted,
                          Colors.green, () {
                        setState(() => _filter = TaskFilter.submitted);
                      }),
                      _buildStatCard("ยังไม่ส่ง", _pending.toString(),
                          Icons.access_time_filled,
                          _filter == TaskFilter.pending,
                          Colors.orangeAccent, () {
                        setState(() => _filter = TaskFilter.pending);
                      }),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "LATEST TASKS",
                    style: TextStyle(
                        color: Colors.blueGrey,
                        letterSpacing: 1.5,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: _filteredTasks.isEmpty
                      ? Center(
                          key: ValueKey('empty-$_filter'),
                          child: const Padding(
                            padding: EdgeInsets.all(40),
                            child: Text("ยังไม่มีงาน",
                                style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      : Column(
                          key: ValueKey('list-$_filter-${_filteredTasks.length}'),
                          children: _filteredTasks.map((task) {
                            final isOverdue =
                                task.status == TaskStatus.pending &&
                                    task.dueDate.isBefore(DateTime.now());

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: _buildTaskCard(
                                context,
                                task: task,
                                isOverdue: isOverdue,
                              ),
                            );
                          }).toList(),
                        ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const NewTaskPage())),
        backgroundColor: Colors.blueAccent,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 35, color: Colors.white),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(5)),
              child: const Text("STUDENT SPACE",
                  style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 5),
            const Text("งานของคุณ",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C2E))),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color:
                            Colors.black.withAlpha((0.05 * 255).round()),
                        blurRadius: 10)
                  ]),
              child: const Icon(Icons.calendar_today_outlined,
                  color: Colors.blueAccent),
            ),
            const SizedBox(width: 10),
            const CircleAvatar(
                radius: 25,
                backgroundImage:
                    NetworkImage('https://placeholder.com/150')),
          ],
        )
      ],
    );
  }

  Widget _buildAISuggestion() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: Colors.orange.withAlpha((0.1 * 255).round()))),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
                "ลุย Mobile App Report เริ่มวางแผนล่วงหน้าไว้ก่อนนะ สู้ๆ ครับ คนเก่งทำได้อยู่แล้ว!",
                style:
                    TextStyle(fontSize: 12, color: Colors.brown)),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Colors.black.withAlpha((0.05 * 255).round()))),
      child: Row(
        children: [
          const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.school,
                  color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Classroom Sync",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                _lastSyncAt == null
                    ? "UPDATED AT --:--:--"
                    : "UPDATED AT ${_formatTime(_lastSyncAt!)}",
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () async {
              final service = ClassroomService();
              final taskService = TaskService();
              
              // Show loading indicator
              if (!mounted) return;
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text("กำลังซิงค์ Classroom..."),
                    ],
                  ),
                  duration: Duration(seconds: 30),
                ),
              );

              try {
                final classroomTasks = await service.fetchCourseWorkTasks();
                final savedCount = await taskService.upsertClassroomTasks(classroomTasks);

                if (mounted) {
                  setState(() => _lastSyncAt = DateTime.now());
                }

                if (!mounted) return;
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(savedCount == 0
                            ? "ไม่พบงานที่มีวันกำหนดส่ง"
                            : "นำเข้างาน $savedCount รายการสำเร็จ"),
                      ],
                    ),
                    backgroundColor: Colors.white,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).clearSnackBars();
                
                // Parse error message
                String errorMsg = "ซิงค์ไม่สำเร็จ";
                if (e.toString().contains('กรุณาเข้าสู่ระบบ')) {
                  errorMsg = "กรุณาล็อกอินด้วย Google ก่อนซิงค์";
                } else if (e.toString().contains('Failed to load')) {
                  errorMsg = "ไม่สามารถเชื่อมต่อ Classroom ได้";
                } else {
                  errorMsg = "เกิดข้อผิดพลาด: ${e.toString()}";
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(errorMsg)),
                      ],
                    ),
                    backgroundColor: Colors.white,
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: "ลองอีกครั้ง",
                      onPressed: () {},
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.sync, size: 16),
            label: const Text("SYNC NOW",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return "$hour:$minute:$second";
  }

  Widget _buildStatCard(
    String label,
    String count,
    IconData icon,
    bool isActive,
    Color activeColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: isActive
              ? Border.all(color: Colors.blueAccent, width: 2)
              : Border.all(color: Colors.transparent),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withAlpha((0.15 * 255).round()),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: activeColor,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              count,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context,
      {required TaskModel task,
      bool isOverdue = false}) {
    final isSubmitted = task.status == TaskStatus.submitted;
    final statusColor = isSubmitted ? Colors.green : Colors.orangeAccent;
    return InkWell(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  TaskDetailPage(task: task))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(25),
          border: Border.all(
              color: Colors.black
                  .withAlpha((0.05 * 255).round())),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.only(
                      topLeft:
                          Radius.circular(25),
                      bottomLeft:
                          Radius.circular(25)),
                ),
                child: Container(
                  color: statusColor,
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets
                                .symmetric(
                                horizontal: 10,
                                vertical: 4),
                            decoration:
                                BoxDecoration(
                              color: statusColor
                                .withAlpha((0.12 * 255).round()),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          8),
                            ),
                            child: Text(
                              isSubmitted
                                ? "SUBMITTED"
                                : "PENDING",
                              style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isOverdue)
                            const Row(
                              children: [
                                Icon(
                                    Icons
                                        .error_outline,
                                    color: Colors
                                        .redAccent,
                                    size: 14),
                                SizedBox(
                                    width: 4),
                                Text(
                                    "OVERDUE",
                                    style: TextStyle(
                                        color: Colors
                                            .redAccent,
                                        fontSize:
                                            10,
                                        fontWeight:
                                            FontWeight
                                                .bold)),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(
                          height: 10),
                      Text(task.title,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold)),
                      Text(task.subject,
                          style: const TextStyle(
                              color:
                                  Colors.blueGrey,
                              fontSize: 14)),
                      const SizedBox(
                          height: 15),
                      Row(
                        children: [
                          const Icon(
                              Icons
                                  .calendar_today,
                              size: 14,
                              color: Colors
                                  .blueAccent),
                          const SizedBox(
                              width: 5),
                          Text(
                              "${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}",
                              style:
                                  const TextStyle(
                                      fontSize:
                                          12,
                                      color: Colors
                                          .grey)),
                          const SizedBox(
                              width: 15),
                          const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors
                                  .blueAccent),
                          const SizedBox(
                              width: 5),
                          Text(
                              "${task.dueDate.hour.toString().padLeft(2, '0')}:${task.dueDate.minute.toString().padLeft(2, '0')}",
                              style:
                                  const TextStyle(
                                      fontSize:
                                          12,
                                      color: Colors
                                          .grey)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        children: [
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home_filled,
                  color: Colors.blueAccent),
              Text("หน้าหลัก",
                  style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 10)),
            ],
          ),
          const SizedBox(width: 40),
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const SettingsPage())),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_outlined,
                    color: Colors.grey),
                Text("ตั้งค่า",
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
