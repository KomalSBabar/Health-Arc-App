import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'add_expense_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  DateTime selectedMonth = DateTime.now();

  double monthlyBudget = 10000;

  String selectedFilter = 'All';

  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Shopping',
      'amount': 200.0,
      'color': Colors.purple,
      'icon': Icons.shopping_bag,
    },
    {
      'name': 'Housing',
      'amount': 200.0,
      'color': Colors.amber,
      'icon': Icons.home,
    },
    {
      'name': 'Transport',
      'amount': 200.0,
      'color': Colors.red,
      'icon': Icons.directions_bus,
    },
    {
      'name': 'Food & Snacks',
      'amount': 200.0,
      'color': Colors.green,
      'icon': Icons.restaurant,
    },
    {
      'name': 'Get Togethers',
      'amount': 200.0,
      'color': Colors.cyan,
      'icon': Icons.people,
    },
  ];

  final List<Map<String, dynamic>> transactions = [
    {
      'title': 'Poha',
      'category': 'Food & Snacks',
      'amount': 20.0,
      'type': 'Manual',
      'date': DateTime.now(),
    },
    {
      'title': 'Auto',
      'category': 'Transport',
      'amount': 50.0,
      'type': 'Online',
      'date': DateTime.now(),
    },
    {
      'title': 'Coffee',
      'category': 'Food & Snacks',
      'amount': 80.0,
      'type': 'Manual',
      'date': DateTime.now(),
    },
  ];

  double get totalSpending {
    return categories.fold(
      0.0,
      (sum, category) => sum + (category['amount'] as double),
    );
  }

  double get budgetLeft => monthlyBudget - totalSpending;

  String get monthName {
    return '${_monthNames[selectedMonth.month - 1]} ${selectedMonth.year}';
  }

  final List<String> _monthNames = const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  void changeMonth(int amount) {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + amount,
      );
    });
  }

  String formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Add a new expense category.
  void showAddCategoryDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'e.g. Pet Expenses',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isEmpty) {
                  return;
                }

                final alreadyExists = categories.any(
                  (category) =>
                      category['name'].toString().toLowerCase() ==
                      name.toLowerCase(),
                );

                if (alreadyExists) {
                  showMessage('This category already exists.');
                  return;
                }

                setState(() {
                  categories.add({
                    'name': name,
                    'amount': 0.0,
                    'color': Colors.blueGrey,
                    'icon': Icons.category,
                  });
                });

                Navigator.pop(dialogContext);
                showMessage('$name category added.');
              },
              child: const Text('Add Category'),
            ),
          ],
        );
      },
    );
  }

  // Show all expense categories.
  void showAllCategoriesDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Expense Categories'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        (category['color'] as Color).withValues(alpha: 0.15),
                    child: Icon(
                      category['icon'] as IconData,
                      color: category['color'] as Color,
                    ),
                  ),
                  title: Text(category['name'] as String),
                  trailing: Text(
                    formatAmount(category['amount'] as double),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                showAddCategoryDialog();
              },
              child: const Text('Add Category'),
            ),
          ],
        );
      },
    );
  }

  // Transaction filtering.
  void showTransactionFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const Text('Payment Type'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['All', 'Manual', 'Online'].map((filter) {
                  return ChoiceChip(
                    label: Text(filter),
                    selected: selectedFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        selectedFilter = filter;
                      });

                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  
  Future<void> openAddExpenseScreen() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          categories: categories
              .map((category) => category['name'] as String)
              .toList(),
          existingTransactions: transactions,
        ),
      ),
    );

    if (result == null || !mounted) return;

    // ONLINE PDF IMPORT
    if (result['resultType'] == 'onlineImport') {
      final importedList =
          result['transactions'] as List<dynamic>? ?? [];

      final List<Map<String, dynamic>> newTransactions = [];

      for (final item in importedList) {
        final transaction = Map<String, dynamic>.from(item);

        final dateValue = transaction['date'];

        newTransactions.add({
          ...transaction,
          'amount': (transaction['amount'] as num).toDouble(),
          'date': dateValue is DateTime
              ? dateValue
              : DateTime.parse(dateValue.toString()),
          'type': 'Online',
        });
      }

      setState(() {
        transactions.insertAll(0, newTransactions);

        for (final transaction in newTransactions) {
          final transactionType =
              transaction['transactionType'] ?? 'Paid';

          // Only outgoing payments increase expense totals.
          if (transactionType == 'Received') continue;

          final categoryName =
              transaction['category'] ?? 'Other';

          final categoryIndex = categories.indexWhere(
            (item) => item['name'] == categoryName,
          );

          if (categoryIndex != -1) {
            categories[categoryIndex]['amount'] =
                (categories[categoryIndex]['amount'] as double) +
                (transaction['amount'] as double);
          }
        }
      });

      await saveTransactions();

      final newCount = result['newCount'] ?? newTransactions.length;
      final duplicateCount = result['duplicateCount'] ?? 0;

      showMessage(
        'Import completed! $newCount new transactions added, '
        '$duplicateCount duplicates skipped.',
      );

      return;
    }

    // MANUAL EXPENSE
    setState(() {
      transactions.insert(0, result);

      final categoryName = result['category'];
      final amount = result['amount'] as double;

      final category = categories.firstWhere(
        (item) => item['name'] == categoryName,
      );

      category['amount'] =
          (category['amount'] as double) + amount;
    });

    await saveTransactions();

    showMessage('Expense added successfully!');
  }


  Widget buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => changeMonth(-1),
            icon: const Icon(Icons.arrow_circle_left_outlined, size: 32),
          ),
          Text(
            monthName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            onPressed: () => changeMonth(1),
            icon: const Icon(Icons.arrow_circle_right_outlined, size: 32),
          ),
        ],
      ),
    );
  }

  Widget buildBudgetCard() {
    final spending = totalSpending;
    final remaining = budgetLeft < 0 ? 0.0 : budgetLeft;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black54),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Spending',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(formatAmount(spending)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Budget Left',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(formatAmount(remaining)),
                  ],
                ),
              ],
            ),
            Slider(
              value: spending.clamp(0.0, monthlyBudget),
              min: 0,
              max: monthlyBudget <= 0 ? 1 : monthlyBudget,
              onChanged: null,
              activeColor: Colors.grey.shade700,
              inactiveColor: Colors.grey.shade300,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  showMessage('Monthly budget settings will be added next.');
                },
                child: const Text('Manage Budget'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCategoryChart() {
    final sortedCategories = [...categories]
      ..sort(
        (a, b) =>
            (b['amount'] as double).compareTo(a['amount'] as double),
      );

    final topCategories = sortedCategories.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: SizedBox(
              height: 170,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 28,
                  sectionsSpace: 2,
                  sections: topCategories.map((category) {
                    final amount = category['amount'] as double;
                    final percentage = totalSpending == 0
                        ? 0
                        : (amount / totalSpending) * 100;

                    return PieChartSectionData(
                      value: amount == 0 ? 0.1 : amount,
                      color: category['color'] as Color,
                      radius: 60,
                      title: '${percentage.toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Top Categories',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ...topCategories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 15,
                          height: 15,
                          color: category['color'] as Color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category['name'] as String,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: showAllCategoriesDialog,
                    child: const Text(
                      'View Details',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: showAddCategoryDialog,
                    child: const Text(
                      '+ Add Category',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTransactionsCard() {
    final filteredTransactions = transactions.where((transaction) {
      return selectedFilter == 'All' ||
          transaction['type'] == selectedFilter;
    }).toList();

    final recentTransactions = filteredTransactions.take(3).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black54),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'All Expense Transactions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: openAddExpenseScreen,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: showTransactionFilter,
                  icon: const Icon(Icons.filter_alt_outlined),
                ),
              ],
            ),
            if (recentTransactions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No transactions found.'),
              ),
            ...recentTransactions.map((transaction) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.circle, size: 8),
                title: Text(
                  transaction['title'] as String,
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  '(${transaction['category']})',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatAmount(transaction['amount'] as double),
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      '(${transaction['type']})',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              );
            }),
            const Divider(),
            TextButton(
              onPressed: () {
                showMessage('All Transactions screen will be created next.');
              },
              child: const Text('View All Transactions'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            buildMonthSelector(),
            buildBudgetCard(),
            buildCategoryChart(),
            Expanded(
              child: SingleChildScrollView(
                child: buildTransactionsCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();

    final savedData = prefs.getString('expense_transactions');

    if (savedData != null) {
      final List<dynamic> decodedData = jsonDecode(savedData);

      setState(() {
        transactions
          ..clear()
          ..addAll(
            decodedData.map((item) {
              return {
                ...Map<String, dynamic>.from(item),
                'amount': (item['amount'] as num).toDouble(),
                'date': DateTime.parse(item['date']),
              };
            }),
          );
      });
    } else {
      // First launch: save the existing sample transactions.
      await saveTransactions();
    }
  }

  Future<void> saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();

    final dataToSave = transactions.map((transaction) {
      return {
        ...transaction,
        'date': (transaction['date'] as DateTime).toIso8601String(),
      };
    }).toList();

    await prefs.setString(
      'expense_transactions',
      jsonEncode(dataToSave),
    );
  }

}