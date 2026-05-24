import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/notification_service.dart';

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
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0E1B2F),
          selectedItemColor: Colors.cyanAccent,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const MainShell(),
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

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const String _statusKey = 'routine_statuses_v1';
  static const String _bestScoreKey = 'best_score_v1';
  static const String _streakKey = 'current_streak_v1';
  static const String _onboardingKey = 'onboarding_summary_v1';

  int selectedIndex = 0;
  int bestScore = 0;
  int streakDays = 0;
  bool loaded = false;
  String onboardingSummary = 'Not prepared yet';

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
      message: 'Track expenses and avoid impulse decisions.',
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

  @override
  void initState() {
    super.initState();
    NotificationService.init();
    _loadSavedProgress();
  }

  Future<void> _loadSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStatuses = prefs.getStringList(_statusKey);
    if (savedStatuses != null && savedStatuses.length == routines.length) {
      for (var i = 0; i < savedStatuses.length; i++) {
        final index = int.tryParse(savedStatuses[i]) ?? 0;
        routines[i].status = RoutineStatus.values[index.clamp(0, RoutineStatus.values.length - 1)];
      }
    }
    setState(() {
      bestScore = prefs.getInt(_bestScoreKey) ?? disciplineScore;
      streakDays = prefs.getInt(_streakKey) ?? 0;
      onboardingSummary = prefs.getString(_onboardingKey) ?? 'Not prepared yet';
      loaded = true;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _statusKey,
      routines.map((item) => item.status.index.toString()).toList(),
    );
    if (disciplineScore > bestScore) {
      bestScore = disciplineScore;
      await prefs.setInt(_bestScoreKey, bestScore);
    }
    final allTrackedAccepted = trackedCount > 0 && acceptedCount == trackedCount;
    if (allTrackedAccepted) {
      streakDays = streakDays == 0 ? 1 : streakDays;
      await prefs.setInt(_streakKey, streakDays);
    }
  }

  Future<void> saveOnboardingSummary(String summary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_onboardingKey, summary);
    setState(() {
      onboardingSummary = summary;
    });
  }

  void updateRoutineStatus(int index, RoutineStatus status) {
    setState(() {
      routines[index].status = status;
    });
    _saveProgress();
  }

  void resetDay() {
    setState(() {
      for (final item in routines) {
        item.status = RoutineStatus.pending;
      }
    });
    _saveProgress();
  }

  Future<void> testReminder(BuildContext context, RoutineItem item) async {
    await NotificationService.showReminderNow(
      title: 'Discipline Mirror: ${item.title}',
      body: '${item.time} • ${item.message}',
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Test reminder sent for ${item.title}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        loaded: loaded,
        routines: routines,
        score: disciplineScore,
        completed: acceptedCount,
        total: trackedCount,
        focusMessage: focusMessage,
        accepted: acceptedCount,
        skipped: skippedCount,
        muted: mutedCount,
        onAccept: (index) => updateRoutineStatus(index, RoutineStatus.accepted),
        onSkip: (index) => updateRoutineStatus(index, RoutineStatus.skipped),
        onMute: (index) => updateRoutineStatus(index, RoutineStatus.muted),
      ),
      RemindersPage(
        routines: routines,
        onTestReminder: (item) => testReminder(context, item),
      ),
      ProgressPage(
        score: disciplineScore,
        bestScore: bestScore,
        streakDays: streakDays,
        accepted: acceptedCount,
        skipped: skippedCount,
        muted: mutedCount,
      ),
      GoalsPage(
        onboardingSummary: onboardingSummary,
        onSaveSummary: saveOnboardingSummary,
      ),
      const AiPlanPage(),
    ];

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
      body: SafeArea(child: pages[selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => setState(() => selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active), label: 'Remind'),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Goals'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'AI Plan'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.loaded,
    required this.routines,
    required this.score,
    required this.completed,
    required this.total,
    required this.focusMessage,
    required this.accepted,
    required this.skipped,
    required this.muted,
    required this.onAccept,
    required this.onSkip,
    required this.onMute,
  });

  final bool loaded;
  final List<RoutineItem> routines;
  final int score;
  final int completed;
  final int total;
  final String focusMessage;
  final int accepted;
  final int skipped;
  final int muted;
  final ValueChanged<int> onAccept;
  final ValueChanged<int> onSkip;
  final ValueChanged<int> onMute;

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeaderCard(score: score, completed: completed, total: total, focusMessage: focusMessage),
        const SizedBox(height: 18),
        const Text('Today Routine', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...List.generate(
          routines.length,
          (index) => RoutineCard(
            item: routines[index],
            onAccept: () => onAccept(index),
            onSkip: () => onSkip(index),
            onMute: () => onMute(index),
          ),
        ),
        SummaryCard(accepted: accepted, skipped: skipped, muted: muted),
        const SizedBox(height: 24),
      ],
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
          const Text('Good Evening, Sreekanth', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(focusMessage, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$score%', style: const TextStyle(fontSize: 52, color: Colors.cyanAccent, fontWeight: FontWeight.w900)),
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
  const ActionPill({super.key, required this.label, required this.icon, required this.color, required this.onTap});

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

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key, required this.routines, required this.onTestReminder});

  final List<RoutineItem> routines;
  final ValueChanged<RoutineItem> onTestReminder;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Reminder Engine', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text(
          'Sprint 3 foundation: test local reminders now. Scheduling and snooze come next.',
          style: TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 16),
        ...routines.map(
          (item) => ReminderTile(item: item, onTest: () => onTestReminder(item)),
        ),
      ],
    );
  }
}

