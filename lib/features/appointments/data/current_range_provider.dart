import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final currentRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(
    start: DateTime(now.year, now.month, 1),
    end: DateTime(now.year, now.month + 1, 0),
  );
});