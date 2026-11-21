import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/expense_transaction.dart';
import '../services/gpay_pdf_parser.dart';


class AddExpenseScreen extends StatefulWidget {
  int currentPage = 1;
  int rowsPerPage = 10;

  final List<String> categories;
  
  final List<int> rowsPerPageOptions = [10, 25, 50];

  const AddExpenseScreen({
    super.key,
    required this.categories,
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
              child: ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red,
                ),
                title: Text(selectedPdfName!),
                subtitle: const Text('PDF selected'),
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
              Text(
                '${extractedTransactions.length} transactions found',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              ...extractedTransactions.map((transaction) {
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

                    trailing: Text(
                      '₹${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: transaction.isIncome
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                );
              }),
            ],

          
          ] else
            const Text(
              'Extracted PDF text will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

          const SizedBox(height: 15),

          const Text(
            'After reviewing and editing the extracted transactions, '
            'you will be able to submit them to your expense history.',
            textAlign: TextAlign.center,
          ),
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

}