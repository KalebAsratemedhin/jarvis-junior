import 'package:flutter/material.dart';
import '../models/parsed_transaction.dart';
import '../models/transaction.dart';
import '../services/intent_classifier.dart';
import 'package:intl/intl.dart';

/// Dialog to show transcribed text, intent, and parsed transaction
class VoiceTransactionResultDialog extends StatelessWidget {
  final String transcribedText;
  final String intent;
  final ParsedTransaction parsed;
  final bool isListening;
  final VoidCallback? onClose;
  final Function(ParsedTransaction)? onConfirm;

  const VoiceTransactionResultDialog({
    super.key,
    required this.transcribedText,
    required this.intent,
    required this.parsed,
    this.isListening = false,
    this.onClose,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
      final screenWidth = MediaQuery.of(context).size.width;
      
      return AlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isListening ? Icons.mic : Icons.mic_none,
              color: isListening ? Colors.red : Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Voice Transaction',
                style: const TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        contentPadding: EdgeInsets.all(isLandscape ? 16 : 24),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isLandscape ? screenWidth * 0.5 : double.infinity,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transcribed text section
                _buildSection(
                  title: isListening ? 'Listening...' : 'What I heard:',
                  icon: isListening ? Icons.mic : Icons.hearing,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isListening ? Colors.red[50] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isListening ? Colors.red[200]! : Colors.blue[200]!,
                      ),
                    ),
                    child: Text(
                      transcribedText.isEmpty 
                          ? (isListening ? '🔴 Listening... Speak now' : '(No speech detected)')
                          : transcribedText,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: transcribedText.isEmpty ? FontStyle.italic : FontStyle.normal,
                        color: isListening ? Colors.red[700] : null,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Intent section
                _buildSection(
                  title: 'Intent identified:',
                  icon: Icons.psychology,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getIntentColor(intent).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getIntentColor(intent).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getIntentIcon(intent),
                          color: _getIntentColor(intent),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatIntent(intent),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _getIntentColor(intent),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Parsed transaction section
                if (parsed.isValid) ...[
                  _buildSection(
                    title: 'Parsed transaction:',
                    icon: Icons.analytics,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Confidence: ${(parsed.confidence * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(fontSize: 12, color: Colors.green[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (parsed.errorMessage != null && parsed.errorMessage != 'Listening...') ...[
                  _buildSection(
                    title: 'Parsing result:',
                    icon: Icons.error_outline,
                    child: Container(
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
                  ),
                ],
              ],
            ),
          ),
        ),
      actions: [
        if (isListening)
          TextButton(
            onPressed: () {
              if (onClose != null) onClose!();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          )
        else ...[
          TextButton(
            onPressed: () {
              if (onClose != null) onClose!();
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          if (parsed.isValid)
            ElevatedButton(
              onPressed: () {
                if (onConfirm != null) {
                  onConfirm!(parsed);
                } else {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Confirm & Save'),
            ),
        ],
      ],
    );
    } catch (e, stackTrace) {
      // If building fails, return a simple error dialog
      print('VoiceTransactionResultDialog: Error building dialog: $e');
      print('Stack trace: $stackTrace');
      return AlertDialog(
        title: const Text('Error'),
        content: Text('Failed to display dialog: $e'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
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
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Color _getIntentColor(String intent) {
    switch (intent) {
      case 'add_transaction':
        return Colors.green;
      case 'query':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getIntentIcon(String intent) {
    switch (intent) {
      case 'add_transaction':
        return Icons.add_circle;
      case 'query':
        return Icons.search;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.help_outline;
    }
  }

  String _formatIntent(String intent) {
    switch (intent) {
      case 'add_transaction':
        return 'Add Transaction';
      case 'query':
        return 'Query Transaction';
      case 'delete':
        return 'Delete Transaction';
      case 'unknown':
        return 'Unknown Intent';
      default:
        return intent;
    }
  }
}
