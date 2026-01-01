/// Classifies the intent from user speech
class IntentClassifier {
  /// Classify the intent from the text
  /// Returns: 'add_transaction', 'query', 'delete', 'unknown'
  String classifyIntent(String text) {
    final lowerText = text.toLowerCase().trim();
    
    // Keywords for adding transaction
    final addKeywords = [
      'add',
      'record',
      'create',
      'new',
      'transaction',
      'owes',
      'owed',
      'owe',
      'debt',
      'lent',
      'borrowed',
    ];
    
    // Keywords for querying
    final queryKeywords = [
      'how much',
      'what',
      'show',
      'list',
      'total',
      'balance',
      'check',
      'see',
    ];
    
    // Keywords for deleting
    final deleteKeywords = [
      'delete',
      'remove',
      'cancel',
      'undo',
    ];
    
    // Check for add transaction intent
    if (addKeywords.any((keyword) => lowerText.contains(keyword)) ||
        _containsTransactionPattern(lowerText)) {
      return 'add_transaction';
    }
    
    // Check for query intent
    if (queryKeywords.any((keyword) => lowerText.contains(keyword))) {
      return 'query';
    }
    
    // Check for delete intent
    if (deleteKeywords.any((keyword) => lowerText.contains(keyword))) {
      return 'delete';
    }
    
    // Default: assume add transaction if it contains transaction-like patterns
    if (_containsTransactionPattern(lowerText)) {
      return 'add_transaction';
    }
    
    return 'unknown';
  }
  
  /// Check if text contains transaction-like patterns
  bool _containsTransactionPattern(String text) {
    // Patterns like "X owes Y", "X birr", etc.
    final patterns = [
      RegExp(r'\w+\s+(owes?|owed)\s+\d+'),
      RegExp(r'\d+\s+(birr|etb|ethiopian)'),
      RegExp(r'(owes?|owed)\s+\d+'),
      RegExp(r'\w+\s+\d+\s+(birr|etb)'),
    ];
    
    return patterns.any((pattern) => pattern.hasMatch(text));
  }
}

