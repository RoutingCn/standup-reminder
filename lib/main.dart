import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/exercise_screen.dart';
import 'services/exercise_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0E21), systemNavigationBarIconBrightness: Brightness.light));
  await NotificationService.init();
  NotificationService.onNotificationTap = (payload) async {
    if (payload == 'reminder') {
      final svc = ExerciseService();
      final e = await svc.recommendWithRotation();
      if (e != null) navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => ExerciseScreen(exercise: e)));
    }
  };
  runApp(const StandUpApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class StandUpApp extends StatelessWidget {
  const StandUpApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '起身', debugShowCheckedModeBanner: false, navigatorKey: navigatorKey,
    theme: ThemeData(
      brightness: Brightness.dark, primaryColor: const Color(0xFFFF6B35),
      scaffoldBackgroundColor: const Color(0xFF0A0E21),
      colorScheme: const ColorScheme.dark(primary: Color(0xFFFF6B35), secondary: Color(0xFF7C5CFC), surface: Color(0xFF151932), error: Color(0xFFFF5252)),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
      useMaterial3: true),
    home: const HomeScreen());
}
