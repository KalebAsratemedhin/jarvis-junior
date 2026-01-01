import '../models/transaction.dart';

/// Model for parsed transaction data from NLP
class ParsedTransaction {
  final String? userName;
  final double? amount;
  final TransactionType? type;
  final DateTime? date;
  final String? note;
  final double confidence; // 0.0 to 1.0
  final String? errorMessage;

  const ParsedTransaction({
    this.userName,
    this.amount,
    this.type,
    this.date,
    this.note,
    this.confidence = 0.0,
    this.errorMessage,
  });

  bool get isValid => 
      userName != null && 
      userName!.isNotEmpty && 
      amount != null && 
      amount! > 0 && 
      type != null &&
      errorMessage == null;

  ParsedTransaction copyWith({
    String? userName,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? note,
    double? confidence,
    String? errorMessage,
  }) {
    return ParsedTransaction(
      userName: userName ?? this.userName,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note ?? this.note,
      confidence: confidence ?? this.confidence,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

