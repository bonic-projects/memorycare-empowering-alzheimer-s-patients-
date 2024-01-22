import 'dart:async';

import 'package:flutter_sms/flutter_sms.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memorycare/services/user_service.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app/app.locator.dart';
import '../app/app.logger.dart';
import 'firestore_service.dart';

class LocationService {
  final log = getLogger('LocationService');
  final _firestoreService = locator<FirestoreService>();
  final _userService = locator<UserService>();

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
      //distance checking
      double distance = Geolocator.distanceBetween(_currentPosition.latitude, _currentPosition.longitude, _userService.user!.homeLat, _userService.user!.homeLong);
      log.e(distance);
      if(distance > 30) {
        _sendSMS("ALERT! Patient is $distance meter away from home!, View current location: http://maps.google.com/maps?z=12&t=m&q=loc:${_currentPosition.latitude}+${_currentPosition.longitude}", [_userService.user!.phone]);
      }

    }
  }

  void _sendSMS(String message, List<String> recipents) async {
    String result = await sendSMS(message: message, recipients: recipents)
        .catchError((onError) {
      log.e(onError);
    });
    log.i(result);
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
