import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_design.dart';
import '../data/training_api.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TrainingApi _api = TrainingApi(baseUrl: 'http://127.0.0.1:8000/api');

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _programs = _defaultPrograms;
  List<Map<String, dynamic>> _drills = _defaultDrills;
  List<Map<String, dynamic>> _challenges = _defaultChallenges;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _startProgram(Map<String, dynamic> program) async {
    try {
      final res = await _api.startSession(
        mode: 'PROGRAM',
        settings: {
          'program_id': program['id'],
          'title': program['title'],
          'level': program['level'],
        },
      );
      _showSnack('Program started (Session ${res['id']})');
    } catch (e) {
      _showSnack('Could not start program: $e', isError: true);
    }
  }

  Future<void> _startDrill(Map<String, dynamic> drill) async {
    try {
      final res = await _api.startSession(
        mode: 'DRILL',
        settings: {
          'drill_id': drill['id'],
          'title': drill['title'],
          'category': drill['category'],
        },
      );
      _showSnack('Drill started (Session ${res['id']})');
    } catch (e) {
      _showSnack('Could not start drill: $e', isError: true);
    }
  }

  Future<void> _startChallenge(Map<String, dynamic> challenge) async {
    try {
      final res = await _api.startSession(
        mode: 'CHALLENGE',
        settings: {
          'challenge_id': challenge['id'],
          'title': challenge['title'],
          'difficulty': challenge['difficulty'],
          'reward': challenge['reward'],
        },
      );
      _showSnack('Challenge started (Session ${res['id']})');
    } catch (e) {
      _showSnack('Could not start challenge: $e', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }

  Future<void> _loadContent() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final programs = await _api.fetchPrograms();
      final drills = await _api.fetchDrills();
      final challenges = await _api.fetchChallenges();
      setState(() {
        _programs = programs.isNotEmpty ? programs : _defaultPrograms;
        _drills = drills.isNotEmpty ? drills : _defaultDrills;
        _challenges = challenges.isNotEmpty ? challenges : _defaultChallenges;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Training content offline. Showing defaults.';
        _programs = _defaultPrograms;
        _drills = _defaultDrills;
        _challenges = _defaultChallenges;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.darkGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Training', style: AppTextStyles.headlineMedium),
                  ],
                ),
              ),
              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.bgCard.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                  border: Border.all(color: AppColors.bgLight.withOpacity(0.3)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Programs'),
                    Tab(text: 'Drills'),
                    Tab(text: 'Challenges'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(loading: _loading, error: _error, onRetry: _loadContent),
                    _ProgramsTab(
                      loading: _loading,
                      programs: _programs,
                      onStart: _startProgram,
                      onCustomize: _showSnack,
                    ),
                    _DrillsTab(
                      loading: _loading,
                      drills: _drills,
                      onStart: _startDrill,
                    ),
                    _ChallengesTab(
                      loading: _loading,
                      challenges: _challenges,
                      onStart: _startChallenge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final Future<void> Function() onRetry;

  const _OverviewTab({required this.loading, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (loading || error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: _Card(
              child: Row(
                children: [
                  Icon(
                    loading ? Icons.refresh : Icons.info_outline,
                    color: loading ? AppColors.primary : AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      loading
                          ? 'Syncing training content...'
                          : (error ?? 'Loaded defaults'),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  if (!loading)
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ),
          ),
        const _Section(
          title: 'Purpose',
          child: _Card(
            child: Text(
              'Oche180 Training is a structured, gamified program designed to build elite-level darting fundamentals: accuracy, consistency, checkout proficiency, pressure handling, and strategic decision making. Progress through curated programs, daily challenges, and performance tracking to unlock achievements and personal bests.',
              style: AppTextStyles.bodyLarge,
            ),
          ),
        ),
        const _Section(
          title: 'Structure',
          child: _Card(
            child: Text(
              'Training includes four pillars:\n\n• Accuracy & Grouping: Segment targeting, doubles, and treble drills\n• Checkout Mastery: Recommended finish routes, doubles confidence\n• Consistency & Endurance: Long-format 501 legs with pace and rhythm\n• Pressure & Simulation: Timed challenges, decider scenarios, and opponents\n\nEach pillar scales from Beginner → Intermediate → Advanced → Pro, with adaptive goals based on your performance.',
              style: AppTextStyles.bodyLarge,
            ),
          ),
        ),
        const _Section(
          title: 'Progression & Rewards',
          child: _Card(
            child: Text(
              'Earn XP by completing sessions, hit milestones (first 180, first 100 checkout), and claim badges. Weekly streaks and challenge tiers keep you motivated. Track personal bests and win-rate improvements over time.',
              style: AppTextStyles.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgramsTab extends StatelessWidget {
  final bool loading;
  final List<Map<String, dynamic>> programs;
  final Future<void> Function(Map<String, dynamic>) onStart;
  final void Function(String) onCustomize;

  const _ProgramsTab({
    required this.loading,
    required this.programs,
    required this.onStart,
    required this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),
        for (final p in programs)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['title'] ?? 'Program', style: AppTextStyles.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text('${p['level'] ?? ''} • ${p['duration'] ?? ''}', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(p['description'] ?? '', style: AppTextStyles.bodyLarge),
                  const SizedBox(height: AppSpacing.md),
                  ...((p['drills'] as List<dynamic>? ?? [])).map(
                    (d) => Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(child: Text('$d', style: AppTextStyles.bodyMedium)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      ElevatedButton(onPressed: () => onStart(p), child: const Text('Start Program')),
                      const SizedBox(width: AppSpacing.sm),
                      TextButton(
                        onPressed: () => onCustomize('Customization coming soon'),
                        child: const Text('Customize'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DrillsTab extends StatelessWidget {
  final bool loading;
  final List<Map<String, dynamic>> drills;
  final Future<void> Function(Map<String, dynamic>) onStart;

  const _DrillsTab({
    required this.loading,
    required this.drills,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),
        ...drills.map(
          (d) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d['title'] ?? 'Drill', style: AppTextStyles.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(d['description'] ?? '', style: AppTextStyles.bodyLarge),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      ElevatedButton(onPressed: () => onStart(d), child: const Text('Start Drill')),
                      const SizedBox(width: AppSpacing.sm),
                      TextButton(onPressed: () {}, child: const Text('Details')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChallengesTab extends StatelessWidget {
  final bool loading;
  final List<Map<String, dynamic>> challenges;
  final Future<void> Function(Map<String, dynamic>) onStart;

  const _ChallengesTab({
    required this.loading,
    required this.challenges,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),
        ...challenges.map(
          (c) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c['title'] ?? 'Challenge', style: AppTextStyles.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text('${c['difficulty'] ?? ''} • ${c['reward'] ?? ''}', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(c['description'] ?? '', style: AppTextStyles.bodyLarge),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      ElevatedButton(onPressed: () => onStart(c), child: const Text('Start Challenge')),
                      const SizedBox(width: AppSpacing.sm),
                      TextButton(onPressed: () {}, child: const Text('More Info')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.bgCard.withOpacity(0.6),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(color: AppColors.bgLight.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }
}

const List<Map<String, dynamic>> _defaultPrograms = [
  {
    'title': 'Core Accuracy Builder',
    'level': 'Beginner',
    'duration': '30–45 min',
    'description':
        'Warm-up → Around-the-World → Doubles Ring → Trebles Focus → Bull Control. Designed to build solid board awareness and clean mechanics.',
    'drills': [
      'Warm-up: 60 throws, smooth rhythm',
      'Around-the-World: 1–20 singles, 2 passes',
      'Doubles Ring: D1 → D20, no repeat on hit',
      'Treble Focus: T20, T19, T18, T17 — 30 throws',
      'Bull Control: 50 throws (SBull + DBull)',
    ],
  },
  {
    'title': 'Checkout Mastery 40–100',
    'level': 'Intermediate',
    'duration': '45–60 min',
    'description': 'Finish route confidence from 40–100. Focus on setup darts, avoiding blockers, and doubling out with rhythm.',
    'drills': [
      'Checkout Ladder: 40 → 100 in +5 steps',
      'Routes Practice: 61, 62, 64, 66, 67, 69, 74, 78, 82, 86',
      'Doubles Under Pressure: 50 attempts on D20 / D16',
      'Endurance Finish: 5 x timed 2-min finish cycles',
    ],
  },
  {
    'title': 'Consistency Engine (Pro Rhythm)',
    'level': 'Advanced',
    'duration': '60–75 min',
    'description': 'Paced 501 legs with recovery windows. Build elite rhythm and pace with consistent setup into finishes.',
    'drills': [
      'Timed Legs: 6 x 501 with 90s between legs',
      'Grouping: 3 x 30 throws on T20/T19 switching mid-round',
      'Finish Focus: 40–80 routes with no busts',
      'Pressure Deciders: 3 legs starting 0–0, winner stays on',
    ],
  },
];

const List<Map<String, dynamic>> _defaultDrills = [
  {
    'title': "Bob's 27 (Doubles)",
    'category': 'Doubles',
    'description': 'Start at 27. Each double hit adds its value, misses subtract. Work around the board.',
  },
  {
    'title': 'Checkout Ladder 40–100',
    'category': 'Checkout',
    'description': 'Climb finishing routes between 40 and 100. Avoid busts, track doubles hit.',
  },
  {
    'title': 'Treble Accuracy Waves',
    'category': 'Scoring',
    'description': 'Alternating T20/T19/T18 waves with grouping focus. 90 throws.',
  },
  {
    'title': 'Bull Control 50',
    'category': 'Bull',
    'description': '50 throws: SBull/DBull mix. Track bulls hit percentage.',
  },
  {
    'title': 'Decider Simulation',
    'category': 'Pressure',
    'description': 'One leg winner-stays with time pressure. Bull to start if deciding.',
  },
];

const List<Map<String, dynamic>> _defaultChallenges = [
  {
    'title': 'Daily Doubles 50',
    'difficulty': 'Easy',
    'reward': '+50 XP',
    'description': 'Hit any 50 doubles attempts, record hit rate.',
  },
  {
    'title': 'Checkout Sprint (20 mins)',
    'difficulty': 'Medium',
    'reward': '+100 XP',
    'description': 'Complete as many 40–80 finishes as possible in 20 minutes.',
  },
  {
    'title': 'Treble Hunt 120',
    'difficulty': 'Hard',
    'reward': '+150 XP',
    'description': 'Accumulate 120 treble hits across T20/T19/T18.',
  },
  {
    'title': 'Bull Mastery 20',
    'difficulty': 'Pro',
    'reward': '+200 XP',
    'description': 'Hit 20 bulls (SBull/DBull), track accuracy.',
  },
];
