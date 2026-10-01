import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../models/hospital_search_result.dart';
import '../../services/patient_service.dart';

class PresetLocation {
  final String name;
  final double lat;
  final double lng;

  const PresetLocation(this.name, this.lat, this.lng);
}

const List<PresetLocation> locationPresets = [
  PresetLocation('City Centre', 25.3960, 68.3578),
  PresetLocation('Qasimabad', 25.4150, 68.3100),
  PresetLocation('Latifabad', 25.3980, 68.3780),
  PresetLocation('Autobahn Road', 25.3650, 68.3450),
  PresetLocation('Gulistan-e-Sajjad', 25.4010, 68.3700),
  PresetLocation('Kotri Road', 25.3640, 68.3080),
  PresetLocation('Jamshoro Road', 25.4200, 68.2900),
];

const Map<String, String> resourceDisplayMap = {
  'icu_bed': 'ICU Bed',
  'ventilator': 'Ventilator',
  'emergency_bed': 'Emergency Bed',
  'nicu_bed': 'NICU Bed',
  'general_bed': 'General Bed',
  'isolation_bed': 'Isolation Bed',
  'dialysis': 'Dialysis',
  'trauma': 'Trauma',
  'operation_theatre': 'Operation Theatre',
  'ambulance': 'Ambulance',
};

class FindHospitalTab extends StatefulWidget {
  final PatientService patientService;
  final VoidCallback onRequestCreated;

  const FindHospitalTab({
    super.key,
    required this.patientService,
    required this.onRequestCreated,
  });

  @override
  State<FindHospitalTab> createState() => _FindHospitalTabState();
}

class _FindHospitalTabState extends State<FindHospitalTab> {
  final Set<String> _selectedResources = {'icu_bed', 'ventilator'};
  late TextEditingController _latController;
  late TextEditingController _lngController;

  String? _selectedPresetName = 'City Centre';
  double _maxDistanceKm = 30.0;
  String _urgency = 'critical';

  bool _isSearching = false;
  String? _errorMessage;
  SearchResponseModel? _searchResult;

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController(text: '25.3960');
    _lngController = TextEditingController(text: '68.3578');
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _onPresetChanged(String? presetName) {
    if (presetName == null) return;
    final preset = locationPresets.firstWhere((p) => p.name == presetName);
    setState(() {
      _selectedPresetName = presetName;
      _latController.text = preset.lat.toString();
      _lngController.text = preset.lng.toString();
    });
  }

  Future<void> _performSearch() async {
    if (_selectedResources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one required resource.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid latitude and longitude coordinates.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final res = await widget.patientService.searchHospitals(
        requiredResources: _selectedResources.toList(),
        latitude: lat,
        longitude: lng,
        maxDistanceKm: _maxDistanceKm,
      );

      if (mounted) {
        setState(() {
          _searchResult = res;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSearching = false;
        });
      }
    }
  }

