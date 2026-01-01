import 'package:flutter/material.dart';

/// Widget for the speech recognition button (press and hold)
class SpeechButton extends StatefulWidget {
  final bool isListening;
  final bool isInitialized;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;

  const SpeechButton({
    super.key,
    required this.isListening,
    required this.isInitialized,
    required this.onStartListening,
    required this.onStopListening,
  });

  @override
  State<SpeechButton> createState() => _SpeechButtonState();
}

class _SpeechButtonState extends State<SpeechButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isPressed = false;

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
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isInitialized) return;
    
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
    widget.onStartListening();
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
      widget.onStopListening();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
      widget.onStopListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isListening || _isPressed;
    
    return GestureDetector(
      onTapDown: widget.isInitialized ? _handleTapDown : null,
      onTapUp: widget.isInitialized ? _handleTapUp : null,
      onTapCancel: widget.isInitialized ? _handleTapCancel : null,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final scale = 1.0 - (_animationController.value * 0.1);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.red : Colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: (isActive ? Colors.red : Colors.blue)
                        .withOpacity(0.4 + (_animationController.value * 0.3)),
                    blurRadius: 20 + (_animationController.value * 10),
                    spreadRadius: 5 + (_animationController.value * 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? Icons.mic : Icons.mic_none,
                    size: 60,
                    color: Colors.white,
                  ),
                  if (!widget.isInitialized)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Initializing...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                        ),
                      ),
                    )
                  else if (!isActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Hold to speak',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
