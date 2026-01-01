import 'package:flutter/material.dart';
import '../models/parsed_transaction.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

/// Dialog to confirm and edit voice-parsed transaction
class VoiceTransactionDialog extends StatelessWidget {
  final ParsedTransaction parsed;
  final List<String> existingUsers;
  final Function(String userName, double amount, TransactionType type, DateTime date, String? note) onConfirm;

  const VoiceTransactionDialog({
    super.key,
    required this.parsed,
    required this.existingUsers,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.mic, color: Colors.blue),
          SizedBox(width: 8),
          Text('Voice Transaction'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (parsed.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        parsed.errorMessage!,
                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            if (parsed.isValid) ...[
              _buildInfoRow('User:', parsed.userName ?? 'Unknown'),
              const SizedBox(height: 8),
              _buildInfoRow('Amount:', '${parsed.amount?.toStringAsFixed(2)} ETB'),
              const SizedBox(height: 8),
              _buildInfoRow('Type:', parsed.type == TransactionType.owes ? 'Owes Me' : 'I Owed'),
              const SizedBox(height: 8),
              _buildInfoRow('Date:', DateFormat('MMM d, yyyy').format(parsed.date ?? DateTime.now())),
              if (parsed.note != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow('Note:', parsed.note!),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Confidence: ${(parsed.confidence * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Text(
                'Could not parse the transaction. Please try again with a clearer statement.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (parsed.isValid)
          ElevatedButton(
            onPressed: () {
              onConfirm(
                parsed.userName!,
                parsed.amount!,
                parsed.type!,
                parsed.date ?? DateTime.now(),
                parsed.note,
              );
              Navigator.of(context).pop();
            },
            child: const Text('Confirm'),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

