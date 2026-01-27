import 'package:flutter/material.dart';

import '../utils/card_density_prefs.dart';

class DensityFab extends StatelessWidget {
  final CardDensity density;
  final VoidCallback onToggle;

  const DensityFab({
    super.key,
    required this.density,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FloatingActionButton(
      onPressed: onToggle,
      shape: const CircleBorder(),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 8,
      tooltip: _densityTooltip(density),
      child: Icon(
        _densityIcon(density),
        size: 26,
      ),
    );
  }

  IconData _densityIcon(CardDensity d) {
    switch (d) {
      case CardDensity.big:
        return Icons.view_carousel_rounded;
      case CardDensity.middle:
        return Icons.view_agenda_rounded;
      case CardDensity.small:
        return Icons.view_list_rounded;
    }
  }

  String _densityTooltip(CardDensity d) {
    switch (d) {
      case CardDensity.big:
        return "大カード表示";
      case CardDensity.middle:
        return "中カード表示";
      case CardDensity.small:
        return "小カード表示";
    }
  }
}
