import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/transaction.dart';
import 'transaction_repository.dart';

class DateRange {
  final DateTime from;
  final DateTime to;
  const DateRange(this.from, this.to);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DateRange &&
          other.from.millisecondsSinceEpoch == from.millisecondsSinceEpoch &&
          other.to.millisecondsSinceEpoch == to.millisecondsSinceEpoch);

  @override
  int get hashCode => Object.hash(
        from.millisecondsSinceEpoch,
        to.millisecondsSinceEpoch,
      );
}

final incomeRangeProvider =
    StreamProvider.family<List<FinanceTransaction>, DateRange>((ref, range) {
  return ref
      .watch(transactionRepositoryProvider)
      .watchIncomeRange(range.from, range.to);
});