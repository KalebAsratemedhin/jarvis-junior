import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/finances_state.dart';
import '../services/finances_service.dart';

/// Provider to manage finances state
class FinancesProvider extends ChangeNotifier {
  final FinancesService _service = FinancesService();
  FinancesState _state = const FinancesState();
  
  FinancesState get state => _state;

  FinancesProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final transactions = await _service.loadTransactions();
      final users = await _service.loadUsers();
      
      _state = _state.copyWith(
        transactions: transactions,
        users: users,
        isLoading: false,
      );
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Failed to load data: $e',
      );
    }
    
    notifyListeners();
  }

  Future<void> addUser(String userName) async {
    if (userName.trim().isEmpty) {
      _state = _state.copyWith(error: 'User name cannot be empty');
      notifyListeners();
      return;
    }

    try {
      await _service.addUser(userName.trim());
      final users = await _service.loadUsers();
      
      _state = _state.copyWith(
        users: users,
        error: null,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to add user: $e');
      notifyListeners();
    }
  }

  Future<void> addTransaction({
    required String userName,
    required double amount,
    required TransactionType type,
    required DateTime date,
    String? note,
  }) async {
    if (amount <= 0) {
      _state = _state.copyWith(error: 'Amount must be greater than 0');
      notifyListeners();
      return;
    }

    try {
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userName: userName,
        amount: amount,
        type: type,
        date: date,
        note: note,
      );

      final transactions = List<Transaction>.from(_state.transactions)
        ..add(transaction);
      
      await _service.saveTransactions(transactions);
      
      _state = _state.copyWith(
        transactions: transactions,
        error: null,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to add transaction: $e');
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      final transactions = _state.transactions
          .where((t) => t.id != transactionId)
          .toList();
      
      await _service.saveTransactions(transactions);
      
      _state = _state.copyWith(
        transactions: transactions,
        error: null,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to delete transaction: $e');
      notifyListeners();
    }
  }

  Future<void> editUser(String oldName, String newName) async {
    if (newName.trim().isEmpty) {
      _state = _state.copyWith(error: 'User name cannot be empty');
      notifyListeners();
      return;
    }

    if (oldName == newName.trim()) {
      return;
    }

    try {
      await _service.updateUserName(oldName, newName.trim());
      final users = await _service.loadUsers();
      final transactions = await _service.loadTransactions();
      
      _state = _state.copyWith(
        users: users,
        transactions: transactions,
        error: null,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to edit user: $e');
      notifyListeners();
    }
  }

  Future<void> deleteUser(String userName) async {
    try {
      await _service.deleteUser(userName);
      final users = await _service.loadUsers();
      final transactions = await _service.loadTransactions();
      
      _state = _state.copyWith(
        users: users,
        transactions: transactions,
        error: null,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to delete user: $e');
      notifyListeners();
    }
  }

  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }
}

