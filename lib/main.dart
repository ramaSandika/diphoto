import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optimasi Tablet Photobooth: Kunci orientasi ke Landscape & Sembunyikan System Bar
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    const ProviderScope(
      child: DigitalPhotoboothApp(),
    ),
  );
}

class DigitalPhotoboothApp extends StatelessWidget {
  const DigitalPhotoboothApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Digital Photobooth Machine',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkBoothTheme,
      routerConfig: appRouter,
    );
  }
}