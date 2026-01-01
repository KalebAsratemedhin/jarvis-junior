import 'package:flutter/material.dart';
import '../providers/speech_provider.dart';
import '../services/nlp_transaction_parser.dart';
import '../services/intent_classifier.dart';
import '../models/parsed_transaction.dart';
import 'voice_transaction_result_dialog.dart';

/// Button for voice transaction input
class VoiceTransactionButton extends StatefulWidget {
  final List<String> existingUsers;
  final Function(ParsedTransaction) onTransactionParsed;

  const VoiceTransactionButton({
    super.key,
    required this.existingUsers,
    required this.onTransactionParsed,
  });

  @override
  State<VoiceTransactionButton> createState() => _VoiceTransactionButtonState();
}

class _VoiceTransactionButtonState extends State<VoiceTransactionButton>
    with SingleTickerProviderStateMixin {
  final SpeechProvider _speechProvider = SpeechProvider();
  final NLPTransactionParser _parser = NLPTransactionParser();
  late AnimationController _animationController;
  bool _isPressed = false;
  String _currentText = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    // Stop listening before disposing
    _speechProvider.stopListening();
    _speechProvider.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) async {
    if (!mounted) return;
    
    setState(() {
      _isPressed = true;
      _currentText = '';
    });
    _animationController.forward();
    
    // Ensure provider is initialized before starting
    try {
      // Wait a bit for initialization if needed
      int attempts = 0;
      while (!_speechProvider.state.isInitialized && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      
      if (!_speechProvider.state.isInitialized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition not ready. Please wait a moment.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isPressed = false;
        });
        _animationController.reverse();
        return;
      }
      
      await _speechProvider.startListening();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start listening: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  void _handleTapUp(TapUpDetails details) async {
    if (!_isPressed) return;
    
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
    
    try {
      // Stop listening and wait for it to complete
      await _speechProvider.stopListening();
      
      // Wait a bit more for final results to be processed
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Show dialog only if widget is still mounted
      if (mounted) {
        _showResultDialog();
      }
    } catch (e) {
      // If stopping fails, still try to show dialog with whatever we have
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        _showResultDialog();
      }
    }
  }

  void _handleTapCancel() async {
    if (!_isPressed) return;
    
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
    
    try {
      // Stop listening and wait for it to complete
      await _speechProvider.stopListening();
      
      // Wait a bit more for final results to be processed
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Show dialog only if widget is still mounted
      if (mounted) {
        _showResultDialog();
      }
    } catch (e) {
      // If stopping fails, still try to show dialog with whatever we have
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        _showResultDialog();
      }
    }
  }
  
  void _showResultDialog() {
    if (!mounted) {
      print('VoiceTransactionButton: Cannot show dialog - widget not mounted');
      return;
    }
    
    // Get text before showing dialog to avoid accessing provider in builder
    String text = '';
    try {
      text = _speechProvider.state.text.trim();
    } catch (e) {
      print('VoiceTransactionButton: Error accessing speech provider state: $e');
      text = '';
    }
    
    print('VoiceTransactionButton: Showing dialog with text: "$text" (length: ${text.length})');
    
    // Use WidgetsBinding to ensure we're on the right frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      try {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) {
            print('VoiceTransactionButton: Building dialog widget');
            return _buildResultDialog(dialogContext, text);
          },
        ).then((_) {
          print('VoiceTransactionButton: Dialog closed');
        }).catchError((error, stackTrace) {
          print('VoiceTransactionButton: Error showing dialog: $error');
          print('Stack trace: $stackTrace');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to show dialog: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      } catch (e, stackTrace) {
        print('VoiceTransactionButton: Exception in _showResultDialog: $e');
        print('Stack trace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    });
  }
  
  Widget _buildResultDialog(BuildContext dialogContext, String text) {
    try {
      final intentClassifier = IntentClassifier();
      final intent = text.isNotEmpty 
          ? intentClassifier.classifyIntent(text)
          : 'unknown';
      
      final parsed = text.isNotEmpty
          ? _parser.parseTransaction(
              text: text,
              existingUsers: widget.existingUsers,
            )
          : const ParsedTransaction(
              errorMessage: 'No speech detected. Please try again.',
              confidence: 0.0,
            );
      
      return VoiceTransactionResultDialog(
        transcribedText: text,
        intent: intent,
        parsed: parsed,
        isListening: false, // Always false since we show dialog after release
        onClose: () {
          try {
            Navigator.of(dialogContext).pop();
          } catch (e) {
            print('VoiceTransactionButton: Error closing dialog: $e');
          }
        },
        onConfirm: (parsed) {
          try {
            Navigator.of(dialogContext).pop();
            widget.onTransactionParsed(parsed);
          } catch (e) {
            print('VoiceTransactionButton: Error confirming dialog: $e');
          }
        },
      );
    } catch (e, stackTrace) {
      print('VoiceTransactionButton: Exception in _buildResultDialog: $e');
      print('Stack trace: $stackTrace');
      // Return a simple error dialog instead of crashing
      return AlertDialog(
        title: const Text('Error'),
        content: Text('Failed to build dialog: $e'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // Safely check if listening
    bool isListening = false;
    try {
      isListening = _speechProvider.state.isListening;
    } catch (e) {
      // Provider might be disposed, use false
      isListening = false;
    }
    final isActive = isListening || _isPressed;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final scale = 1.0 - (_animationController.value * 0.1);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.green : Colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: (isActive ? Colors.green : Colors.blue)
                        .withOpacity(0.4 + (_animationController.value * 0.3)),
                    blurRadius: 15 + (_animationController.value * 8),
                    spreadRadius: 3 + (_animationController.value * 2),
                  ),
                ],
              ),
              child: Icon(
                isActive ? Icons.mic : Icons.mic_none,
                size: 40,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}

