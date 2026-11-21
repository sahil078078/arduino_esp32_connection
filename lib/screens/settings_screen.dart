import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../services/url_launch.dart';
import '../theme/app_colors.dart';
import 'developer_info_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static final UrlLaunch _launcher = UrlLaunch();

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothProvider>(
      builder: (context, bt, child) {
        return Scaffold(
          backgroundColor: AppColors.appBackground,
          appBar: AppBar(
            backgroundColor: AppColors.cardBackground,
            elevation: 0,
            scrolledUnderElevation: 1,
            surfaceTintColor: Colors.transparent,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(color: AppColors.border, height: 1),
            ),
            title: const Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
                letterSpacing: -0.3,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // 1. Developer Profile Spotlight Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.lightOrange,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryOrange,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sahil Prajapati',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'App Developer & Creator',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'sahil078078@gmail.com',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 12),

                    // Open Developer Info Screen Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DeveloperInfoScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.badge_outlined, size: 18),
                        label: const Text(
                          'View Full Developer Profile',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Developer Online Handles (Quick Links)
              const Text(
                'Developer Links',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.layers_rounded,
                      iconColor: const Color(0xFFF48024),
                      title: 'Stack Overflow Profile',
                      subtitle: 'sahil-prajapati',
                      onTap: () => _launcher.urlLaunch(
                        url: 'https://stackoverflow.com/users/sahil-prajapati',
                        context: context,
                      ),
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildSettingsTile(
                      icon: Icons.code_rounded,
                      iconColor: const Color(0xFF24292E),
                      title: 'GitHub Repositories',
                      subtitle: 'github.com/sahil078078',
                      onTap: () => _launcher.urlLaunch(
                        url: 'https://github.com/sahil078078',
                        context: context,
                      ),
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildSettingsTile(
                      icon: Icons.question_answer_rounded,
                      iconColor: const Color(0xFFB92B27),
                      title: 'Quora Answers',
                      subtitle: 'quora.com/profile/Sahil-Prajapati-19',
                      onTap: () => _launcher.urlLaunch(
                        url: 'https://www.quora.com/profile/Sahil-Prajapati-19',
                        context: context,
                      ),
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildSettingsTile(
                      icon: Icons.email_rounded,
                      iconColor: AppColors.primaryOrange,
                      title: 'Developer Email',
                      subtitle: 'sahil078078@gmail.com',
                      onTap: () => _launcher.mail(
                        email: 'sahil078078@gmail.com',
                        context: context,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Application Preferences
              const Text(
                'Terminal & Console',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Terminal Auto-Scroll',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                      subtitle: const Text(
                        'Automatically scroll to newest messages',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      value: bt.autoScroll,
                      thumbColor: WidgetStateProperty.resolveWith(
                        (states) => Colors.white,
                      ),
                      trackColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? AppColors.primaryOrange
                            : const Color(0xFFE5E7EB),
                      ),
                      trackOutlineColor: WidgetStateProperty.resolveWith(
                        (states) => Colors.transparent,
                      ),
                      onChanged: (_) => bt.toggleAutoScroll(),
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_sweep_outlined,
                        color: AppColors.primaryOrange,
                      ),
                      title: const Text(
                        'Clear Terminal Logs',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                      subtitle: Text(
                        '${bt.messages.length} messages currently buffered',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      onTap: () => bt.clearLogs(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. System & Build Info
              const Text(
                'About Application',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: const Column(
                  children: [
                    _InfoRow(label: 'App Name', value: 'Arduino/Esp32 Controller'),
                    SizedBox(height: 8),
                    _InfoRow(
                      label: 'Package ID',
                      value: 'app.arduino.esp32.controller.com',
                    ),
                    SizedBox(height: 8),
                    _InfoRow(label: 'Version', value: '1.0.0 (Release)'),
                    SizedBox(height: 8),
                    _InfoRow(label: 'Protocol', value: 'Bluetooth SPP (RFCOMM)'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 13,
        color: AppColors.secondaryText,
      ),
      onTap: onTap,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondaryText,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }
}
