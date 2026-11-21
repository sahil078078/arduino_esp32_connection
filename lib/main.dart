import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/bluetooth_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ArduinoBluetoothApp());
}

class ArduinoBluetoothApp extends StatelessWidget {
  const ArduinoBluetoothApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BluetoothProvider>(
          create: (_) => BluetoothProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Arduino/Esp32 Controller',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
