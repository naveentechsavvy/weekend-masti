import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'order_tracking_screen.dart' hide OrderService;
import 'restaurant_detail_screen.dart';
import 'saved_addresses_screen.dart';
import '../services/address_service.dart';
import '../services/order_service.dart';

enum PaymentMethod { cod, upi, card }

class CheckoutScreen extends StatefulWidget {
  final int grandTotal;
  const CheckoutScreen({super.key, required this.grandTotal});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Cash on Delivery is pre-selected by default so "Pay" works immediately
  // without forcing the user to tap a payment row first.
  PaymentMethod? _selected = PaymentMethod.cod;
  bool _placing = false;
  bool _loadingAddress = true;
  bool _amountExpanded = false;
  Map<String, dynamic>? _selectedAddress;

  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    final addresses = await AddressService.getAddresses();
    if (!mounted) return;
    setState(() {
      if (addresses.isNotEmpty) {
        _selectedAddress = addresses.firstWhere(
          (a) => a['isDefault'] == true,
          orElse: () => addresses.first,
        );
      }
      _loadingAddress = false;
    });
  }

  Future<void> _changeAddress() async {
    final picked = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
          builder: (_) => const SavedAddressesScreen(selectionMode: true)),
    );
    if (picked != null) {
      setState(() => _selectedAddress = picked);
    }
  }

  @override
  void dispose() {
    _upiController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  int get _itemTotal => CartManager.totalPrice;
  int get _delivery => 30;
  int get _taxes => (_itemTotal * 0.05).round();

  bool get _canPlaceOrder {
    if (_selectedAddress == null) return false;
    switch (_selected) {
      case PaymentMethod.cod:
        return true;
      case PaymentMethod.upi:
        return _upiController.text.trim().contains('@');
      case PaymentMethod.card:
        return _cardNumberController.text.trim().length >= 12 &&
            _cardExpiryController.text.trim().isNotEmpty &&
            _cardCvvController.text.trim().length >= 3;
      case null:
        return false;
    }
  }

  String get _paymentLabel {
    switch (_selected) {
      case PaymentMethod.cod:
        return 'Cash on Delivery';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
      case null:
        return '';
    }
  }

  /// Success confirmation shown briefly after the order is placed,
  /// before we redirect into live order tracking.
  Widget _buildSuccessDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 16),
            Text('Order Placed!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 6),
            Text('Redirecting to order status...',
                style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }

  /// Shows an unmissable error dialog instead of a SnackBar, since SnackBars
  /// can render underneath the system gesture-nav bar on some devices and
  /// never actually be seen.
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 8),
            const Text('Order Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      _showErrorDialog(
          'Please add or select a delivery address before placing your order.');
      return;
    }
    if (_selected == null) {
      _showErrorDialog('Please select a payment method to continue.');
      return;
    }
    if (!_canPlaceOrder) {
      _showErrorDialog(
          'Please complete your payment details before placing your order.');
      return;
    }

    setState(() => _placing = true);

    final items = List<Map<String, dynamic>>.from(CartManager.items);
    final itemTotal = _itemTotal;
    final delivery = _delivery;
    final taxes = _taxes;

    try {
      // Simulated payment processing delay (dummy/mock gateway, no real charge)
      await Future.delayed(const Duration(seconds: 2));

      debugPrint('CHECKOUT: calling OrderService.placeOrder...');

      await OrderService.placeOrder(
        items: items,
        itemTotal: itemTotal,
        delivery: delivery,
        taxes: taxes,
        grandTotal: widget.grandTotal,
        paymentMethod: _paymentLabel,
        address: _selectedAddress,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
              'The request timed out. Please check your internet connection and try again.');
        },
      );

      debugPrint('CHECKOUT: order placed successfully');

      if (!mounted) return;

      CartManager.items.clear();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _buildSuccessDialog(),
      );

      await Future.delayed(const Duration(milliseconds: 1600));
      if (!mounted) return;

      Navigator.pop(context); // close the success dialog
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderTrackingScreen()),
      );
    } catch (e, stack) {
      debugPrint('CHECKOUT ERROR: $e');
      debugPrint('CHECKOUT STACK: $stack');
      if (!mounted) return;
      setState(() => _placing = false);
      _showErrorDialog('Could not place order:\n$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: AppColors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Deliver To',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildAddressCard(),
                ),
                const SizedBox(height: 16),
                _buildAmountBar(),
                const SizedBox(height: 8),
                _buildPayButtonInline(),
                const SizedBox(height: 8),
                Container(color: AppColors.divider, height: 8),
                _buildMethodTile(
                  method: PaymentMethod.upi,
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'UPI',
                  subtitle: 'Pay by any UPI app',
                  offerText: 'Get upto ₹50 cashback  •  2 offers available',
                  expandedChild: _buildUpiForm(),
                ),
                _divider(),
                _buildMethodTile(
                  method: PaymentMethod.card,
                  icon: Icons.credit_card,
                  title: 'Credit / Debit / ATM Card',
                  subtitle: 'Add and use cards securely',
                  offerText: 'Get upto 5% cashback  •  2 offers available',
                  expandedChild: _buildCardForm(),
                ),
                _divider(),
                _buildMethodTile(
                  method: PaymentMethod.cod,
                  icon: Icons.payments_outlined,
                  title: 'Cash on Delivery',
                  subtitle: 'Pay when your order arrives',
                  offerText: null,
                  expandedChild: null,
                ),
                _divider(),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This is a test checkout. No real payment will be processed.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textGrey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Trusted by thousands of happy customers!',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(color: AppColors.divider, height: 1);

  /// Flipkart-style "Total Amount ▾  ₹XXX" collapsible summary bar.
  Widget _buildAmountBar() {
    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _amountExpanded = !_amountExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text('Total Amount',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _amountExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down,
                        size: 20, color: AppColors.primary),
                  ),
                  const Spacer(),
                  Text('₹${widget.grandTotal}',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ],
              ),
            ),
          ),
          if (_amountExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                children: [
                  _amountRow('Item Total', _itemTotal),
                  _amountRow('Delivery Fee', _delivery),
                  _amountRow('Taxes', _taxes),
                  const Divider(height: 16),
                  _amountRow('Total Payable', widget.grandTotal, bold: true),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, int value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textGrey,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          Text('₹$value',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textDark,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }

  /// The big amber "Pay ₹X" button, sitting right under the amount bar
  /// like Flipkart's payments screen.
  Widget _buildPayButtonInline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black87,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: _placing ? null : _placeOrder,
          child: _placing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.black87,
                  ),
                )
              : Text('Pay ₹${widget.grandTotal}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    if (_loadingAddress) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedAddress == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off_outlined, color: AppColors.textGrey),
            const SizedBox(width: 12),
            Expanded(
              child: Text('No address added yet',
                  style: TextStyle(color: AppColors.textGrey)),
            ),
            TextButton(
              onPressed: _changeAddress,
              child: const Text('Add Address'),
            ),
          ],
        ),
      );
    }

    final a = _selectedAddress!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['label'] ?? 'Address',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(
                  '${a['line1'] ?? ''}, ${a['line2'] ?? ''}, ${a['city'] ?? ''} - ${a['pincode'] ?? ''}',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _changeAddress,
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  /// Flipkart-style accordion row: icon + title/subtitle on the left,
  /// a chevron on the right that rotates when expanded, with the
  /// method's form (if any) revealed underneath when selected.
  ///
  /// FIX: previously, tapping a row that was already selected set
  /// `_selected = null` unconditionally — including for Cash on
  /// Delivery, which starts pre-selected. That meant simply tapping the
  /// already-selected COD row (or re-collapsing UPI/Card after opening
  /// them to look) silently cleared the selection, so "Pay" would then
  /// fail with "Please select a payment method," with no obvious cause.
  /// Now, collapsing/re-tapping never leaves nothing selected: tapping
  /// an already-selected method just keeps it selected, and closing an
  /// expanded UPI/Card form falls back to Cash on Delivery (which is
  /// always valid) instead of null.
  Widget _buildMethodTile({
    required PaymentMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
    required String? offerText,
    required Widget? expandedChild,
  }) {
    final isExpanded = _selected == method;
    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (!isExpanded) {
                  // Selecting a different method — straightforward.
                  _selected = method;
                } else if (expandedChild == null) {
                  // Re-tapping an already-selected method with no form
                  // (i.e. Cash on Delivery) — keep it selected, there's
                  // nothing to collapse.
                  _selected = method;
                } else {
                  // Collapsing an expanded UPI/Card form — fall back to
                  // Cash on Delivery instead of leaving nothing selected.
                  _selected = PaymentMethod.cod;
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.textDark, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textGrey)),
                        if (offerText != null) ...[
                          const SizedBox(height: 4),
                          Text(offerText,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ),
                  if (expandedChild != null)
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down,
                          color: AppColors.textGrey),
                    )
                  else
                    Radio<PaymentMethod>(
                      value: method,
                      groupValue: _selected,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _selected = v),
                    ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: expandedChild ?? const SizedBox.shrink(),
            ),
            crossFadeState: (isExpanded && expandedChild != null)
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  /// UPI form with quick-pick app tiles (GPay / PhonePe / Paytm) above the
  /// manual UPI-ID entry, matching Flipkart's payments screen layout.
  ///
  /// NOTE: these are placeholder tiles for demo purposes only — tapping one
  /// does not deep-link into the real app or process any payment. You must
  /// supply your own GPay/PhonePe/Paytm icon assets (see note below);
  /// official brand logos can't be generated here.
  Widget _buildUpiForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pay via UPI Apps',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey)),
        const SizedBox(height: 10),
        Row(
          children: [
            _upiAppTile('Google Pay', 'assets/images/gpay.png'),
            const SizedBox(width: 12),
            _upiAppTile('PhonePe', 'assets/images/phonepe.png'),
            const SizedBox(width: 12),
            _upiAppTile('Paytm', 'assets/images/paytm.png'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('OR',
                  style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
            ),
            Expanded(child: Divider(color: AppColors.divider)),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _upiController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Enter UPI ID',
            hintText: 'yourname@upi',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _upiController.text.trim().contains('@')
                ? () => setState(() {})
                : null,
            child: const Text('Verify & Add'),
          ),
        ),
      ],
    );
  }

  Widget _upiAppTile(String label, String assetPath) {
    return Expanded(
      child: InkWell(
        onTap: () {
          // Placeholder tap handler — in a real gateway integration this
          // would deep-link into the selected UPI app.
          setState(() {});
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Image.asset(
                assetPath,
                height: 28,
                errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 28,
                    color: AppColors.textGrey),
              ),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(fontSize: 11, color: AppColors.textDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      children: [
        TextField(
          controller: _cardNumberController,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.number,
          maxLength: 16,
          decoration: const InputDecoration(
            labelText: 'Card Number',
            hintText: '1234 5678 9012 3456',
            border: OutlineInputBorder(),
            counterText: '',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cardExpiryController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'MM/YY',
                  hintText: '12/28',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _cardCvvController,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.number,
                maxLength: 3,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
