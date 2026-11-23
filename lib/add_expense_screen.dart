import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/expense_transaction.dart';
import '../services/gpay_pdf_parser.dart';


class AddExpenseScreen extends StatefulWidget {

  final List<String> categories;
  final List<Map<String, dynamic>> existingTransactions;

  const AddExpenseScreen({
    super.key,
    required this.categories,
    required this.existingTransactions,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> 
    with SingleTickerProviderStateMixin {

        
  late TabController _tabController;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();

  String? selectedCategory;
  String? selectedPdfName;
  // String? selectedPdfPath;
  String extractedPdfText = '';
  List<ExpenseTransaction> extractedTransactions = [];
  int currentPage = 1;
  int rowsPerPage = 10;

  final List<int> rowsPerPageOptions = [10, 25, 50];
  PlatformFile? selectedPdfFile;
  // List<int>? selectedPdfBytes;
  
  

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    if (widget.categories.isNotEmpty) {
      selectedCategory = widget.categories.first;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    amountController.dispose();

    super.dispose();
  }

  void submitManualExpense() {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final amountText = amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (title.isEmpty) {
      showMessage('Please enter an expense title.');
      return;
    }

    if (selectedCategory == null) {
      showMessage('Please select a category.');
      return;
    }

    if (amount == null || amount <= 0) {
      showMessage('Please enter a valid amount.');
      return;
    }

    final expense = <String, dynamic>{
      'title': title,
      'category': selectedCategory,
      'description': description,
      'amount': amount,
      'type': 'Manual',
      'date': DateTime.now(),
    };

    Navigator.pop(context, expense);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }


  Future<void> editTransaction(ExpenseTransaction transaction) async {
    String editedTitle = transaction.title;
    String editedDescription = transaction.description;

    final availableCategories = widget.categories.toSet().toList();

    if (!availableCategories.contains(transaction.category)) {
      availableCategories.add(transaction.category);
    }

    String editedCategory = transaction.category;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Transaction'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: editedTitle,
                      decoration: const InputDecoration(
                        labelText: 'Transaction Title',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        editedTitle = value;
                      },
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: editedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: availableCategories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            editedCategory = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 15),

                    TextFormField(
                      initialValue: editedDescription,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        editedDescription = value;
                      },
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Amount: ₹${transaction.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () {
                    if (editedTitle.trim().isEmpty) {
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave == true && mounted) {
      final index = extractedTransactions.indexOf(transaction);

      if (index != -1) {
        setState(() {
          extractedTransactions[index] = transaction.copyWith(
            title: editedTitle.trim(),
            category: editedCategory,
            description: editedDescription.trim(),
          );
        });

        showMessage('Transaction updated successfully!');
      }
    }
  }


  Widget buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expense Title',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              hintText: 'e.g. Lunch, Grocery, Petrol',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Category',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            value: selectedCategory,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            hint: const Text('Select Category'),
            items: widget.categories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCategory = value;
              });
            },
          ),

          const SizedBox(height: 20),

