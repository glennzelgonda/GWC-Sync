import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class Tire {
  final String id;
  final String branchId;
  String itemName;
  String brand;
  String specifications;
  double price;
  int currentStock;
  String? supplier;
  String? skuCode;

  Tire({
    required this.id,
    required this.branchId,
    required this.itemName,
    required this.brand,
    required this.specifications,
    required this.price,
    required this.currentStock,
    this.supplier,
    this.skuCode,
  });

  factory Tire.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Tire(
      id: doc.id,
      branchId: data['branchId'] as String? ?? '',
      itemName: data['itemName'] as String? ?? '',
      brand: data['brand'] as String? ?? '',
      specifications: data['specifications'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      currentStock: (data['currentStock'] as num?)?.toInt() ?? 0,
      supplier: data['supplier'] as String?,
      skuCode: data['skuCode'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'branchId': branchId,
        'itemName': itemName,
        'brand': brand,
        'specifications': specifications,
        'price': price,
        'currentStock': currentStock,
        if (supplier != null) 'supplier': supplier,
        if (skuCode != null) 'skuCode': skuCode,
      };
}

class HistoryLog {
  final String logId;
  final String branchId;
  final String date;
  final String tireName;
  final String movementType; 
  final int quantity;
  final DateTime? createdAt;
  final String? performedBy;

  HistoryLog({
    required this.logId,
    required this.branchId,
    required this.date,
    required this.tireName,
    required this.movementType,
    required this.quantity,
    this.createdAt,
    this.performedBy,
  });

  factory HistoryLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return HistoryLog(
      logId: doc.id,
      branchId: data['branchId'] as String? ?? '',
      date: data['date'] as String? ?? '',
      tireName: data['tireName'] as String? ?? '',
      movementType: data['movementType'] as String? ?? 'INCOMING',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      performedBy: data['performedBy'] as String?,
    );
  }
}

class MonthlyVolume {
  final String month;
  final int incoming;
  final int outgoing;

  const MonthlyVolume({
    required this.month,
    required this.incoming,
    required this.outgoing,
  });
}

class InventoryStore extends ChangeNotifier {
  InventoryStore._internal();

  static final InventoryStore instance = InventoryStore._internal();

  static const int lowStockThreshold = 10;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? currentBranchId;
  String? currentManagerName;
  String? currentUid;

  List<Tire> _tires = [];
  List<HistoryLog> _history = [];

  bool isLoadingInitialData = false;
  String? tiresError;
  String? historyError;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _tiresSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _historySub;

  List<Tire> getTiresForBranch({String searchQuery = ''}) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _tires;
    return _tires
        .where((t) =>
            t.itemName.toLowerCase().contains(query) ||
            t.brand.toLowerCase().contains(query))
        .toList();
  }

  Tire? findTireById(String id) {
    try {
      return _tires.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  DateTime? lastRestockDateFor(Tire tire) {
    DateTime? latest;
    for (final log in _history) {
      if (log.movementType != 'INCOMING') continue;
      if (log.branchId != tire.branchId || log.tireName != tire.itemName) continue;
      final d = log.createdAt ?? DateTime.tryParse(log.date);
      if (d == null) continue;
      if (latest == null || d.isAfter(latest)) latest = d;
    }
    return latest;
  }

  List<HistoryLog> getHistoryForBranch({String filter = 'ALL'}) {
    if (filter == 'ALL') return _history;
    return _history.where((h) => h.movementType == filter).toList();
  }

  ({int incoming, int outgoing}) getHistoryTotals({String filter = 'ALL'}) {
    var inTotal = 0;
    var outTotal = 0;
    for (final log in getHistoryForBranch(filter: filter)) {
      if (log.movementType == 'INCOMING') inTotal += log.quantity;
      if (log.movementType == 'OUTGOING') outTotal += log.quantity;
    }
    return (incoming: inTotal, outgoing: outTotal);
  }

  List<MonthlyVolume> getMonthlyVolumes() {
    final branch = currentBranchId;
    if (branch == null) return [];

    final now = DateTime.now();
    final months = List.generate(
      6,
      (i) => DateTime(now.year, now.month - (5 - i), 1),
    );

    final Map<String, MonthlyVolume> byMonth = {
      for (final m in months)
        _monthKey(m): MonthlyVolume(month: _monthLabel(m), incoming: 0, outgoing: 0),
    };

    for (final log in _history) {
      final date = DateTime.tryParse(log.date);
      if (date == null) continue;
      final key = _monthKey(DateTime(date.year, date.month, 1));
      final existing = byMonth[key];
      if (existing == null) continue; // outside the 6-month window
      byMonth[key] = MonthlyVolume(
        month: existing.month,
        incoming: existing.incoming + (log.movementType == 'INCOMING' ? log.quantity : 0),
        outgoing: existing.outgoing + (log.movementType == 'OUTGOING' ? log.quantity : 0),
      );
    }

    return months.map((m) => byMonth[_monthKey(m)]!).toList();
  }

  String _monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

  String _monthLabel(DateTime d) {
    const labels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return labels[d.month - 1];
  }

  Future<void> addOrRestock({
    required String itemName,
    required String brand,
    required String specifications,
    required double price,
    required int stockToAdd,
  }) async {
    final branch = currentBranchId;
    if (branch == null) {
      throw StateError('No active branch — please log in again.');
    }

    try {
      await _db.runTransaction((tx) async {
        final existingQuery = await _db
            .collection('tires')
            .where('branchId', isEqualTo: branch)
            .where('itemName', isEqualTo: itemName)
            .where('brand', isEqualTo: brand)
            .limit(1)
            .get();

        if (existingQuery.docs.isNotEmpty) {
          final doc = existingQuery.docs.first;
          final freshSnapshot = await tx.get(doc.reference);
          final freshStock = (freshSnapshot.data()?['currentStock'] as num?)?.toInt() ?? 0;
          tx.update(doc.reference, {
            'currentStock': freshStock + stockToAdd,
            'price': price,
            if (specifications.isNotEmpty) 'specifications': specifications,
          });
        } else {
          final newDocRef = _db.collection('tires').doc();
          tx.set(newDocRef, {
            'branchId': branch,
            'itemName': itemName,
            'brand': brand,
            'specifications': specifications,
            'price': price,
            'currentStock': stockToAdd,
          });
        }

        final historyRef = _db.collection('stock_history').doc();
        tx.set(historyRef, {
          'branchId': branch,
          'date': _todayLabel(),
          'tireName': itemName,
          'movementType': 'INCOMING',
          'quantity': stockToAdd,
          'createdAt': FieldValue.serverTimestamp(),
          'performedBy': currentManagerName ?? 'Unknown',
        });
      });
    } on FirebaseException catch (e) {
      throw Exception('Could not save stock update: ${e.message}');
    }
  }

  String _todayLabel() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  Future<void> login() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user — please log in again.');
    }

    final managerDoc = await _db.collection('managers').doc(user.uid).get();
    if (!managerDoc.exists) {
      throw StateError(
        'This account is not registered to any branch. Contact an administrator.',
      );
    }

    final data = managerDoc.data()!;
    final branchId = data['branchId'] as String?;
    final managerName = data['name'] as String?;
    if (branchId == null || managerName == null) {
      throw StateError('Manager profile is incomplete. Contact an administrator.');
    }

    currentUid = user.uid;
    currentBranchId = branchId;
    currentManagerName = managerName;
    isLoadingInitialData = true;
    tiresError = null;
    historyError = null;
    _listenToBranch(branchId);
    notifyListeners();
  }

  void _listenToBranch(String branchId) {
    _tiresSub?.cancel();
    _historySub?.cancel();

    _tiresSub = _db
        .collection('tires')
        .where('branchId', isEqualTo: branchId)
        .snapshots()
        .listen(
      (snapshot) {
        _tires = snapshot.docs.map(Tire.fromDoc).toList();
        tiresError = null;
        isLoadingInitialData = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('TIRES LISTENER ERROR: $e');
        tiresError = 'Failed to load inventory: $e';
        isLoadingInitialData = false;
        notifyListeners();
      },
    );

    _historySub = _db
        .collection('stock_history')
        .where('branchId', isEqualTo: branchId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _history = snapshot.docs.map(HistoryLog.fromDoc).toList();
        historyError = null;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('HISTORY LISTENER ERROR: $e');
        historyError = 'Failed to load stock history: $e';
        notifyListeners();
      },
    );
  }

  Future<void> logout() async {
    _tiresSub?.cancel();
    _historySub?.cancel();
    _tiresSub = null;
    _historySub = null;
    _tires = [];
    _history = [];
    currentBranchId = null;
    currentManagerName = null;
    currentUid = null;
    isLoadingInitialData = false;
    tiresError = null;
    historyError = null;
    notifyListeners();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> quickAdjustStock(String tireId, int delta) async {
    if (delta == 0) return;
    final cachedTire = findTireById(tireId);
    if (cachedTire == null) return;

    final tireRef = _db.collection('tires').doc(tireId);

    try {
      await _db.runTransaction((tx) async {
        final snapshot = await tx.get(tireRef);
        if (!snapshot.exists) return;
        final serverStock = (snapshot.data()?['currentStock'] as num?)?.toInt() ?? 0;

        final applied =
            delta < 0 && serverStock + delta < 0 ? -serverStock : delta;
        if (applied == 0) return;

        tx.update(tireRef, {'currentStock': serverStock + applied});

        final historyRef = _db.collection('stock_history').doc();
        tx.set(historyRef, {
          'branchId': cachedTire.branchId,
          'date': _todayLabel(),
          'tireName': cachedTire.itemName,
          'movementType': applied > 0 ? 'INCOMING' : 'OUTGOING',
          'quantity': applied.abs(),
          'createdAt': FieldValue.serverTimestamp(),
          'performedBy': currentManagerName ?? 'Unknown',
        });
      });
    } on FirebaseException catch (e) {
      throw Exception('Could not adjust stock: ${e.message}');
    }
  }

  Future<void> discontinueTire(String tireId) async {
    final tire = findTireById(tireId);
    if (tire == null) return;

    try {
      final batch = _db.batch();
      batch.delete(_db.collection('tires').doc(tireId));
      batch.set(_db.collection('stock_history').doc(), {
        'branchId': tire.branchId,
        'date': _todayLabel(),
        'tireName': tire.itemName,
        'movementType': 'DISCONTINUED',
        'quantity': tire.currentStock,
        'createdAt': FieldValue.serverTimestamp(),
        'performedBy': currentManagerName ?? 'Unknown',
      });
      await batch.commit();
    } on FirebaseException catch (e) {
      throw Exception('Could not discontinue product: ${e.message}');
    }
  }

  Future<void> simulateRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}