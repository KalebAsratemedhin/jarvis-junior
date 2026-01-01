import 'package:flutter/material.dart';

/// Widget to display transcribed text
class SpeechTextDisplay extends StatelessWidget {
  final String text;
  
  const SpeechTextDisplay({
    super.key,
    required this.text,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SingleChildScrollView(
        child: Text(
          text.isEmpty ? 'Tap the button and start speaking...' : text,
          style: TextStyle(
            fontSize: 20,
            color: text.isEmpty ? Colors.grey[600] : Colors.black87,
          ),
        ),
      ),
    );
  }
}



