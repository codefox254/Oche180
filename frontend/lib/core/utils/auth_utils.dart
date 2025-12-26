import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_design.dart';
import '../providers/auth_provider.dart';

/// Shows a dialog prompting the user to login to access a feature
void showLoginRequiredDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      title: const Text('Login Required'),
      content: const Text(
        'Please log in to access this feature. Create an account or sign in to save your progress and compete!',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            context.push('/auth/login');
          },
          child: const Text('Login'),
        ),
      ],
    ),
  );
}

/// Wrapper widget that guards a feature based on authentication
class RequiresAuth extends ConsumerWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool showDialogIfGuest;

  const RequiresAuth({
    super.key,
    required this.child,
    required this.onTap,
    this.showDialogIfGuest = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return GestureDetector(
      onTap: () {
        if (authState.isGuest) {
          if (showDialogIfGuest) {
            showLoginRequiredDialog(context);
          }
        } else {
          onTap();
        }
      },
      child: child,
    );
  }
}

/// Helper to check if a user can access a feature
bool canAccessFeature(WidgetRef ref, BuildContext context, {bool showDialog = true}) {
  final authState = ref.read(authProvider);
  if (authState.isGuest) {
    if (showDialog) {
      showLoginRequiredDialog(context);
    }
    return false;
  }
  return true;
}
