import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arduino_control_app/main.dart';
import 'package:arduino_control_app/screens/splash_screen.dart';
import 'package:arduino_control_app/widgets/led_control_card.dart';
import 'package:arduino_control_app/widgets/pwm_control_card.dart';
import 'package:arduino_control_app/widgets/rgb_led_control_card.dart';
import 'package:arduino_control_app/widgets/voice_control_card.dart';

void main() {
  testWidgets('Arduino/Esp32 Controller splash screen & voice controller smoke test',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ArduinoBluetoothApp());
    await tester.pump();

    // 1. Verify Splash Screen is displayed first with Developer Info
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Arduino/Esp32 Controller'), findsOneWidget);
    expect(find.text('BLUETOOTH CONTROL HUB'), findsOneWidget);
    expect(find.text('Sahil Prajapati'), findsOneWidget);
    expect(find.text('sahil078078@gmail.com'), findsOneWidget);

    // 2. Advance time past the splash timer (2.8s) and finish transition
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();

    // 3. Verify main controller screen and tabs
    expect(find.text('Arduino/Esp32 Controller'), findsOneWidget);
    expect(find.text('Connect'), findsWidgets);
    expect(find.text('Controls'), findsOneWidget);
    expect(find.text('Terminal'), findsOneWidget);
    expect(find.text('Code'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // 4. Verify core cards are present on dashboard
    expect(find.byType(LedControlCard), findsOneWidget);
    expect(find.byType(RgbLedControlCard), findsOneWidget);
    expect(find.text('LED & Relay Control'), findsOneWidget);
    expect(find.text('RGB LED Module (4-Pin)'), findsOneWidget);

    // Scroll to PwmControlCard in the dashboard list
    await tester.scrollUntilVisible(
      find.byType(PwmControlCard),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(PwmControlCard), findsOneWidget);
    expect(find.text('PWM Duty Cycle'), findsOneWidget);

    // Scroll to VoiceControlCard in the dashboard list
    await tester.scrollUntilVisible(
      find.byType(VoiceControlCard),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(VoiceControlCard), findsOneWidget);
    expect(find.text('Voice Command Control'), findsOneWidget);
  });
}
