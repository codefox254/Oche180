import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/providers/auth_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
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
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  onPressed: () => context.pop(),
                ),
                title: const Text('Profile'),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Profile Header
                    _ProfileHeader(),
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Statistics Cards
                    _SectionTitle(title: 'Performance Statistics'),
                    const SizedBox(height: AppSpacing.md),
                    _StatsGrid(),
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Achievement Section
                    _SectionTitle(title: 'Achievements'),
                    const SizedBox(height: AppSpacing.md),
                    _AchievementsSection(),
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Recent Matches
                    _SectionTitle(title: 'Recent Matches'),
                    const SizedBox(height: AppSpacing.md),
                    _RecentMatches(),
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Settings
                    _SectionTitle(title: 'Account Settings'),
                    const SizedBox(height: AppSpacing.md),
                    _SettingsSection(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final profile = user?.profile;
    
    final displayName = user?.displayName ?? 'Guest Player';
    final skillLevel = user?.skillLevel ?? 'BEGINNER';
    final totalGames = profile?.totalGamesPlayed ?? 0;
    final level = profile?.level ?? 1;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppBorderRadius.xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.bgCard.withOpacity(0.6),
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(AppBorderRadius.full),
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppBorderRadius.full),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Name and Level
              Text(
                displayName,
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.accentGradient,
                  ),
                  borderRadius: BorderRadius.circular(AppBorderRadius.full),
                ),
                child: Text(
                  _formatSkillLevel(skillLevel),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Quick Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickStat(label: 'Level', value: '$level'),
                  Container(
                    width: 1,
                    height: 30,
                    color: AppColors.bgLight,
                  ),
                  _QuickStat(label: 'Games', value: '$totalGames'),
                  Container(
                    width: 1,
                    height: 30,
                    color: AppColors.bgLight,
                  ),
                  _QuickStat(label: 'XP', value: '${profile?.totalXp ?? 0}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatSkillLevel(String level) {
    switch (level) {
      case 'BEGINNER':
        return 'Beginner';
      case 'INTERMEDIATE':
        return 'Intermediate';
      case 'ADVANCED':
        return 'Advanced';
      case 'PROFESSIONAL':
        return 'Professional';
      default:
        return level;
    }
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;

  const _QuickStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.titleLarge,
    );
  }
}

class _StatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.show_chart,
          label: 'Average',
          value: '0.0',
          color: AppColors.primary,
        ),
        _StatCard(
          icon: Icons.star,
          label: '180s',
          value: '0',
          color: AppColors.secondary,
        ),
        _StatCard(
          icon: Icons.favorite,
          label: 'Checkout %',
          value: '0%',
          color: AppColors.accent,
        ),
        _StatCard(
          icon: Icons.sports_score,
          label: 'High Score',
          value: '0',
          color: AppColors.warning,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              color: color,
              fontSize: 20,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final achievements = [
      {'title': 'First Win', 'icon': Icons.emoji_events, 'locked': true},
      {'title': 'First 180', 'icon': Icons.star, 'locked': true},
      {'title': '100 Games', 'icon': Icons.sports_score, 'locked': true},
      {'title': 'Perfect Leg', 'icon': Icons.whatshot, 'locked': true},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          final isLocked = achievement['locked'] as bool;
          
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.bgCard.withOpacity(0.6),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                color: isLocked
                    ? AppColors.bgLight.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.5),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  achievement['icon'] as IconData,
                  color: isLocked ? AppColors.textTertiary : AppColors.primary,
                  size: 32,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  achievement['title'] as String,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 10,
                    color: isLocked ? AppColors.textTertiary : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RecentMatches extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.bgLight.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.sports_esports,
            color: AppColors.textTertiary,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No matches played yet',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start playing to see your match history here',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends ConsumerWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return Column(
      children: [
        _SettingItem(
          icon: Icons.edit,
          title: 'Edit Profile',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditProfileScreen(),
              ),
            );
          },
        ),
        _SettingItem(
          icon: Icons.palette,
          title: 'Theme Settings',
          onTap: () {},
        ),
        _SettingItem(
          icon: Icons.notifications,
          title: 'Notifications',
          onTap: () {},
        ),
        if (authState.isAuthenticated)
          _SettingItem(
            icon: Icons.logout,
            title: 'Sign Out',
            textColor: AppColors.error,
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Signed out successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
                context.go('/auth');
              }
            },
          )
        else
          _SettingItem(
            icon: Icons.login,
            title: 'Sign In',
            textColor: AppColors.primary,
            onTap: () => context.push('/auth/login'),
          ),
      ],
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? textColor;
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.bgLight.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: textColor ?? AppColors.primary,
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            color: textColor ?? AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
