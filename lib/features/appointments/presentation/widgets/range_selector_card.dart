import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/current_range_provider.dart';

class RangeSelectorCard extends ConsumerWidget {
  const RangeSelectorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(currentRangeProvider);

    void setMonth(DateTime base) {
      final from = DateTime(base.year, base.month, 1);
      final to = DateTime(base.year, base.month + 1, 1);

      ref.read(currentRangeProvider.notifier).state = DateTimeRange(
        start: from,
        end: to,
      );
    }

    void previousMonth() {
      final current = range.start;
      setMonth(DateTime(current.year, current.month - 1, 1));
    }

    void nextMonth() {
      final current = range.start;
      setMonth(DateTime(current.year, current.month + 1, 1));
    }

    void currentMonth() {
      final now = DateTime.now();
      setMonth(now);
    }

    final label =
        '${range.start.month.toString().padLeft(2, '0')}/${range.start.year}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconButton(
              onPressed: previousMonth,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: nextMonth,
              icon: const Icon(Icons.chevron_right),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: currentMonth,
              child: const Text('Mês atual'),
            ),
          ],
        ),
      ),
    );
  }
}