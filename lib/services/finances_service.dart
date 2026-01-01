import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';

/// Service to handle finances data persistence
class FinancesService {
  static const String _transactionsFileName = 'transactions.json';
  static const String _usersFileName = 'users.json';

  /// Get the file path for transactions
  Future<File> _getTransactionsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_transactionsFileName');
  }

  /// Get the file path for users
  Future<File> _getUsersFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_usersFileName');
  }

  /// Load transactions from file
  Future<List<Transaction>> loadTransactions() async {
    try {
      final file = await _getTransactionsFile();
      if (!await file.exists()) {
        return [];
      }

      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      
      return jsonList
          .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save transactions to file
  Future<void> saveTransactions(List<Transaction> transactions) async {
    try {
      final file = await _getTransactionsFile();
      final jsonList = transactions.map((t) => t.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      throw Exception('Failed to save transactions: $e');
    }
  }

  /// Load users from file
  Future<List<String>> loadUsers() async {
    try {
      final file = await _getUsersFile();
      if (!await file.exists()) {
        return [];
      }

      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      
      return jsonList.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save users to file
  Future<void> saveUsers(List<String> users) async {
    try {
      final file = await _getUsersFile();
      await file.writeAsString(jsonEncode(users));
    } catch (e) {
      throw Exception('Failed to save users: $e');
    }
  }

  /// Add a new user
  Future<void> addUser(String userName) async {
    final users = await loadUsers();
    if (!users.contains(userName)) {
      users.add(userName);
      await saveUsers(users);
    }
  }

  /// Update a user name in both users list and all transactions
  Future<void> updateUserName(String oldName, String newName) async {
    // Update users list
    final users = await loadUsers();
    final index = users.indexOf(oldName);
    if (index != -1) {
      users[index] = newName;
      await saveUsers(users);
    }

    // Update all transactions with this user name
    final transactions = await loadTransactions();
    final updatedTransactions = transactions.map((transaction) {
      if (transaction.userName == oldName) {
        return Transaction(
          id: transaction.id,
          userName: newName,
          amount: transaction.amount,
          type: transaction.type,
          date: transaction.date,
          note: transaction.note,
        );
      }
      return transaction;
    }).toList();

    await saveTransactions(updatedTransactions);
  }

  /// Delete a user and all their transactions
  Future<void> deleteUser(String userName) async {
    // Remove from users list
    final users = await loadUsers();
    users.remove(userName);
    await saveUsers(users);

    // Remove all transactions for this user
    final transactions = await loadTransactions();
    final remainingTransactions = transactions
        .where((t) => t.userName != userName)
        .toList();
    await saveTransactions(remainingTransactions);
  }
}



