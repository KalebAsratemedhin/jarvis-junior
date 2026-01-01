import 'dart:math';
import '../models/transaction.dart';

/// Extracts entities (names, amounts, types) from text
class EntityExtractor {
  /// Extract person name from text
  String? extractName(String text, List<String> existingUsers) {
    // Normalize text
    final normalized = text.toLowerCase();
    
    // Try to find existing user names first (fuzzy match)
    for (var user in existingUsers) {
      final userLower = user.toLowerCase();
      // Exact match
      if (normalized.contains(userLower)) {
        return user; // Return original case
      }
      // Partial match (name contains user or user contains name)
      if (userLower.contains(normalized.split(' ').first) ||
          normalized.contains(userLower.split(' ').first)) {
        return user;
      }
    }
    
    // Extract name using patterns
    // Pattern 1: "John owes..." or "John owes me..."
    final pattern1 = RegExp(r'^([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\s+(?:owes?|owed)', caseSensitive: false);
    final match1 = pattern1.firstMatch(text);
    if (match1 != null) {
      return _capitalizeName(match1.group(1)!);
    }
    
    // Pattern 2: "I owe John..." or "I owed John..."
    final pattern2 = RegExp(r'(?:I|i)\s+(?:owe|owed)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)', caseSensitive: false);
    final match2 = pattern2.firstMatch(text);
    if (match2 != null) {
      return _capitalizeName(match2.group(1)!);
    }
    
    // Pattern 3: "Add transaction for John..."
    final pattern3 = RegExp(r'(?:for|to)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)', caseSensitive: false);
    final match3 = pattern3.firstMatch(text);
    if (match3 != null) {
      return _capitalizeName(match3.group(1)!);
    }
    
    // Pattern 4: Extract first capitalized word sequence (likely a name)
    final pattern4 = RegExp(r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b');
    final matches = pattern4.allMatches(text);
    for (var match in matches) {
      final potentialName = match.group(1)!;
      // Skip common words
      if (!_isCommonWord(potentialName.toLowerCase())) {
        return potentialName;
      }
    }
    
    return null;
  }
  
  /// Extract amount from text
  double? extractAmount(String text) {
    // Normalize currency terms
    final normalized = text.toLowerCase()
        .replaceAll('birr', '')
        .replaceAll('etb', '')
        .replaceAll('ethiopian', '')
        .replaceAll('currency', '');
    
    // Pattern 1: "100", "100.50", "1,000"
    final pattern1 = RegExp(r'(\d+(?:[.,]\d+)?)');
    final matches = pattern1.allMatches(normalized);
    
    // Get the largest number (likely the amount)
    double? maxAmount;
    for (var match in matches) {
      final numberStr = match.group(1)!.replaceAll(',', '');
      final amount = double.tryParse(numberStr);
      if (amount != null && amount > 0) {
        if (maxAmount == null || amount > maxAmount) {
          maxAmount = amount;
        }
      }
    }
    
    return maxAmount;
  }
  
  /// Extract transaction type (owes or owed)
  TransactionType? extractType(String text) {
    final lowerText = text.toLowerCase();
    
    // Patterns for "owes me" or "owes"
    final owesPatterns = [
      r'\w+\s+owes?\s+(?:me\s+)?\d+',
      r'\w+\s+owes?\s+\d+',
      r'owes?\s+\d+',
      r'\w+\s+debt',
      r'\w+\s+lent',
      r'\w+\s+borrowed',
    ];
    
    // Patterns for "I owe" or "I owed"
    final owedPatterns = [
      r'I\s+owe\s+\w+',
      r'I\s+owed\s+\w+',
      r'owe\s+\w+',
      r'owed\s+\w+',
    ];
    
    // Check for "owes me" first (stronger signal)
    if (owesPatterns.any((pattern) => RegExp(pattern, caseSensitive: false).hasMatch(lowerText))) {
      return TransactionType.owes;
    }
    
    // Check for "I owe" (means I owed them)
    if (owedPatterns.any((pattern) => RegExp(pattern, caseSensitive: false).hasMatch(lowerText))) {
      return TransactionType.owed;
    }
    
    // Default: if contains "owes" without "I", assume "owes me"
    if (lowerText.contains('owes') && !lowerText.contains('i owe')) {
      return TransactionType.owes;
    }
    
    // If contains "owe" with "I", assume "I owed"
    if (lowerText.contains('i owe') || lowerText.contains('i owed')) {
      return TransactionType.owed;
    }
    
    return null;
  }
  
  /// Extract date from text (optional)
  DateTime? extractDate(String text) {
    final lowerText = text.toLowerCase();
    final now = DateTime.now();
    
    if (lowerText.contains('today')) {
      return now;
    }
    if (lowerText.contains('yesterday')) {
      return now.subtract(const Duration(days: 1));
    }
    if (lowerText.contains('tomorrow')) {
      return now.add(const Duration(days: 1));
    }
    
    // Default to today
    return now;
  }
  
  /// Extract note from text (optional)
  String? extractNote(String text) {
    // Look for phrases after "for", "about", "regarding"
    final patterns = [
      RegExp(r'for\s+(.+?)(?:\s+(?:owes?|owed|\d+))', caseSensitive: false),
      RegExp(r'about\s+(.+?)(?:\s+(?:owes?|owed|\d+))', caseSensitive: false),
      RegExp(r'regarding\s+(.+?)(?:\s+(?:owes?|owed|\d+))', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final note = match.group(1)?.trim();
        if (note != null && note.isNotEmpty && note.length > 3) {
          return note;
        }
      }
    }
    
    return null;
  }
  
  /// Calculate confidence score (0.0 to 1.0)
  double calculateConfidence({
    required String? userName,
    required double? amount,
    required TransactionType? type,
  }) {
    double score = 0.0;
    
    if (userName != null && userName.isNotEmpty) {
      score += 0.4;
    }
    if (amount != null && amount > 0) {
      score += 0.4;
    }
    if (type != null) {
      score += 0.2;
    }
    
    return score;
  }
  
  /// Helper: Capitalize name properly
  String _capitalizeName(String name) {
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
  
  /// Helper: Check if word is common (not a name)
  bool _isCommonWord(String word) {
    const commonWords = {
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
      'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'been',
      'be', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would',
      'should', 'could', 'may', 'might', 'must', 'can', 'this', 'that',
      'these', 'those', 'i', 'you', 'he', 'she', 'it', 'we', 'they',
      'me', 'him', 'her', 'us', 'them', 'my', 'your', 'his', 'its',
      'our', 'their', 'add', 'record', 'create', 'new', 'transaction',
      'owes', 'owed', 'owe', 'debt', 'lent', 'borrowed', 'birr', 'etb',
    };
    return commonWords.contains(word.toLowerCase());
  }
}

