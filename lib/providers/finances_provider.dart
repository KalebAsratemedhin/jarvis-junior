import 'dart:io';
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
      // Use a more unique ID to avoid collisions when adding multiple transactions quickly
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = (timestamp % 10000).toString().padLeft(4, '0');
      final transaction = Transaction(
        id: '${timestamp}_$random',
        userName: userName,
        amount: amount,
        type: type,
        date: date,
        note: note,
      );

      // Always read from the current state to ensure we have the latest transactions
      final transactions = List<Transaction>.from(_state.transactions)
        ..add(transaction);
      
      await _service.saveTransactions(transactions);
      await _service.addTransactionAndLog(transaction);
      
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
      await _service.deleteTransactionAndMarkPaid(transactionId);
      final transactions = await _service.loadTransactions();
      
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

  /// Delete all transactions for a user (but keep the user)
  Future<void> deleteAllTransactionsForUser(String userName) async {
    try {
      await _service.deleteAllTransactionsForUser(userName);
      final transactions = await _service.loadTransactions();
      
      _state = _state.copyWith(
        transactions: transactions,
        error: null,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to delete transactions: $e');
      notifyListeners();
    }
  }

  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }

  /// Export data to JSON file
  Future<File> exportToJson() async {
    return await _service.exportToJson();
  }

  /// Export data to CSV file
  Future<File> exportToCsv() async {
    return await _service.exportToCsv();
  }

  /// Get documents directory path
  Future<String> getDocumentsDirectoryPath() async {
    return await _service.getDocumentsDirectoryPath();
  }

  /// Read transactions log file
  Future<String> readTransactionsLog() async {
    return await _service.readTransactionsLog();
  }
}

