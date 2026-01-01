import 'package:flutter/material.dart';
import '../services/speech_service.dart';
import '../models/speech_state.dart';

/// Provider class to manage speech recognition state
class SpeechProvider extends ChangeNotifier {
  final SpeechService _speechService = SpeechService();
  SpeechState _state = const SpeechState();
  bool _isDisposed = false;
  
  SpeechState get state => _state;
  
  SpeechProvider() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    if (_isDisposed) return;
    
    _updateStatus('Initializing speech recognition...');
    
    // Check permission first (initialize() will request permission if needed)
    final hasPermission = await _speechService.hasPermission();
    if (_isDisposed) return;
    
    if (!hasPermission) {
      _updateStatus('Requesting microphone permission...');
    }
    
    final initialized = await _speechService.initialize(
      onStatus: (status) {
        if (!_isDisposed) {
          _updateStatus('Status: $status');
        }
      },
      onError: (error) {
        if (!_isDisposed) {
          _updateError(error);
        }
      },
    );
    
    if (_isDisposed) return;
    
    if (initialized) {
      // Check if speech recognition is available
      if (!_speechService.isAvailable) {
        _state = _state.copyWith(
          isInitialized: false,
          status: 'Speech recognition not available',
          error: 'Speech service unavailable. Install Google app from Play Store.',
        );
      } else {
        final locales = _speechService.locales
            .map((locale) => locale.localeId)
            .toList();
        
        _state = _state.copyWith(
          isInitialized: true,
          status: locales.isEmpty 
              ? 'Ready (using default locale)'
              : 'Ready - ${locales.length} locales available',
          availableLocales: locales,
        );
      }
    } else {
      // Check permission again after initialization attempt
      final permissionAfterInit = await _speechService.hasPermission();
      if (_isDisposed) return;
      
      if (!permissionAfterInit) {
        _state = _state.copyWith(
          isInitialized: false,
          status: 'Microphone permission not granted',
          error: 'Permission denied. Please grant microphone access in app settings.',
        );
      } else {
        _state = _state.copyWith(
          isInitialized: false,
          status: 'Speech recognition not available - check permissions',
          error: 'Failed to initialize speech recognition. Please check permissions and try again.',
        );
      }
    }
    
    if (!_isDisposed) {
      notifyListeners();
    }
  }
  
  Future<void> toggleListening() async {
    if (!_state.isInitialized) {
      await _initialize();
      if (!_state.isInitialized) {
        return;
      }
    }
    
    if (_state.isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }
  
  Future<void> startListening() async {
    if (_isDisposed) return;
    
    // Don't return early if already listening - allow restart if needed
    if (_state.isListening) {
      // If already listening, just update status
      if (!_isDisposed) {
        _state = _state.copyWith(
          status: 'Listening...',
          error: null, // Clear any previous errors
        );
        notifyListeners();
      }
      return;
    }
    
    if (!_isDisposed) {
      _state = _state.copyWith(
        text: '',
        status: 'Starting...',
        error: null, // Clear errors when starting
      );
      notifyListeners();
    }
    
    final started = await _speechService.listen(
      onResult: (text, isFinal) {
        if (!_isDisposed) {
          // Always update text, even if it's a final result
          // Don't stop listening on final - keep accumulating
          _state = _state.copyWith(
            text: text, // Always update with latest text
            status: text.isEmpty 
                ? 'Listening...'
                : 'Listening...', // Always show listening while button is held
            error: null, // Clear errors when receiving results
            isListening: true, // Ensure we stay in listening state
          );
          notifyListeners();
        }
      },
    );
    
    if (_isDisposed) return;
    
    if (started == true) {
      _state = _state.copyWith(
        isListening: true,
        status: 'Listening...',
        error: null,
      );
    } else {
      // Only show critical errors, not timeouts
      String? errorMsg;
      if (started == false) {
        errorMsg = 'Failed to start. Check permissions.';
      } else if (started == null) {
        // Don't show timeout errors - just keep trying
        errorMsg = null;
        _state = _state.copyWith(
          isListening: true, // Assume it's working even if timeout
          status: 'Listening...',
          error: null, // Clear errors on timeout
        );
        if (!_isDisposed) {
          notifyListeners();
        }
        return; // Early return to avoid setting error
      } else {
        errorMsg = 'Failed to start.';
      }
      
      _state = _state.copyWith(
        isListening: false,
        status: 'Failed to start',
        error: errorMsg,
      );
    }
    
    if (!_isDisposed) {
      notifyListeners();
    }
  }
  
  Future<void> stopListening() async {
    if (_isDisposed || !_state.isListening) return;
    
    await _speechService.stop();
    
    if (_isDisposed) return;
    
    // Wait a moment for any final results to come through
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_isDisposed) return;
    
    _state = _state.copyWith(
      isListening: false,
      status: _state.text.isEmpty ? 'Stopped' : 'Processing final result...',
    );
    notifyListeners();
    
    // Update status after a moment
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (_isDisposed) return;
    
    _state = _state.copyWith(
      status: _state.text.isEmpty ? 'Ready' : 'Ready - ${_state.text.length} chars',
    );
    notifyListeners();
  }
  
  void _updateStatus(String status) {
    if (_isDisposed) return;
    _state = _state.copyWith(status: status);
    notifyListeners();
  }
  
  void _updateError(String error) {
    if (_isDisposed) return;
    _state = _state.copyWith(
      error: error,
      isListening: false,
    );
    notifyListeners();
  }
  
  /// Retry initialization (useful if permission was denied)
  Future<void> retryInitialization() async {
    await _initialize();
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _speechService.cancel();
    _speechService.dispose();
    super.dispose();
  }
}



