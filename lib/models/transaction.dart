/// Model representing a financial transaction
class Transaction {
  final String id;
  final String userName;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? note;

  const Transaction({
    required this.id,
    required this.userName,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'amount': amount,
      'type': type.name,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  /// Create from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userName: json['userName'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.owes,
      ),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }

  /// Get the effective amount (positive for owes, negative for owed)
  double get effectiveAmount {
    return type == TransactionType.owes ? amount : -amount;
  }
}

/// Type of transaction
enum TransactionType {
  owes,  // User owes me (adds to total)
  owed,  // I owed user (subtracts from total)
}



