import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

/// Service to handle finances data persistence
class FinancesService {
  static const String _transactionsFileName = 'transactions.json';
  static const String _usersFileName = 'users.json';
  static const String _transactionsLogFileName = 'transactions_log.txt';

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

  /// Get the file path for transactions log
  Future<File> _getTransactionsLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_transactionsLogFileName');
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

  /// Append transaction to log file
  Future<void> _appendToLogFile(Transaction transaction) async {
    try {
      final logFile = await _getTransactionsLogFile();
      final timestampFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      final dateFormat = DateFormat('yyyy-MM-dd');
      final timestamp = timestampFormat.format(DateTime.now());
      final dateStr = dateFormat.format(transaction.date);
      final typeStr = transaction.type == TransactionType.owes ? 'OWES' : 'OWED';
      final noteStr = transaction.note != null ? ' - ${transaction.note}' : '';
      
      final logEntry = '[$timestamp] $dateStr | ${transaction.userName} | $typeStr | ${transaction.amount.toStringAsFixed(2)} ETB$noteStr\n';
      
      await logFile.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      // Don't throw, just log the error silently
      print('Failed to append to log file: $e');
    }
  }

  /// Mark transaction as paid in log file
  Future<void> _markAsPaidInLogFile(Transaction transaction) async {
    try {
      final logFile = await _getTransactionsLogFile();
      final timestampFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      final dateFormat = DateFormat('yyyy-MM-dd');
      final timestamp = timestampFormat.format(DateTime.now());
      final dateStr = dateFormat.format(transaction.date);
      final typeStr = transaction.type == TransactionType.owes ? 'OWES' : 'OWED';
      final noteStr = transaction.note != null ? ' - ${transaction.note}' : '';
      
      final logEntry = '[$timestamp] $dateStr | ${transaction.userName} | $typeStr | ${transaction.amount.toStringAsFixed(2)} ETB$noteStr | PAID\n';
      
      await logFile.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      // Don't throw, just log the error silently
      print('Failed to mark as paid in log file: $e');
    }
  }

  /// Read transactions log file
  Future<String> readTransactionsLog() async {
    try {
      final logFile = await _getTransactionsLogFile();
      if (!await logFile.exists()) {
        return 'No transactions recorded yet.\n';
      }
      return await logFile.readAsString();
    } catch (e) {
      return 'Error reading log file: $e\n';
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

  /// Delete all transactions for a user (but keep the user)
  Future<void> deleteAllTransactionsForUser(String userName) async {
    final transactions = await loadTransactions();
    final deletedTransactions = transactions
        .where((t) => t.userName == userName)
        .toList();
    final remainingTransactions = transactions
        .where((t) => t.userName != userName)
        .toList();
    
    // Mark all deleted transactions as paid
    for (var transaction in deletedTransactions) {
      await _markAsPaidInLogFile(transaction);
    }
    
    await saveTransactions(remainingTransactions);
  }

  /// Add a transaction and log it
  Future<void> addTransactionAndLog(Transaction transaction) async {
    final transactions = await loadTransactions();
    transactions.add(transaction);
    await saveTransactions(transactions);
    await _appendToLogFile(transaction);
  }

  /// Delete a transaction and mark as paid
  Future<void> deleteTransactionAndMarkPaid(String transactionId) async {
    final transactions = await loadTransactions();
    final transaction = transactions.firstWhere(
      (t) => t.id == transactionId,
      orElse: () => throw Exception('Transaction not found'),
    );
    
    final remainingTransactions = transactions
        .where((t) => t.id != transactionId)
        .toList();
    
    await _markAsPaidInLogFile(transaction);
    await saveTransactions(remainingTransactions);
  }

  /// Export all data to a JSON file
  Future<File> exportToJson() async {
    final transactions = await loadTransactions();
    final users = await loadUsers();
    
    final exportData = {
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
      'users': users,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
    
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/finances_export_$timestamp.json');
    
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(exportData),
    );
    
    return file;
  }

  /// Export transactions to CSV file
  Future<File> exportToCsv() async {
    final transactions = await loadTransactions();
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    // CSV header
    final csvLines = <String>[
      'Date,User,Amount,Type,Note',
    ];
    
    // Sort by date (newest first)
    final sortedTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    // CSV rows
    for (var transaction in sortedTransactions) {
      final date = dateFormat.format(transaction.date);
      final amount = transaction.amount.toStringAsFixed(2);
      final type = transaction.type == TransactionType.owes ? 'Owes Me' : 'I Owed';
      final note = transaction.note?.replaceAll(',', ';').replaceAll('\n', ' ') ?? '';
      
      csvLines.add('$date,"${transaction.userName}",$amount,$type,"$note"');
    }
    
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/finances_export_$timestamp.csv');
    
    await file.writeAsString(csvLines.join('\n'));
    
    return file;
  }

  /// Get the path to the documents directory (for user access)
  Future<String> getDocumentsDirectoryPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}



