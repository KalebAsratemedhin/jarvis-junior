import 'package:flutter/material.dart';

/// Widget to display summary of amounts owed per user
class UserSummaryList extends StatelessWidget {
  final Map<String, double> userTotals;
  final Function(String userName)? onDeleteAllTransactions;

  const UserSummaryList({
    super.key,
    required this.userTotals,
    this.onDeleteAllTransactions,
  });

  @override
  Widget build(BuildContext context) {
    if (userTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort users by amount (highest first)
    final sortedEntries = userTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Summary (ETB)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...sortedEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final userEntry = entry.value;
          final userName = userEntry.key;
          final amount = userEntry.value;
          final color = amount >= 0 
              ? Colors.green[700]! 
              : Colors.red[700]!;
          
          return Container(
            margin: EdgeInsets.only(
              bottom: index < sortedEntries.length - 1 ? 12 : 0,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: color.withOpacity(0.2),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          userName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      amount.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (onDeleteAllTransactions != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.red[400],
                        onPressed: () => onDeleteAllTransactions!(userName),
                        tooltip: 'Delete all transactions for this user',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

