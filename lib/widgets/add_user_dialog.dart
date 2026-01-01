import 'package:flutter/material.dart';

/// Dialog to add a new user
class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenSize = MediaQuery.of(context).size;
    
    return AlertDialog(
      contentPadding: EdgeInsets.all(isLandscape ? 16 : 24),
      title: const Text('Add User'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isLandscape ? screenSize.width * 0.5 : double.infinity,
        ),
        child: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'User Name',
          hintText: 'Enter user name',
        ),
          autofocus: true,
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _submit() {
    final userName = _controller.text.trim();
    if (userName.isNotEmpty) {
      Navigator.of(context).pop(userName);
    }
  }
}



