# AutoCenter Inventory Module — Local Static Mock Engine

A Flutter mobile frontend simulating a Branch Manager inventory module for an
automotive tire center. No backend/cloud connectivity — all data lives in
memory for the duration of the app session, isolated by `branch_id`.

## Setup

1. Create a new Flutter project (or reuse an existing one):
   ```
   flutter create autocenter_inventory
   ```
2. Replace the generated `lib/` folder and `pubspec.yaml` with the ones in
   this delivery, or copy each file into the matching path.
3. Fetch dependencies:
   ```
   flutter pub get
   ```
4. Run on an emulator:
   ```
   flutter run
   ```

## File Map

```
lib/
  main.dart                          -> App entry point, dark theme wiring
  theme/app_theme.dart               -> Dark Industrial color palette + ThemeData
  mock_data/inventory_store.dart     -> Tire/HistoryLog models + InventoryStore (ChangeNotifier singleton)
  utils/responsive.dart              -> Tablet/phone breakpoint helper
  utils/page_transitions.dart        -> Custom fade+slide PageRouteBuilder
  screens/login_screen.dart          -> Credential entry, branch_id routing
  screens/nav_shell.dart             -> Bottom nav (phone) / NavigationRail (tablet) shell
  screens/dashboard_screen.dart      -> KPI scorecards + fl_chart bar graph
  screens/inventory_list_screen.dart -> Searchable, branch-isolated tire directory
  screens/tire_details_screen.dart   -> Full tire specification sheet
  screens/add_inventory_screen.dart  -> Validated restock/intake form
  screens/stock_history_screen.dart  -> Branch-isolated audit trail feed
```

## Gestures, Animations & Responsive Design

| Feature | Where |
|---|---|
| Swipe-to-delete (`Dismissible`) with confirm dialog | Stock History screen |
| Long-press quick actions (`onLongPress` + `showModalBottomSheet`) | Inventory Directory cards |
| Pull-to-refresh (`RefreshIndicator`) | Dashboard, Inventory Directory, Stock History |
| Hero transition between list icon and detail screen | Inventory Directory → Tire Details |
| Fade + slide-up entrance animation | Tire Details screen content |
| Staggered fade/slide-in KPI cards | Dashboard |
| Custom fade+slide page transitions (`FadeSlideRoute`) | Login → Nav Shell, Inventory List → Tire Details, Logout |
| Cross-fading app bar title | Nav Shell, on tab switch |
| Scale-in logo entrance | Login screen |
| Responsive layout: `NavigationRail` (tablet) vs `BottomNavigationBar` (phone) | Nav Shell |
| Responsive layout: `GridView` (tablet) vs `ListView` (phone) | Inventory Directory |
| Responsive KPI row (3-across vs 2+1 stack) and chart height | Dashboard |

## Demo Credentials

| Username           | Password        | Branch              |
|---------------------|-----------------|----------------------|
| `manager_lipa`       | `lipa123`       | LIPA_CITY            |
| `manager_mahabang`   | `mahabang123`   | MAHABANG_PARANG      |

## Notes

- State is held in `InventoryStore.instance`, a `ChangeNotifier` singleton.
  Screens rebuild reactively via `AnimatedBuilder`, so no extra state
  management package is required.
- Submitting the restock form updates in-memory stock counts, writes a new
  `HistoryLog` entry (`INCOMING`), and refreshes the Dashboard/Inventory/
  History screens instantly.
- All mock data resets when the app is fully restarted, matching the
  "static mock engine, no persistence" requirement.