class ReminderTile extends StatelessWidget {
  const ReminderTile({super.key, required this.item, required this.onTest});

  final RoutineItem item;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0E1B2F), borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          Icon(item.icon, color: Colors.cyanAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('${item.time} - ${item.message}', style: const TextStyle(fontSize: 12, color: Colors.white60)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTest,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            child: const Text('Test'),
          ),
        ],
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

class ProgressPage extends StatelessWidget {
  const ProgressPage({
    super.key,
    required this.score,
    required this.bestScore,
    required this.streakDays,
    required this.accepted,
    required this.skipped,
    required this.muted,
  });

  final int score;
  final int bestScore;
  final int streakDays;
  final int accepted;
  final int skipped;
  final int muted;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Progress Command Center', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        MetricTile(title: 'Today Score', value: '$score%', icon: Icons.speed, color: Colors.cyanAccent),
        MetricTile(title: 'Best Score', value: '$bestScore%', icon: Icons.emoji_events, color: Colors.amberAccent),
        MetricTile(title: 'Current Streak', value: '$streakDays day', icon: Icons.local_fire_department, color: Colors.orangeAccent),
        const SizedBox(height: 12),
        SummaryCard(accepted: accepted, skipped: skipped, muted: muted),
      ],
    );
  }
}

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key, required this.onboardingSummary, required this.onSaveSummary});

  final String onboardingSummary;
  final ValueChanged<String> onSaveSummary;

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final TextEditingController situationController = TextEditingController();
  final TextEditingController ambitionController = TextEditingController();

  @override
  void dispose() {
    situationController.dispose();
    ambitionController.dispose();
    super.dispose();
  }

  void save() {
    final situation = situationController.text.trim();
    final ambition = ambitionController.text.trim();
    if (situation.isEmpty && ambition.isEmpty) return;
    widget.onSaveSummary('Current: ${situation.isEmpty ? 'Not provided' : situation}\nGoal: ${ambition.isEmpty ? 'Not provided' : ambition}');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Onboarding summary saved')));
  }

  @override
  Widget build(BuildContext context) {
    final goals = [
      ('Health', 'Daily exercise and better food discipline', Icons.favorite, Colors.greenAccent),
      ('AI Enabler', 'Become AI transformation leader for the team', Icons.psychology, Colors.cyanAccent),
      ('SCM Domain', 'Build CPIM and supply chain planning foundation', Icons.account_tree, Colors.blueAccent),
      ('Finance', 'Track money and build long-term stability', Icons.savings, Colors.amberAccent),
      ('Family', 'Be present and emotionally available', Icons.family_restroom, Colors.pinkAccent),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Transformation Goals', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        ...goals.map((goal) => GoalTile(title: goal.$1, subtitle: goal.$2, icon: goal.$3, color: goal.$4)),
        const SizedBox(height: 16),
        const Text('Onboarding Foundation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        TextField(
          controller: situationController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'What are you going through now?',
            filled: true,
            fillColor: Color(0xFF0E1B2F),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: ambitionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'What do you want to become?',
            filled: true,
            fillColor: Color(0xFF0E1B2F),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: save, child: const Text('Save Onboarding Summary')),
        const SizedBox(height: 12),
        InfoPanel(title: 'Saved Summary', body: widget.onboardingSummary),
      ],
    );
  }
}

class AiPlanPage extends StatelessWidget {
  const AiPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('AI Plan Builder', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        SizedBox(height: 16),
        InfoPanel(
          title: 'Sprint 3 Foundation',
          body: 'This screen will later connect to OpenAI-compatible models. For MVP, we first capture user goals, generate local routine suggestions, and keep AI optional to control cost.',
        ),
        SizedBox(height: 12),
        InfoPanel(
          title: 'Planned AI Output',
          body: 'Daily plan, weekly structure, emotional reminders, SCM/CPIM learning plan, AI enabler roadmap, finance discipline plan and family presence routine.',
        ),
        SizedBox(height: 12),
        InfoPanel(
          title: 'Privacy Direction',
          body: 'User controls what is shared. AI analysis is optional. Personal images and calendar integrations will require explicit consent later.',
        ),
      ],
    );
  }
}

class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0E1B2F), borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(color: Colors.white60, height: 1.4)),
        ],
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.title, required this.value, required this.icon, required this.color});

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0E1B2F), borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          Text(value, style: TextStyle(fontSize: 22, color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class GoalTile extends StatelessWidget {
  const GoalTile({super.key, required this.title, required this.subtitle, required this.icon, required this.color});

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0E1B2F), borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white60)),
              ],
            ),
          ),
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
