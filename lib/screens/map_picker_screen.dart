import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/colors.dart';

/// Result returned from the map picker: raw coordinates plus a best-effort
/// reverse-geocoded address split into the fields our address form uses.
class PickedLocation {
  final double latitude;
  final double longitude;
  final String line1;
  final String city;
  final String pincode;

  PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.line1,
    required this.city,
    required this.pincode,
  });
}

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(20.5937, 78.9629); // India centroid fallback
  bool _loadingLocation = true;
  bool _resolvingAddress = false;
  String _addressPreview = 'Move the map to place the pin';

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _center = LatLng(widget.initialLat!, widget.initialLng!);
      _loadingLocation = false;
      _reverseGeocode(_center);
    } else {
      _detectCurrentLocation();
    }
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _loadingLocation = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _loadingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _center = loc;
        _loadingLocation = false;
      });
      _mapController.move(loc, 16);
      _reverseGeocode(loc);
    } catch (_) {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _resolvingAddress = true);
    try {
      final placemarks =
          await placemarkFromCoordinates(point.latitude, point.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [p.street, p.subLocality, p.locality]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');
        setState(() {
          _addressPreview = parts.isEmpty ? 'Unknown location' : parts;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _addressPreview = 'Could not resolve address');
    } finally {
      if (mounted) setState(() => _resolvingAddress = false);
    }
  }

  Future<void> _confirm() async {
    setState(() => _resolvingAddress = true);
    try {
      final placemarks =
          await placemarkFromCoordinates(_center.latitude, _center.longitude);
      final p = placemarks.isNotEmpty ? placemarks.first : null;
      final result = PickedLocation(
        latitude: _center.latitude,
        longitude: _center.longitude,
        line1: [p?.street, p?.subLocality]
            .where((s) => s != null && s.isNotEmpty)
            .join(', '),
        city: p?.locality ?? '',
        pincode: p?.postalCode ?? '',
      );
      if (mounted) Navigator.pop(context, result);
    } catch (_) {
      if (mounted) {
        Navigator.pop(
          context,
          PickedLocation(
            latitude: _center.latitude,
            longitude: _center.longitude,
            line1: '',
            city: '',
            pincode: '',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Delivery Location'),
        backgroundColor: AppColors.white,
      ),
      body: _loadingLocation
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 16,
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd ||
                          event is MapEventFlingAnimationEnd) {
                        final newCenter = _mapController.camera.center;
                        setState(() => _center = newCenter);
                        _reverseGeocode(newCenter);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.wekend.masti',
                    ),
                  ],
                ),
                // Fixed center pin — the map moves under it, not the other way round.
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.location_on,
                          size: 48, color: Colors.redAccent),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 190,
                  child: FloatingActionButton(
                    heroTag: 'my_location',
                    backgroundColor: AppColors.white,
                    onPressed: _detectCurrentLocation,
                    child: Icon(Icons.my_location, color: AppColors.primary),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _resolvingAddress
                                  ? Text('Locating...',
                                      style: TextStyle(
                                          color: AppColors.textGrey,
                                          fontSize: 13))
                                  : Text(
                                      _addressPreview,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                          fontSize: 13),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _resolvingAddress ? null : _confirm,
                            child: const Text('Confirm Location'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
