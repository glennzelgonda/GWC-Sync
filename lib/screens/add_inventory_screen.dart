import 'package:flutter/material.dart';
import '../mock_data/inventory_store.dart';
import '../theme/app_theme.dart';

class AddInventoryScreen extends StatefulWidget {
  const AddInventoryScreen({super.key});

  @override
  State<AddInventoryScreen> createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends State<AddInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _specController = TextEditingController();
  final _stockController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _specController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await InventoryStore.instance.addOrRestock(
        itemName: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        specifications: _specController.text.trim().isEmpty
            ? 'Standard specification'
            : _specController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        stockToAdd: int.parse(_stockController.text.trim()),
      );

      if (!mounted) return;

      _formKey.currentState!.reset();
      _nameController.clear();
      _brandController.clear();
      _specController.clear();
      _stockController.clear();
      _priceController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 12),
              Expanded(child: Text('Stock updated successfully.')),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update stock: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _requiredValidator(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName cannot be empty';
    }
    return null;
  }

  String? _priceValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Price cannot be empty';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= 0) return 'Price must be greater than zero';
    return null;
  }

  String? _stockValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Stock level cannot be empty';
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Enter a whole number';
    if (parsed <= 0) return 'Stock must be greater than zero';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Simulate Replenishment / Intake',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'If the product already exists in this branch, stock will be added to the existing entry.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                      prefixIcon: Icon(Icons.label, color: AppColors.accent),
                    ),
                    validator: (v) => _requiredValidator(v, fieldName: 'Product name'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _brandController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Brand Name',
                      prefixIcon: Icon(Icons.factory, color: AppColors.accent),
                    ),
                    validator: (v) => _requiredValidator(v, fieldName: 'Brand name'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _specController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Specifications (optional)',
                      prefixIcon: Icon(Icons.straighten, color: AppColors.accent),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: false),
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Stock Level',
                            prefixIcon: Icon(Icons.numbers, color: AppColors.accent),
                          ),
                          validator: _stockValidator,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Price (₱)',
                            prefixIcon: Icon(Icons.attach_money, color: AppColors.accent),
                          ),
                          validator: _priceValidator,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          valueColor: AlwaysStoppedAnimation(Colors.black),
                        ),
                      )
                    : const Text('CONFIRM RESTOCK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}