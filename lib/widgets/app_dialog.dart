import 'dart:ui';

import 'package:flutter/material.dart';

enum AppDialogActionsAlignment {
  end,
  center,
}

class AppDialog extends StatelessWidget {
  final String title;
  final String message;
  final List<Widget> actions;
  final Widget? child;

  final bool showCloseButton;
  final VoidCallback? onClose;
  final AppDialogActionsAlignment actionsAlignment;

  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actions,
    this.child,
    this.showCloseButton = false,
    this.onClose,
    this.actionsAlignment = AppDialogActionsAlignment.end,
  });

  Widget _buildActionsRow(BuildContext context) {
    final mainAxisAlignment = switch (actionsAlignment) {
      AppDialogActionsAlignment.end => MainAxisAlignment.end,
      AppDialogActionsAlignment.center => MainAxisAlignment.center,
    };

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: actions
          .map(
            (action) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: action,
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const baseColor = Colors.blueAccent;

    final bgColors = isDark
        ? [
            baseColor.withValues(alpha: 0.46),
            baseColor.withValues(alpha: 0.34),
            baseColor.withValues(alpha: 0.26),
          ]
        : [
            baseColor.withValues(alpha: 0.50),
            baseColor.withValues(alpha: 0.38),
            baseColor.withValues(alpha: 0.28),
          ];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12,
            sigmaY: 12,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: bgColors,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.82 : 0.92),
                width: 2.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.32),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 560,
                maxWidth: 420,
              ),
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Colors.white,
                ),
                child: IconTheme(
                  data: const IconThemeData(
                    color: Colors.white,
                  ),
                  child: TextButtonTheme(
                    data: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        disabledForegroundColor:
                            Colors.white.withValues(alpha: 0.45),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    child: FilledButtonTheme(
                      data: FilledButtonThemeData(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.transparent,
                          disabledForegroundColor:
                              Colors.white.withValues(alpha: 0.45),
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.88),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 10,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              20,
                              20,
                              actions.isEmpty ? 20 : 18,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (title.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: showCloseButton ? 40 : 0,
                                      bottom: 14,
                                    ),
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        height: 1.2,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                Flexible(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (message.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 10,
                                            ),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: Text(
                                                message,
                                                textAlign: TextAlign.start,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  height: 1.45,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (child != null) child!,
                                      ],
                                    ),
                                  ),
                                ),
                                if (actions.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  _buildActionsRow(context),
                                ],
                              ],
                            ),
                          ),
                          if (showCloseButton)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.close),
                                color: Colors.white,
                                splashRadius: 20,
                                onPressed:
                                    onClose ?? () => Navigator.pop(context),
                              ),
                            ),
                        ],
                      ),
                    ),
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
