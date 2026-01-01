import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Dialog to split a bill equally among selected users
class SplitBillDialog extends StatefulWidget {
  final List<String> users;
  final Function(String userName, double amount, DateTime date, String? note) onSplit;

  const SplitBillDialog({
    super.key,
    required this.users,
    required this.onSplit,
  });

  @override
  State<SplitBillDialog> createState() => _SplitBillDialogState();
}

class _SplitBillDialogState extends State<SplitBillDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final Set<String> _selectedUsers = {};
  bool _includeMe = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updatePreview);
  }

  @override
  void dispose() {
    _amountController.removeListener(_updatePreview);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    setState(() {
      // Trigger rebuild to update preview
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the total amount'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final totalAmount = double.tryParse(amountText);
    if (totalAmount == null || totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedUsers.isEmpty && !_includeMe) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one user or include yourself'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Calculate number of people (selected users + optionally "me")
    final numberOfPeople = _selectedUsers.length + (_includeMe ? 1 : 0);
    if (numberOfPeople == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one person'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Calculate amount per person
    final amountPerPerson = totalAmount / numberOfPeople;
    final note = _noteController.text.trim().isEmpty 
        ? null 
        : _noteController.text.trim();

    // Create transactions for each selected user (not for "me")
    // Await each transaction to ensure they're all saved
    for (var user in _selectedUsers) {
      await widget.onSplit(user, amountPerPerson, _selectedDate, note);
    }

    if (mounted) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Split ${totalAmount.toStringAsFixed(2)} ETB among ${numberOfPeople} ${numberOfPeople == 1 ? 'person' : 'people'} (${amountPerPerson.toStringAsFixed(2)} ETB each)',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isLandscape ? screenSize.width * 0.6 : 400,
          maxHeight: screenSize.height * 0.8,
        ),
        padding: EdgeInsets.all(isLandscape ? 16 : 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Split Bill',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Total amount input
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Total Amount (ETB)',
                  hintText: 'Enter total amount',
                  prefixText: 'ETB ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  ),
                  child: Text(
                    DateFormat('MMM d, yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Include me checkbox
              Card(
                color: Colors.blue[50],
                child: CheckboxListTile(
                  title: const Text('Include me'),
                  subtitle: const Text('Counted but not charged'),
                  value: _includeMe,
                  onChanged: (value) {
                    setState(() {
                      _includeMe = value ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Users selection
              const Text(
                'Select users to split with:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              if (widget.users.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No users available. Please add users first.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              else
                ...widget.users.map((user) => CheckboxListTile(
                      title: Text(user),
                      value: _selectedUsers.contains(user),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedUsers.add(user);
                          } else {
                            _selectedUsers.remove(user);
                          }
                        });
                      },
                    )),

              const SizedBox(height: 16),

              // Note input
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'e.g., Restaurant bill, Groceries',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Preview
              if (_amountController.text.isNotEmpty &&
                  (_selectedUsers.isNotEmpty || _includeMe))
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Preview:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final totalAmount = double.tryParse(_amountController.text.trim()) ?? 0;
                            final numberOfPeople = _selectedUsers.length + (_includeMe ? 1 : 0);
                            final amountPerPerson = numberOfPeople > 0 
                                ? totalAmount / numberOfPeople 
                                : 0;
                            
                            return Text(
                              '${numberOfPeople} ${numberOfPeople == 1 ? 'person' : 'people'} × ${amountPerPerson.toStringAsFixed(2)} ETB = ${totalAmount.toStringAsFixed(2)} ETB',
                              style: const TextStyle(fontSize: 14),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Actions
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
                    child: const Text('Split Bill'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

