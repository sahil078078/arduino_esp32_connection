import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'arduino_code_screen.dart';
import 'bluetooth_connect_screen.dart';
import 'controller_dashboard_screen.dart';
import 'settings_screen.dart';
import 'terminal_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Default to Controls dashboard tab!

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    final List<Widget> screens = [
      BluetoothConnectScreen(onOpenCodeScreen: () => _navigateToTab(3)),
      ControllerDashboardScreen(onOpenConnect: () => _navigateToTab(0)),
      const TerminalScreen(),
      const ArduinoCodeScreen(),
      const SettingsScreen(),
    ];

    final navItems = [
      _NavDescriptor(
        label: 'Connect',
        icon: Icons.sensors_outlined,
        activeIcon: Icons.sensors_rounded,
      ),
      _NavDescriptor(
        label: 'Controls',
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
      ),
      _NavDescriptor(
        label: 'Terminal',
        icon: Icons.terminal_outlined,
        activeIcon: Icons.terminal_rounded,
      ),
      _NavDescriptor(
        label: 'Code',
        icon: Icons.code_outlined,
        activeIcon: Icons.code_rounded,
      ),
      _NavDescriptor(
        label: 'Settings',
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
      ),
    ];

    if (isWideScreen) {
      // Desktop / Web Wide Layout
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 220,
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(
                  right: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 22,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.lightOrange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.bluetooth_audio_rounded,
                            color: AppColors.primaryOrange,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Arduino BT',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Hardware Control',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.secondaryText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      itemCount: navItems.length,
                      itemBuilder: (context, index) {
                        final item = navItems[index];
                        final isSelected = _currentIndex == index;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: InkWell(
                            onTap: () => _navigateToTab(index),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.lightOrange
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? item.activeIcon : item.icon,
                                    size: 20,
                                    color: isSelected
                                        ? AppColors.primaryOrange
                                        : AppColors.secondaryText,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.primaryOrange
                                          : AppColors.primaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: screens),
            ),
          ],
        ),
      );
    }

    // Mobile Layout: Clean Bottom Navigation Bar
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _navigateToTab,
          backgroundColor: AppColors.cardBackground,
          selectedItemColor: AppColors.primaryOrange,
          unselectedItemColor: AppColors.secondaryText,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: navItems.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.activeIcon),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavDescriptor {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  _NavDescriptor({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
