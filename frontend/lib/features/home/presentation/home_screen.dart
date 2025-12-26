import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_design.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/utils/auth_utils.dart';
import '../../../core/widgets/dartboard_icon.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    return Scaffold(
      drawer: const _AppDrawer(),
        bottomNavigationBar: _FooterNavigation(),
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
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.primary),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: AppColors.bgDark.withOpacity(0.3)),
                  ),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user != null ? 'Hi, ${user.displayName}' : 'Oche180',
                      style: AppTextStyles.headlineMedium.copyWith(
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: AppColors.primaryGradient,
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                      ),
                    ),
                    Text(
                      user != null ? 'Ready to play?' : 'Professional Darts',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Consumer(
                      builder: (context, ref, _) {
                        final themeMode = ref.watch(themeModeProvider);
                        return Icon(
                          themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                          color: AppColors.primary,
                        );
                      },
                    ),
                    onPressed: () {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    },
                    tooltip: 'Toggle Theme',
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_outline, color: AppColors.primary),
                    onPressed: () => context.push('/profile'),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const _StatsOverview(),
                    const SizedBox(height: AppSpacing.xl),
                    const _QuickActions(),
                    const SizedBox(height: AppSpacing.xl),
                    const _GameModes(),
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

class _StatsOverview extends ConsumerWidget {
  const _StatsOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final profile = user?.profile;
    
