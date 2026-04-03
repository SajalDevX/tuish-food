import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/core/widgets/tuish_text_field.dart';
import 'package:tuish_food/features/customer/profile/domain/entities/address.dart';
import 'package:tuish_food/features/customer/profile/presentation/providers/map_address_provider.dart';
import 'package:tuish_food/features/customer/profile/presentation/providers/profile_provider.dart';
import 'package:tuish_food/injection_container.dart';

enum _AddStep { mapPicker, details }

class AddAddressScreen extends ConsumerStatefulWidget {
  const AddAddressScreen({super.key, this.existingAddress});

  /// Pass an existing [Address] to enter edit mode (skips map step, pre-fills form).
  final Address? existingAddress;

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  _AddStep _step = _AddStep.mapPicker;
  GoogleMapController? _mapController;

  /// The center coordinate tracked as the user pans the map.
  LatLng _currentMapCenter = const LatLng(20.5937, 78.9629); // India center

  /// Confirmed after tapping "Confirm Location".
  LatLng? _confirmedLatLng;

  // Step 2 form
  final _formKey = GlobalKey<FormState>();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  String _selectedLabel = 'Home';
  final _customLabelController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;

  static const _labels = ['Home', 'Work', 'Other'];

  bool get _isEditing => widget.existingAddress != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _step = _AddStep.details;
      _prefillFromExisting(widget.existingAddress!);
    }
  }

  void _prefillFromExisting(Address a) {
    _addressLine1Controller.text = a.addressLine1;
    _addressLine2Controller.text = a.addressLine2 ?? '';
    _cityController.text = a.city;
    _stateController.text = a.state;
    _zipCodeController.text = a.zipCode;
    _selectedLabel = a.label;
    _customLabelController.text = a.customLabel ?? '';
    _isDefault = a.isDefault;
    if (a.latitude != null && a.longitude != null) {
      _confirmedLatLng = LatLng(a.latitude!, a.longitude!);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _customLabelController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Step 1 helpers
  // ---------------------------------------------------------------------------

  void _onConfirmLocation() {
    final mapState = ref.read(mapAddressProvider);
    if (mapState.selectedLatLng == null) return;

    setState(() {
      _confirmedLatLng = mapState.selectedLatLng;

      // Auto-fill city/state/pincode from reverse geocoding result
      if (mapState.placemark != null) {
        final p = mapState.placemark!;
        if (p.city.isNotEmpty) _cityController.text = p.city;
        if (p.state.isNotEmpty) _stateController.text = p.state;
        if (p.zipCode.isNotEmpty) _zipCodeController.text = p.zipCode;
      }

      _step = _AddStep.details;
    });
  }

  Future<void> _onUseMyLocation() async {
    await ref.read(mapAddressProvider.notifier).useMyLocation();
    // After GPS updates selectedLatLng, animate the camera there
    final latLng = ref.read(mapAddressProvider).selectedLatLng;
    if (latLng != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 16),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Step 2 helpers
  // ---------------------------------------------------------------------------

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    final address = Address(
      id: _isEditing ? widget.existingAddress!.id : const Uuid().v4(),
      label: _selectedLabel,
      customLabel: _selectedLabel == 'Other'
          ? _customLabelController.text.trim()
          : null,
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim().isEmpty
          ? null
          : _addressLine2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      zipCode: _zipCodeController.text.trim(),
      latitude: _confirmedLatLng?.latitude,
      longitude: _confirmedLatLng?.longitude,
      isDefault: _isDefault,
    );

    final notifier = ref.read(addressManagementProvider.notifier);
    final success = _isEditing
        ? await notifier.updateAddress(currentUser.uid, address)
        : await notifier.addAddress(currentUser.uid, address);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ref.invalidate(addressesProvider(currentUser.uid));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Address updated' : 'Address saved'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save address. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Listen for GPS result to animate camera
    ref.listen<MapAddressState>(mapAddressProvider, (prev, next) {
      if (next.selectedLatLng != null &&
          next.selectedLatLng != prev?.selectedLatLng &&
          _mapController != null &&
          next.isGpsLoading == false) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(next.selectedLatLng!, 16),
        );
      }
    });

    // Also listen for permission errors to show snackbar
    ref.listen<MapAddressState>(mapAddressProvider, (prev, next) {
      if (next.geocodeError != null &&
          next.geocodeError != prev?.geocodeError &&
          (next.geocodeError!.contains('permission') ||
              next.geocodeError!.contains('disabled'))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.geocodeError!),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: Geolocator.openAppSettings,
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          _step == _AddStep.mapPicker
              ? 'Set Location'
              : (_isEditing ? 'Edit Address' : 'Add Address'),
          style: AppTypography.titleMedium,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (_step == _AddStep.details && !_isEditing) {
              setState(() => _step = _AddStep.mapPicker);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: _step == _AddStep.mapPicker
          ? _buildMapStep()
          : _buildDetailsStep(),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1: Map picker
  // ---------------------------------------------------------------------------

  Widget _buildMapStep() {
    final mapState = ref.watch(mapAddressProvider);

    return Stack(
      children: [
        // Full-screen map
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentMapCenter,
            zoom: 5,
          ),
          onMapCreated: (controller) => _mapController = controller,
          onCameraMove: (pos) => _currentMapCenter = pos.target,
          onCameraIdle: () =>
              ref.read(mapAddressProvider.notifier).onCameraIdle(_currentMapCenter),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
        ),

        // Fixed center pin (drawn as overlay, not a map Marker — stays centered)
        const Align(
          alignment: Alignment.center,
          child: Padding(
            // Offset up slightly so the tip of the pin sits on the target
            padding: EdgeInsets.only(bottom: 48),
            child: Icon(
              Icons.location_pin,
              color: AppColors.primary,
              size: 48,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),
        ),

        // Bottom sheet
        DraggableScrollableSheet(
          initialChildSize: 0.26,
          minChildSize: 0.26,
          maxChildSize: 0.26,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusL),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: AppSizes.paddingAllM,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSizes.s12),
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: AppSizes.borderRadiusPill,
                      ),
                    ),
                  ),

                  // Detected area name
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: AppSizes.s8),
                      Expanded(child: _buildAreaLabel(mapState)),
                    ],
                  ),
                  const SizedBox(height: AppSizes.s12),

                  // Buttons row
                  Row(
                    children: [
                      // Use My Location
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: mapState.isGpsLoading
                              ? null
                              : _onUseMyLocation,
                          icon: mapState.isGpsLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Icon(Icons.my_location, size: 16),
                          label: const Text('My Location'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.s8),
                            shape: RoundedRectangleBorder(
                                borderRadius: AppSizes.borderRadiusM),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.s12),

                      // Confirm location
                      Expanded(
                        flex: 2,
                        child: TuishButton.primary(
                          label: 'Confirm Location',
                          isLoading: mapState.isGeocodingLoading,
                          onPressed: mapState.selectedLatLng == null ||
                                  mapState.isGeocodingLoading
                              ? null
                              : _onConfirmLocation,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAreaLabel(MapAddressState mapState) {
    if (mapState.isGeocodingLoading) {
      return Shimmer.fromColors(
        baseColor: AppColors.divider,
        highlightColor: AppColors.surface,
        child: Container(
          height: 16,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: AppSizes.borderRadiusS,
          ),
        ),
      );
    }

    if (mapState.placemark != null) {
      return Text(
        mapState.placemark!.displayName.isNotEmpty
            ? mapState.placemark!.displayName
            : 'Selected location',
        style: AppTypography.bodyMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    if (mapState.geocodeError != null &&
        !mapState.geocodeError!.contains('permission') &&
        !mapState.geocodeError!.contains('disabled')) {
      return Text(
        'Move the map to select your location',
        style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary),
      );
    }

    return Text(
      'Move the map to select your location',
      style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: Address details form
  // ---------------------------------------------------------------------------

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map thumbnail (shown only if we have coordinates)
            if (_confirmedLatLng != null) _buildMapThumbnail(),

            Padding(
              padding: AppSizes.paddingAllM,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // House / Flat / Block No.
                  TuishTextField(
                    label: 'House / Flat / Block No.',
                    hint: 'e.g. 4B, 12th Floor',
                    controller: _addressLine1Controller,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Required'
                        : null,
                  ),
                  const SizedBox(height: AppSizes.s16),

                  // Landmark
                  TuishTextField(
                    label: 'Landmark (Optional)',
                    hint: 'Nearby place for easy navigation',
                    controller: _addressLine2Controller,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSizes.s16),

                  // City
                  TuishTextField(
                    label: 'City',
                    hint: 'City',
                    controller: _cityController,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'City is required'
                        : null,
                  ),
                  const SizedBox(height: AppSizes.s16),

                  // State + Pincode row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TuishTextField(
                          label: 'State',
                          hint: 'State',
                          controller: _stateController,
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: AppSizes.s16),
                      Expanded(
                        child: TuishTextField(
                          label: 'Pincode',
                          hint: 'Pincode',
                          controller: _zipCodeController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.s20),

                  // Label chips
                  Text('Save address as', style: AppTypography.labelLarge),
                  const SizedBox(height: AppSizes.s12),
                  Wrap(
                    spacing: AppSizes.s8,
                    children: _labels.map((label) {
                      final isSelected = _selectedLabel == label;
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.onPrimary
                              : AppColors.textPrimary,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedLabel = label);
                        },
                      );
                    }).toList(),
                  ),

                  // Custom label
                  if (_selectedLabel == 'Other') ...[
                    const SizedBox(height: AppSizes.s16),
                    TuishTextField(
                      label: 'Custom Label',
                      hint: "e.g. Parent's Home",
                      controller: _customLabelController,
                      textInputAction: TextInputAction.done,
                      validator: (v) =>
                          (_selectedLabel == 'Other' &&
                                  (v == null || v.trim().isEmpty))
                              ? 'Please enter a label'
                              : null,
                    ),
                  ],

                  const SizedBox(height: AppSizes.s8),

                  // Default toggle
                  SwitchListTile(
                    title: Text(
                      'Set as default address',
                      style: AppTypography.bodyLarge,
                    ),
                    value: _isDefault,
                    activeTrackColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _isDefault = v),
                  ),

                  const SizedBox(height: AppSizes.s24),

                  TuishButton.primary(
                    label: _isEditing ? 'Update Address' : 'Save Address',
                    isLoading: _isLoading,
                    onPressed: _saveAddress,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapThumbnail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.zero,
          child: SizedBox(
            height: 140,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _confirmedLatLng!,
                zoom: 16,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: _confirmedLatLng!,
                ),
              },
              zoomControlsEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: AppSizes.s16, top: AppSizes.s4, bottom: AppSizes.s4),
          child: TextButton.icon(
            onPressed: () => setState(() => _step = _AddStep.mapPicker),
            icon: const Icon(Icons.edit_location_alt_outlined,
                size: 16, color: AppColors.primary),
            label: Text(
              'Change Location',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.primary),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s4, vertical: AppSizes.s4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