          const Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter additional details (optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description_outlined),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Amount Spent',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              hintText: 'Enter amount',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.currency_rupee),
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: submitManualExpense,
              icon: const Icon(Icons.check),
              label: const Text(
                'Submit Expense',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOnlineTab() {


    String normalizeTitle(String title) {
      return title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    }

    DateTime parseTransactionDate(dynamic value) {
      if (value is DateTime) return value;
      return DateTime.parse(value.toString());
    }

    bool isDuplicate(ExpenseTransaction candidate, Map<String, dynamic> saved) {
      final candidateId = candidate.transactionId?.trim() ?? '';
      final savedId = saved['transactionId']?.toString().trim() ?? '';

      // Prefer UPI transaction ID when both transactions have one.
      if (candidateId.isNotEmpty && savedId.isNotEmpty) {
        return candidateId == savedId;
      }

      // Otherwise compare date, amount, direction, and normalized title.
      final savedDate = parseTransactionDate(saved['date']);

      final savedDirection =
          saved['transactionType'] ??
          (saved['type'] == 'Received' ? 'Received' : 'Paid');

      return candidate.date.year == savedDate.year &&
          candidate.date.month == savedDate.month &&
          candidate.date.day == savedDate.day &&
          candidate.amount == (saved['amount'] as num).toDouble() &&
          candidate.type == savedDirection &&
          normalizeTitle(candidate.title) ==
              normalizeTitle(saved['title']?.toString() ?? '');
    }


    final List<Map<String, dynamic>> previewNewTransactions = [];
    int previewDuplicateCount = 0;

    for (final candidate in extractedTransactions) {
      final alreadySaved = widget.existingTransactions.any(
        (saved) => isDuplicate(candidate, saved),
      );

      final alreadyInImport = previewNewTransactions.any(
        (saved) => isDuplicate(candidate, saved),
      );

      if (alreadySaved || alreadyInImport) {
        previewDuplicateCount++;
        continue;
      }

      previewNewTransactions.add({
        'id': candidate.id,
        'title': candidate.title,
        'category': candidate.category,
        'description': candidate.description,
        'amount': candidate.amount,
        'type': 'Online',
        'transactionType': candidate.type,
        'date': candidate.date,
        'transactionId': candidate.transactionId,
        'bankName': candidate.bankName,
        'accountNumber': candidate.accountNumber,
      });
    }

    void submitOnlineTransactions() {
      if (extractedTransactions.isEmpty) {
        showMessage('No transactions available to submit.');
        return;
      }

      Navigator.pop(context, {
        'resultType': 'onlineImport',
        'transactions': previewNewTransactions,
        'newCount': previewNewTransactions.length,
        'duplicateCount': previewDuplicateCount,
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),

          const Icon(
            Icons.picture_as_pdf,
            size: 75,
            color: Colors.red,
          ),

          const SizedBox(height: 15),

          const Text(
            'Import Online Transactions',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Upload your GPay transaction statement PDF '
            'to extract and review your transactions.',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 15),

          ElevatedButton.icon(
            onPressed: pickPdfFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload PDF Statement'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 15),

          ElevatedButton.icon(
            onPressed: extractPdfText,
            icon: const Icon(Icons.document_scanner),
            label: const Text('Extract Transactions'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 25),

          if (selectedPdfName != null)
            Card(
              // child: ListTile(
              //   leading: const Icon(
              //     Icons.picture_as_pdf,
              //     color: Colors.red,
              //   ),
              //   title: Text(selectedPdfName!),
              //   subtitle: const Text('PDF selected'),
              // ),
              child: ListTile(
                minVerticalPadding: 8,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
            ),

          if (extractedPdfText.isNotEmpty) ...[
            const Divider(height: 30),

            const Text(
              'Extracted Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (extractedTransactions.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No transactions could be identified. '
                    'We may need to adjust the parser for your PDF format.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            
            else ...[
              // Total transaction count
              Text(
                '${extractedTransactions.length} transactions found',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 15),

              // Pagination calculations
              Builder(
                builder: (context) {
                  final int totalTransactions = extractedTransactions.length;

                  final int totalPages =
                      (totalTransactions / rowsPerPage).ceil();

                  final int startIndex = (currentPage - 1) * rowsPerPage;

                  final int endIndex =
                      (startIndex + rowsPerPage).clamp(0, totalTransactions);

                  final pageTransactions =
                      extractedTransactions.sublist(startIndex, endIndex);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Rows per page selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Rows per page:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),

                          DropdownButton<int>(
                            value: rowsPerPage,
                            items: rowsPerPageOptions.map((value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  rowsPerPage = value;
                                  currentPage = 1;
                                });
                              }
                            },
                          ),
                        ],
                      ),

                      Text(
                        'Showing ${startIndex + 1} to $endIndex '
                        'of $totalTransactions transactions',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Transaction cards for current page
                      ...pageTransactions.map((transaction) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: transaction.isIncome
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              child: Icon(
                                transaction.isIncome
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: transaction.isIncome
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),

                            title: Text(
                              transaction.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            subtitle: Text(
                              '${transaction.category} • '
                              '${transaction.date.day}/'
                              '${transaction.date.month}/'
                              '${transaction.date.year}\n'
                              '${transaction.type}',
                            ),

                            isThreeLine: true,

                            // trailing: Text(
                            //   '₹${transaction.amount.toStringAsFixed(2)}',
                            //   style: TextStyle(
                            //     fontWeight: FontWeight.bold,
                            //     color: transaction.isIncome
                            //         ? Colors.green
                            //         : Colors.red,
                            //   ),
                            // ),

                            
                            
                            trailing: SizedBox(
                              width: 140,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '₹${transaction.amount.toStringAsFixed(2)}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: transaction.isIncome
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ),

                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    tooltip: 'Edit Transaction',
                                    onPressed: () {
                                      editTransaction(transaction);
                                    },
                                  ),

                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    tooltip: 'Delete Transaction',
                                    onPressed: () {
                                      deleteTransaction(transaction);
                                    },
                                  ),
                                ],
                              ),
                            ),



                          ),
                        );
                      }),

                      const SizedBox(height: 15),

                      // Previous and Next buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton.icon(
                            onPressed: currentPage > 1
                                ? () {
                                    setState(() {
                                      currentPage--;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_left),
                            label: const Text('Previous'),
                          ),

                          Text(
                            'Page $currentPage of $totalPages',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          OutlinedButton.icon(
                            onPressed: currentPage < totalPages
                                ? () {
                                    setState(() {
                                      currentPage++;
                                    });
                                  }
                                : null,
                            icon: const Text('Next'),
                            label: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          
          ] else
            const Text(
              'Extracted PDF text will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

           
          if (extractedTransactions.isNotEmpty) ...[
            const SizedBox(height: 20),

            // IMPORT SUMMARY
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Import Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total extracted'),
                        Text('${extractedTransactions.length}'),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('New transactions'),
                        Text(
                          '${previewNewTransactions.length}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Duplicates'),
                        Text(
                          '$previewDuplicateCount',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // SUBMIT BUTTON
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: submitOnlineTransactions,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Submit Transactions',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],

          const SizedBox(height: 15),
          
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,

        // Tab text and icon colors
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,

        // Selected tab indicator
        indicatorColor: Colors.white,
        indicatorWeight: 3,

          tabs: const [
            Tab(
              icon: Icon(Icons.edit_note),
              text: 'Manual',
            ),
            Tab(
              icon: Icon(Icons.cloud_upload_outlined),
              text: 'Online',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildManualTab(),
          buildOnlineTab(),
        ],
      ),
    );
  }


  Future<void> extractPdfText() async {
    try {
      if (selectedPdfFile == null) {
        showMessage('Please upload a PDF first.');
        return;
      }

      final pdfBytes = await selectedPdfFile!.readAsBytes();
      final document = PdfDocument(inputBytes: pdfBytes);

      try {
        final extractor = PdfTextExtractor(document);

        final List<String> pages = [];

        for (int i = 0; i < document.pages.count; i++) {
          final text = extractor.extractText(
            startPageIndex: i,
            endPageIndex: i,
          );

          pages.add(text);
        }

        final result = pages.join('\n\n');
        debugPrint('========== GPAY EXTRACTED TEXT ==========');
        debugPrint(result);
        debugPrint('========== END GPAY TEXT ==========');

        if (result.trim().isEmpty) {
          setState(() {
            extractedPdfText = '';
            extractedTransactions = [];
          });

          showMessage('No selectable text found in this PDF.');
          return;
        }

        // Parse extracted text into transactions.
        final transactions = GPayPdfParser.parse(result);

        setState(() {
          extractedPdfText = result;
          extractedTransactions = transactions;
        });

        debugPrint(
          'Total transactions found: ${transactions.length}',
        );

        if (transactions.isEmpty) {
          showMessage(
            'PDF text extracted, but no transactions were identified.',
          );
        } else {
          showMessage(
            '${transactions.length} transactions extracted successfully!',
          );
        }
      } finally {
        document.dispose();
      }
    } catch (e) {
      showMessage('PDF extraction failed: $e');
      debugPrint('PDF extraction error: $e');
    }
  }

    Future<void> pickPdfFile() async {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          selectedPdfFile = result;
          selectedPdfName = result.name;
          // selectedPdfPath = result.path;
          // selectedPdfBytes = result.bytes;
          extractedPdfText = '';
          extractedTransactions = [];
        });

        showMessage('PDF uploaded successfully!');
      }
    }



Future<void> deleteTransaction(ExpenseTransaction transaction) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete "${transaction.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  if (shouldDelete == true && mounted) {
    setState(() {
      extractedTransactions.remove(transaction);

      final totalPages =
          (extractedTransactions.length / rowsPerPage).ceil();

      if (currentPage > totalPages && totalPages > 0) {
        currentPage = totalPages;
      }

      if (extractedTransactions.isEmpty) {
        currentPage = 1;
      }
    });

    showMessage('Transaction deleted successfully!');
  }
}


}