import 'package:flutter/material.dart';
import 'edit_user_dialog.dart';

/// Dialog to show and manage users
class UsersListDialog extends StatelessWidget {
  final List<String> users;
  final Function(String oldName, String newName) onEditUser;
  final Function(String userName) onDeleteUser;
  final Function() onAddUser;

  const UsersListDialog({
    super.key,
    required this.users,
    required this.onEditUser,
    required this.onDeleteUser,
    required this.onAddUser,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Users',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onAddUser();
                    },
                    tooltip: 'Add User',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: users.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No users yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              user.isNotEmpty ? user[0].toUpperCase() : '?',
                            ),
                          ),
                          title: Text(user),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditDialog(
                                  context,
                                  user,
                                  onEditUser,
                                ),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteConfirmation(
                                  context,
                                  user,
                                  onDeleteUser,
                                ),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    String currentName,
    Function(String, String) onEditUser,
  ) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => EditUserDialog(currentName: currentName),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      onEditUser(currentName, newName);
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    String userName,
    Function(String) onDeleteUser,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete "$userName"?\n\n'
          'This will also delete all transactions for this user.',
        ),
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
      Navigator.of(context).pop(); // Close users list dialog
      onDeleteUser(userName);
    }
  }
}

