import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_finances/models/transaction.dart';
import 'package:lumina_finances/models/savings_box.dart';

void main() {
  group('Transaction Model Tests', () {
    test('Transaction with isPending should be created correctly', () {
      final transaction = Transaction(
        id: 1,
        title: 'Test Transaction',
        amount: 100.0,
        date: DateTime.now(),
        category: 'Test',
        type: 'expense',
        isPending: true,
      );

      expect(transaction.isPending, true);
      expect(transaction.amount, 100.0);
      expect(transaction.type, 'expense');
    });

    test('Transaction toMap should include isPending', () {
      final transaction = Transaction(
        id: 1,
        title: 'Test',
        amount: 100.0,
        date: DateTime(2024, 1, 1),
        category: 'Test',
        type: 'income',
        isPending: true,
      );

      final map = transaction.toMap();
      expect(map['isPending'], 1);
    });

    test('Transaction fromMap should handle isPending', () {
      final map = {
        'id': 1,
        'title': 'Test',
        'amount': 100.0,
        'date': '2024-01-01',
        'category': 'Test',
        'type': 'income',
        'isRecurring': 0,
        'recurrenceFrequency': 'monthly',
        'description': '',
        'isPending': 1,
      };

      final transaction = Transaction.fromMap(map);
      expect(transaction.isPending, true);
    });
  });

  group('SavingsBox Model Tests', () {
    test('SavingsBox should calculate current value correctly', () {
      final box = SavingsBox(
        id: 1,
        name: 'Test Box',
        initialAmount: 1000.0,
        entryDate: DateTime.now().subtract(const Duration(days: 365)),
        cdiRate: 100.0,
      );

      final currentValue = box.getCurrentValue();
      expect(currentValue, greaterThan(1000.0)); // Should have some profit
    });

    test('SavingsBox should calculate gross profit', () {
      final box = SavingsBox(
        id: 1,
        name: 'Test Box',
        initialAmount: 1000.0,
        entryDate: DateTime.now().subtract(const Duration(days: 365)),
        cdiRate: 100.0,
      );

      final grossProfit = box.getGrossProfit();
      expect(grossProfit, greaterThan(0)); // Should have profit after 1 year
    });

    test('SavingsBox should calculate income tax correctly', () {
      final box = SavingsBox(
        id: 1,
        name: 'Test Box',
        initialAmount: 1000.0,
        entryDate: DateTime.now().subtract(const Duration(days: 180)),
        exitDate: DateTime.now(),
        cdiRate: 100.0,
      );

      final incomeTax = box.getIncomeTax();
      expect(incomeTax, greaterThan(0)); // Should have some tax
      
      // Tax rate should be 22.5% for investments <= 180 days
      final grossProfit = box.getGrossProfit();
      expect(incomeTax, closeTo(grossProfit * 0.225, 0.01));
    });

    test('SavingsBox should calculate IOF for investments under 30 days', () {
      final box = SavingsBox(
        id: 1,
        name: 'Test Box',
        initialAmount: 1000.0,
        entryDate: DateTime.now().subtract(const Duration(days: 15)),
        exitDate: DateTime.now(),
        cdiRate: 100.0,
      );

      final iof = box.getIOF();
      expect(iof, greaterThan(0)); // Should have IOF
    });

    test('SavingsBox should not have IOF for investments over 30 days', () {
      final box = SavingsBox(
        id: 1,
        name: 'Test Box',
        initialAmount: 1000.0,
        entryDate: DateTime.now().subtract(const Duration(days: 31)),
        exitDate: DateTime.now(),
        cdiRate: 100.0,
      );

      final iof = box.getIOF();
      expect(iof, equals(0.0)); // No IOF after 30 days
    });

    test('SavingsBox should return initial amount for future entry date', () {
      final box = SavingsBox(
        id: 1,
        name: 'Test Box',
        initialAmount: 1000.0,
        entryDate: DateTime.now().add(const Duration(days: 30)),
        cdiRate: 100.0,
      );

      final currentValue = box.getCurrentValue();
      expect(currentValue, equals(1000.0)); // Should be initial amount
    });

    test('SavingsBox toMap and fromMap should work correctly', () {
      final box = SavingsBox(
        id: 1,
        name: 'Test Box',
        initialAmount: 1000.0,
        entryDate: DateTime(2024, 1, 1),
        exitDate: DateTime(2025, 1, 1),
        cdiRate: 110.0,
        description: 'Test description',
      );

      final map = box.toMap();
      final restoredBox = SavingsBox.fromMap(map);

      expect(restoredBox.id, equals(box.id));
      expect(restoredBox.name, equals(box.name));
      expect(restoredBox.initialAmount, equals(box.initialAmount));
      expect(restoredBox.cdiRate, equals(box.cdiRate));
      expect(restoredBox.description, equals(box.description));
    });
  });
}
