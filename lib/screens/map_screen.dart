import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Isse LatLng aur GoogleMap theek hoga
import 'package:geolocator/geolocator.dart'; // Isse Position aur Geolocator theek hoga
import 'package:flutter_polyline_points/flutter_polyline_points.dart'; // Isse PolylinePoints theek hoga
import 'package:provider/provider.dart';
import '../provider/driver_state.dart'; // Isse DriverState ka error jayega
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverMapScreen extends StatefulWidget {
  const DriverMapScreen({super.key});

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;

  LatLng? _currentPosition;
  late LatLng
  _destinationLocation; // Iska naam generic rakha hai taaki patient/hospital switch ho sake

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];

  final String _apiKey = "AIzaSyDvRtdFAsuJ3XF5jYVZ7e8xz1PTpFvvvUo";
  late PolylinePoints _polylinePoints;

  double _speedKmph = 0;
  String _distanceLeftKm = "Calculating...";
  String _etaText = "-- min";

  @override
  void initState() {
    super.initState();
    // initState ke andar
    _polylinePoints = PolylinePoints(apiKey: _apiKey); // Ab yahan API key nahi deni hoti

    final state = Provider.of<DriverState>(context, listen: false);
    final data = state.activeRequestData;

    // Initial destination is Patient
    double lat =
        double.tryParse(
          data?['citizen_latitude']?.toString() ??
              data?['lat']?.toString() ??
              "27.1767",
        ) ??
        27.1767;
    double lng =
        double.tryParse(
          data?['citizen_longitude']?.toString() ??
              data?['lng']?.toString() ??
              "78.0081",
        ) ??
        78.0081;

    _destinationLocation = LatLng(lat, lng);

    _updateMarkers();
    _initLiveLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLiveLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 15, // 👈 2 se badhakar 15 karo taaki lag kam ho
      ),
    ).listen((Position position) {
          if (!mounted) return;

          LatLng newPos = LatLng(position.latitude, position.longitude);

          setState(() {
            _currentPosition = newPos;
            _speedKmph = position.speed * 3.6;
          });

          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: newPos,
                zoom: 18.5,
                bearing: position.heading,
                tilt: 45,
              ),
            ),
          );

          _updateDriverLocationInDB(position);
          _getPolyline();
          _updateMarkers();
        });
  }

  Future<void> _switchToHospitalRouting() async {
    final state = context.read<DriverState>();
    final hospitalId = state.activeRequestData?['hospital_id'];

    if (hospitalId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('hospitals')
          .select('latitude, longitude')
          .eq('profile_id', hospitalId)
          .single();

      if (response != null) {
        setState(() {
          _destinationLocation = LatLng(
            double.parse(response['latitude'].toString()),
            double.parse(response['longitude'].toString()),
          );
        });
        _getPolyline();
        _updateMarkers();
      }
    } catch (e) {
      debugPrint("Error switching to Hospital: $e");
    }
  }

  Future<void> _updateDriverLocationInDB(Position pos) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('drivers')
            .update({'current_lat': pos.latitude, 'current_lng': pos.longitude})
            .eq('id', user.id);
      }
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

  void _getPolyline() async {
    if (_currentPosition == null) return;

    PolylineResult result = await _polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest( // Sahi hai
        origin: PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        destination: PointLatLng(_destinationLocation.latitude, _destinationLocation.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      _polylineCoordinates.clear();
      for (var point in result.points) {
        _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }

      double totalDistance = 0;
      for (var i = 0; i < _polylineCoordinates.length - 1; i++) {
        totalDistance += Geolocator.distanceBetween(
          _polylineCoordinates[i].latitude,
          _polylineCoordinates[i].longitude,
          _polylineCoordinates[i + 1].latitude,
          _polylineCoordinates[i + 1].longitude,
        );
      }

      if (mounted) {
        setState(() {
          _distanceLeftKm = "${(totalDistance / 1000).toStringAsFixed(1)} km";
          _etaText = "${(totalDistance / 450).toStringAsFixed(0)} min";
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              color: Colors.blueAccent,
              width: 7,
              points: _polylineCoordinates,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          };
        });
      }
    }
  }

  void _updateMarkers() {
    if (!mounted) return;
    final status = context.read<DriverState>().activeRequestData?['status'];

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('ambulance'),
          position: _currentPosition ?? const LatLng(0, 0),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: "Ambulance"),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: status == 'patient_onboard'
                ? "Hospital"
                : "Patient Location",
          ),
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DriverState>();
    final currentStatus =
        state.activeRequestData?['status'] ?? 'driver_assigned';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _destinationLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            trafficEnabled: true,
            padding: const EdgeInsets.only(bottom: 280),
          ),

          Positioned(
            top: 50,
            left: 20,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              child: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _infoCol("DISTANCE", _distanceLeftKm, Icons.directions),
                      _infoCol(
                        "SPEED",
                        "${_speedKmph.toStringAsFixed(0)} km/h",
                        Icons.speed,
                      ),
                      _infoCol("ARRIVAL", _etaText, Icons.access_time),
                    ],
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: _buildActionButton(currentStatus),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCol(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white24, size: 18),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String status) {
    if (status == 'driver_assigned') {
      return _statusBtn(
        "START JOURNEY",
        Colors.blueAccent,
        () => _changeStatus('on_the_way'),
      );
    } else if (status == 'on_the_way') {
      return _statusBtn(
        "REACHED PATIENT",
        Colors.orangeAccent,
        () => _changeStatus('reached_patient'),
      );
    } else if (status == 'reached_patient') {
      return _statusBtn("PATIENT ONBOARD", Colors.teal, () async {
        await context.read<DriverState>().updateStatus('patient_onboard');
        await _switchToHospitalRouting(); // Switch destination to Hospital
      });
    } else if (status == 'patient_onboard') {
      return _statusBtn("FINISH TRIP", Colors.green, () async {
        await context.read<DriverState>().updateStatus('completed');
        await context.read<DriverState>().clearEmergency();
        if (mounted) Navigator.pop(context);
      });
    }
    return const SizedBox();
  }

  void _changeStatus(String status) async {
    await context.read<DriverState>().updateStatus(status);
  }

  Widget _statusBtn(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
