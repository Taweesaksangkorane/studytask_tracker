import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Section ---
              _buildHeader(),
              const SizedBox(height: 20),
              
              // --- AI Suggestion Box ---
              _buildAISuggestion(),
              const SizedBox(height: 20),

              // --- Classroom Sync Bar ---
              _buildSyncBar(),
              const SizedBox(height: 25),

              // --- Search Bar ---
              _buildSearchBar(),
              const SizedBox(height: 25),

              // --- Stats Cards Row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard("ทั้งหมด", "2", Icons.grid_view_rounded, true),
                  _buildStatCard("ส่งแล้ว", "0", Icons.send_rounded, false),
                  _buildStatCard("ยังไม่ส่ง", "2", Icons.access_time_filled, false),
                ],
              ),
              const SizedBox(height: 30),

              // --- Latest Tasks Title ---
              const Text(
                "LATEST TASKS",
                style: TextStyle(color: Colors.blueGrey, letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              // --- Task List ---
              _buildTaskCard(
                title: "Mobile App Report",
                subtitle: "Mobile Application Development",
                date: "18 ก.พ. 69",
                time: "14:59",
                isOverdue: true,
              ),
              const SizedBox(height: 15),
              _buildTaskCard(
                title: "Homework 5: Logic Gates",
                subtitle: "Digital Systems",
                date: "21 ก.พ. 69",
                time: "14:59",
                isSynced: true,
              ),
              const SizedBox(height: 80), // เผื่อที่ให้ Floating Action Button
            ],
          ),
        ),
      ),
      // --- Bottom Navigation Bar ---
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blueAccent,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 35, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // --- Widget Helpers ---

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
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
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
      decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orange.withOpacity(0.1))),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text("ลุย Mobile App Report เริ่มวางแผนล่วงหน้าไว้ก่อนนะ สู้ๆ ครับ คนเก่งทำได้อยู่แล้ว!", style: TextStyle(fontSize: 12, color: Colors.brown)),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncBar() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withOpacity(0.05))),
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
            onPressed: () {},
            icon: const Icon(Icons.sync, size: 16),
            label: const Text("SYNC NOW", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.blueAccent, side: const BorderSide(color: Colors.blueAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
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

  Widget _buildTaskCard({required String title, required String subtitle, required String date, required String time, bool isOverdue = false, bool isSynced = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 6, decoration: const BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.only(topLeft: Radius.circular(25), bottomLeft: Radius.circular(25)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)), child: const Text("PENDING", style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold))),
                        if (isOverdue) const Row(children: [Icon(Icons.error_outline, color: Colors.redAccent, size: 14), SizedBox(width: 4), Text("OVERDUE", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold))]),
                        if (isSynced) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(5)), child: const Text("SYNCED", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: const TextStyle(color: Colors.blueGrey, fontSize: 14)),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.blueAccent),
                        const SizedBox(width: 5),
                        Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 15),
                        const Icon(Icons.access_time, size: 14, color: Colors.blueAccent),
                        const SizedBox(width: 5),
                        Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.home_filled, color: Colors.blueAccent), Text("หน้าหลัก", style: TextStyle(color: Colors.blueAccent, fontSize: 10))]),
          const SizedBox(width: 40), // Space for FAB
          Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.settings_outlined, color: Colors.grey), Text("ตั้งค่า", style: TextStyle(color: Colors.grey, fontSize: 10))]),
        ],
      ),
    );
  }
}