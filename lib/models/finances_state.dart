import '../models/transaction.dart';

/// State model for finances screen
class FinancesState {
  final List<String> users;
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;

  const FinancesState({
    this.users = const [],
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  FinancesState copyWith({
    List<String>? users,
    List<Transaction>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return FinancesState(
      users: users ?? this.users,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get transactions grouped by date
  Map<DateTime, List<Transaction>> get transactionsByDate {
    final Map<DateTime, List<Transaction>> grouped = {};
    
    for (var transaction in transactions) {
      // Group by date (ignore time)
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      
      grouped.putIfAbsent(date, () => []).add(transaction);
    }
    
    // Sort dates in descending order (newest first)
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    
    return Map.fromEntries(sortedEntries);
  }

  /// Calculate total owed by a specific user
  double getTotalOwedByUser(String userName) {
    return transactions
        .where((t) => t.userName == userName)
        .fold(0.0, (sum, t) => sum + t.effectiveAmount);
  }

  /// Calculate total owed by all users
  double get totalOwed {
    return transactions.fold(0.0, (sum, t) => sum + t.effectiveAmount);
  }
}



