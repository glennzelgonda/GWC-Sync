import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../mock_data/inventory_store.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../utils/page_transitions.dart';
import 'add_inventory_screen.dart';
import 'stock_history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  static const double _brandCapacityReference = 30;

  
  double _maxVolume(List<MonthlyVolume> volumes) {
    double max = 10;
    for (final v in volumes) {
      if (v.incoming > max) max = v.incoming.toDouble();
      if (v.outgoing > max) max = v.outgoing.toDouble();
    }
    const step = 10.0;
    final headroom = max * 1.2;
    return (headroom / step).ceil() * step;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

  List<_BrandLevel> _brandLevels(List<Tire> tires) {
    final Map<String, int> totals = {};
    for (final t in tires) {
      totals[t.brand] = (totals[t.brand] ?? 0) + t.currentStock;
    }
    final levels = totals.entries.map((e) {
      final percent = (e.value / _brandCapacityReference).clamp(0.0, 1.0);
      final isLow = e.value < InventoryStore.lowStockThreshold;
      return _BrandLevel(brand: e.key, stock: e.value, percent: percent, isLow: isLow);
    }).toList();
    levels.sort((a, b) => b.percent.compareTo(a.percent));
    return levels;
  }

  @override
  Widget build(BuildContext context) {
    final store = InventoryStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final tires = store.getTiresForBranch();
        final totalSkus = tires.length;
        final lowStockCount =
            tires.where((t) => t.currentStock < InventoryStore.lowStockThreshold).length;
        final auditLogCount = store.getHistoryForBranch().length;
        final volumes = store.getMonthlyVolumes();
        final brandLevels = _brandLevels(tires);
        final isTablet = Responsive.isTablet(context);

        final skuCard = _FadeInUp(
          delay: Duration.zero,
          child: _CompactKpiCard(
            value: '$totalSkus',
            label: 'Total SKUs',
            accentColor: AppColors.accent,
          ),
        );
        final lowStockCard = _FadeInUp(
          delay: const Duration(milliseconds: 80),
          child: _CompactKpiCard(
            value: '$lowStockCount',
            label: 'Low Stock',
            accentColor: AppColors.lowStock,
          ),
        );
        final auditLogCard = _FadeInUp(
          delay: const Duration(milliseconds: 160),
          child: _CompactKpiCard(
            value: '$auditLogCount',
            label: 'Audit Logs',
            accentColor: AppColors.accent,
          ),
        );

        return RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.card,
          onRefresh: store.simulateRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_greeting()},',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            store.currentManagerName ?? 'Branch Manager',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _NotificationBell(
                      count: lowStockCount,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              lowStockCount == 0
                                  ? 'No low stock alerts right now.'
                                  : '$lowStockCount item${lowStockCount == 1 ? '' : 's'} below the stock threshold.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: skuCard),
                    const SizedBox(width: 10),
                    Expanded(child: lowStockCard),
                    const SizedBox(width: 10),
                    Expanded(child: auditLogCard),
                  ],
                ),
                const SizedBox(height: 24),
                // Simulated Stock Levels
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Simulated Stock Levels',
                                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  '% of capacity by brand',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                          _LivePill(),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (brandLevels.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No stock data available for this branch.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                          ),
                        )
                      else
                        ...brandLevels.map((level) => _BrandLevelRow(level: level)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Monthly Stocking Volume',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Incoming vs Outgoing tire movement',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 20),
                Container(
                  height: isTablet ? 320 : 260,
                  padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: volumes.isEmpty
                      ? const Center(
                          child: Text('No chart data available', style: TextStyle(color: AppColors.textSecondary)),
                        )
                      : LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: (volumes.length - 1).toDouble(),
                            minY: 0,
                            maxY: _maxVolume(volumes),
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) => AppColors.surface,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final label = spot.barIndex == 0 ? 'In' : 'Out';
                                    return LineTooltipItem(
                                      '$label: ${spot.y.toInt()}',
                                      const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  interval: _maxVolume(volumes) / 4,
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                  ),
                                ),
                              ),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.round();
                                    if (index < 0 || index >= volumes.length) return const SizedBox.shrink();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        volumes[index].month,
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            gridData: FlGridData(
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: AppColors.accent.withValues(alpha: 0.12),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(
                                  volumes.length,
                                  (i) => FlSpot(i.toDouble(), volumes[i].incoming.toDouble()),
                                ),
                                isCurved: true,
                                curveSmoothness: 0.25,
                                color: AppColors.accent,
                                barWidth: 3,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                                    radius: 3.5,
                                    color: AppColors.accent,
                                    strokeWidth: 2,
                                    strokeColor: AppColors.card,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.accent.withValues(alpha: 0.35),
                                      AppColors.accent.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                              // Outgoing — dimmer line, no fill, for contrast.
                              LineChartBarData(
                                spots: List.generate(
                                  volumes.length,
                                  (i) => FlSpot(i.toDouble(), volumes[i].outgoing.toDouble()),
                                ),
                                isCurved: true,
                                curveSmoothness: 0.25,
                                color: AppColors.accent.withValues(alpha: 0.35),
                                barWidth: 2,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(show: false),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const _LegendDot(color: AppColors.accent, label: 'Incoming'),
                    const SizedBox(width: 16),
                    _LegendDot(color: AppColors.accent.withValues(alpha: 0.35), label: 'Outgoing'),
                  ],
                ),
                const SizedBox(height: 24),
                // Quick actions
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionTile(
                        icon: Icons.add_box,
                        label: 'Add Stock',
                        onTap: () => Navigator.of(context).push(
                          FadeSlideRoute(
                            page: Scaffold(
                              appBar: AppBar(title: const Text('Restock Entry')),
                              body: const AddInventoryScreen(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionTile(
                        icon: Icons.bar_chart_rounded,
                        label: 'Reports',
                        onTap: () => Navigator.of(context).push(
                          FadeSlideRoute(
                            page: Scaffold(
                              appBar: AppBar(title: const Text('Stock Audit Trail')),
                              body: const StockHistoryScreen(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FadeInUp extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _FadeInUp({required this.child, this.delay = Duration.zero});

  @override
  State<_FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<_FadeInUp> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}


class _CompactKpiCard extends StatelessWidget {
  final String value;
  final String label;
  final Color accentColor;

  const _CompactKpiCard({
    required this.value,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(color: accentColor, fontSize: 22, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _NotificationBell({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card,
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.notifications_rounded, color: AppColors.accent, size: 22),
          ),
          if (count > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: AppColors.lowStock, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}

class _BrandLevel {
  final String brand;
  final int stock;
  final double percent;
  final bool isLow;

  const _BrandLevel({
    required this.brand,
    required this.stock,
    required this.percent,
    required this.isLow,
  });
}

class _BrandLevelRow extends StatelessWidget {
  final _BrandLevel level;
  const _BrandLevelRow({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = level.isLow ? AppColors.lowStock : AppColors.accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                level.brand,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                '${(level.percent * 100).round()}%',
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: level.percent,
              minHeight: 7,
              backgroundColor: AppColors.cardAlt,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.accent, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}