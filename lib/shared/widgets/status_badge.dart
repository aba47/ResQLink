import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? _resolveColor(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: effectiveColor.withAlpha(128)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: effectiveColor),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: effectiveColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _resolveColor(String status) {
    switch (status.toUpperCase()) {
      case 'CRITICAL':
      case 'HIGH':
      case 'FAILED':
      case 'CLOSED':
        return Colors.red;
      case 'MEDIUM':
      case 'WARNING':
      case 'PENDING':
      case 'SYNCING':
        return Colors.orange;
      case 'LOW':
      case 'OPEN':
      case 'SYNCED':
      case 'COMPLETED':
      case 'ACTIVE':
      case 'OPERATIONAL':
        return Colors.green;
      case 'REQUESTED':
      case 'ACCEPTED':
      case 'TEAM ASSIGNED':
      case 'IN PROGRESS':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
