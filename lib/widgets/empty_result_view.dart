import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class EmptyResultView extends StatelessWidget {
  final VoidCallback? onRetry;

  const EmptyResultView({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            t.noVideosFound,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
