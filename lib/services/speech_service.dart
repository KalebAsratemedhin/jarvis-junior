import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Service class to handle all speech recognition operations
class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isInitialized = false;
  bool _isListening = false;
  List<stt.LocaleName> _locales = [];
  
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  List<stt.LocaleName> get locales => _locales;
  
  /// Initialize speech recognition
  Future<bool> initialize({
    required Function(String status) onStatus,
    required Function(String errorMsg) onError,
  }) async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          _isListening = status == 'listening';
          onStatus(status);
        },
        onError: (error) {
          // Don't stop listening on timeout - let user continue speaking
          if (error.errorMsg.contains('timeout') || 
              error.errorMsg.contains('error_speech_timeout')) {
            // Keep listening silently - don't show error for timeouts
            // The recognition will continue
            return;
          } else {
            _isListening = false;
            // Only show critical errors, not timeouts
            onError(error.errorMsg);
          }
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
      
      if (available) {
        try {
          _locales = await _speech.locales().timeout(
            const Duration(seconds: 10),
            onTimeout: () => <stt.LocaleName>[],
          );
        } catch (e) {
          _locales = [];
        }
        _isInitialized = true;
        return true;
      }
      
      _isInitialized = false;
      return false;
    } catch (e) {
      _isInitialized = false;
      onError('Initialization error: $e');
      return false;
    }
  }
  
  /// Start listening for speech
  Future<bool?> listen({
    required Function(String text, bool isFinal) onResult,
    String? localeId,
  }) async {
    if (!_isInitialized) {
      return false;
    }
    
    // Check if speech recognition is available
    if (!_speech.isAvailable) {
      return false;
    }
    
    // Determine locale
    String finalLocaleId = localeId ?? _getDefaultLocale();
    
    try {
      // Stop any existing listening
      if (_isListening) {
        await _speech.stop();
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      final started = await _speech.listen(
        onResult: (result) {
          // Always pass results, whether final or partial
          // This ensures continuous recognition
          onResult(result.recognizedWords, result.finalResult);
        },
        listenFor: const Duration(seconds: 300), // 5 minutes for long speech
        pauseFor: const Duration(seconds: 15), // Increased to 15 seconds - very long pause tolerance
        localeId: finalLocaleId,
        cancelOnError: false, // Don't auto-cancel on errors
        listenOptions: stt.SpeechListenOptions(
          partialResults: true, // Essential for continuous recognition
          listenMode: stt.ListenMode.dictation, // Dictation mode for longer speech
          autoPunctuation: true,
        ),
      ).timeout(
        const Duration(seconds: 20), // Increased timeout for slow connections
        onTimeout: () => null,
      );
      
      return started;
    } catch (e) {
      return null;
    }
  }
  
  /// Stop listening
  Future<void> stop() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }
  
  /// Get default locale (English or first available)
  String _getDefaultLocale() {
    if (_locales.isEmpty) {
      return 'en_US';
    }
    
    // Try to find English locale
    for (var locale in _locales) {
      if (locale.localeId.startsWith('en')) {
        return locale.localeId;
      }
    }
    
    // Use first available
    return _locales.first.localeId;
  }
  
  /// Check if permission is granted
  Future<bool> hasPermission() async {
    return await _speech.hasPermission;
  }
  
  /// Check if speech recognition is available
  bool get isAvailable => _speech.isAvailable;
  
  /// Cancel any ongoing recognition
  Future<void> cancel() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
    }
  }
  
  /// Dispose resources
  void dispose() {
    _speech.stop();
    _speech.cancel();
  }
}

