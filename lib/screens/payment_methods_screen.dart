import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/payment_service.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = PaymentService.methodsStream();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: AppColors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add New', style: TextStyle(color: Colors.white)),
        onPressed: () => _openForm(context),
      ),
      body: stream == null
          ? const Center(child: Text('Please log in to manage payment methods'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.credit_card_off_outlined,
                              size: 64, color: AppColors.textLight),
                          const SizedBox(height: 16),
                          Text('No payment methods saved',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 6),
                          Text('Add a UPI ID or card for faster checkout',
                              style: TextStyle(color: AppColors.textGrey)),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = {...docs[index].data(), 'id': docs[index].id};
                    return _MethodCard(
                      data: data,
                      onDelete: () => _confirmDelete(context, data['id']),
                    );
                  },
                );
              },
            ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove this payment method?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              PaymentService.deleteMethod(id);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PaymentFormSheet(),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDelete;
  const _MethodCard({required this.data, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isUpi = data['type'] == 'upi';
    final isDefault = data['isDefault'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDefault ? Border.all(color: AppColors.primary, width: 1.5) : null,
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Icon(isUpi ? Icons.account_balance_wallet_outlined : Icons.credit_card,
              color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUpi ? data['upiId'] ?? '' : '•••• •••• •••• ${data['last4'] ?? ''}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                if (!isUpi)
                  Text('${data['holderName'] ?? ''} · Exp ${data['expiry'] ?? ''}',
                      style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                if (isDefault)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('DEFAULT',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _PaymentFormSheet extends StatefulWidget {
  const _PaymentFormSheet();

  @override
  State<_PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends State<_PaymentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'upi';
  bool _isDefault = false;
  bool _saving = false;

  final _upi = TextEditingController();
  final _cardNumber = TextEditingController();
  final _expiry = TextEditingController();
  final _holder = TextEditingController();

  @override
  void dispose() {
    _upi.dispose();
    _cardNumber.dispose();
    _expiry.dispose();
    _holder.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_type == 'upi') {
        await PaymentService.addUpi(_upi.text.trim(), isDefault: _isDefault);
      } else {
        await PaymentService.addCard(
          cardNumber: _cardNumber.text.trim(),
          expiry: _expiry.text.trim(),
          holderName: _holder.text.trim(),
          isDefault: _isDefault,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Payment Method',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'upi',
                        groupValue: _type,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('UPI'),
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'card',
                        groupValue: _type,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Card'),
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_type == 'upi')
                  TextFormField(
                    controller: _upi,
                    decoration: const InputDecoration(
                        labelText: 'UPI ID', hintText: 'yourname@upi'),
                    validator: (v) =>
                        v == null || !v.contains('@') ? 'Enter a valid UPI ID' : null,
                  )
                else ...[
                  TextFormField(
                    controller: _cardNumber,
                    keyboardType: TextInputType.number,
                    maxLength: 16,
                    decoration: const InputDecoration(
                        labelText: 'Card Number', counterText: ''),
                    validator: (v) =>
                        v == null || v.trim().length < 12 ? 'Enter a valid card number' : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expiry,
                          decoration: const InputDecoration(
                              labelText: 'MM/YY', hintText: '12/28'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _holder,
                          decoration: const InputDecoration(labelText: 'Holder Name'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Set as default payment method'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
