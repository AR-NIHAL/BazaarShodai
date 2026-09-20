import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../buyer/presentation/screens/profile_screen.dart';

/// Production Settings Screen for BazaarShodai.
/// Provides:
/// - Dark Mode enable/disable toggle switch with persistent state
/// - Quick link to ProfileScreen
/// - Notification and language preferences
/// - Help Center and App Information
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final authUser = ref.watch(authStateChangesProvider).value;
    final userProfileAsync = ref.watch(currentUserProfileStreamProvider);

    final user = userProfileAsync.asData?.value;
    final displayName = user?.name.isNotEmpty == true
        ? user!.name
        : (authUser?.displayName?.isNotEmpty == true ? authUser!.displayName! : 'Valued Customer');
    final email = user?.email.isNotEmpty == true
        ? user!.email
        : (authUser?.email ?? 'Browsing as Guest');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Account Profile Quick Banner
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: isDarkMode ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? const Color(0xFF34D399) : const Color(0xFF047857),
                  ),
                ),
              ),
              title: Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: Text(
                email,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // 2. Appearance Section Header
          _buildSectionHeader('Appearance', context),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: isDarkMode,
                  onChanged: (val) {
                    ref.read(themeModeProvider.notifier).toggleDarkMode(val);
                  },
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Dark Mode',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    isDarkMode ? 'Night theme enabled' : 'Clean daytime theme enabled',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  activeTrackColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Preferences Section
          _buildSectionHeader('Preferences', context),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: _notificationsEnabled,
                  onChanged: (val) {
                    setState(() => _notificationsEnabled = val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(val ? 'Notifications enabled' : 'Notifications disabled'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Order Alerts & Offers',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Delivery updates and fresh arrival notices',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  activeTrackColor: AppColors.primary,
                ),
                Divider(
                  height: 1,
                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.language_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'App Language',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    'English (US)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bangla language support coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. About & Legal
          _buildSectionHeader('About & Support', context),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.help_outline, color: AppColors.primary, size: 22),
                  ),
                  title: const Text(
                    'Help Center & Support',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_outlined, color: Color(0xFF64748B), size: 22),
                  ),
                  title: const Text(
                    'Terms & Privacy Policy',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Version Footer
          Center(
            child: Column(
              children: [
                Text(
                  'BazaarShodai v1.0.0+1 (Production)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fresh from Local, For a Better Tomorrow',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
        letterSpacing: 0.5,
      ),
    );
  }
}
