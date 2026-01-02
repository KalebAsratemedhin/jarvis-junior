import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

/// Dialog to add multiple transactions for a user with a single date
class AddMultipleTransactionsDialog extends StatefulWidget {
  final List<String> users;
  final Function(String userName, double amount, TransactionType type, DateTime date, String? note) onSubmit;

  const AddMultipleTransactionsDialog({
    super.key,
    required this.users,
    required this.onSubmit,
  });

  @override
  State<AddMultipleTransactionsDialog> createState() => _AddMultipleTransactionsDialogState();
}

class _AddMultipleTransactionsDialogState extends State<AddMultipleTransactionsDialog> {
  String? _selectedUser;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _amountsController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _amountsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() async {
    if (_selectedUser == null || _selectedUser!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a user')),
        );
      }
      return;
    }

    final amountsText = _amountsController.text.trim();
    if (amountsText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter at least one amount')),
        );
      }
      return;
    }

    // Parse amounts - split by comma, newline, or space
    final amountsList = amountsText
        .split(RegExp(r'[,;\n\r\s]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => double.tryParse(s))
        .where((amount) => amount != null && amount != 0)
        .toList();

    if (amountsList.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter valid amounts (positive or negative numbers)')),
        );
      }
      return;
    }

    final note = _noteController.text.trim().isEmpty 
        ? null 
        : _noteController.text.trim();

    // Submit all transactions
    int submittedCount = 0;
    for (var amount in amountsList) {
      final type = amount! > 0 ? TransactionType.owes : TransactionType.owed;
      final absAmount = amount.abs();

      await widget.onSubmit(
        _selectedUser!,
        absAmount,
        type,
        _selectedDate,
        note,
      );

      submittedCount++;
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $submittedCount transaction${submittedCount == 1 ? '' : 's'} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenSize = MediaQuery.of(context).size;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final keyboardHeight = viewInsets.bottom;
    final availableHeight = screenSize.height - keyboardHeight;

    return Dialog(
      insetPadding: EdgeInsets.only(
        left: isLandscape ? screenSize.width * 0.15 : 16,
        right: isLandscape ? screenSize.width * 0.15 : 16,
        top: keyboardHeight > 0 ? 8 : 24,
        bottom: keyboardHeight > 0 ? 8 : 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isLandscape ? screenSize.width * 0.7 : double.infinity,
          maxHeight: keyboardHeight > 0 
              ? availableHeight - 16  // When keyboard is open, use almost all available space
              : screenSize.height * 0.85,  // When keyboard is closed, use 85% of screen
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Header with flexible title
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add Multiple Transactions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // User selection
              DropdownButtonFormField<String>(
                value: _selectedUser,
                decoration: const InputDecoration(
                  labelText: 'User',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                items: widget.users.map((user) {
                  return DropdownMenuItem(
                    value: user,
                    child: Text(user),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUser = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Date picker
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  child: Text(
                    DateFormat('MMMM d, yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amounts input
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 80,
                  maxHeight: keyboardHeight > 0 ? 100 : 150,
                ),
                child: TextField(
                  controller: _amountsController,
                  decoration: const InputDecoration(
                    labelText: 'Amounts',
                    hintText: '100, -50, 200\nor one per line',
                    border: OutlineInputBorder(),
                    prefixText: 'ETB ',
                    alignLabelWithHint: true,
                    contentPadding: EdgeInsets.all(12),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  maxLines: null,
                  minLines: keyboardHeight > 0 ? 2 : 3,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
              const SizedBox(height: 12),

              // Help text - more compact
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Separate by commas or new lines. Positive = they owe, negative = you owe.',
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Note field
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Add All'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
