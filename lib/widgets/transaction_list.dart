import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

/// Widget to display transactions grouped by date
class TransactionList extends StatelessWidget {
  final Map<DateTime, List<Transaction>> transactionsByDate;
  final Function(String transactionId)? onDelete;

  const TransactionList({
    super.key,
    required this.transactionsByDate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (transactionsByDate.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No transactions yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add a transaction to get started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: transactionsByDate.length,
      itemBuilder: (context, index) {
        final dateEntry = transactionsByDate.entries.toList()[index];
        final date = dateEntry.key;
        final transactions = dateEntry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            ...transactions.map((transaction) => _TransactionTile(
              transaction: transaction,
              onDelete: onDelete,
            )),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final Function(String transactionId)? onDelete;

  const _TransactionTile({
    required this.transaction,
    this.onDelete,
  });

  void _showDetailsDialog(BuildContext context) {
    final isOwes = transaction.type == TransactionType.owes;
    final color = isOwes ? Colors.green[700]! : Colors.red[700]!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isOwes ? Icons.arrow_upward : Icons.arrow_downward,
              color: color,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Transaction Details',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'User', value: transaction.userName),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Amount',
              value: '${isOwes ? '+' : '-'}${transaction.amount.toStringAsFixed(2)} ETB',
              valueColor: color,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Type',
              value: isOwes ? 'They Owe Me' : 'I Owed Them',
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Date',
              value: DateFormat('MMMM d, yyyy').format(transaction.date),
            ),
            if (transaction.note != null && transaction.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Note',
                value: transaction.note!,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwes = transaction.type == TransactionType.owes;
    final color = isOwes ? Colors.green[700]! : Colors.red[700]!;
    final noteText = transaction.note != null && transaction.note!.isNotEmpty
        ? (transaction.note!.length > 12
            ? '${transaction.note!.substring(0, 12)}...'
            : transaction.note!)
        : null;

    return InkWell(
      onTap: () => _showDetailsDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                  Icon(
                    isOwes ? Icons.arrow_upward : Icons.arrow_downward,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          transaction.userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (noteText != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            noteText,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isOwes ? '+' : '-'}${transaction.amount.toStringAsFixed(2)} ETB',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red[400],
                    onPressed: () => onDelete!(transaction.id),
                    tooltip: 'Delete transaction',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

