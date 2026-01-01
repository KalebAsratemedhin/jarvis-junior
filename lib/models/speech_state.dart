/// Model class to represent speech recognition state
class SpeechState {
  final bool isInitialized;
  final bool isListening;
  final String status;
  final String text;
  final List<String> availableLocales;
  final String? error;
  
  const SpeechState({
    this.isInitialized = false,
    this.isListening = false,
    this.status = 'Initializing...',
    this.text = '',
    this.availableLocales = const [],
    this.error,
  });
  
  SpeechState copyWith({
    bool? isInitialized,
    bool? isListening,
    String? status,
    String? text,
    List<String>? availableLocales,
    String? error,
  }) {
    return SpeechState(
      isInitialized: isInitialized ?? this.isInitialized,
      isListening: isListening ?? this.isListening,
      status: status ?? this.status,
      text: text ?? this.text,
      availableLocales: availableLocales ?? this.availableLocales,
      error: error,
    );
  }
}



