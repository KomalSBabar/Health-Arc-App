
import '../models/expense_transaction.dart';

class GPayPdfParser {
  static List<ExpenseTransaction> parse(String extractedText) {
    final List<ExpenseTransaction> transactions = [];

    if (extractedText.trim().isEmpty) {
      return transactions;
    }

    // Convert PDF text into one continuous string.
    final String text = extractedText
        .replaceAll('\r', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Recognize dates such as:
    // 27 Oct, 2026
    // 27 Oct 2026
    // 31/10/2026
    // 2026-10-31
    final dateRegex = RegExp(
      r'\b\d{1,2}\s+[A-Za-z]{3,9},?\s+\d{4}\b'
      r'|\b\d{1,2}[/-]\d{1,2}[/-]\d{4}\b'
      r'|\b\d{4}-\d{2}-\d{2}\b',
      caseSensitive: false,
    );

    final dateMatches = dateRegex.allMatches(text).toList();

    for (int i = 0; i < dateMatches.length; i++) {
      final match = dateMatches[i];

      final int start = match.start;
      final int end = i + 1 < dateMatches.length
          ? dateMatches[i + 1].start
          : text.length;

      final String transactionText = text.substring(start, end);

      // Ignore dates that are not transaction records.
      if (!RegExp(
        r'\b(Paid\s+to|Received\s+from)\b',
        caseSensitive: false,
      ).hasMatch(transactionText)) {
        continue;
      }

      final DateTime? transactionDate = _parseDate(match.group(0)!);

      if (transactionDate == null) continue;

      final double? amount = _extractAmount(transactionText);

      if (amount == null || amount <= 0) continue;

      final String type = _extractType(transactionText);

      final String title = _extractTitle(transactionText);

      final String? transactionId =
          _extractTransactionId(transactionText);

      final String? bankName =
          _extractBankName(transactionText);

      final String? accountNumber =
          _extractAccountNumber(transactionText);

      transactions.add(
        ExpenseTransaction(
          id: 'gpay_${DateTime.now().microsecondsSinceEpoch}_$i',
          title: title,
          category: 'Other',
          description: transactionText.trim(),
          amount: amount,
          type: type,
          date: transactionDate,
          transactionId: transactionId,
          bankName: bankName,
          accountNumber: accountNumber,
        ),
      );
    }

    return transactions;
  }

  static DateTime? _parseDate(String value) {
    try {
      final cleaned = value.trim().replaceAll(',', '');

      // yyyy-MM-dd
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(cleaned)) {
        return DateTime.parse(cleaned);
      }

      // dd/MM/yyyy or dd-MM-yyyy
      if (RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{4}$')
          .hasMatch(cleaned)) {
        final parts = cleaned.split(RegExp(r'[/-]'));

        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      // dd MMM yyyy
      final parts = cleaned.split(RegExp(r'\s+'));

      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final monthText = parts[1].toLowerCase();
        final year = int.parse(parts[2]);

        const months = {
          'jan': 1, 'january': 1,
          'feb': 2, 'february': 2,
          'mar': 3, 'march': 3,
          'apr': 4, 'april': 4,
          'may': 5,
          'jun': 6, 'june': 6,
          'jul': 7, 'july': 7,
          'aug': 8, 'august': 8,
          'sep': 9, 'sept': 9, 'september': 9,
          'oct': 10, 'october': 10,
          'nov': 11, 'november': 11,
          'dec': 12, 'december': 12,
        };

        final month = months[monthText];

        if (month != null) {
          return DateTime(year, month, day);
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static double? _extractAmount(String text) {
    final regex = RegExp(
      r'₹\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    );

    final match = regex.firstMatch(text);

    if (match == null) return null;

    return double.tryParse(
      match.group(1)!.replaceAll(',', ''),
    );
  }

  static String _extractType(String text) {
    if (RegExp(
      r'\bReceived\s+from\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return 'Received';
    }

    return 'Paid';
  }

  static String _extractTitle(String text) {
    final paidMatch = RegExp(
      r'\bPaid\s+to\s+(.+?)\s+UPI\s+Transaction\s*ID\b',
      caseSensitive: false,
    ).firstMatch(text);

    if (paidMatch != null) {
      return paidMatch.group(1)!.trim();
    }

    final receivedMatch = RegExp(
      r'\bReceived\s+from\s+(.+?)\s+UPI\s+Transaction\s*ID\b',
      caseSensitive: false,
    ).firstMatch(text);

    if (receivedMatch != null) {
      return receivedMatch.group(1)!.trim();
    }

    return 'Google Pay Transaction';
  }

  static String? _extractTransactionId(String text) {
    final regex = RegExp(
      r'UPI\s+Transaction\s*ID\s*[:#-]?\s*([A-Za-z0-9]+)',
      caseSensitive: false,
    );

    return regex.firstMatch(text)?.group(1);
  }

  static String? _extractBankName(String text) {
    final regex = RegExp(
      r'Paid\s+by\s+(.+?)\s+\d{4}\s+₹',
      caseSensitive: false,
    );

    return regex.firstMatch(text)?.group(1)?.trim();
  }

  static String? _extractAccountNumber(String text) {
    final regex = RegExp(
      r'Paid\s+by\s+.*?\s+(\d{4})\s+₹',
      caseSensitive: false,
    );

    return regex.firstMatch(text)?.group(1);
  }
}
