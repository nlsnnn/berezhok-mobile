import 'package:geolocator/geolocator.dart';

enum LocationStatus { granted, denied, deniedForever, serviceDisabled }

class UserLocationResult {
  const UserLocationResult({required this.status, this.position});

  final LocationStatus status;
  final Position? position;

  bool get hasLocation => position != null;
}

class UserLocationService {
  Future<UserLocationResult> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const UserLocationResult(status: LocationStatus.serviceDisabled);
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const UserLocationResult(status: LocationStatus.denied);
    }
    if (permission == LocationPermission.deniedForever) {
      return const UserLocationResult(status: LocationStatus.deniedForever);
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    return UserLocationResult(status: LocationStatus.granted, position: position);
  }

  Future<bool> openSettings() => Geolocator.openLocationSettings();
}
