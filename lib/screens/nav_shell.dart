import 'package:flutter/material.dart';
import '../mock_data/inventory_store.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../utils/responsive.dart';
import 'dashboard_screen.dart';
import 'inventory_list_screen.dart';
import 'add_inventory_screen.dart';
import 'stock_history_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class NavShell extends StatefulWidget {
  const NavShell({super.key});

  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    InventoryListScreen(),
    StockHistoryScreen(),
  ];

  static const List<String> _titles = [
    'Home',
    'Inventory Directory',
    'Stock Audit Trail',
  ];

  static const List<String> _navLabels = ['Home', 'Inventory', 'Log History'];

  static const List<IconData> _outlineIcons = [
    Icons.dashboard_outlined,
    Icons.inventory_2_outlined,
    Icons.history,
  ];

  static const List<IconData> _filledIcons = [
    Icons.dashboard,
    Icons.inventory_2,
    Icons.history,
  ];

  static const int _inventoryTabIndex = 1;

  void _openAddInventory() {
    Navigator.of(context).push(
      FadeSlideRoute(
        page: Scaffold(
          appBar: AppBar(title: const Text('Restock Entry')),
          body: const AddInventoryScreen(),
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).pop(); // isara muna ang drawer
    Navigator.of(context).push(
      FadeSlideRoute(page: SettingsScreen(onLogout: _confirmLogout)),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to end this session?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await InventoryStore.instance.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                FadeSlideRoute(page: const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Log Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  String _branchLabel(String? id) {
    switch (id) {
      case 'LIPA_CITY':
        return 'Lipa City Branch';
      case 'MAHABANG_PARANG':
        return 'Mahabang Parang Branch';
      case 'STA_RITA':
        return 'Sta. Rita Branch';
      default:
        return 'Unknown Branch';
    }
  }

  PreferredSizeWidget _buildAppBar() {
    final branchId = InventoryStore.instance.currentBranchId;
    return AppBar(
      // Animation: title cross-fades when switching tabs.
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Text(_titles[_currentIndex], key: ValueKey(_currentIndex)),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
              ),
              child: Text(
                _branchLabel(branchId),
                style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: AppColors.textSecondary),
          onPressed: _confirmLogout,
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    final store = InventoryStore.instance;
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(alpha: 0.12),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.person, color: AppColors.accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.currentManagerName ?? 'Branch Manager',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _branchLabel(store.currentBranchId),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.accent),
              title: const Text('Settings', style: TextStyle(color: AppColors.textPrimary)),
              onTap: _openSettings,
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Log Out', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.of(context).pop(); // isara ang drawer bago ang dialog
                _confirmLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);

    if (isTablet) {
      return Scaffold(
        appBar: _buildAppBar(),
        drawer: _buildDrawer(),
        floatingActionButton: _currentIndex == _inventoryTabIndex
            ? FloatingActionButton(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                onPressed: _openAddInventory,
                child: const Icon(Icons.add),
              )
            : null,
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: AppColors.surface,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: AppColors.accent),
              unselectedIconTheme: IconThemeData(color: AppColors.textSecondary.withValues(alpha: 0.8)),
              selectedLabelTextStyle: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
              unselectedLabelTextStyle: const TextStyle(color: AppColors.textSecondary),
              destinations: List.generate(_navLabels.length, (i) {
                return NavigationRailDestination(
                  icon: Icon(_outlineIcons[i]),
                  selectedIcon: Icon(_filledIcons[i]),
                  label: Text(_navLabels[i]),
                );
              }),
            ),
            const VerticalDivider(width: 1, color: Color(0xFF2A2A2A)),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: _screens),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      floatingActionButton: _currentIndex == _inventoryTabIndex
          ? FloatingActionButton(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              onPressed: _openAddInventory,
              child: const Icon(Icons.add),
            )
          : null,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: List.generate(_navLabels.length, (i) {
          return BottomNavigationBarItem(
            icon: Icon(_outlineIcons[i]),
            activeIcon: Icon(_filledIcons[i]),
            label: _navLabels[i],
          );
        }),
      ),
    );
  }
}