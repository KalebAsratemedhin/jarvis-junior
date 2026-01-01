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
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(24),
        child: TransactionForm(
          users: users,
          onSubmit: (userName, amount, type, date, note) {
            onSubmit(userName, amount, type, date, note);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

