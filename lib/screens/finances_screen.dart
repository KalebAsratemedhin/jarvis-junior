import 'package:flutter/material.dart';
import '../providers/finances_provider.dart';
import '../models/transaction.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/add_multiple_transactions_dialog.dart';
import '../widgets/transaction_list.dart';
import '../widgets/split_bill_dialog.dart';

/// Finances screen to manage transactions only
class FinancesScreen extends StatefulWidget {
  final FinancesProvider provider;
  
  const FinancesScreen({super.key, required this.provider});

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  FinancesProvider get _provider => widget.provider;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showSplitBillDialog() async {
    if (_provider.state.users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one user first'),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => SplitBillDialog(
        users: _provider.state.users,
        onSplit: (userName, amount, date, note) async {
          await _provider.addTransaction(
            userName: userName,
            amount: amount,
            type: TransactionType.owes, // They owe me their share
            date: date,
            note: note,
          );

          if (_provider.state.error != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_provider.state.error!)),
              );
            }
          }
        },
      ),
    );

    // Scroll to top to show new transactions
    if (mounted) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _showAddTransactionDialog() async {
    if (_provider.state.users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a user first in the Summary tab'),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(
        users: _provider.state.users,
        onSubmit: (userName, amount, type, date, note) async {
          await _provider.addTransaction(
            userName: userName,
            amount: amount,
            type: type,
            date: date,
            note: note,
          );

          if (_provider.state.error != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_provider.state.error!)),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              // Scroll to top to show new transaction
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _showAddMultipleTransactionsDialog() async {
    if (_provider.state.users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a user first in the Summary tab'),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AddMultipleTransactionsDialog(
        users: _provider.state.users,
        onSubmit: (userName, amount, type, date, note) async {
          await _provider.addTransaction(
            userName: userName,
            amount: amount,
            type: type,
            date: date,
            note: note,
          );

          if (_provider.state.error != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_provider.state.error!)),
              );
            }
          }
        },
      ),
    );

    // Scroll to top to show new transactions
    if (mounted) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleDeleteTransaction(String transactionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _provider.deleteTransaction(transactionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: _showSplitBillDialog,
            tooltip: 'Split Bill',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddTransactionDialog,
            tooltip: 'Add Transaction',
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: _showAddMultipleTransactionsDialog,
            tooltip: 'Add Multiple Transactions',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _provider,
        builder: (context, _) {
          final state = _provider.state;

          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactionsByDate = state.transactionsByDate;

          if (state.users.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.all(24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No users added yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please add users in the Summary tab first',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          if (transactionsByDate.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.all(24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add your first transaction using the buttons above',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return TransactionList(
            transactionsByDate: transactionsByDate,
            onDelete: _handleDeleteTransaction,
          );
        },
      ),
    );
  }
}
