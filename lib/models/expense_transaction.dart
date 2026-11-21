
class ExpenseTransaction {
  final String id;
  final String title;
  final String category;
  final String description;
  final double amount;
  final String type;
  final DateTime date;

  // Online transaction details
  final String? transactionId;
  final String? bankName;
  final String? accountNumber;

  ExpenseTransaction({
    required this.id,
    required this.title,
    required this.category,
    this.description = '',
    required this.amount,
    required this.type,
    required this.date,
    this.transactionId,
    this.bankName,
    this.accountNumber,
  });

  // Check whether money is going out or coming in.
  bool get isIncome => type == 'Received';

  bool get isExpense => type == 'Paid';

  // Convert transaction into JSON for local storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'transactionId': transactionId,
      'bankName': bankName,
      'accountNumber': accountNumber,
    };
  }

  // Restore transaction from saved JSON.
  factory ExpenseTransaction.fromJson(
    Map<String, dynamic> json,
  ) {
    return ExpenseTransaction(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'Other',
      description: json['description'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] ?? 'Paid',
      date: DateTime.parse(json['date']),
      transactionId: json['transactionId'],
      bankName: json['bankName'],
      accountNumber: json['accountNumber'],
    );
  }
}
