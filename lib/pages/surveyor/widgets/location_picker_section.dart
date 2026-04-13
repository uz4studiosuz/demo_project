import 'package:flutter/material.dart';
import '../../../utils/location_data.dart';

class LocationPickerSection extends StatefulWidget {
  final Function(
    String? tuman,
    String? qfy,
    String? mfy,
    String? street,
    String fullAddress,
  )
  onAddressChanged;

  const LocationPickerSection({super.key, required this.onAddressChanged});

  @override
  State<LocationPickerSection> createState() => _LocationPickerSectionState();
}

class _LocationPickerSectionState extends State<LocationPickerSection> {
  String? _selectedTuman;
  String? _selectedQfy;
  String? _selectedMfy;
  String? _selectedStreet;

  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _updateAddress() {
    List<String> parts = [];
    if (_selectedTuman != null) parts.add(_selectedTuman!);
    if (_selectedQfy != null) parts.add('$_selectedQfy QFY');
    if (_selectedMfy != null) parts.add('$_selectedMfy MFY');
    if (_selectedStreet != null) parts.add('$_selectedStreet ko\'chasi');

    final fullAddress = parts.join(', ');
    _addressController.text = fullAddress;

    widget.onAddressChanged(
      _selectedTuman,
      _selectedQfy,
      _selectedMfy,
      _selectedStreet,
      fullAddress,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedTuman,
          decoration: const InputDecoration(
            labelText: 'Tuman / Shahar',
            prefixIcon: Icon(Icons.location_city),
          ),
          items: LocationData.tumanlar
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedTuman = val;
              _selectedQfy = null;
              _selectedMfy = null;
              _updateAddress();
            });
          },
          validator: (val) => val == null ? 'Bajarilishi shart' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedQfy,
          decoration: const InputDecoration(
            labelText: 'QFY / Shaharcha',
            prefixIcon: Icon(Icons.terrain),
          ),
          items:
              _selectedTuman != null &&
                      LocationData.qfylar[_selectedTuman!] != null
                  ? LocationData.qfylar[_selectedTuman!]!
                        .map(
                          (q) => DropdownMenuItem(value: q, child: Text(q)),
                        )
                        .toList()
                  : [],
          onChanged: (val) {
            setState(() {
              _selectedQfy = val;
              _updateAddress();
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedMfy,
          decoration: const InputDecoration(
            labelText: 'MFY nomi',
            prefixIcon: Icon(Icons.groups_outlined),
          ),
          items:
              _selectedTuman != null &&
                      LocationData.mfylar[_selectedTuman!] != null
                  ? LocationData.mfylar[_selectedTuman!]!
                        .map(
                          (m) => DropdownMenuItem(value: m, child: Text(m)),
                        )
                        .toList()
                  : [],
          onChanged: (val) {
            setState(() {
              _selectedMfy = val;
              _updateAddress();
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedStreet,
          decoration: const InputDecoration(
            labelText: 'Ko\'cha / Qishloq',
            prefixIcon: Icon(Icons.add_road),
          ),
          items: LocationData.kochalar
              .map((k) => DropdownMenuItem(value: k, child: Text(k)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedStreet = val;
              _updateAddress();
            });
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _addressController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'To\'liq rasmiy manzil',
            prefixIcon: const Icon(Icons.home_outlined),
            fillColor: Colors.grey.withValues(alpha: 0.1),
            filled: true,
          ),
          validator: (val) => val!.isEmpty ? 'Manzil majburiy' : null,
        ),
      ],
    );
  }
}
