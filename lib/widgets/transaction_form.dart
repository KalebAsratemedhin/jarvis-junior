import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

/// Form widget to add a new transaction
class TransactionForm extends StatefulWidget {
  final List<String> users;
  final Function(String userName, double amount, TransactionType type, DateTime date, String? note) onSubmit;

  const TransactionForm({
    super.key,
    required this.users,
    required this.onSubmit,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  String? _selectedUser;
  final _amountController = TextEditingController();
  TransactionType _type = TransactionType.owes;
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
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

  void _submit() {
    if (_selectedUser == null || _selectedUser!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a user')),
      );
      return;
    }

    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    widget.onSubmit(
      _selectedUser!,
      amount,
      _type,
      _selectedDate,
      _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    // Reset form
    _amountController.clear();
    _noteController.clear();
    setState(() {
      _type = TransactionType.owes;
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Add Transaction',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedUser,
            decoration: const InputDecoration(
              labelText: 'User',
              border: OutlineInputBorder(),
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
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: 'ETB ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('MMMM d, yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.owes,
                label: Text('Owes Me'),
                icon: Icon(Icons.arrow_upward),
              ),
              ButtonSegment(
                value: TransactionType.owed,
                label: Text('I Owed'),
                icon: Icon(Icons.arrow_downward),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (Set<TransactionType> newSelection) {
              setState(() {
                _type = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

