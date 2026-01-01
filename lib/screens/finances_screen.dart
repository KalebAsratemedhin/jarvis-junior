import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../providers/finances_provider.dart';
import '../models/transaction.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/transaction_list.dart';
import '../widgets/user_summary_list.dart';
import '../widgets/users_list_dialog.dart';
import '../widgets/split_bill_dialog.dart';

/// Finances screen to manage transactions
class FinancesScreen extends StatefulWidget {
  const FinancesScreen({super.key});

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  late final FinancesProvider _provider;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _provider = FinancesProvider();
  }

  @override
  void dispose() {
    _provider.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showAddUserDialog() async {
    final userName = await showDialog<String>(
      context: context,
      builder: (context) => const AddUserDialog(),
    );

    if (userName != null && userName.isNotEmpty) {
      await _provider.addUser(userName);
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
              content: Text('User added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _showUsersListDialog() async {
    await showDialog(
      context: context,
      builder: (context) => UsersListDialog(
        users: _provider.state.users,
        onEditUser: (oldName, newName) async {
          await _provider.editUser(oldName, newName);
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
                  content: Text('User updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        },
        onDeleteUser: (userName) async {
          await _provider.deleteUser(userName);
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
                  content: Text('User deleted successfully'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        },
        onAddUser: _showAddUserDialog,
      ),
    );
  }

  Future<void> _exportData({required String format}) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Exporting data...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      File exportFile;
      if (format == 'json') {
        exportFile = await _provider.exportToJson();
      } else {
        exportFile = await _provider.exportToCsv();
      }

      if (mounted) {
        // Share the file
        await Share.shareXFiles(
          [XFile(exportFile.path)],
          subject: 'Finances Export',
          text: 'Finances data export',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data exported successfully! File saved to: ${exportFile.path}',
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          content: Text('Please add a user first'),
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

  Future<void> _handleDeleteAllTransactionsForUser(String userName) async {
    await _provider.deleteAllTransactionsForUser(userName);
    
    if (_provider.state.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_provider.state.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All transactions for $userName deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
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
        title: const Text('Jarvis 1.0'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'export_json') {
                _exportData(format: 'json');
              } else if (value == 'export_csv') {
                _exportData(format: 'csv');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_json',
                child: Row(
                  children: [
                    Icon(Icons.file_download, size: 20),
                    SizedBox(width: 8),
                    Text('Export as JSON'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, size: 20),
                    SizedBox(width: 8),
                    Text('Export as CSV'),
                  ],
                ),
              ),
            ],
          ),
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
            icon: const Icon(Icons.people),
            onPressed: _showUsersListDialog,
            tooltip: 'Manage Users',
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
          
          // Calculate totals per user
          final Map<String, double> userTotals = {};
          for (var user in state.users) {
            final total = state.getTotalOwedByUser(user);
            if (total != 0 || state.transactions.any((t) => t.userName == user)) {
              userTotals[user] = total;
            }
          }

          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
          
          return Column(
            children: [
              // Empty state if no users
              if (state.users.isEmpty)
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Card(
                        elevation: 2,
                        margin: EdgeInsets.all(isLandscape ? 16 : 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isLandscape ? 20 : 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: isLandscape ? 48 : 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: isLandscape ? 12 : 16),
                              Text(
                                'No users added yet',
                                style: TextStyle(
                                  fontSize: isLandscape ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: isLandscape ? 6 : 8),
                              Text(
                                'Add your first user to start tracking finances',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isLandscape ? 12 : 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: isLandscape ? 16 : 24),
                              ElevatedButton.icon(
                                onPressed: _showAddUserDialog,
                                icon: const Icon(Icons.person_add),
                                label: const Text('Add First User'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isLandscape ? 16 : 24,
                                    vertical: isLandscape ? 8 : 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Transactions list
              Expanded(
                flex: isLandscape ? 2 : 1,
                child: TransactionList(
                  transactionsByDate: transactionsByDate,
                  onDelete: _handleDeleteTransaction,
                ),
              ),

              // Summary footer - Per user breakdown (only show if there are transactions)
              if (state.transactions.isNotEmpty && userTotals.isNotEmpty)
                Flexible(
                  flex: isLandscape ? 1 : 0,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: isLandscape ? 200 : double.infinity,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(isLandscape ? 12 : 20),
                          child: UserSummaryList(
                            userTotals: userTotals,
                            onDeleteAllTransactions: _handleDeleteAllTransactionsForUser,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

