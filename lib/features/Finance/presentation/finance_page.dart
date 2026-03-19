import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/finance_providers.dart';
import '../domain/transaction.dart';

class FinancePage extends ConsumerStatefulWidget {
  const FinancePage({super.key});

  @override
  ConsumerState<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends ConsumerState<FinancePage> {
  DateTime _visibleMonth = DateTime.now();
  PaymentMethod? _methodFilter;

  static const _pink = Color(0xFFE91E63);
  static const _rose = Color(0xFFF8BBD0);
  static const _nude = Color(0xFFFFF3F6);
  static const _ink = Color(0xFF1F1F1F);
  static const _white = Colors.white;

  DateRange _monthRange(DateTime date) {
    final first = DateTime(date.year, date.month, 1);
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    return DateRange(first, nextMonth);
  }

  String _monthTitle(DateTime d) {
    final fmt = DateFormat('MMMM yyyy', 'pt_BR');
    return toBeginningOfSentenceCase(fmt.format(d)) ?? fmt.format(d);
  }

  String _methodLabel(PaymentMethod? m) {
    switch (m) {
      case PaymentMethod.pix:
        return 'Pix';
      case PaymentMethod.dinheiro:
        return 'Dinheiro';
      case PaymentMethod.cartao:
        return 'Cartão';
      default:
        return 'Todos';
    }
  }

  IconData _methodIcon(PaymentMethod? m) {
    switch (m) {
      case PaymentMethod.pix:
        return Icons.qr_code_2;
      case PaymentMethod.dinheiro:
        return Icons.payments_outlined;
      case PaymentMethod.cartao:
        return Icons.credit_card;
      default:
        return Icons.filter_alt_outlined;
    }
  }

  double _sumByMethod(List<FinanceTransaction> list, PaymentMethod method) {
    return list
        .where((t) => t.method == method)
        .fold<double>(0, (acc, t) => acc + t.amount);
  }

  void _prevMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    });
  }

  List<double> _dailyTotals(
    List<FinanceTransaction> items,
    DateTime visibleMonth,
  ) {
    final daysInMonth = DateTime(
      visibleMonth.year,
      visibleMonth.month + 1,
      0,
    ).day;

    final daily = List<double>.filled(daysInMonth, 0.0);

    for (final t in items) {
      final dt = t.effectiveAt?.toLocal();
      if (dt == null) continue;
      if (dt.year != visibleMonth.year || dt.month != visibleMonth.month) {
        continue;
      }
      daily[dt.day - 1] += t.amount;
    }

    return daily;
  }

  double _maxValue(List<double> values) {
    var maxV = 0.0;
    for (final v in values) {
      if (v > maxV) maxV = v;
    }
    return maxV <= 0 ? 1 : maxV;
  }

  Widget _sectionCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _headerCard(String monthText) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_nude, Color(0xFFF7DCE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.attach_money, color: _pink, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Financeiro',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  monthText,
                  style: TextStyle(
                    color: _ink.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Mês anterior',
            onPressed: _prevMonth,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Próximo mês',
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final range = _monthRange(_visibleMonth);
    final async = ref.watch(incomeRangeProvider(range));
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: _nude,
      appBar: AppBar(
        backgroundColor: _nude,
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Financeiro',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (items) {
          final totalPix = _sumByMethod(items, PaymentMethod.pix);
          final totalCash = _sumByMethod(items, PaymentMethod.dinheiro);
          final totalCard = _sumByMethod(items, PaymentMethod.cartao);
          final totalAll = items.fold<double>(0, (acc, t) => acc + t.amount);

          final count = items.length;
          final ticketMedio = count == 0 ? 0.0 : totalAll / count;

          final daily = _dailyTotals(items, _visibleMonth);
          final maxDay = _maxValue(daily);

          final filtered = (_methodFilter == null)
              ? items
              : items.where((t) => t.method == _methodFilter).toList();

          Widget chip({
            required String label,
            required bool selected,
            required VoidCallback onTap,
            IconData? icon,
          }) {
            return ChoiceChip(
              selected: selected,
              onSelected: (_) => onTap(),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 16,
                      color: selected ? _pink : _ink.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              selectedColor: _pink.withValues(alpha: 0.14),
              backgroundColor: _white,
              side: BorderSide(
                color: selected ? _pink : _rose.withValues(alpha: 0.75),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              _headerCard(_monthTitle(_visibleMonth)),
              const SizedBox(height: 14),

              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _rose,
                          child: Icon(_methodIcon(_methodFilter), color: _pink),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Filtro: ${_methodLabel(_methodFilter)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _ink.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        chip(
                          label: 'Todos',
                          icon: Icons.all_inclusive,
                          selected: _methodFilter == null,
                          onTap: () => setState(() => _methodFilter = null),
                        ),
                        chip(
                          label: 'Pix',
                          icon: Icons.qr_code_2,
                          selected: _methodFilter == PaymentMethod.pix,
                          onTap: () =>
                              setState(() => _methodFilter = PaymentMethod.pix),
                        ),
                        chip(
                          label: 'Dinheiro',
                          icon: Icons.payments_outlined,
                          selected: _methodFilter == PaymentMethod.dinheiro,
                          onTap: () => setState(
                            () => _methodFilter = PaymentMethod.dinheiro,
                          ),
                        ),
                        chip(
                          label: 'Cartão',
                          icon: Icons.credit_card,
                          selected: _methodFilter == PaymentMethod.cartao,
                          onTap: () => setState(
                            () => _methodFilter = PaymentMethod.cartao,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard do mês',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: _ink.withValues(alpha: 0.85),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final small = constraints.maxWidth < 520;

                        if (small) {
                          return Column(
                            children: [
                              _KpiCard(
                                title: 'Faturamento',
                                value: money.format(totalAll),
                              ),
                              const SizedBox(height: 10),
                              _KpiCard(
                                title: 'Ticket médio',
                                value: money.format(ticketMedio),
                              ),
                              const SizedBox(height: 10),
                              _KpiCard(
                                title: 'Entradas',
                                value: '$count',
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: _KpiCard(
                                title: 'Faturamento',
                                value: money.format(totalAll),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _KpiCard(
                                title: 'Ticket médio',
                                value: money.format(ticketMedio),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _KpiCard(
                                title: 'Entradas',
                                value: '$count',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Faturamento por dia',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: _ink.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 120,
                      child: _BarsChart(
                        values: daily,
                        maxValue: maxDay,
                        rose: _rose,
                        pink: _pink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo do mês',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: _ink.withValues(alpha: 0.85),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _RowMoney(
                      label: 'Total',
                      value: money.format(totalAll),
                      bold: true,
                    ),
                    const SizedBox(height: 8),
                    Divider(color: _rose.withValues(alpha: 0.6)),
                    const SizedBox(height: 8),
                    _RowMoney(
                      label: 'Pix',
                      value: money.format(totalPix),
                      icon: Icons.qr_code_2,
                    ),
                    _RowMoney(
                      label: 'Dinheiro',
                      value: money.format(totalCash),
                      icon: Icons.payments_outlined,
                    ),
                    _RowMoney(
                      label: 'Cartão',
                      value: money.format(totalCard),
                      icon: Icons.credit_card,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Text(
                    'Entradas',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _ink.withValues(alpha: 0.85),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _rose.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${filtered.length}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (filtered.isEmpty)
                _sectionCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _rose,
                        child: const Icon(Icons.inbox, color: _pink),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Nenhuma entrada neste filtro.',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _ink.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...filtered.map((t) {
                  final dt = t.effectiveAt;
                  final whenText = dt == null
                      ? '-'
                      : DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
                  final methodText = _methodLabel(t.method);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _sectionCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: _rose,
                          child: const Icon(
                            Icons.arrow_downward,
                            color: _pink,
                          ),
                        ),
                        title: Text(
                          money.format(t.amount),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          'Método: $methodText\n$whenText',
                          style: TextStyle(color: _ink.withValues(alpha: 0.65)),
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _RowMoney extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final IconData? icon;

  const _RowMoney({
    required this.label,
    required this.value,
    this.bold = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1F1F1F);

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: ink.withValues(alpha: 0.75)),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: ink.withValues(alpha: 0.85),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;

  const _KpiCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1F1F1F);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF8BBD0).withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: ink.withValues(alpha: 0.65),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarsChart extends StatelessWidget {
  final List<double> values;
  final double maxValue;
  final Color rose;
  final Color pink;

  const _BarsChart({
    required this.values,
    required this.maxValue,
    required this.rose,
    required this.pink,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        const barWidth = 8.0;
        const spacing = 3.0;
        final neededWidth = values.length * (barWidth + spacing);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: neededWidth < c.maxWidth ? c.maxWidth : neededWidth,
            height: h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final v in values)
                  Padding(
                    padding: const EdgeInsets.only(right: spacing),
                    child: Container(
                      width: barWidth,
                      height: (h * (v / maxValue)).clamp(2.0, h),
                      decoration: BoxDecoration(
                        color: v <= 0
                            ? rose.withValues(alpha: 0.28)
                            : pink.withValues(alpha: 0.68),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}