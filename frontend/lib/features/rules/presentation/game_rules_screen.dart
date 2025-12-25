import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_design.dart';

class GameRulesScreen extends StatefulWidget {
  const GameRulesScreen({super.key});

  @override
  State<GameRulesScreen> createState() => _GameRulesScreenState();
}

class _GameRulesScreenState extends State<GameRulesScreen> {
  String? _selectedMode;

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Game Rules', style: AppTextStyles.headlineMedium),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    // Sidebar with game modes list
                    Container(
                      width: 200,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard.withOpacity(0.4),
                        border: Border(right: BorderSide(color: AppColors.bgLight.withOpacity(0.3))),
                      ),
                      child: ListView(
                        children: _gameModes.map((mode) {
                          final isSelected = _selectedMode == mode['id'];
                          return InkWell(
                            onTap: () => setState(() => _selectedMode = mode['id']),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: isSelected ? AppColors.primary : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Text(
                                mode['name'] as String,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Main content area
                    Expanded(
                      child: _selectedMode == null
                          ? Center(
                              child: Text(
                                'Select a game mode to view rules',
                                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                              ),
                            )
                          : _buildRulesContent(),
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

  Widget _buildRulesContent() {
    final mode = _gameModes.firstWhere((m) => m['id'] == _selectedMode);
    
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(mode['icon'] as IconData, color: AppColors.primary, size: 32),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(mode['name'] as String, style: AppTextStyles.headlineMedium),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Text(
                  mode['difficulty'] as String,
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overview', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(mode['description'] as String, style: AppTextStyles.bodyLarge),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rules', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              ...(mode['rules'] as List<String>).map(
                (rule) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(rule, style: AppTextStyles.bodyLarge)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (mode['variations'] != null) ...[
          const SizedBox(height: AppSpacing.md),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Variations', style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                ...(mode['variations'] as List<String>).map(
                  (variation) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.star, color: AppColors.warning, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(variation, style: AppTextStyles.bodyLarge)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (mode['tips'] != null) ...[
          const SizedBox(height: AppSpacing.md),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tips & Strategy', style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                ...(mode['tips'] as List<String>).map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb, color: AppColors.warning, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(tip, style: AppTextStyles.bodyLarge)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

final List<Map<String, dynamic>> _gameModes = [
  {
    'id': '501',
    'name': '501',
    'difficulty': 'Standard',
    'icon': Icons.sports_esports,
    'description': 'The most popular competitive darts game. Start at 501 points and race to zero.',
    'rules': [
      'Start with 501 points',
      'Each turn consists of 3 darts',
      'Subtract your score from the total',
      'Must finish exactly on zero',
      'Must finish with a double (outer ring)',
      'Going below zero or hitting zero without a double is a "bust" - score reverts to start of turn',
    ],
    'variations': [
      '301/401/701/1001: Same rules, different starting scores',
      'Double-In: Must hit a double before scoring counts',
      'Master-Out: Finish with either double or treble',
      'Straight-Start: No double-in required',
    ],
    'tips': [
      'Aim for treble 20 (T20) to maximize scoring',
      'Learn common checkout routes (e.g., 170, 167, 164)',
      'Leave yourself on an even number for easier doubles',
      'Practice doubles D20, D16, D18, and D10 most',
    ],
  },
  {
    'id': 'cricket',
    'name': 'Cricket',
    'difficulty': 'Intermediate',
    'icon': Icons.grid_on,
    'description': 'Strategic game combining territory control with scoring. Close numbers before your opponent.',
    'rules': [
      'Target numbers: 15, 16, 17, 18, 19, 20, and Bull',
      'Hit each number 3 times to "close" it (single = 1 mark, double = 2, treble = 3)',
      'After closing a number, you score points on it if opponent hasn\'t closed it',
      'First player to close all numbers with equal or more points wins',
      'If tied on closures, highest score wins',
    ],
    'variations': [
      'Cut-Throat: Points scored against you instead of for you',
      'English Cricket: No scoring after closing, pure race',
      'No-Score Cricket: Close all numbers first, no points counted',
    ],
    'tips': [
      'Close high numbers (20, 19, 18) first for scoring potential',
      'Watch opponent\'s open numbers for strategic scoring',
      'Bulls are worth 25/50 points when open',
      'Balance between closing and scoring based on position',
    ],
  },
  {
    'id': 'atc',
    'name': 'Around the Clock',
    'difficulty': 'Beginner',
    'icon': Icons.access_time,
    'description': 'Simple accuracy game hitting numbers 1-20 in sequence, then bull to finish.',
    'rules': [
      'Start at number 1',
      'Hit each number in sequence: 1, 2, 3... up to 20',
      'Any part of the number counts (single, double, or treble)',
      'Cannot advance until current number is hit',
      'Finish by hitting the bull (single or double)',
      'First to complete the sequence wins',
    ],
    'variations': [
      'Doubles Only: Must hit the double ring of each number',
      'Trebles Only: Must hit the treble ring of each number',
      'Reverse: Start at 20 and work backward to 1',
      'Timed: Complete as many numbers as possible in set time',
    ],
    'tips': [
      'Great practice for board awareness and accuracy',
      'Focus on smooth, consistent throwing motion',
      'Don\'t rush - accuracy over speed',
      'Learn where each number is without looking',
    ],
  },
  {
    'id': 'shanghai',
    'name': 'Shanghai',
    'difficulty': 'Intermediate',
    'icon': Icons.location_city,
    'description': 'Score-based game where each round targets a specific number. Hit single, double, and treble in one turn for instant win.',
    'rules': [
      'Usually played on numbers 1-7 or 1-20',
      'Each round targets one number (Round 1 = 1s, Round 2 = 2s, etc.)',
      'Score = total value hit on target number only',
      'Singles count face value, doubles count 2x, trebles count 3x',
      'SHANGHAI: Hit single, double, AND treble of target number in one turn = instant win',
      'Otherwise, highest total score after all rounds wins',
    ],
    'tips': [
      'Early rounds worth less - take risks for Shanghai',
      'Later rounds (15-20) offer more points',
      'Going for treble is high risk, high reward',
      'Track opponents\' scores to know when to gamble',
    ],
  },
  {
    'id': 'killer',
    'name': 'Killer',
    'difficulty': 'Party Game',
    'icon': Icons.dangerous,
    'description': 'Elimination game where you target opponents\' numbers. Last player standing wins.',
    'rules': [
      'Each player throws one dart with non-throwing hand to determine their number',
      'Players start with 3-5 lives',
      'Must hit double of YOUR number to become a "killer"',
      'Once a killer, hitting opponents\' doubles removes their lives',
      'Hitting your own double as killer adds a life (optional rule)',
      'Last player with lives remaining wins',
      'Lose killer status if you bust or miss board completely (optional)',
    ],
    'variations': [
      'Blind Killer: Numbers assigned randomly',
      'Suicide: Hitting your own double removes a life',
      'Team Killer: Form teams and protect each other',
    ],
    'tips': [
      'Become killer quickly - more time to eliminate others',
      'Target players with fewer lives first',
      'Protect your number by staying killer',
      'High numbers (18-20) easier to hit doubles',
    ],
  },
  {
    'id': 'halve_it',
    'name': 'Halve-It',
    'difficulty': 'Intermediate',
    'icon': Icons.trending_down,
    'description': 'High stakes scoring game where missing targets halves your total score.',
    'rules': [
      'Pre-determined target sequence (e.g., Any Double, 41, Any Treble, 25, 50, Bull)',
      'Each round has a specific target',
      'Score points for hitting target areas',
      'If you score ZERO in a round, your TOTAL score is halved',
      'Negative scores possible if starting from zero',
      'Highest score after all rounds wins',
    ],
    'variations': [
      'Custom Targets: Create your own sequence',
      'Double Jeopardy: Missing two rounds in a row zeros your score',
      'Treble Trouble: All trebles in sequence',
    ],
    'tips': [
      'Even a small score prevents halving',
      'High-value rounds worth taking risks',
      'Building a lead early provides cushion',
      'Going for target vs safe score is key decision',
    ],
  },
  {
    'id': 'bobs_27',
    'name': 'Bob\'s 27',
    'difficulty': 'Beginner',
    'icon': Icons.exposure,
    'description': 'Doubles-focused game starting at 27 points. Add or subtract based on hitting doubles.',
    'rules': [
      'Everyone starts with 27 points',
      'Work through doubles: D1, D2, D3... up to D20',
      'Hit the double: ADD that double\'s value to your score',
      'Miss all 3 darts at the double: SUBTRACT that value',
      'Hit zero or below: ELIMINATED',
      'Highest score after D20 wins (or last player standing)',
    ],
    'variations': [
      'Bob\'s 36: Start with higher score for longer game',
      'Reverse Bob: Start at D20 and work backward',
      'Speed Bob: Timed rounds',
    ],
    'tips': [
      'Low doubles (D1-D5) less risky early on',
      'Build score on easier doubles before big ones',
      'High doubles (D16-D20) are elimination risks',
      'Know when to play safe vs aggressive',
    ],
  },
  {
    'id': 'scram',
    'name': 'Scram',
    'difficulty': 'Two Players',
    'icon': Icons.swap_horiz,
    'description': 'Two-player game with alternating roles: one opens numbers, the other scores on them.',
    'rules': [
      'Player 1 (Stopper): First 3 rounds, hits numbers to "close" them',
      'Player 2 (Scorer): Scores points on any numbers NOT closed',
      'After 3 rounds, roles switch',
      'Player 2 becomes Stopper, Player 1 becomes Scorer',
      'Player 1 scores on numbers still open after Player 2\'s stopping',
      'Higher total score wins',
    ],
    'tips': [
      'As Stopper: Close high-value numbers first (20, 19, Bull)',
      'As Scorer: Hit closed numbers\' neighbors for points',
      'Trebles close numbers faster',
      'Balance speed vs completeness when stopping',
    ],
  },
  {
    'id': 'tic_tac_toe',
    'name': 'Tic-Tac-Toe',
    'difficulty': 'Party Game',
    'icon': Icons.tag,
    'description': 'Classic tic-tac-toe on dartboard. Hit numbers to claim squares.',
    'rules': [
      'Draw 3x3 grid, assign numbers to each square',
      'Players alternate turns',
      'Hit the number to claim that square',
      'Three in a row (horizontal, vertical, diagonal) wins',
      'If all squares filled with no winner: draw or highest score wins',
    ],
    'variations': [
      'Doubles Grid: Must hit double of the number',
      'Speed Tic-Tac-Toe: First to claim square owns it (no alternating)',
      'Four-in-a-Row: Larger grid',
    ],
    'tips': [
      'Center square most valuable strategically',
      'Block opponent\'s winning moves',
      'Corner squares offer multiple winning paths',
      'Assign easier numbers to key squares',
    ],
  },
  {
    'id': 'all_fives',
    'name': 'All-Fives (Fives)',
    'difficulty': 'Advanced',
    'icon': Icons.filter_5,
    'description': 'Mental math game where scores divisible by 5 earn points.',
    'rules': [
      'Each turn throw 3 darts',
      'Add up your 3-dart total',
      'If total is divisible by 5: earn (total ÷ 5) points',
      'Example: 60 points = 12 game points, 45 points = 9 game points',
      'Zero if not divisible by 5',
      'First to 50 or 100 game points wins',
    ],
    'tips': [
      'Multiples of 5 to aim for: 20, 5, 15, 10',
      'Treble 20 (60) + anything = likely divisible by 5',
      '50 (bull) helps reach divisible totals',
      'Calculate on the fly to adjust third dart target',
    ],
  },
  {
    'id': 'mickey_mouse',
    'name': 'Mickey Mouse',
    'difficulty': 'Beginner',
    'icon': Icons.mouse,
    'description': 'Simple 10-round game targeting specific numbers each round.',
    'rules': [
      'Target numbers: Usually 20, Bull, and one custom number per round',
      'Play 10 rounds',
      'Each dart hitting a target counts',
      'Miss all targets with a dart = zero for that dart',
      'Highest total score after 10 rounds wins',
    ],
    'variations': [
      'Custom Targets: Change numbers each round',
      'Doubles Mickey: Only doubles of targets count',
      'Progressive Mickey: Add numbers each round',
    ],
    'tips': [
      'Consistent accuracy matters more than big scores',
      'Bull and 20 are standard high-value targets',
      'Safe play: aim for reliable single hits',
    ],
  },
  {
    'id': 'english_cricket',
    'name': 'English Cricket',
    'difficulty': 'Intermediate',
    'icon': Icons.sports_cricket,
    'description': 'Pure closing race - no scoring after closing numbers.',
    'rules': [
      'Target numbers: 20, 19, 18, 17, 16, 15, Bull',
      'Hit each number 3 times to close it',
      'Singles = 1 mark, Doubles = 2 marks, Trebles = 3 marks',
      'NO scoring after closing - just mark it off',
      'First to close all numbers wins',
      'Pure speed race',
    ],
    'tips': [
      'Go for trebles to close numbers in one dart',
      'No need to block opponent since no scoring',
      'Bull last since it\'s harder to hit',
      'Accuracy and consistency beat power',
    ],
  },
  {
    'id': 'gotcha',
    'name': 'Gotcha (Trap)',
    'difficulty': 'Party Game',
    'icon': Icons.gps_fixed,
    'description': 'Chaotic 501 variant where landing on opponent\'s exact score sends them backward.',
    'rules': [
      'Play standard 301, 501, or similar',
      'If you land EXACTLY on another player\'s current score, they get "sent back"',
      'Sent back means: score halved, or reset to starting score (varies by house rules)',
      'Continue subtracting as normal otherwise',
      'First to zero (with double-out) wins',
    ],
    'variations': [
      'Gotcha Rebounds: Sent player returns to last checkpoint',
      'Team Gotcha: Teams can trap opponents',
      'Mercy Rule: Can\'t trap same player twice in a row',
    ],
    'tips': [
      'Track all player scores for trap opportunities',
      'Avoid common score clusters (e.g., around 100-140)',
      'Aggressive scoring to get away from pack',
      'Late game traps can swing victory',
    ],
  },
];
