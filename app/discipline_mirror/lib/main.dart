import 'package:flutter/material.dart';

void main() {
  runApp(const DisciplineMirrorApp());
}

class DisciplineMirrorApp extends StatelessWidget {
  const DisciplineMirrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Discipline Mirror',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF07111F),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Discipline Mirror"),
        backgroundColor: const Color(0xFF0E1B2F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildRoutineCard(
              title: "Morning Exercise",
              time: "5:45 AM",
              icon: Icons.fitness_center,
            ),
            _buildRoutineCard(
              title: "AI + SCM Learning",
              time: "6:30 AM",
              icon: Icons.psychology,
            ),
            _buildRoutineCard(
              title: "Family Time",
              time: "7:00 PM",
              icon: Icons.family_restroom,
            ),
            _buildRoutineCard(
              title: "Financial Review",
              time: "9:00 PM",
              icon: Icons.account_balance_wallet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13243D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Good Evening, Sreekanth 👋",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Today's Discipline Score",
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 10),
          Text(
            "78%",
            style: TextStyle(
              fontSize: 42,
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard({
    required String title,
    required String time,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1B2F),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.cyanAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                time,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text("Accept"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text("Skip"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text("Mute"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}