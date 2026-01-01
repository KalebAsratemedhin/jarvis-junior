import 'package:flutter/material.dart';

/// Widget to display status and error messages
class StatusIndicator extends StatelessWidget {
  final String status;
  final bool isListening;
  final String? error;
  final List<String> locales;
  final VoidCallback? onRetry;
  
  const StatusIndicator({
    super.key,
    required this.status,
    required this.isListening,
    this.error,
    this.locales = const [],
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          status,
          style: TextStyle(
            fontSize: 14,
            color: isListening ? Colors.red : Colors.grey[600],
            fontWeight: isListening ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (isListening) ...[
          const SizedBox(height: 8),
          const Text(
            '🔴 Recording audio...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        if (error != null && error!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              children: [
                Text(
                  error!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (locales.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Locale: ${locales.first}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }
}



