import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/address_service.dart';
import 'map_picker_screen.dart';

class SavedAddressesScreen extends StatelessWidget {
  /// When true, tapping an address pops this screen and returns the
  /// selected address map instead of opening it for edit. Used by Checkout.
  final bool selectionMode;

  const SavedAddressesScreen({super.key, this.selectionMode = false});

  @override
  Widget build(BuildContext context) {
    final stream = AddressService.addressesStream();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(selectionMode ? 'Select Address' : 'Saved Addresses'),
        backgroundColor: AppColors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Address', style: TextStyle(color: Colors.white)),
        onPressed: () => _openForm(context),
      ),
      body: stream == null
          ? const Center(child: Text('Please log in to manage addresses'))
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
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.location_off_outlined,
                                size: 48, color: AppColors.primary),
                          ),
                          const SizedBox(height: 20),
                          Text('No saved addresses',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 6),
                          Text('Add an address to get started',
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
                    return _AddressCard(
                      address: data,
                      selectionMode: selectionMode,
                      onTap: () {
                        if (selectionMode) {
                          Navigator.pop(context, data);
                        } else {
                          _openForm(context, existing: data);
                        }
                      },
                      onEdit: () => _openForm(context, existing: data),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete address?'),
        content: const Text('This address will be removed permanently.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              AddressService.deleteAddress(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, {Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressFormSheet(existing: existing),
    );
  }
}

/// Picks an icon + accent color for a label, so Home/Work/Other are
/// visually distinct at a glance.
class _LabelStyle {
  final IconData icon;
  final Color color;
  const _LabelStyle(this.icon, this.color);

  static _LabelStyle forLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('home')) {
      return const _LabelStyle(Icons.home_rounded, Color(0xFF2E7D32));
    } else if (l.contains('work') || l.contains('office')) {
      return const _LabelStyle(Icons.work_rounded, Color(0xFF1565C0));
    }
    return const _LabelStyle(Icons.location_on_rounded, Color(0xFFEF6C00));
  }
}

class _AddressCard extends StatelessWidget {
  final Map<String, dynamic> address;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.selectionMode,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDefault = address['isDefault'] == true;
    final label = (address['label'] ?? 'Address').toString();
    final style = _LabelStyle.forLabel(label);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: isDefault
              ? Border.all(color: AppColors.primary, width: 1.5)
              : Border.all(color: AppColors.divider, width: 1),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 10, offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: style.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(style.icon, color: style.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textDark)),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('DEFAULT',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${address['line1'] ?? ''}, ${address['line2'] ?? ''}, ${address['city'] ?? ''} - ${address['pincode'] ?? ''}',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13, height: 1.3),
                  ),
                  if ((address['phone'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.call_outlined, size: 12, color: AppColors.textGrey),
                        const SizedBox(width: 4),
                        Text(address['phone'],
                            style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!selectionMode)
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.textGrey),
                    onPressed: onEdit,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    onPressed: onDelete,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                ],
              )
            else
              Icon(Icons.chevron_right, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _AddressFormSheet({this.existing});

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _city;
  late final TextEditingController _pincode;
  late final TextEditingController _phone;
  bool _isDefault = false;
  bool _saving = false;
  bool _locatingOnMap = false;
  double? _latitude;
  double? _longitude;

  static const _quickLabels = ['Home', 'Work', 'Other'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?['label'] ?? 'Home');
    _line1 = TextEditingController(text: e?['line1'] ?? '');
    _line2 = TextEditingController(text: e?['line2'] ?? '');
    _city = TextEditingController(text: e?['city'] ?? '');
    _pincode = TextEditingController(text: e?['pincode'] ?? '');
    _phone = TextEditingController(text: e?['phone'] ?? '');
    _isDefault = e?['isDefault'] == true;
    _latitude = (e?['latitude'] as num?)?.toDouble();
    _longitude = (e?['longitude'] as num?)?.toDouble();
  }

  @override
  void dispose() {
    _label.dispose();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _pincode.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickOnMap() async {
    setState(() => _locatingOnMap = true);
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLat: _latitude,
          initialLng: _longitude,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _locatingOnMap = false);
    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        if (result.line1.isNotEmpty) _line1.text = result.line1;
        if (result.city.isNotEmpty) _city.text = result.city;
        if (result.pincode.isNotEmpty) _pincode.text = result.pincode;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.existing != null) {
        await AddressService.updateAddress(
          widget.existing!['id'],
          label: _label.text.trim(),
          line1: _line1.text.trim(),
          line2: _line2.text.trim(),
          city: _city.text.trim(),
          pincode: _pincode.text.trim(),
          phone: _phone.text.trim(),
          isDefault: _isDefault,
          latitude: _latitude,
          longitude: _longitude,
        );
      } else {
        await AddressService.addAddress(
          label: _label.text.trim(),
          line1: _line1.text.trim(),
          line2: _line2.text.trim(),
          city: _city.text.trim(),
          pincode: _pincode.text.trim(),
          phone: _phone.text.trim(),
          isDefault: _isDefault,
          latitude: _latitude,
          longitude: _longitude,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save address: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      // SafeArea keeps the Save Address button clear of the system nav bar /
      // gesture strip, which is what was cutting it off before.
      child: SafeArea(
        top: false,
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
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(widget.existing != null ? 'Edit Address' : 'Add Address',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 16),

                  // Pick on map button — fixed height + centered content so
                  // the icon and label never crowd or overlap each other.
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _locatingOnMap ? null : _pickOnMap,
                      icon: _locatingOnMap
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary),
                            )
                          : Icon(Icons.map_outlined,
                              color: AppColors.primary, size: 20),
                      label: Text(
                        _latitude != null
                            ? 'Location pinned • Change on map'
                            : 'Pick location on map',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary),
                        alignment: Alignment.center,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick label chips
                  Wrap(
                    spacing: 8,
                    children: _quickLabels.map((l) {
                      final selected =
                          _label.text.trim().toLowerCase() == l.toLowerCase();
                      return ChoiceChip(
                        label: Text(l),
                        selected: selected,
                        selectedColor: AppColors.primary.withOpacity(0.15),
                        labelStyle: TextStyle(
                          color:
                              selected ? AppColors.primary : AppColors.textGrey,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.normal,
                        ),
                        onSelected: (_) => setState(() => _label.text = l),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _label,
                    decoration: const InputDecoration(
                        labelText: 'Label (e.g. Home, Work)'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _line1,
                    decoration:
                        const InputDecoration(labelText: 'Address Line 1'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _line2,
                    decoration: const InputDecoration(
                        labelText: 'Address Line 2 (optional)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _city,
                          decoration: const InputDecoration(labelText: 'City'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _pincode,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Pincode'),
                          validator: (v) => v == null || v.trim().length < 5
                              ? 'Invalid'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration:
                        const InputDecoration(labelText: 'Contact Phone'),
                    validator: (v) => v == null || v.trim().length < 10
                        ? 'Enter valid phone'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _isDefault,
                    onChanged: (v) => setState(() => _isDefault = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Set as default address'),
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
                          : const Text('Save Address'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
