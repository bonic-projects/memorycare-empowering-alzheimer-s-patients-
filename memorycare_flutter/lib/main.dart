import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:memorycare/app/app.bottomsheets.dart';
import 'package:memorycare/app/app.dialogs.dart';
import 'package:memorycare/app/app.locator.dart';
import 'package:memorycare/app/app.router.dart';
import 'package:memorycare/ui/common/app_colors.dart';
import 'package:stacked_services/stacked_services.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await setupLocator();
  setupDialogUi();
  setupBottomSheetUi();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: Routes.startupView,
      onGenerateRoute: StackedRouter().onGenerateRoute,
      navigatorKey: StackedService.navigatorKey,
      navigatorObservers: [
        StackedService.routeObserver,
      ],
      theme: ThemeData(
        primaryColor: kcPrimaryColor,
        fontFamily: "Poppins",
      ),
    );
  }
}
