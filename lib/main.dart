import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'app.dart';
import 'core/di/service_locator.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    timeago.setLocaleMessages('en_short', timeago.EnShortMessages());
    // Inter and JetBrains Mono ship in assets/fonts (SIL OFL): credit them on
    // the licenses screen.
    LicenseRegistry.addLicense(() async* {
      for (final font in ['Inter', 'JetBrainsMono']) {
        final text = await rootBundle.loadString('assets/fonts/$font-OFL.txt');
        yield LicenseEntryWithLineBreaks([font], text);
      }
    });

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (kReleaseMode) debugPrint('FlutterError: ${details.exceptionAsString()}');
    };

    await setupServiceLocator();
    runApp(const TradingBookApp());
  }, (error, stack) {
    debugPrint('Uncaught: $error\n$stack');
  });
}
