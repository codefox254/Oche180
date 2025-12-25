import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router.dart';
import '../../../core/constants/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Oche180',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Professional darts scoring with realtime stats and offline reliability.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.go(AppRoute.home.path),
                icon: const Icon(Icons.sports_esports),
                label: const Text('Jump in'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(AppRoute.authLanding.path),
                child: const Text('Login or sign up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
