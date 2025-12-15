import 'package:flutter/material.dart';

class RankBadge extends StatelessWidget {
  const RankBadge({
    super.key,
    required this.rank,
    required this.consensusScore,
  });

  final int rank;
  final double consensusScore;

  Color get _rankColor {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown.shade400;
      default:
        return Colors.grey;
    }
  }

  IconData get _rankIcon {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.military_tech;
      case 3:
        return Icons.workspace_premium;
      default:
        return Icons.star;
    }
  }

  String get _rankLabel {
    switch (rank) {
      case 1:
        return 'First Place';
      case 2:
        return 'Second Place';
      case 3:
        return 'Third Place';
      default:
        return '$rank Place';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _rankColor.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _rankColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            _rankIcon,
            color: _rankColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            _rankLabel,
            style: TextStyle(
              color: _rankColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _rankColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  consensusScore.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
