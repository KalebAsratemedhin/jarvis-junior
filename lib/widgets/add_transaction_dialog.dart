import 'package:flutter/material.dart';
import 'transaction_form.dart';
import '../models/transaction.dart';

/// Dialog wrapper for adding a transaction
class AddTransactionDialog extends StatelessWidget {
  final List<String> users;
  final Function(String userName, double amount, TransactionType type, DateTime date, String? note) onSubmit;

  const AddTransactionDialog({
    super.key,
    required this.users,
    required this.onSubmit,
  });

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
          child: TransactionForm(
            users: users,
            onSubmit: (userName, amount, type, date, note) {
              onSubmit(userName, amount, type, date, note);
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }
}

