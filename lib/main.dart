import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/firebase/firebase_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseAppInitializer.initialize();
  runApp(App());
}
