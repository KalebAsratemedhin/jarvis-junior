import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../providers/finances_provider.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/users_list_dialog.dart';
import '../widgets/user_summary_list.dart';

/// Summary screen for user management and transaction summary
class SummaryScreen extends StatefulWidget {
  final FinancesProvider provider;
  
  const SummaryScreen({super.key, required this.provider});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  FinancesProvider get _provider => widget.provider;

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

  Future<void> _handleDeleteAllTransactionsForUser(String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Transactions'),
        content: Text(
          'Are you sure you want to delete ALL transactions for "$userName"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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
              content: Text('All transactions for "$userName" deleted.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary'),
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

          // Calculate totals per user - show all users even if they have no transactions
          final Map<String, double> userTotals = {};
          for (var user in state.users) {
            final total = state.getTotalOwedByUser(user);
            userTotals[user] = total; // Include all users
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(isLandscape ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Empty state if no users
                if (state.users.isEmpty)
                  Card(
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
                          const Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No users added yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add your first user to start tracking finances',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showAddUserDialog,
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add First User'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Summary section - always show if users exist
                if (state.users.isNotEmpty)
                  UserSummaryList(
                    userTotals: userTotals,
                    onDeleteAllTransactions: _handleDeleteAllTransactionsForUser,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