  void _showSendRequestDialog(HospitalMatchItem hospital) {
    final patientRefController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.send_rounded, color: Color(0xFF00796B)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Send Referral Request',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: patientRefController,
                        decoration: const InputDecoration(
                          labelText: 'Patient Reference / Name',
                          hintText: 'e.g. PAT-98231 or John Doe',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a patient reference or name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Urgency: ${_urgency.toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Resources: ${_selectedResources.map((r) => resourceDisplayMap[r] ?? r).join(", ")}',
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSubmitting = true);

                          final lat = double.tryParse(_latController.text.trim()) ?? 17.4435;
                          final lng = double.tryParse(_lngController.text.trim()) ?? 78.3772;
                          final navigator = Navigator.of(dialogContext);
                          final messenger = ScaffoldMessenger.of(this.context);

                          try {
                            await widget.patientService.createReferralRequest(
                              patientReference: patientRefController.text.trim(),
                              requiredResources: _selectedResources.toList(),
                              urgency: _urgency,
                              latitude: lat,
                              longitude: lng,
                              selectedHospitalId: hospital.hospitalId,
                            );

                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Referral request sent to ${hospital.name}!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            widget.onRequestCreated();
                          } on DioException catch (e) {
                            setDialogState(() => isSubmitting = false);
                            final errorMsg = e.error?.toString() ??
                                (e.response?.statusCode == 409
                                    ? "Bed was just taken, please search again"
                                    : "Failed to send request.");
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(errorMsg),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Error sending request: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Send Request'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatLastUpdated(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'recently';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) {
        return 'just now';
      } else if (diff.inMinutes == 1) {
        return '1 min ago';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} min ago';
      } else {
        final hours = diff.inHours;
        return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
      }
    } catch (e) {
      return 'recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Form Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Search Parameters',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Resource Selector (Multi-select Chips)
                  const Text(
                    'Required Resources:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: resourceDisplayMap.entries.map((entry) {
                      final isSelected = _selectedResources.contains(entry.key);
                      return FilterChip(
                        label: Text(entry.value),
                        selected: isSelected,
                        selectedColor: theme.colorScheme.primaryContainer,
                        checkmarkColor: theme.colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? theme.colorScheme.primary : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedResources.add(entry.key);
                            } else {
                              _selectedResources.remove(entry.key);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Location Presets & Coordinates
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedPresetName,
                          decoration: const InputDecoration(
                            labelText: 'Location Preset',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: locationPresets.map((preset) {
                            return DropdownMenuItem<String>(
                              value: preset.name,
                              child: Text(preset.name),
                            );
                          }).toList(),
                          onChanged: _onPresetChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() => _selectedPresetName = null),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lngController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() => _selectedPresetName = null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Distance Slider & Urgency Dropdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Max Distance:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        '${_maxDistanceKm.toInt()} km',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _maxDistanceKm,
                    min: 5.0,
                    max: 50.0,
                    divisions: 45,
                    label: '${_maxDistanceKm.toInt()} km',
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => setState(() => _maxDistanceKm = val),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _urgency,
                          decoration: const InputDecoration(
                            labelText: 'Patient Urgency Level',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'low', child: Text('Low')),
                            DropdownMenuItem(value: 'medium', child: Text('Medium')),
                            DropdownMenuItem(value: 'high', child: Text('High')),
                            DropdownMenuItem(value: 'critical', child: Text('Critical')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _urgency = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Search Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSearching ? null : _performSearch,
                      icon: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.search_rounded),
                      label: Text(_isSearching ? 'Searching Hospitals...' : 'Search Hospitals'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Error Display
          if (_errorMessage != null) ...[
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Search Results
          if (_searchResult != null) ...[
            Text(
              'Suitable Hospitals (${_searchResult!.suitable.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (_searchResult!.suitable.isEmpty) ...[
              Card(
                elevation: 1,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: const Column(
                    children: [
                      Icon(Icons.domain_disabled_rounded, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No suitable hospitals found for selected resources within this distance range.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResult!.suitable.length,
                itemBuilder: (context, index) {
                  final hosp = _searchResult!.suitable[index];
                  final rank = index + 1;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rank & Match % Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: rank == 1 ? Colors.amber.shade700 : theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '#$rank',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (rank == 1) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green.shade700),
                                  ),
                                  child: const Text(
                                    'Best match',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              // Big Match % Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.teal.shade300),
                                ),
                                child: Text(
                                  '${hosp.matchPercent.toStringAsFixed(1)}% Match',
                                  style: const TextStyle(
                                    color: Color(0xFF00796B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Hospital Name & Address
                          Text(
                            hosp.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  hosp.address,
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Distance & Travel Time
                          Row(
                            children: [
                              Icon(Icons.directions_car_outlined, size: 16, color: theme.colorScheme.secondary),
                              const SizedBox(width: 4),
                              Text(
                                '${hosp.distanceKm} km away',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.secondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '~${hosp.estimatedTravelMinutes} mins travel',
                                style: const TextStyle(color: Colors.black87, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Availability per resource
                          const Text(
                            'Required Resource Availability:',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black54),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: _selectedResources.map((resKey) {
                              final cap = hosp.capacities[resKey];
                              final displayName = resourceDisplayMap[resKey] ?? resKey;
                              final avail = cap?.available ?? 0;
                              final total = cap?.total ?? 0;

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  '$displayName: $avail available (Total $total)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: avail > 0 ? Colors.green.shade800 : Colors.red,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),

                          // Last Updated Label & Stale Warning
                          Row(
                            children: [
                              const Icon(Icons.history_outlined, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Last updated ${_formatLastUpdated(hosp.lastUpdated)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),

                          if (hosp.stale) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Capacity information may be outdated',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Send Request Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showSendRequestDialog(hosp),
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: const Text('Send Request'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00796B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 16),

            // Collapsed Excluded Hospitals Section
            if (_searchResult!.excluded.isNotEmpty) ...[
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.shade200),
                ),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  leading: const Icon(Icons.block_rounded, color: Colors.red),
                  title: Text(
                    'Not Suitable Hospitals (${_searchResult!.excluded.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  children: _searchResult!.excluded.map((exHosp) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(exHosp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(exHosp.address, style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            'Reason: ${exHosp.exclusionReason}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text('${exHosp.distanceKm} km', style: const TextStyle(color: Colors.grey)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
