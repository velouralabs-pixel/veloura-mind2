import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color cream = Color(0xFFFAF8F3);
const Color sage = Color(0xFF7FAF8B);
const Color darkText = Color(0xFF2F3A35);
const Color softText = Color(0xFF6F7A73);
const Color borderColor = Color(0xFFE5E0D6);
const Color disabledColor = Color(0xFFD8DED8);

void main() {
  runApp(const VelouraMindApp());
}

class VelouraMindApp extends StatelessWidget {
  const VelouraMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veloura Mind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(seedColor: sage),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class PlanData {
  final List<String> topThree;
  final List<String> laterThisWeek;
  final List<String> delegate;
  final List<String> letGo;
  final String smallWin;

  const PlanData({
    required this.topThree,
    required this.laterThisWeek,
    required this.delegate,
    required this.letGo,
    required this.smallWin,
  });
}

class LastSession {
  final String mood;
  final String energy;
  final String focus;
  final String brainDumpText;

  const LastSession({
    required this.mood,
    required this.energy,
    required this.focus,
    required this.brainDumpText,
  });
}

class LocalHistoryService {
  static const String moodKey = 'last_mood';
  static const String energyKey = 'last_energy';
  static const String focusKey = 'last_focus';
  static const String brainDumpKey = 'last_brain_dump';

