import 'package:flutter/material.dart';

/// Dialog to edit a user name
class EditUserDialog extends StatefulWidget {
  final String currentName;

  const EditUserDialog({
    super.key,
    required this.currentName,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit User'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'User Name',
          hintText: 'Enter user name',
        ),
        autofocus: true,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submit() {
    final userName = _controller.text.trim();
    if (userName.isNotEmpty && userName != widget.currentName) {
      Navigator.of(context).pop(userName);
    } else if (userName == widget.currentName) {
      Navigator.of(context).pop();
    }
  }
}

