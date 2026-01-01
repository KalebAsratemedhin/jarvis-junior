import 'package:flutter/material.dart';
import '../providers/speech_provider.dart';
import '../widgets/speech_text_display.dart';
import '../widgets/speech_button.dart';
import '../widgets/status_indicator.dart';

/// Main home screen for speech recognition
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final SpeechProvider _speechProvider;
  
  @override
  void initState() {
    super.initState();
    _speechProvider = SpeechProvider();
  }
  
  @override
  void dispose() {
    _speechProvider.dispose();
    super.dispose();
  }
  
  void _showErrorSnackBar(String? error) {
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Speech to Text'),
        automaticallyImplyLeading: false,
      ),
      body: ListenableBuilder(
        listenable: _speechProvider,
        builder: (context, _) {
          final state = _speechProvider.state;
          
          // Show error snackbar if there's an error
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showErrorSnackBar(state.error);
          });
          
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: SpeechTextDisplay(text: state.text),
                  ),
                  const SizedBox(height: 32),
                  SpeechButton(
                    isListening: state.isListening,
                    isInitialized: state.isInitialized,
                    onStartListening: () => _speechProvider.startListening(),
                    onStopListening: () => _speechProvider.stopListening(),
                  ),
                  const SizedBox(height: 16),
                  StatusIndicator(
                    status: state.status,
                    isListening: state.isListening,
                    error: state.error,
                    locales: state.availableLocales,
                    onRetry: !state.isInitialized && state.error != null
                        ? () => _speechProvider.retryInitialization()
                        : null,
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

