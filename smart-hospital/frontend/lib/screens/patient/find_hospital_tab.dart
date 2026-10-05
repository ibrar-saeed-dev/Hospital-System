import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../../config/app_theme.dart';
import '../../models/hospital_search_result.dart';
import '../../services/map_service.dart';
import '../../services/patient_service.dart';
import '../../widgets/widgets.dart';

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

enum ResultViewMode { list, map, split }

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
  bool _isLocating = false;
  String? _errorMessage;
  SearchResponseModel? _searchResult;
  ResultViewMode _viewMode = ResultViewMode.list;

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

  Future<void> _useMyLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      final position = await MapService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _latController.text = position.latitude.toStringAsFixed(4);
          _lngController.text = position.longitude.toStringAsFixed(4);
          _selectedPresetName = null;
          _isLocating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated from device GPS.'),
            backgroundColor: AppColors.greenDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocating = false;
          _onPresetChanged('City Centre');
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not get GPS location ($e). Defaulted to City Centre.',
            ),
            backgroundColor: AppColors.amberDark,
          ),
        );
      }
    }
  }

  Future<void> _performSearch() async {
    if (_selectedResources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one required resource.'),
          backgroundColor: AppColors.primaryRed,
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
          backgroundColor: AppColors.primaryRed,
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
              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
              title: Row(
                children: [
                  const Icon(Icons.send_rounded, color: AppColors.primaryRed),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Dispatch Referral Request',
                      style: AppTypography.headingSmall(),
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
                        style: AppTypography.headingSmall(color: AppColors.primaryRed),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hospital.address,
                        style: AppTypography.bodySmall(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: patientRefController,
                        decoration: const InputDecoration(
                          labelText: 'Patient Reference / Name',
                          hintText: 'e.g. PAT-98231 or John Doe',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a patient reference or name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: AppRadius.radiusMd,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('URGENCY: ', style: AppTypography.label(fontSize: 10)),
                                StatusChip(status: _urgency, fontSize: 10),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Resources: ${_selectedResources.map((r) => resourceDisplayMap[r] ?? r).join(", ")}',
                              style: AppTypography.bodySmall(fontWeight: FontWeight.w600),
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
                  child: Text('Cancel', style: AppTypography.bodyMedium(color: AppColors.textSecondary)),
                ),
                SizedBox(
                  width: 150,
                  child: AppButton(
                    text: 'Send Request',
                    isLoading: isSubmitting,
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setDialogState(() => isSubmitting = true);

                            final lat = double.tryParse(_latController.text.trim()) ?? 25.3960;
                            final lng = double.tryParse(_lngController.text.trim()) ?? 68.3578;
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
                                  content: Text('Referral request dispatched to ${hospital.name}!'),
                                  backgroundColor: AppColors.greenDark,
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
                                  backgroundColor: AppColors.primaryRed,
                                ),
                              );
                            } catch (e) {
                              setDialogState(() => isSubmitting = false);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Error sending request: $e'),
                                  backgroundColor: AppColors.primaryRed,
                                ),
                              );
                            }
                          },
                    height: 44,
                    fontSize: 14,
                  ),
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
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 1000;

    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final userLocation = (lat != null && lng != null) ? LatLng(lat, lng) : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Form Card
          _buildSearchParametersCard(),

          const SizedBox(height: AppSpacing.xl),

          // Search Results Area
          if (_isSearching) ...[
            const SectionHeader(
              title: 'Searching Hospitals',
              subtitle: 'Evaluating capacity telemetry and transit distance...',
            ),
            const SizedBox(height: AppSpacing.md),
            const SkeletonListPlaceholder(count: 3, itemHeight: 160),
          ] else if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.redTint,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.primaryRed),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.bodySmall(color: AppColors.redDark),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_searchResult != null) ...[
            _buildResultsHeader(isWide),
            const SizedBox(height: AppSpacing.md),
            _buildResultsContent(isWide, userLocation),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchParametersCard() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.12),
                  borderRadius: AppRadius.radiusSm,
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Search Parameters', style: AppTypography.headingSmall()),
                    Text(
                      'Specify clinical requirements & origin coordinates for instant triage',
                      style: AppTypography.bodySmall(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Resource Multi-Select Chips
          Text(
            'REQUIRED CLINICAL RESOURCES',
            style: AppTypography.label(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs + 2,
            runSpacing: AppSpacing.xs + 2,
            children: resourceDisplayMap.entries.map((entry) {
              final isSelected = _selectedResources.contains(entry.key);
              return FilterChip(
                label: Text(entry.value),
                selected: isSelected,
                selectedColor: AppColors.primaryRed.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primaryRed,
                backgroundColor: AppColors.background,
                side: BorderSide(
                  color: isSelected ? AppColors.primaryRed : AppColors.border,
                  width: 1,
                ),
                labelStyle: AppTypography.label(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primaryRed : AppColors.ink,
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

          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),

          // Location Preset & "Use My Location"
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedPresetName,
                  decoration: const InputDecoration(
                    labelText: 'Location Preset',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  items: locationPresets.map((preset) {
                    return DropdownMenuItem<String>(
                      value: preset.name,
                      child: Text(preset.name, style: AppTypography.bodyMedium()),
                    );
                  }).toList(),
                  onChanged: _onPresetChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 170,
                child: AppButton(
                  text: 'Use My GPS',
                  icon: Icons.my_location_rounded,
                  variant: AppButtonVariant.secondary,
                  isLoading: _isLocating,
                  onPressed: _useMyLocation,
                  height: 52,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Lat / Lng inputs
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Origin Latitude',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                  ),
                  onChanged: (_) => setState(() => _selectedPresetName = null),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextFormField(
                  controller: _lngController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Origin Longitude',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                  ),
                  onChanged: (_) => setState(() => _selectedPresetName = null),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Distance Slider & Urgency Dropdown
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MAX SEARCH RADIUS',
                          style: AppTypography.label(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${_maxDistanceKm.toInt()} km',
                          style: AppTypography.headingSmall(color: AppColors.primaryRed),
                        ),
                      ],
                    ),
                    Slider(
                      value: _maxDistanceKm,
                      min: 5.0,
                      max: 50.0,
                      divisions: 45,
                      activeColor: AppColors.primaryRed,
                      inactiveColor: AppColors.border,
                      onChanged: (val) => setState(() => _maxDistanceKm = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _urgency,
                  decoration: const InputDecoration(
                    labelText: 'Patient Urgency Level',
                    prefixIcon: Icon(Icons.warning_amber_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low Urgency')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium Urgency')),
                    DropdownMenuItem(value: 'high', child: Text('High Urgency')),
                    DropdownMenuItem(value: 'critical', child: Text('Critical / Emergency')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _urgency = val);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Search Button
          AppButton(
            text: _isSearching ? 'Searching Telemetry...' : 'Find Matching Hospitals',
            icon: Icons.search_rounded,
            isLoading: _isSearching,
            onPressed: _performSearch,
            height: 52,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(bool isWide) {
    final suitableCount = _searchResult?.suitable.length ?? 0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Matching Facilities ($suitableCount)',
                style: AppTypography.headingMedium(),
              ),
              Text(
                'Ranked by clinical capability, bed availability, and transit time',
                style: AppTypography.bodySmall(),
              ),
            ],
          ),
        ),
        if (!isWide)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewModeToggle(
                  mode: ResultViewMode.list,
                  icon: Icons.view_list_rounded,
                  label: 'List',
                ),
                _buildViewModeToggle(
                  mode: ResultViewMode.map,
                  icon: Icons.map_rounded,
                  label: 'Map',
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildViewModeToggle({
    required ResultViewMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: AppRadius.radiusSm,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primaryRed : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.label(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.ink : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsContent(bool isWide, LatLng? userLocation) {
    if (_searchResult == null) return const SizedBox.shrink();

    if (_searchResult!.suitable.isEmpty && _searchResult!.excluded.isEmpty) {
      return const EmptyState(
        icon: Icons.domain_disabled_rounded,
        title: 'No Facilities Found',
        message: 'No hospitals matched your required resources within this radius.',
      );
    }

    if (isWide) {
      // Side-by-Side on Desktop (List on Left, Interactive Map on Right)
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: _buildSuitableList(),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            flex: 6,
            child: SizedBox(
              height: 680,
              child: AppCard(
                padding: EdgeInsets.zero,
                child: HospitalMap(
                  userLocation: userLocation,
                  suitableHospitals: _searchResult!.suitable,
                  excludedHospitals: _searchResult!.excluded,
                  requiredResources: _selectedResources.toList(),
                  onRequestHospital: _showSendRequestDialog,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Mobile / Tablet: toggle between list and map
    if (_viewMode == ResultViewMode.map) {
      return SizedBox(
        height: 520,
        child: AppCard(
          padding: EdgeInsets.zero,
          child: HospitalMap(
            userLocation: userLocation,
            suitableHospitals: _searchResult!.suitable,
            excludedHospitals: _searchResult!.excluded,
            requiredResources: _selectedResources.toList(),
            onRequestHospital: _showSendRequestDialog,
          ),
        ),
      );
    }

    return _buildSuitableList();
  }

  Widget _buildSuitableList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _searchResult!.suitable.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final hosp = _searchResult!.suitable[index];
            final rank = index + 1;
            return _buildSuitableHospitalCard(hosp, rank);
          },
        ),
        if (_searchResult!.excluded.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _buildExcludedSection(),
        ],
      ],
    );
  }

  Widget _buildSuitableHospitalCard(HospitalMatchItem hosp, int rank) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: rank == 1 ? AppColors.primaryRed : AppColors.black,
                  borderRadius: AppRadius.radiusMd,
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: AppTypography.display(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hosp.name,
                            style: AppTypography.headingSmall(color: AppColors.ink),
                          ),
                        ),
                        if (rank == 1) ...[
                          const SizedBox(width: 8),
                          const StatusChip(status: 'BEST MATCH', fontSize: 10),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hosp.address,
                      style: AppTypography.bodySmall(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              MatchRing(score: hosp.matchPercent, size: 52),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Distance, Time & Last Updated
          Row(
            children: [
              const Icon(Icons.near_me_rounded, size: 15, color: AppColors.primaryRed),
              const SizedBox(width: 4),
              Text(
                '${hosp.distanceKm.toStringAsFixed(1)} km',
                style: AppTypography.bodySmall(fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
              const SizedBox(width: AppSpacing.lg),
              const Icon(Icons.schedule_rounded, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '~${hosp.estimatedTravelMinutes.round()} mins driving',
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                'Updated ${_formatLastUpdated(hosp.lastUpdated)}',
                style: AppTypography.label(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Resource Availability Chips
          _buildResourceChips(hosp.capacities),

          if (hosp.stale) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.amberTint,
                borderRadius: AppRadius.radiusSm,
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.amberDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Capacity data has not been updated in over 30 mins.',
                      style: AppTypography.label(fontSize: 10, color: AppColors.amberDark),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // Action Buttons: Navigate & Send Request
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Navigate',
                  icon: Icons.directions_rounded,
                  variant: AppButtonVariant.secondary,
                  height: 44,
                  fontSize: 13,
                  onPressed: () {
                    if (hosp.latitude != null && hosp.longitude != null) {
                      MapService.openInGoogleMaps(hosp.latitude!, hosp.longitude!, hosp.name);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  text: 'Dispatch Request',
                  icon: Icons.send_rounded,
                  height: 44,
                  fontSize: 13,
                  onPressed: () => _showSendRequestDialog(hosp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourceChips(Map<String, CapacityDetail> capacities) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: _selectedResources.map((resKey) {
        final cap = capacities[resKey];
        final displayName = resourceDisplayMap[resKey] ?? resKey;
        final avail = cap?.available ?? 0;
        final total = cap?.total ?? 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: avail > 0 ? AppColors.greenTint : AppColors.redTint,
            borderRadius: AppRadius.radiusPill,
            border: Border.all(
              color: avail > 0
                  ? AppColors.green.withValues(alpha: 0.3)
                  : AppColors.primaryRed.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            '$displayName: $avail / $total',
            style: AppTypography.label(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: avail > 0 ? AppColors.greenDark : AppColors.redDark,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExcludedSection() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: ExpansionTile(
        initiallyExpanded: false,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          'Excluded Facilities (${_searchResult!.excluded.length})',
          style: AppTypography.headingSmall(fontSize: 15, color: AppColors.textSecondary),
        ),
        subtitle: Text(
          'Hospitals lacking requested resource capacity or beyond radius limit',
          style: AppTypography.bodySmall(),
        ),
        children: _searchResult!.excluded.map((hosp) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.radiusMd,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hosp.name, style: AppTypography.bodyMedium(fontWeight: FontWeight.w600)),
                      Text(hosp.address, style: AppTypography.bodySmall()),
                      const SizedBox(height: 4),
                      StatusChip(status: hosp.exclusionReason, fontSize: 10),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                AppButton(
                  text: 'Navigate',
                  icon: Icons.directions_rounded,
                  variant: AppButtonVariant.secondary,
                  isFullWidth: false,
                  height: 36,
                  fontSize: 12,
                  onPressed: () {
                    if (hosp.latitude != null && hosp.longitude != null) {
                      MapService.openInGoogleMaps(hosp.latitude!, hosp.longitude!, hosp.name);
                    }
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
