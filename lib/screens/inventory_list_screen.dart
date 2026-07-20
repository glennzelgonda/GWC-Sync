import 'dart:async';
import 'package:flutter/material.dart';
import '../mock_data/inventory_store.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../utils/responsive.dart';
import 'tire_details_screen.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  final Set<String> _pendingDiscontinueIds = {};
  final Map<String, Timer> _pendingTimers = {};

  @override
  void dispose() {
    _searchController.dispose();
    for (final timer in _pendingTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<void> _showQuantityDialog(BuildContext context, Tire tire, {required bool isAdd}) async {
    final controller = TextEditingController(text: isAdd ? '0' : '0');
    final formKey = GlobalKey<FormState>();

    final qty = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isAdd ? 'Add Stock — ${tire.itemName}' : 'Deduct Stock — ${tire.itemName}',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Quantity'),
            validator: (v) {
              final n = int.tryParse(v?.trim() ?? '');
              if (n == null || n <= 0) return 'Enter a valid quantity';
              if (!isAdd && tire.currentStock - n < 0) {
                return 'Only ${tire.currentStock} in stock';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx, int.parse(controller.text.trim()));
            },
            child: Text(isAdd ? 'Add' : 'Deduct', style: const TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    if (qty == null || !context.mounted) return;

    try {
      await InventoryStore.instance.quickAdjustStock(tire.id, isAdd ? qty : -qty);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAdd ? 'Added $qty units to stock.' : 'Deducted $qty unit(s) from stock.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update stock: $e')),
      );
    }
  }

  Future<bool> _askDiscontinueConfirmation(BuildContext context, Tire tire) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discontinue Product', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Remove "${tire.itemName}" (${tire.brand}) from the active catalog? '
          'Its stock movement history stays in the audit trail — only the '
          'product listing itself is removed. This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discontinue', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _scheduleDiscontinue(BuildContext context, Tire tire) {
    setState(() => _pendingDiscontinueIds.add(tire.id));

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text('${tire.itemName} discontinued.'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.accent,
          onPressed: () {
            _pendingTimers[tire.id]?.cancel();
            _pendingTimers.remove(tire.id);
            if (mounted) {
              setState(() => _pendingDiscontinueIds.remove(tire.id));
            }
          },
        ),
      ),
    );

    _pendingTimers[tire.id] = Timer(const Duration(seconds: 4), () async {
      _pendingTimers.remove(tire.id);
      try {
        await InventoryStore.instance.discontinueTire(tire.id);
        
      } catch (e) {
        if (!mounted) return;
        setState(() => _pendingDiscontinueIds.remove(tire.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to discontinue: $e')),
        );
      }
    });
  }

   void _openQuickActions(BuildContext context, Tire tire) {
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
                Text(
                  tire.itemName,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text('Quick Actions', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add, color: AppColors.success),
                  ),
                  title: const Text('Add Stock', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text(
                    'Enter a custom incoming quantity',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showQuantityDialog(context, tire, isAdd: true);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.lowStock.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.remove, color: AppColors.lowStock),
                  ),
                  title: const Text('Deduct Stock', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text(
                    'Enter a custom outgoing quantity',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showQuantityDialog(context, tire, isAdd: false);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.info_outline, color: AppColors.accent),
                  ),
                  title: const Text('View Full Details', style: TextStyle(color: AppColors.textPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      FadeSlideRoute(page: TireDetailsScreen(tireId: tire.id)),
                    );
                  },
                ),
                const Divider(color: AppColors.border, height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                  ),
                  title: const Text('Discontinue Product', style: TextStyle(color: AppColors.error)),
                  subtitle: const Text(
                    'Removes the listing — audit history is kept',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirmed = await _askDiscontinueConfirmation(context, tire);
                    if (confirmed && context.mounted) {
                      _scheduleDiscontinue(context, tire);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTireCard(BuildContext context, Tire tire) {
    final isLow = tire.currentStock < InventoryStore.lowStockThreshold;
    return Dismissible(
      key: ValueKey(tire.id),
      direction: DismissDirection.endToStart,
    
      confirmDismiss: (_) => _askDiscontinueConfirmation(context, tire),
      onDismissed: (_) => _scheduleDiscontinue(context, tire),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.remove_circle_outline, color: Colors.white),
      ),
      child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          FadeSlideRoute(page: TireDetailsScreen(tireId: tire.id)),
        );
      },
      // Gesture: long-press opens the quick actions bottom sheet.
      onLongPress: () => _openQuickActions(context, tire),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLow ? AppColors.lowStock.withValues(alpha: 0.5) : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'tire-icon-${tire.id}',
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
                ),
                alignment: Alignment.center,
                child: Text(
                  tire.brand.isNotEmpty ? tire.brand[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tire.itemName,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${tire.brand} · ${tire.specifications}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${tire.price.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isLow ? AppColors.lowStock.withValues(alpha: 0.18) : AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isLow ? AppColors.lowStock : AppColors.accent, width: 1),
              ),
              child: Text(
                '${tire.currentStock}',
                style: TextStyle(
                  color: isLow ? AppColors.lowStock : AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = InventoryStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (store.isLoadingInitialData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        if (store.tiresError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                store.tiresError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          );
        }

        final tires = store
            .getTiresForBranch(searchQuery: _query)
            .where((t) => !_pendingDiscontinueIds.contains(t.id))
            .toList();
        final isTablet = Responsive.isTablet(context);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary),
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search by tire name or brand...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search, color: AppColors.accent),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
            if (!isTablet)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tip: swipe left to discontinue, long-press for quick actions',
                    style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 11),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Expanded(
              child: tires.isEmpty
                  ? const _EmptyState()
                  // Gesture: pull-to-refresh.
                  : RefreshIndicator(
                      color: AppColors.accent,
                      backgroundColor: AppColors.card,
                      onRefresh: store.simulateRefresh,
                      child: isTablet
                          ? GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisExtent: 108,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: tires.length,
                              itemBuilder: (context, index) => _buildTireCard(context, tires[index]),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemCount: tires.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildTireCard(context, tires[index]),
                              ),
                            ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 48),
          const SizedBox(height: 12),
          const Text('No matching tires found', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}