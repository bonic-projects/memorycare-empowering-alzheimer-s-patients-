import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memorycare/models/reminder.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.bottomsheets.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.logger.dart';
import '../../../app/app.router.dart';
import '../../../models/appuser.dart';
import '../../../services/firestore_service.dart';
import '../../../services/tts_service.dart';
import '../../../services/user_service.dart';
import '../../common/app_strings.dart';

class HomeViewModel extends StreamViewModel<List<Reminder>> {
  final log = getLogger('HomeViewModel');

  final _snackBarService = locator<SnackbarService>();
  final _navigationService = locator<NavigationService>();
  final _userService = locator<UserService>();
  final _firestoreService = locator<FirestoreService>();
  final _bottomSheetService = locator<BottomSheetService>();
  final TTSService _ttsService = locator<TTSService>();

  @override
  Stream<List<Reminder>> get stream => _firestoreService.getRemindersStream();

  AppUser? get user => _userService.user;

  late Timer _reminderTimer;

  void onModelRdy() async {
    log.i("started");
    setBusy(true);
    if (user == null) {
      await _userService.fetchUser();
    }
    if (user!.userRole == "bystander") {
      await getPatients();
    } else {
      startReminderCheck();
    }
    setBusy(false);
  }

  List<AppUser> _patients = <AppUser>[];

  List<AppUser> get patients => _patients;

  // Future
  Future getPatients() async {
    _patients = await _firestoreService.getUsersWithBystander();
    log.i("Users count: ${_patients.length}");
  }

  void openInAppView() {
    _navigationService.navigateTo(Routes.inAppView);
  }

  void openHardwareView() {
    _navigationService.navigateTo(Routes.hardwareView);
  }

  void openFaceTrainView() {
    _navigationService.navigateTo(Routes.faceRecView);
  }

  void openFaceTestView() {
    // _navigationService.navigateTo(Routes.faceTest);
  }

  void setPickedLocation(LatLng latLng) {
    _firestoreService.updateHomeLocation(latLng.latitude, latLng.longitude);
    _userService.fetchUser();
    _snackBarService.showSnackbar(message: "Home location set");
  }

  void onDelete(Reminder reminder) async {
    log.i("DELETE");
    log.i(reminder.id);
    await _firestoreService.deleteReminder(user!.id, reminder.id);
    _snackBarService.showSnackbar(message: "Reminder delete");
  }

  void logout() {
    _navigationService.replaceWithLoginRegisterView();
    _userService.logout();
  }

  void showBottomSheetUserSearch() async {
    final result = await _bottomSheetService.showCustomSheet(
      variant: BottomSheetType.notice,
      title: ksHomeBottomSheetTitle,
      description: ksHomeBottomSheetDescription,
    );
    if (result != null) {
      if (result.confirmed) {
        log.i("Bystander added: ${result.data.fullName}");
        _snackBarService.showSnackbar(
            message: "${result.data.fullName} added as bystander");
      }
      // _bottomSheetService.
    }
  }

  void openMapView(AppUser user) {
    _navigationService.navigateToMapView(user: user);
  }

  // Method to start checking for reminders
  void startReminderCheck() {
    // Schedule a timer to check reminders every minute
    _reminderTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      checkReminders();
    });
  }

  void stopReminderCheck() {
    _reminderTimer.cancel();
  }

  void checkReminders() {
    // log.i("Reminder");
    if (data != null) {
      // Get the current time
      final DateTime currentTime = DateTime.now();

      // Iterate through reminders and check if any have reached the current time
      for (Reminder reminder in data!) {
        // if (currentTime.isAfter(reminder.dateTime)) {
        if (currentTime.hour == reminder.dateTime.hour && currentTime.minute == reminder.dateTime.minute) {
          // Call a function or trigger an action when the reminder time is reached
          handleReminderReachedTime(reminder);
        }
      }
    }
  }

  // Method to handle the action when a reminder reaches the current time
  void handleReminderReachedTime(Reminder reminder) async {
    log.i('Reminder reached time: ${reminder.message}');
    await _ttsService.speak("Reminder: ${reminder.message}");
    // onDelete(reminder);
  }

  @override
  void dispose() {
    if (user!.userRole == "patient") {
      stopReminderCheck();
    }
    super.dispose();
  }
}
