import '../models/parsed_transaction.dart';
import 'intent_classifier.dart';
import 'entity_extractor.dart';

/// Main NLP service for parsing transaction speech
class NLPTransactionParser {
  final IntentClassifier _intentClassifier = IntentClassifier();
  final EntityExtractor _entityExtractor = EntityExtractor();
  
  /// Parse speech text into a transaction
  /// 
  /// Returns ParsedTransaction with extracted entities and confidence score
  ParsedTransaction parseTransaction({
    required String text,
    required List<String> existingUsers,
  }) {
    if (text.trim().isEmpty) {
      return const ParsedTransaction(
        errorMessage: 'No text provided',
        confidence: 0.0,
      );
    }
    
    // Classify intent
    final intent = _intentClassifier.classifyIntent(text);
    
    if (intent != 'add_transaction' && intent != 'unknown') {
      return ParsedTransaction(
        errorMessage: 'Intent not supported: $intent. Please say something like "John owes 100 birr"',
        confidence: 0.0,
      );
    }
    
    // Extract entities
    final userName = _entityExtractor.extractName(text, existingUsers);
    final amount = _entityExtractor.extractAmount(text);
    final type = _entityExtractor.extractType(text);
    final date = _entityExtractor.extractDate(text);
    final note = _entityExtractor.extractNote(text);
    
    // Calculate confidence
    final confidence = _entityExtractor.calculateConfidence(
      userName: userName,
      amount: amount,
      type: type,
    );
    
    // Validate and create error messages
    String? errorMessage;
    if (userName == null || userName.isEmpty) {
      errorMessage = 'Could not identify the person. Please say the name clearly.';
    } else if (amount == null || amount <= 0) {
      errorMessage = 'Could not identify the amount. Please say a number like "100 birr".';
    } else if (type == null) {
      errorMessage = 'Could not determine if they owe you or you owe them. Try saying "owes" or "I owe".';
    }
    
    return ParsedTransaction(
      userName: userName,
      amount: amount,
      type: type,
      date: date ?? DateTime.now(),
      note: note,
      confidence: confidence,
      errorMessage: errorMessage,
    );
  }
  
  /// Get suggestions for improving the speech
  List<String> getSuggestions(ParsedTransaction parsed) {
    final suggestions = <String>[];
    
    if (parsed.userName == null) {
      suggestions.add('Try saying: "John owes 100 birr"');
      suggestions.add('Or: "I owe Mary 50 ETB"');
    }
    
    if (parsed.amount == null) {
      suggestions.add('Include the amount: "100 birr" or "50 ETB"');
    }
    
    if (parsed.type == null) {
      suggestions.add('Specify who owes: "John owes me" or "I owe John"');
    }
    
    return suggestions;
  }
}

