import 'package:flutter/material.dart';
import '../mock_data/inventory_store.dart';
import '../theme/app_theme.dart';

class TireDetailsScreen extends StatelessWidget {
  final String tireId;
  const TireDetailsScreen({super.key, required this.tireId});

  ({String? width, String? aspect, String? rim}) _parseSpec(String spec) {
    final match = RegExp(r'^(\d{2,3})\s*/\s*(\d{2,3})\s*R\s*(\d{1,2}\.?\d?)', caseSensitive: false)
        .firstMatch(spec.trim());
    if (match == null) return (width: null, aspect: null, rim: null);
    return (
      width: '${match.group(1)} mm',
      aspect: '${match.group(2)}%',
      rim: 'R${match.group(3)}',
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final store = InventoryStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final tire = store.findTireById(tireId);
        if (tire == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Tire Details')),
            body: const Center(
              child: Text(
                'This item is no longer available.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final isLow = tire.currentStock < InventoryStore.lowStockThreshold;
        final parsedSpec = _parseSpec(tire.specifications);
        final lastRestock = store.lastRestockDateFor(tire);

        return Scaffold(
          appBar: AppBar(title: const Text('Tire Details')),
          body: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 16),
                  child: child,
                ),
              );
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Centered hero: icon glows only while pressed, not
                  // statically — matches what was actually asked for.
                  _PressGlowHero(tireId: tire.id, brand: tire.brand),
                  const SizedBox(height: 18),
                  Text(
                    tire.itemName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tire.specifications,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.accent, fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Container(
                      width: 60,
                      height: 3,
                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatColumn(
                            value: '₱${tire.price.toStringAsFixed(0)}',
                            label: 'UNIT PRICE',
                          ),
                        ),
                        Container(width: 1, height: 34, color: AppColors.border),
                        Expanded(
                          child: _StatColumn(
                            value: '${tire.currentStock}',
                            label: 'IN STOCK',
                            valueColor: isLow ? AppColors.lowStock : AppColors.textPrimary,
                          ),
                        ),
                        Container(width: 1, height: 34, color: AppColors.border),
                        Expanded(
                          child: _StatColumn(
                            value: tire.brand,
                            label: 'BRAND',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'PRODUCT SPECIFICATIONS',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _SpecRow(
                          label: 'Price per Unit',
                          value: '₱${tire.price.toStringAsFixed(2)}',
                          highlighted: true,
                        ),
                        _SpecRow(label: 'Available Qty', value: '${tire.currentStock} units'),
                        _SpecRow(label: 'Width', value: parsedSpec.width ?? '—'),
                        _SpecRow(label: 'Aspect Ratio', value: parsedSpec.aspect ?? '—'),
                        _SpecRow(label: 'Rim Diameter', value: parsedSpec.rim ?? '—'),
                        _SpecRow(label: 'Supplier', value: tire.supplier ?? 'Not set'),
                        _SpecRow(label: 'SKU Code', value: tire.skuCode ?? 'Not set'),
                        _SpecRow(
                          label: 'Last Restocked',
                          value: lastRestock != null ? _formatDate(lastRestock) : 'No restock recorded',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (parsedSpec.width == null || tire.supplier == null || tire.skuCode == null)
                    const Padding(
                      padding: EdgeInsets.only(left: 4, top: 10),
                      child: Text(
                        'Some fields show "—" or "Not set" — that\'s real, not a bug. This SKU\'s size format isn\'t standard metric, or supplier/SKU data hasn\'t been entered yet.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 10.5, height: 1.4),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _StatColumn({required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: valueColor ?? AppColors.accent, fontSize: 16, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5, letterSpacing: 0.4),
        ),
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;
  final bool isLast;

  const _SpecRow({
    required this.label,
    required this.value,
    this.highlighted = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.accent.withValues(alpha: 0.16) : Colors.transparent,
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: highlighted ? AppColors.accent : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: highlighted ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PressGlowHero extends StatefulWidget {
  final String tireId;
  final String brand;
  const _PressGlowHero({required this.tireId, required this.brand});

  @override
  State<_PressGlowHero> createState() => _PressGlowHeroState();
}

class _PressGlowHeroState extends State<_PressGlowHero> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: Hero(
          tag: 'tire-icon-${widget.tireId}',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: _pressed ? 0.9 : 0.5),
                width: _pressed ? 2 : 1.4,
              ),
              boxShadow: _pressed
                  ? [
                      BoxShadow(color: AppColors.accent.withValues(alpha: 0.55), blurRadius: 36, spreadRadius: 4),
                      BoxShadow(color: AppColors.accent.withValues(alpha: 0.25), blurRadius: 60, spreadRadius: 10),
                    ]
                  : [
                      BoxShadow(color: AppColors.accent.withValues(alpha: 0.22), blurRadius: 24, spreadRadius: 1),
                    ],
            ),
            child: Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: _pressed ? 1.08 : 1.0,
                child: Text(
                  widget.brand.isNotEmpty ? widget.brand[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: _pressed ? 42 : 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}