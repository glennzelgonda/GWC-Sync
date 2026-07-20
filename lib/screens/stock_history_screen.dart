import 'package:flutter/material.dart';
import '../mock_data/inventory_store.dart';
import '../theme/app_theme.dart';

class StockHistoryScreen extends StatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  // 'ALL' | 'INCOMING' | 'OUTGOING' | 'DISCONTINUED'
  String _filter = 'ALL';

  static const Map<String, String> _filterLabels = {
    'ALL': 'All Activity',
    'INCOMING': 'Inbound Only',
    'OUTGOING': 'Outbound Only',
    'DISCONTINUED': 'Discontinued Only',
  };

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Text(
                  'Filter Activity',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                for (final entry in _filterLabels.entries)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.accent,
                    value: entry.key,
                    groupValue: _filter,
                    title: Text(entry.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    onChanged: (v) {
                      setState(() => _filter = v!);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _groupLabel(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    if (that == today) return 'TODAY';
    if (that == today.subtract(const Duration(days: 1))) return 'YESTERDAY';
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final store = InventoryStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (store.historyError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                store.historyError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          );
        }

        final logs = store.getHistoryForBranch(filter: _filter);
        final totals = store.getHistoryTotals(filter: _filter);
        final net = totals.incoming - totals.outgoing;

        return RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.card,
          onRefresh: store.simulateRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _SummaryHeader(
                  entryCount: logs.length,
                  incoming: totals.incoming,
                  outgoing: totals.outgoing,
                  net: net,
                  onFilterTap: _openFilterSheet,
                  filterLabel: _filterLabels[_filter]!,
                ),
              ),
              if (logs.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 120),
                      child: Text(
                        'No stock movement recorded yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                )
              else
                _buildGroupedList(logs),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupedList(List<HistoryLog> logs) {
    final items = <Widget>[];
    String? lastGroup;
    for (final log in logs) {
      final group = _groupLabel(log.date);
      if (group != lastGroup) {
        items.add(_DateHeader(label: group));
        lastGroup = group;
      }
      items.add(_HistoryTile(log: log));
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      sliver: SliverList(delegate: SliverChildListDelegate(items)),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final int entryCount;
  final int incoming;
  final int outgoing;
  final int net;
  final VoidCallback onFilterTap;
  final String filterLabel;

  const _SummaryHeader({
    required this.entryCount,
    required this.incoming,
    required this.outgoing,
    required this.net,
    required this.onFilterTap,
    required this.filterLabel,
  });

  @override
  Widget build(BuildContext context) {
    final netColor = net >= 0 ? AppColors.success : AppColors.lowStock;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '$entryCount ${entryCount == 1 ? 'entry' : 'entries'} · $filterLabel',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ),
              Material(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onFilterTap,
                  child: const Padding(
                    padding:  EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list, color: AppColors.accent, size: 16),
                        SizedBox(width: 6),
                        Text('Filter', style: TextStyle(color: AppColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _SummaryPill(
                  color: AppColors.success,
                  icon: Icons.arrow_downward_rounded,
                  label: '+$incoming units in',
                ),
                const SizedBox(width: 10),
                _SummaryPill(
                  color: AppColors.lowStock,
                  icon: Icons.arrow_upward_rounded,
                  label: '-$outgoing units out',
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Net', style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5)),
                    Text(
                      '${net >= 0 ? '+' : ''}$net',
                      style: TextStyle(color: netColor, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _SummaryPill({required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 1)],
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryLog log;
  const _HistoryTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final isIncoming = log.movementType == 'INCOMING';
    final isDiscontinued = log.movementType == 'DISCONTINUED';
    final color = isDiscontinued
        ? AppColors.textSecondary
        : (isIncoming ? AppColors.success : AppColors.lowStock);
    final icon = isDiscontinued
        ? Icons.remove_circle_outline
        : (isIncoming ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded);
    final badgeLabel = isDiscontinued ? 'DISCONTINUED' : (isIncoming ? 'INBOUND' : 'OUTBOUND');

    final timeLabel = log.createdAt != null
        ? '${_hour12(log.createdAt!)}:${log.createdAt!.minute.toString().padLeft(2, '0')} ${log.createdAt!.hour >= 12 ? 'PM' : 'AM'}'
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: isDiscontinued ? 0.15 : 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background,
              border: Border.all(color: color, width: 1.6),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, spreadRadius: 0.5)],
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isDiscontinued ? '${log.quantity} left' : (isIncoming ? '+${log.quantity} units' : '-${log.quantity} units'),
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const Spacer(),
                    if (timeLabel != null)
                      Text(timeLabel, style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  log.tireName,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline, color: AppColors.textMuted, size: 13),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        log.performedBy ?? InventoryStore.instance.currentManagerName ?? 'Unattributed',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _hour12(DateTime dt) {
    final h = dt.hour % 12;
    return h == 0 ? 12 : h;
  }
}