    final totalGames = profile?.totalGamesPlayed ?? 0;
    final totalXP = profile?.totalXp ?? 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.bgDark.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: const Icon(Icons.trending_up, color: AppColors.bgDark),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Your Stats',
                style: AppTextStyles.titleLarge.copyWith(color: AppColors.bgDark),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Games', value: '$totalGames', icon: Icons.sports_esports),
              _StatItem(label: 'XP', value: '$totalXP', icon: Icons.stars),
              _StatItem(label: 'Level', value: '${profile?.level ?? 1}', icon: Icons.trending_up),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.bgDark.withOpacity(0.6), size: 20),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.displayMedium.copyWith(
            color: AppColors.bgDark,
            fontSize: 28,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.bgDark.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.play_circle_fill,
                label: 'Quick Match',
                gradient: AppColors.primaryGradient,
                requiresAuth: false,
                onTap: () => context.push('/game-modes'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ActionCard(
                icon: Icons.fitness_center,
                label: 'Training',
                gradient: AppColors.accentGradient,
                requiresAuth: true,
                onTap: () {
                  if (authState.isAuthenticated) {
                    context.push('/training');
                  } else {
                    showLoginRequiredDialog(context);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.emoji_events,
                label: 'Tournaments',
                gradient: AppColors.secondaryGradient,
                requiresAuth: true,
                onTap: () {
                  if (authState.isAuthenticated) {
                    context.push('/tournaments');
                  } else {
                    showLoginRequiredDialog(context);
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ActionCard(
                icon: Icons.bar_chart,
                label: 'Statistics',
                gradient: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                requiresAuth: true,
                onTap: () {
                  if (authState.isAuthenticated) {
                    context.push('/statistics');
                  } else {
                    showLoginRequiredDialog(context);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;
  final bool requiresAuth;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
    this.requiresAuth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 40),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if (requiresAuth)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: const Icon(Icons.lock_outline, color: Colors.white70, size: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameModes extends StatelessWidget {
  const _GameModes();

  @override
  Widget build(BuildContext context) {
    final modes = [
      _GameModeData('501', '501', Icons.filter_1, AppColors.primary),
      _GameModeData('Cricket', 'CRICKET', Icons.grid_on, AppColors.secondary),
      _GameModeData('Around the Clock', 'ATC', Icons.access_time, AppColors.accent),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Game Modes', style: AppTextStyles.headlineMedium),
            TextButton(
              onPressed: () => context.push('/game-modes'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...modes.map((mode) => _GameModeCard(mode: mode)),
      ],
    );
  }
}

class _GameModeData {
  final String title;
  final String key;
  final IconData icon;
  final Color color;

  _GameModeData(this.title, this.key, this.icon, this.color);
}

class _GameModeCard extends StatelessWidget {
  final _GameModeData mode;

  const _GameModeCard({required this.mode});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard.withOpacity(0.6),
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(
                color: mode.color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/game-setup/${mode.key}'),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: mode.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        ),
                        child: Icon(mode.icon, color: mode.color, size: 28),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mode.title, style: AppTextStyles.titleLarge),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Tap to start',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: mode.color,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAuthenticated = authState.isAuthenticated;

    return Drawer(
      backgroundColor: AppColors.bgDark,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppBorderRadius.full),
                  ),
                  child: const DartboardIcon(size: 32, color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  isAuthenticated ? user!.displayName : 'Oche180',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isAuthenticated ? user!.email : 'Professional Darts Scoring',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: Icons.home,
                  title: 'Home',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    if (isAuthenticated) {
                      context.push('/profile');
                    } else {
                      showLoginRequiredDialog(context);
                    }
                  },
                  requiresAuth: true,
                  isAuthenticated: isAuthenticated,
                ),
                _DrawerItem(
                  icon: Icons.play_circle_filled,
                  title: 'Quick Play',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/game-modes');
                  },
                ),
                _DrawerItem(
                  icon: Icons.sports_esports,
                  title: 'Game Modes',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/game-modes');
                  },
                ),
                _DrawerItem(
                  icon: Icons.emoji_events,
                  title: 'Tournaments',
                  onTap: () {
                    Navigator.pop(context);
                    if (isAuthenticated) {
                      context.push('/tournaments');
                    } else {
                      showLoginRequiredDialog(context);
                    }
                  },
                  requiresAuth: true,
                  isAuthenticated: isAuthenticated,
                ),
                _DrawerItem(
                  icon: Icons.fitness_center,
                  title: 'Training',
                  onTap: () {
                    Navigator.pop(context);
                    if (isAuthenticated) {
                      context.push('/training');
                    } else {
                      showLoginRequiredDialog(context);
                    }
                  },
                  requiresAuth: true,
                  isAuthenticated: isAuthenticated,
                ),
                const Divider(color: AppColors.bgLight),
                _DrawerItem(
                  icon: Icons.bar_chart,
                  title: 'Statistics',
                  onTap: () {
                    Navigator.pop(context);
                    if (isAuthenticated) {
                      context.push('/statistics');
                    } else {
                      showLoginRequiredDialog(context);
                    }
                  },
                  requiresAuth: true,
                  isAuthenticated: isAuthenticated,
                ),
                _DrawerItem(
                  icon: Icons.book,
                  title: 'Game Rules',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/game-rules');
                  },
                ),
                const Divider(color: AppColors.bgLight),
                if (!isAuthenticated)
                  _DrawerItem(
                    icon: Icons.shield_outlined,
                    title: 'Login / Signup',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/auth');
                    },
                  ),
                if (isAuthenticated)
                  _DrawerItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/auth');
                      }
                    },
                    textColor: AppColors.error,
                  ),
                _DrawerItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Version 1.0.0',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final bool requiresAuth;
  final bool isAuthenticated;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.requiresAuth = false,
    this.isAuthenticated = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppColors.primary),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(color: textColor ?? AppColors.textPrimary),
      ),
      trailing: (requiresAuth && !isAuthenticated)
          ? Icon(Icons.lock_outline, color: AppColors.textTertiary.withOpacity(0.5), size: 18)
          : null,
      onTap: onTap,
      hoverColor: AppColors.bgLight,
    );
  }
}

class _FooterNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _FooterTab(
                icon: Icons.home,
                label: 'Home',
                isActive: true,
                onTap: () {},
              ),
              _FooterTab(
                icon: Icons.sports_esports,
                label: 'Games',
                isActive: false,
                onTap: () => context.push('/game-modes'),
              ),
              _FooterTab(
                icon: Icons.bar_chart,
                label: 'Stats',
                isActive: false,
                onTap: () => context.push('/statistics'),
              ),
              _FooterTab(
                icon: Icons.person,
                label: 'Profile',
                isActive: false,
                onTap: () => context.push('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FooterTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
