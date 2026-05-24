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
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0E1B2F),
          elevation: 0,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

enum RoutineStatus { pending, accepted, skipped, muted }

class RoutineItem {
  RoutineItem({
    required this.title,
    required this.time,
    required this.category,
    required this.icon,
    required this.message,
    this.status = RoutineStatus.pending,
  });

  final String title;
  final String time;
  final String category;
  final IconData icon;
  final String message;
  RoutineStatus status;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<RoutineItem> routines = [
    RoutineItem(
      title: 'Morning Exercise',
      time: '5:45 AM',
      category: 'Health',
      icon: Icons.fitness_center,
      message: 'Build energy before the day starts.',
    ),
    RoutineItem(
      title: 'AI + SCM Learning',
      time: '6:30 AM',
      category: 'Career',
      icon: Icons.psychology,
      message: 'AI enabler plus CPIM and SCM growth.',
    ),
    RoutineItem(
      title: 'Family Time',
      time: '7:00 PM',
      category: 'Family',
      icon: Icons.family_restroom,
      message: 'Be fully present with family.',
    ),
    RoutineItem(
      title: 'Financial Review',
      time: '9:00 PM',
      category: 'Finance',
      icon: Icons.account_balance_wallet,
      message: 'Track expense and avoid impulse decisions.',
    ),
  ];

  int get acceptedCount => routines.where((item) => item.status == RoutineStatus.accepted).length;
  int get skippedCount => routines.where((item) => item.status == RoutineStatus.skipped).length;
  int get mutedCount => routines.where((item) => item.status == RoutineStatus.muted).length;
  int get trackedCount => routines.where((item) => item.status != RoutineStatus.muted).length;

  int get disciplineScore {
    if (trackedCount == 0) return 0;
    return ((acceptedCount / trackedCount) * 100).round();
  }

  String get focusMessage {
    if (disciplineScore >= 80) return 'Strong day. Protect this momentum.';
    if (disciplineScore >= 50) return 'Good start. Complete one more routine.';
    return 'Start small. Accept the next right action.';
  }

  void updateRoutineStatus(int index, RoutineStatus status) {
    setState(() {
      routines[index].status = status;
    });
  }

  void resetDay() {
    setState(() {
      for (final item in routines) {
        item.status = RoutineStatus.pending;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discipline Mirror'),
        actions: [
          IconButton(
            onPressed: resetDay,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset day',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            HeaderCard(
              score: disciplineScore,
              completed: acceptedCount,
              total: trackedCount,
              focusMessage: focusMessage,
            ),
            const SizedBox(height: 18),
            const Text(
              'Today Routine',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              routines.length,
              (index) => RoutineCard(
                item: routines[index],
                onAccept: () => updateRoutineStatus(index, RoutineStatus.accepted),
                onSkip: () => updateRoutineStatus(index, RoutineStatus.skipped),
                onMute: () => updateRoutineStatus(index, RoutineStatus.muted),
              ),
            ),
            SummaryCard(accepted: acceptedCount, skipped: skippedCount, muted: mutedCount),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class HeaderCard extends StatelessWidget {
  const HeaderCard({
    super.key,
    required this.score,
    required this.completed,
    required this.total,
    required this.focusMessage,
  });

  final int score;
  final int completed;
  final int total;
  final String focusMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF13243D),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Good Evening, Sreekanth',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(focusMessage, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score%',
                style: const TextStyle(fontSize: 52, color: Colors.cyanAccent, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('$completed / $total completed', style: const TextStyle(color: Colors.white70)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : score / 100,
              minHeight: 9,
              backgroundColor: Colors.white12,
              color: Colors.cyanAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class RoutineCard extends StatelessWidget {
  const RoutineCard({
    super.key,
    required this.item,
    required this.onAccept,
    required this.onSkip,
    required this.onMute,
  });

  final RoutineItem item;
  final VoidCallback onAccept;
  final VoidCallback onSkip;
  final VoidCallback onMute;

  Color get statusColor {
    switch (item.status) {
      case RoutineStatus.accepted:
        return const Color(0xFF22C55E);
      case RoutineStatus.skipped:
        return const Color(0xFFF97316);
      case RoutineStatus.muted:
        return const Color(0xFF94A3B8);
      case RoutineStatus.pending:
        return const Color(0xFF38BDF8);
    }
  }

  String get statusText {
    switch (item.status) {
      case RoutineStatus.accepted:
        return 'Accepted';
      case RoutineStatus.skipped:
        return 'Skipped';
      case RoutineStatus.muted:
        return 'Muted';
      case RoutineStatus.pending:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1B2F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(color: statusColor.withOpacity(0.16), borderRadius: BorderRadius.circular(14)),
                child: Icon(item.icon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('${item.category} - ${item.message}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item.time, style: const TextStyle(color: Colors.white60)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.18), borderRadius: BorderRadius.circular(999)),
                    child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ActionPill(label: 'Accept', icon: Icons.check, color: const Color(0xFF22C55E), onTap: onAccept),
              const SizedBox(width: 8),
              ActionPill(label: 'Skip', icon: Icons.close, color: const Color(0xFFF97316), onTap: onSkip),
              const SizedBox(width: 8),
              ActionPill(label: 'Mute', icon: Icons.notifications_off, color: const Color(0xFF94A3B8), onTap: onMute),
            ],
          ),
        ],
      ),
    );
  }
}

class ActionPill extends StatelessWidget {
  const ActionPill({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 42,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 15),
          label: FittedBox(child: Text(label)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.accepted, required this.skipped, required this.muted});

  final int accepted;
  final int skipped;
  final int muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF101D31), borderRadius: BorderRadius.circular(22)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MiniMetric(label: 'Accepted', value: accepted, color: Colors.green),
          MiniMetric(label: 'Skipped', value: skipped, color: Colors.orange),
          MiniMetric(label: 'Muted', value: muted, color: Colors.grey),
        ],
      ),
    );
  }
}

class MiniMetric extends StatelessWidget {
  const MiniMetric({super.key, required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: Colors.white60)),
      ],
    );
  }
}