  static Future<void> saveSession({
    required String mood,
    required String energy,
    required String focus,
    required String brainDumpText,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(moodKey, mood);
    await prefs.setString(energyKey, energy);
    await prefs.setString(focusKey, focus);
    await prefs.setString(brainDumpKey, brainDumpText);
  }

  static Future<LastSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    final mood = prefs.getString(moodKey);
    final energy = prefs.getString(energyKey);
    final focus = prefs.getString(focusKey);
    final brainDumpText = prefs.getString(brainDumpKey);

    if (mood == null ||
        energy == null ||
        focus == null ||
        brainDumpText == null ||
        brainDumpText.trim().isEmpty) {
      return null;
    }

    return LastSession(
      mood: mood,
      energy: energy,
      focus: focus,
      brainDumpText: brainDumpText,
    );
  }
}

class SmartPlanService {
  static PlanData buildPlan({
    required String brainDumpText,
    required String mood,
    required String energy,
    required String focus,
  }) {
    final tasks = brainDumpText
        .split(RegExp(r'[\n,;]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    if (tasks.isEmpty) {
      return const PlanData(
        topThree: ['Write one thing that feels important today'],
        laterThisWeek: ['Come back later and add more tasks'],
        delegate: ['Ask for help if one task feels too heavy'],
        letGo: ['You do not need to solve everything at once'],
        smallWin: 'Take one small step for five minutes.',
      );
    }

    final scored = tasks.map((task) {
      return _ScoredTask(task, _scoreTask(task, mood, energy, focus));
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final topThree = scored.take(3).map((item) => item.title).toList();
    final topSet = topThree.toSet();

    final laterThisWeek = tasks
        .where((task) => !topSet.contains(task))
        .where((task) => !_isDelegatable(task))
        .take(5)
        .toList();

    final delegate = tasks
        .where((task) => !topSet.contains(task))
        .where(_isDelegatable)
        .take(3)
        .toList();

    return PlanData(
      topThree: topThree,
      laterThisWeek: laterThisWeek.isEmpty
          ? ['No extra tasks for this week yet']
          : laterThisWeek,
      delegate: delegate.isEmpty
          ? ['Ask someone for help with one home or family task if possible']
          : delegate,
      letGo: [
        energy == 'Low'
            ? 'Anything that is not urgent can wait until your energy is better.'
            : 'You do not need to complete every task today.',
      ],
      smallWin: _findSmallWin(tasks),
    );
  }

  static int _scoreTask(
    String task,
    String mood,
    String energy,
    String focus,
  ) {
    final lower = task.toLowerCase();
    int score = 0;

    final urgentWords = [
      'pay',
      'bill',
      'rent',
      'doctor',
      'appointment',
      'call',
      'finish',
      'presentation',
      'due',
      'school',
      'work',
      'medicine',
      'insurance',
      'email',
      'phone',
      'meeting',
      'kids',
    ];

    for (final word in urgentWords) {
      if (lower.contains(word)) {
        score += 3;
      }
    }

    if (focus == 'Money' &&
        (lower.contains('pay') ||
            lower.contains('bill') ||
            lower.contains('rent') ||
            lower.contains('phone'))) {
      score += 4;
    }

    if (focus == 'Health' &&
        (lower.contains('doctor') ||
            lower.contains('medicine') ||
            lower.contains('appointment'))) {
      score += 4;
    }

    if (focus == 'Work' &&
        (lower.contains('work') ||
            lower.contains('presentation') ||
            lower.contains('email') ||
            lower.contains('meeting'))) {
      score += 4;
    }

    if (focus == 'Family' &&
        (lower.contains('kids') ||
            lower.contains('child') ||
            lower.contains('school') ||
            lower.contains('family'))) {
      score += 4;
    }

    if (mood == 'Overwhelmed' || energy == 'Low') {
      if (lower.contains('laundry') ||
          lower.contains('clean') ||
          lower.contains('organize')) {
        score -= 2;
      }
    }

    return score;
  }

  static bool _isDelegatable(String task) {
    final lower = task.toLowerCase();

    return lower.contains('groceries') ||
        lower.contains('laundry') ||
        lower.contains('clean') ||
        lower.contains('pick up') ||
        lower.contains('kids') ||
        lower.contains('home') ||
        lower.contains('organize');
  }

  static String _findSmallWin(List<String> tasks) {
    for (final task in tasks) {
      final lower = task.toLowerCase();

      if (lower.contains('call')) {
        return 'Make one quick phone call.';
      }

      if (lower.contains('pay')) {
        return 'Pay one bill or set a reminder for it.';
      }

      if (lower.contains('laundry')) {
        return 'Start one small load of laundry.';
      }

      if (lower.contains('email')) {
        return 'Send or answer one important email.';
      }
    }

    return 'Spend five minutes starting the easiest task.';
  }
}

class _ScoredTask {
  final String title;
  final int score;

  const _ScoredTask(this.title, this.score);
}

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.maxWidth > 430 ? 430.0 : constraints.maxWidth;

          return Center(
            child: SizedBox(
              width: width,
              height: constraints.maxHeight,
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: sage.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🌿', style: TextStyle(fontSize: 52)),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Veloura Mind',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'From Overwhelmed\nto Organized',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Clear your mind, organize your day,\nand feel more in control.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: softText,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Get Started',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainNavigationScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              const ContinueLastPlanButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int selectedIndex = 0;

  void changeTab(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeDashboardContent(),
      const ResetTabContent(),
      const HistoryTabContent(),
      const ProfileTabContent(),
    ];

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(child: pages[selectedIndex]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: borderColor),
                ),
              ),
              child: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: changeTab,
                backgroundColor: Colors.white,
                indicatorColor: sage.withValues(alpha: 0.18),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.refresh_outlined),
                    selectedIcon: Icon(Icons.refresh),
                    label: 'Reset',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.history_outlined),
                    selectedIcon: Icon(Icons.history),
                    label: 'History',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContinueLastPlanButton extends StatelessWidget {
  const ContinueLastPlanButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LastSession?>(
      future: LocalHistoryService.loadSession(),
      builder: (context, snapshot) {
        final session = snapshot.data;

        if (session == null) {
          return const SizedBox.shrink();
        }

        return TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => YourPlanScreen(
                  mood: session.mood,
                  energy: session.energy,
                  focus: session.focus,
                  brainDumpText: session.brainDumpText,
                ),
              ),
            );
          },
          child: const Text(
            'Continue Last Plan',
            style: TextStyle(
              color: darkText,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

class HomeDashboardContent extends StatelessWidget {
  const HomeDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: FutureBuilder<LastSession?>(
        future: LocalHistoryService.loadSession(),
        builder: (context, snapshot) {
          final session = snapshot.data;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Good morning, Primene 🌿',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Let’s create a lighter, calmer day.',
                style: TextStyle(fontSize: 16, color: softText),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Today’s Focus',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkText,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              session == null
                                  ? 'Start a reset to find your focus for today.'
                                  : 'Last focus: ${session.focus}',
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: softText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkText,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DashboardAction(
                              icon: '🌅',
                              title: 'Start New Reset',
                              subtitle:
                                  'Check in with your mood, energy, and focus.',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MorningResetScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            DashboardAction(
                              icon: '🧠',
                              title: 'Quick Brain Dump',
                              subtitle:
                                  'Empty your mind fast and organize later.',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const BrainDumpScreen(
                                      mood: 'Okay',
                                      energy: 'Medium',
                                      focus: 'Personal',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            DashboardAction(
                              icon: '✨',
                              title: 'Continue Last Plan',
                              subtitle: session == null
                                  ? 'No saved plan yet.'
                                  : 'Open your last saved plan.',
                              onTap: session == null
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => YourPlanScreen(
                                            mood: session.mood,
                                            energy: session.energy,
                                            focus: session.focus,
                                            brainDumpText:
                                                session.brainDumpText,
                                          ),
                                        ),
                                      );
                                    },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      AppCard(
                        child: const Text(
                          'Small reminder: you do not need to fix everything today. Start with one clear step.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Start New Reset',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MorningResetScreen(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class ResetTabContent extends StatelessWidget {
  const ResetTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            'Reset Center 🌿',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose how you want to clear your mind today.',
            style: TextStyle(fontSize: 16, color: softText),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              children: [
                DashboardAction(
                  icon: '🌅',
                  title: 'Guided Morning Reset',
                  subtitle: 'Mood, energy, focus, brain dump, and plan.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MorningResetScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                DashboardAction(
                  icon: '🧠',
                  title: 'Quick Brain Dump',
                  subtitle: 'Skip the check-in and empty your mind now.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BrainDumpScreen(
                          mood: 'Okay',
                          energy: 'Medium',
                          focus: 'Personal',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: const Text(
              'Best for overwhelmed days: start with the guided reset. Best for busy days: use quick brain dump.',
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryTabContent extends StatelessWidget {
  const HistoryTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: FutureBuilder<LastSession?>(
        future: LocalHistoryService.loadSession(),
        builder: (context, snapshot) {
          final session = snapshot.data;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'History 📚',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your most recent saved reset.',
                style: TextStyle(fontSize: 16, color: softText),
              ),
              const SizedBox(height: 24),
              if (session == null)
                AppCard(
                  child: const Text(
                    'No saved history yet. Complete one Brain Dump and your last plan will show here.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: softText,
                    ),
                  ),
                )
              else ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Saved Plan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InfoChip(label: 'Mood: ${session.mood}'),
                      const SizedBox(height: 8),
                      InfoChip(label: 'Energy: ${session.energy}'),
                      const SizedBox(height: 8),
                      InfoChip(label: 'Focus: ${session.focus}'),
                      const SizedBox(height: 16),
                      const Text(
                        'Brain Dump',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        session.brainDumpText,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: softText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: 'Open Last Plan',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => YourPlanScreen(
                          mood: session.mood,
                          energy: session.energy,
                          focus: session.focus,
                          brainDumpText: session.brainDumpText,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class ProfileTabContent extends StatelessWidget {
  const ProfileTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            'Profile 👤',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your Veloura Mind settings.',
            style: TextStyle(fontSize: 16, color: softText),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Primene',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Goal: turn overwhelm into calm daily action.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: softText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              children: const [
                ProfileRow(
                  icon: '🌿',
                  title: 'App Version',
                  value: 'MVP 1.0',
                ),
                SizedBox(height: 14),
                ProfileRow(
                  icon: '💾',
                  title: 'Storage',
                  value: 'Local history enabled',
                ),
                SizedBox(height: 14),
                ProfileRow(
                  icon: '✨',
                  title: 'AI Plan',
                  value: 'Smart sorting enabled',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileRow extends StatelessWidget {
  final String icon;
  final String title;
  final String value;

  const ProfileRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: softText,
          ),
        ),
      ],
    );
  }
}

class DashboardAction extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const DashboardAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDisabled ? const Color(0xFFE7EEE7) : cream,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDisabled ? const Color(0xFF9A9A9A) : darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: isDisabled ? const Color(0xFF9A9A9A) : softText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDisabled ? const Color(0xFFB8B8B8) : sage,
            ),
          ],
        ),
      ),
    );
  }
}

class MorningResetScreen extends StatefulWidget {
  const MorningResetScreen({super.key});

  @override
  State<MorningResetScreen> createState() => _MorningResetScreenState();
}

class _MorningResetScreenState extends State<MorningResetScreen> {
  String? selectedMood;
  String? selectedEnergy;
  String? selectedFocus;

  final List<List<String>> moods = const [
    ['😊', 'Great'],
    ['🙂', 'Good'],
    ['😐', 'Okay'],
    ['😔', 'Tired'],
    ['😣', 'Overwhelmed'],
  ];

  final List<List<String>> energies = const [
    ['⚡', 'High'],
    ['🔋', 'Medium'],
    ['🪫', 'Low'],
  ];

  final List<List<String>> focuses = const [
    ['💼', 'Work'],
    ['👨‍👩‍👧', 'Family'],
    ['❤️', 'Health'],
    ['💵', 'Money'],
    ['🌿', 'Personal'],
    ['✨', 'Other'],
  ];

  bool get canContinue =>
      selectedMood != null && selectedEnergy != null && selectedFocus != null;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackButton(
                color: darkText,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
              const Text(
                'Good Morning 🌿',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Let's make today feel lighter.",
                style: TextStyle(fontSize: 16, color: softText),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      QuestionCard(
                        title: '1. How are you feeling today?',
                        children: moods.map((item) {
                          return ChoiceItem(
                            emoji: item[0],
                            label: item[1],
                            isSelected: selectedMood == item[1],
                            onTap: () {
                              setState(() {
                                selectedMood = item[1];
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      QuestionCard(
                        title: "2. What's your energy level?",
                        children: energies.map((item) {
                          return ChoiceItem(
                            emoji: item[0],
                            label: item[1],
                            isSelected: selectedEnergy == item[1],
                            onTap: () {
                              setState(() {
                                selectedEnergy = item[1];
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      QuestionCard(
                        title: "3. What's most important today?",
                        children: focuses.map((item) {
                          return ChoiceItem(
                            emoji: item[0],
                            label: item[1],
                            isSelected: selectedFocus == item[1],
                            onTap: () {
                              setState(() {
                                selectedFocus = item[1];
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              PrimaryButton(
                text: 'Build My Day',
                enabled: canContinue,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BrainDumpScreen(
                        mood: selectedMood!,
                        energy: selectedEnergy!,
                        focus: selectedFocus!,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BrainDumpScreen extends StatefulWidget {
  final String mood;
  final String energy;
  final String focus;

  const BrainDumpScreen({
    super.key,
    required this.mood,
    required this.energy,
    required this.focus,
  });

  @override
  State<BrainDumpScreen> createState() => _BrainDumpScreenState();
}

class _BrainDumpScreenState extends State<BrainDumpScreen> {
  final TextEditingController controller = TextEditingController();

  bool get hasText => controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void goToThinkingScreen() {
    final text = controller.text.trim();

    LocalHistoryService.saveSession(
      mood: widget.mood,
      energy: widget.energy,
      focus: widget.focus,
      brainDumpText: text,
    ).then((_) {
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AIThinkingScreen(
            mood: widget.mood,
            energy: widget.energy,
            focus: widget.focus,
            brainDumpText: text,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackButton(
                color: darkText,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
              const Text(
                "What's on your mind?",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Write everything. Don't organize it. Just empty your mind.",
                style: TextStyle(fontSize: 16, color: softText),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InfoChip(label: 'Mood: ${widget.mood}'),
                  InfoChip(label: 'Energy: ${widget.energy}'),
                  InfoChip(label: 'Focus: ${widget.focus}'),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: controller,
                    onChanged: (_) => setState(() {}),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText:
                          'Example:\nPay electric bill\nCall doctor\nLaundry\nGroceries\nFinish presentation...',
                      hintStyle: TextStyle(color: Color(0xFF9A9A9A)),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: darkText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                text: '✨ Reset My Mind',
                enabled: hasText,
                onPressed: goToThinkingScreen,
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Save Draft',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AIThinkingScreen extends StatefulWidget {
  final String mood;
  final String energy;
  final String focus;
  final String brainDumpText;

  const AIThinkingScreen({
    super.key,
    required this.mood,
    required this.energy,
    required this.focus,
    required this.brainDumpText,
  });

  @override
  State<AIThinkingScreen> createState() => _AIThinkingScreenState();
}

class _AIThinkingScreenState extends State<AIThinkingScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => YourPlanScreen(
            mood: widget.mood,
            energy: widget.energy,
            focus: widget.focus,
            brainDumpText: widget.brainDumpText,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: const [
              Spacer(),
              Text('🌿', style: TextStyle(fontSize: 76)),
              SizedBox(height: 30),
              Text(
                'Understanding your day...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Veloura Mind is finding what matters most.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: softText,
                ),
              ),
              SizedBox(height: 32),
              ThinkingStep(text: 'Reading your thoughts'),
              ThinkingStep(text: 'Checking your mood and energy'),
              ThinkingStep(text: 'Choosing your top priorities'),
              ThinkingStep(text: 'Building your calm plan'),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class YourPlanScreen extends StatelessWidget {
  final String mood;
  final String energy;
  final String focus;
  final String brainDumpText;

  const YourPlanScreen({
    super.key,
    required this.mood,
    required this.energy,
    required this.focus,
    required this.brainDumpText,
  });

  @override
  Widget build(BuildContext context) {
    final plan = SmartPlanService.buildPlan(
      brainDumpText: brainDumpText,
      mood: mood,
      energy: energy,
      focus: focus,
    );

    return AppShell(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackButton(
                color: darkText,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
              const Text(
                "Here's your plan ✨",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mood: $mood • Energy: $energy • Focus: $focus',
                style: const TextStyle(
                  fontSize: 14,
                  color: softText,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      PlanCard(
                        icon: '⭐',
                        title: "Today's Top 3",
                        items: plan.topThree,
                      ),
                      const SizedBox(height: 14),
                      PlanCard(
                        icon: '📅',
                        title: 'Later This Week',
                        items: plan.laterThisWeek,
                      ),
                      const SizedBox(height: 14),
                      PlanCard(
                        icon: '🤝',
                        title: 'Delegate',
                        items: plan.delegate,
                      ),
                      const SizedBox(height: 14),
                      PlanCard(
                        icon: '🌿',
                        title: 'Let Go For Now',
                        items: plan.letGo,
                      ),
                      const SizedBox(height: 14),
                      PlanCard(
                        icon: '🏆',
                        title: 'One Small Win',
                        items: [plan.smallWin],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Start My Day',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlannerScreen(tasks: plan.topThree),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlannerScreen extends StatefulWidget {
  final List<String> tasks;

  const PlannerScreen({
    super.key,
    required this.tasks,
  });

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  late List<bool> completed;

  @override
  void initState() {
    super.initState();
    completed = List.generate(widget.tasks.length, (_) => false);
  }

  int get completedCount => completed.where((task) => task).length;

  double get progress {
    if (completed.isEmpty) return 0;
    return completedCount / completed.length;
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackButton(
                color: darkText,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
              const Text(
                "Today's Planner 📅",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Focus on your top three. One step at a time.',
                style: TextStyle(fontSize: 16, color: softText),
              ),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(99),
                      backgroundColor: const Color(0xFFE7EEE7),
                      color: sage,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$completedCount of ${completed.length} tasks completed',
                      style: const TextStyle(
                        fontSize: 14,
                        color: softText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.tasks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return AppCard(
                      child: Row(
                        children: [
                          Checkbox(
                            value: completed[index],
                            activeColor: sage,
                            onChanged: (value) {
                              setState(() {
                                completed[index] = value ?? false;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.tasks[index],
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: darkText,
                                decoration: completed[index]
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Complete Day',
                enabled: completedCount > 0,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EveningReflectionScreen(
                        completedCount: completedCount,
                        totalTasks: completed.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EveningReflectionScreen extends StatefulWidget {
  final int completedCount;
  final int totalTasks;

  const EveningReflectionScreen({
    super.key,
    required this.completedCount,
    required this.totalTasks,
  });

  @override
  State<EveningReflectionScreen> createState() =>
      _EveningReflectionScreenState();
}

class _EveningReflectionScreenState extends State<EveningReflectionScreen> {
  final TextEditingController wentWellController = TextEditingController();
  final TextEditingController challengeController = TextEditingController();
  final TextEditingController tomorrowController = TextEditingController();

  bool get canFinish =>
      wentWellController.text.trim().isNotEmpty &&
      challengeController.text.trim().isNotEmpty &&
      tomorrowController.text.trim().isNotEmpty;

  @override
  void dispose() {
    wentWellController.dispose();
    challengeController.dispose();
    tomorrowController.dispose();
    super.dispose();
  }

  Widget reflectionQuestion({
    required String number,
    required String title,
    required String hint,
    required TextEditingController controller,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. $title',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9A9A9A)),
              filled: true,
              fillColor: cream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: sage,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackButton(
                color: darkText,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
              const Text(
                "Evening Reflection 🌙",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You completed ${widget.completedCount} of ${widget.totalTasks} top tasks today.',
                style: const TextStyle(
                  fontSize: 16,
                  color: softText,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      reflectionQuestion(
                        number: '1',
                        title: 'What went well today?',
                        hint: 'Example: I finished my most important task.',
                        controller: wentWellController,
                      ),
                      const SizedBox(height: 16),
                      reflectionQuestion(
                        number: '2',
                        title: 'What challenged you today?',
                        hint: 'Example: I felt tired in the afternoon.',
                        controller: challengeController,
                      ),
                      const SizedBox(height: 16),
                      reflectionQuestion(
                        number: '3',
                        title: 'What should tomorrow begin with?',
                        hint: 'Example: Start with the doctor call.',
                        controller: tomorrowController,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Finish Day',
                enabled: canFinish,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DayCompleteScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DayCompleteScreen extends StatelessWidget {
  const DayCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              const Text('🌿', style: TextStyle(fontSize: 78)),
              const SizedBox(height: 24),
              const Text(
                'Day Complete',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'You showed up for yourself today.\nThat matters.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.4,
                  color: softText,
                ),
              ),
              const SizedBox(height: 28),
              AppCard(
                child: const Text(
                  "Tomorrow, we'll help you begin again with clarity and calm.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: darkText,
                  ),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Back to Home',
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainNavigationScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool enabled;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: sage,
          disabledBackgroundColor: disabledColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class QuestionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const QuestionCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: children,
          ),
        ],
      ),
    );
  }
}

class ChoiceItem extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const ChoiceItem({
    super.key,
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 98,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? sage.withValues(alpha: 0.18) : cream,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? sage : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 27)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final String label;

  const InfoChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: sage.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: darkText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ThinkingStep extends StatelessWidget {
  final String text;

  const ThinkingStep({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: sage),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlanCard extends StatelessWidget {
  final String icon;
  final String title;
  final List<String> items;

  const PlanCard({
    super.key,
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$icon  $title',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 18,
                      color: sage,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: darkText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;

  const AppCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}