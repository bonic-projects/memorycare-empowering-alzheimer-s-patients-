import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app/app.locator.dart';
import '../app/app.logger.dart';
import 'firestore_service.dart';

class LocationService {
  final log = getLogger('LocationService');
  final _firestoreService = locator<FirestoreService>();

  late Position _currentPosition;
  late String _currentPlace;
  late Timer _timer;

  Future<void> getLocation() async {
    log.i("Getting location..");
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled on the device.
      log.e("Not enabled");
      return;
    } else {
      log.i("Service enabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      log.e("Permission denied");
      permission = await Geolocator.requestPermission();
      if (permission != PermissionStatus.granted) {
        // The user didn't grant permission.
        log.e("No permission");
        return;
      }
    } else {
      // if (permission == PermissionStatus.granted)
      log.i("Permission $permission");
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      // Get the current location
      _currentPosition = await Geolocator.getCurrentPosition();
      // Get the current place
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);
      Placemark place = placemarks[0];
      _currentPlace = "${place.name}, ${place.locality}";
      // TODO: store the location in a database
      log.i(
          "Lat: ${_currentPosition.latitude}, Long: ${_currentPosition.longitude}  Place: $_currentPlace");
      _firestoreService.updateLocation(
          _currentPosition.latitude, _currentPosition.longitude, _currentPlace);
    }
  }

  Future<void> initialise() async {
    log.i("Init");
    await getLocation();
    // Start the timer to update the location every 1 minutes
    _timer = Timer.periodic(const Duration(minutes: 1), (Timer timer) async {
      await getLocation();
    });
  }

  void dispose() {
    _timer.cancel();
  }
}
