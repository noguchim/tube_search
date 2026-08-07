import 'package:flutter/material.dart';

class SimpleTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<Widget> tabs;
  final double height;

  const SimpleTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.height = 48,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      height: height,
      child: TabBar(
        controller: controller,
        labelColor: onSurface,
        unselectedLabelColor: onSurface.withValues(alpha: 0.62),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        dividerColor: onSurface.withValues(alpha: 0.10),
        dividerHeight: 1,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: onSurface, width: 2),
          insets: const EdgeInsets.symmetric(horizontal: -18),
        ),
        tabs: tabs,
      ),
    );
  }
}
