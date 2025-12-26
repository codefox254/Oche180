import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_design.dart';
import '../data/training_api.dart';

class ActiveChallengeNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void setSession(int? id) {
    state = id;
  }
}

class ChallengeTimerNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setElapsed(int value) {
    state = value;
  }
}

final activeChallengeProvider = NotifierProvider<ActiveChallengeNotifier, int?>(() {
  return ActiveChallengeNotifier();
});
final challengeTimerProvider = NotifierProvider<ChallengeTimerNotifier, int>(() {
  return ChallengeTimerNotifier();
});

class ChallengeSessionScreen extends ConsumerStatefulWidget {
  final int sessionId;
  final String title;
  final int durationMinutes;
  final TrainingApi api;

  const ChallengeSessionScreen({
    super.key,
    required this.sessionId,
    required this.title,
    required this.durationMinutes,
    required this.api,
  });

  @override
  ConsumerState<ChallengeSessionScreen> createState() => _ChallengeSessionScreenState();
}

class _ChallengeSessionScreenState extends ConsumerState<ChallengeSessionScreen> {
  Timer? _timer;
  int _elapsed = 0;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    ref.read(activeChallengeProvider.notifier).setSession(widget.sessionId);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_paused) {
        setState(() {
          _elapsed++;
          ref.read(challengeTimerProvider.notifier).setElapsed(_elapsed);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _terminate() async {
    try {
      await widget.api.terminateSession(widget.sessionId);
      ref.read(activeChallengeProvider.notifier).setSession(null);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to terminate: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (widget.durationMinutes * 60) - _elapsed;
    final progress = (_elapsed / (widget.durationMinutes * 60)).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Challenge: ${widget.title}'),
        actions: [
          IconButton(
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause, color: AppColors.primary),
            onPressed: () => setState(() => _paused = !_paused),
          ),
          IconButton(
            icon: const Icon(Icons.stop_circle, color: AppColors.error),
            onPressed: _terminate,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              ),
              child: Column(
                children: [
                  Text('Time', style: AppTextStyles.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  Text(_format(_elapsed), style: AppTextStyles.displayMedium),
                  const SizedBox(height: AppSpacing.md),
                  LinearProgressIndicator(value: progress, color: AppColors.primary),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Remaining: ${_format(remaining.clamp(0, widget.durationMinutes * 60))}', style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Interact', style: AppTextStyles.titleLarge),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        ElevatedButton(onPressed: (){}, child: const Text('Hit')), 
                        ElevatedButton(onPressed: (){}, child: const Text('Miss')),
                        ElevatedButton(onPressed: (){}, child: const Text('Checkout')),
                        ElevatedButton(onPressed: (){}, child: const Text('Undo')),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Notes', style: AppTextStyles.titleLarge),
                    const SizedBox(height: AppSpacing.md),
                    Text('Record specific actions during the challenge. UI hooks can be wired to API if needed.', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
