import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'task_detail_page.dart';
import 'settings_page.dart';
import 'new_task_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final TaskService taskService = TaskService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: StreamBuilder<List<TaskModel>>(
          stream: taskService.getTasks(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final tasks = snapshot.data ?? [];
            final total = tasks.length;
            final submitted = tasks.where((t) => t.status == TaskStatus.submitted).length;
            final pending = total - submitted;

            return SingleChildScrollView(
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
                  _buildSearchBar(),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard("ทั้งหมด", total.toString(), Icons.grid_view_rounded, true),
                      _buildStatCard("ส่งแล้ว", submitted.toString(), Icons.send_rounded, false),
                      _buildStatCard("ยังไม่ส่ง", pending.toString(), Icons.access_time_filled, false),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "LATEST TASKS",
                    style: TextStyle(color: Colors.blueGrey, letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  if (tasks.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text("ยังไม่มีงาน", style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ...tasks.map((task) {
                      final isOverdue = task.status == TaskStatus.pending && task.dueDate.isBefore(DateTime.now());
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: _buildTaskCard(context, task: task, isOverdue: isOverdue),
                      );
                    }).toList(),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewTaskPage())),
        backgroundColor: Colors.blueAccent,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 35, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(5)),
              child: const Text("STUDENT SPACE", style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 5),
            const Text("งานของคุณ", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1C2E))),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.05 * 255).round()), blurRadius: 10)]),
              child: const Icon(Icons.calendar_today_outlined, color: Colors.blueAccent),
            ),
            const SizedBox(width: 10),
            const CircleAvatar(radius: 25, backgroundImage: NetworkImage('https://placeholder.com/150')),
          ],
        )
      ],
    );
  }

  Widget _buildAISuggestion() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orange.withAlpha((0.1 * 255).round()))),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text("ลุย Mobile App Report เริ่มวางแผนล่วงหน้าไว้ก่อนนะ สู้ๆ ครับ คนเก่งทำได้อยู่แล้ว!", style: TextStyle(fontSize: 12, color: Colors.brown)),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withAlpha((0.05 * 255).round()))),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.school, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Classroom Sync", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("UPDATED AT 14:59", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing...')));
            },
            icon: const Icon(Icons.sync, size: 16),
            label: const Text("SYNC NOW", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: "ค้นหาวิชาหรือชื่อวิชา...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildStatCard(String label, String count, IconData icon, bool isActive) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: isActive ? Border.all(color: Colors.blueAccent, width: 2) : Border.all(color: Colors.transparent),
      ),
      child: Column(
        children: [
          Icon(icon, color: isActive ? Colors.blueAccent : Colors.orangeAccent),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, {required TaskModel task, bool isOverdue = false}) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailPage(task: task))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.black.withAlpha((0.05 * 255).round())),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: const BoxDecoration(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(25), bottomLeft: Radius.circular(25)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              task.status == TaskStatus.submitted ? "SUBMITTED" : "PENDING",
                              style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (isOverdue)
                            const Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.redAccent, size: 14),
                                SizedBox(width: 4),
                                Text("OVERDUE", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          if (task.status == TaskStatus.submitted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(5)),
                              child: const Text("SYNCED", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(task.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(task.subject, style: const TextStyle(color: Colors.blueGrey, fontSize: 14)),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.blueAccent),
                          const SizedBox(width: 5),
                          Text("${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(width: 15),
                          const Icon(Icons.access_time, size: 14, color: Colors.blueAccent),
                          const SizedBox(width: 5),
                          Text("${task.dueDate.hour.toString().padLeft(2, '0')}:${task.dueDate.minute.toString().padLeft(2, '0')}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () {},
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_filled, color: Colors.blueAccent),
                Text("หน้าหลัก", style: TextStyle(color: Colors.blueAccent, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 40),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_outlined, color: Colors.grey),
                Text("ตั้งค่า", style: TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
