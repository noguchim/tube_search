import 'package:flutter/material.dart';

class NewVideoBadge extends StatelessWidget {
  const NewVideoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fiber_manual_record,
            size: 8,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            "新着",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.0,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
