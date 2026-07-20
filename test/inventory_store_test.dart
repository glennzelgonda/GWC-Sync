import 'package:flutter_test/flutter_test.dart';
import 'package:glomags_tire_app/mock_data/inventory_store.dart';

void main() {
  group('InventoryStore login context', () {
    test('applyLoginContext updates branch and notifies listeners', () {
      final store = InventoryStore.instance;
      store.currentBranchId = null;
      store.currentManagerName = null;

      var notified = false;
      store.addListener(() => notified = true);

      store.applyLoginContext(
        branchId: 'LIPA_CITY',
        managerName: 'Lipa City Branch Manager',
      );

      expect(store.currentBranchId, 'LIPA_CITY');
      expect(store.currentManagerName, 'Lipa City Branch Manager');
      expect(notified, isTrue);
    });
  });
}
