import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;
  final TaskService _taskService = TaskService();
  List<TaskModel> _allTasks = [];

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDate = DateTime.now();
    
    _taskService.getTasks().listen((tasks) {
      if (mounted) {
        setState(() {
          _allTasks = tasks;
        });
      }
    });
  }

  List<TaskModel> _getTasksForDate(DateTime date) {
    return _allTasks.where((task) {
      return task.dueDate.year == date.year &&
          task.dueDate.month == date.month &&
          task.dueDate.day == date.day;
    }).toList();
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _getFirstWeekday(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _getDaysInMonth(_currentMonth);
    final firstWeekday = _getFirstWeekday(_currentMonth);
    
    List<DateTime> days = [];
    for (int i = 0; i < firstWeekday - 1; i++) {
      days.add(DateTime(0));
    }
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }

    final thaiMonths = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน',
      'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม',
      'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];

    final selectedDateTasks = _selectedDate != null 
        ? _getTasksForDate(_selectedDate!)
        : [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('ปฎิทินงาน',
            style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month selector card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                      color: Colors.black
                          .withAlpha((0.05 * 255).round())),
                ),
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.blueAccent),
                          onPressed: _previousMonth,
                        ),
                        Text(
                          '${thaiMonths[_currentMonth.month - 1]} ${_currentMonth.year + 543}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1C2E),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.blueAccent),
                          onPressed: _nextMonth,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Calendar grid
                    GridView.count(
                      crossAxisCount: 7,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: [
                        // Week day headers
                        const Text('อ', textAlign: TextAlign.center, 
                            style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 12,
                                color: Colors.blueGrey)),
                        const Text('จ', textAlign: TextAlign.center, 
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.blueGrey)),
                        const Text('อ', textAlign: TextAlign.center, 
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.blueGrey)),
                        const Text('พ', textAlign: TextAlign.center, 
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.blueGrey)),
                        const Text('พ', textAlign: TextAlign.center, 
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.blueGrey)),
                        const Text('ศ', textAlign: TextAlign.center, 
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.blueGrey)),
                        const Text('ส', textAlign: TextAlign.center, 
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.blueGrey)),
                        // Days
                        ...days.map((day) {
                          if (day.year == 0) {
                            return const SizedBox();
                          }
                          
                          final isSelected = _selectedDate != null &&
                              day.year == _selectedDate!.year &&
                              day.month == _selectedDate!.month &&
                              day.day == _selectedDate!.day;
                          
                          final hasTask = _getTasksForDate(day).isNotEmpty;
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDate = day;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blueAccent : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasTask 
                                      ? Colors.orangeAccent 
                                      : Colors.black.withAlpha((0.05 * 255).round()),
                                  width: hasTask ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.blueAccent
                                              .withAlpha((0.15 * 255).round()),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    '${day.day}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (hasTask)
                                    Positioned(
                                      bottom: 6,
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.white : Colors.orangeAccent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Selected date tasks
              if (_selectedDate != null) ...[
                Text(
                  'งานวันที่ ${_selectedDate!.day} ${thaiMonths[_selectedDate!.month - 1]} ${_selectedDate!.year + 543}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 15),
                selectedDateTasks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            'ไม่มีงานในวันนี้',
                            style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14),
                          ),
                        ),
                      )
                    : Column(
                        children: selectedDateTasks.map((task) {
                          final isSubmitted = task.status == TaskStatus.submitted;
                          final isClosedDeadline = task.isExpired;
                          final statusColor = isClosedDeadline
                              ? Colors.grey
                              : isSubmitted
                                  ? Colors.green
                                  : Colors.orangeAccent;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isClosedDeadline ? Colors.grey[100] : Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                    color: isClosedDeadline
                                        ? Colors.grey.withAlpha((0.3 * 255).round())
                                        : Colors.black
                                            .withAlpha((0.05 * 255).round())),
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(25),
                                            bottomLeft: Radius.circular(25)),
                                      ),
                                      child: Container(
                                        color: statusColor,
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
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
                                                    color: isClosedDeadline
                                                        ? Colors.red.withAlpha((0.12 * 255).round())
                                                        : statusColor
                                                            .withAlpha((0.12 * 255).round()),
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                                8),
                                                  ),
                                                  child: Text(
                                                    isClosedDeadline
                                                        ? "CLOSED"
                                                        : isSubmitted
                                                            ? "SUBMITTED"
                                                            : "PENDING",
                                                    style: TextStyle(
                                                    color: isClosedDeadline
                                                        ? Colors.red
                                                        : statusColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                if (isClosedDeadline)
                                                  const Row(
                                                    children: [
                                                      Icon(
                                                          Icons.lock_outline,
                                                          color: Colors.red,
                                                          size: 14),
                                                      SizedBox(width: 4),
                                                      Text(
                                                          "ปิดรับงานแล้ว",
                                                          style: TextStyle(
                                                              color: Colors.red,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Text(task.title,
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(task.subject,
                                                style: const TextStyle(
                                                    color:
                                                        Colors.blueGrey,
                                                    fontSize: 13)),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                const Icon(
                                                    Icons
                                                        .access_time,
                                                    size: 14,
                                                    color: Colors
                                                        .blueAccent),
                                                const SizedBox(width: 5),
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
                        }).toList(),
                      ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
