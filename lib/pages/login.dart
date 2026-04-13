import 'package:beemor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../utils/locale_provider.dart';
import '../models/user_role.dart';
import '../providers/app_provider.dart';
import '../widgets/liquid_background.dart';
import 'surveyor/surveyor_dashboard.dart';
import 'driver/driver_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showLanguageSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<LocaleProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.select,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildLanguageOption(
                'O\'zbekcha',
                const Locale('uz'),
                provider,
                context,
              ),
              _buildLanguageOption(
                'English',
                const Locale('en'),
                provider,
                context,
              ),
              _buildLanguageOption(
                'Русский',
                const Locale('ru'),
                provider,
                context,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    String title,
    Locale locale,
    LocaleProvider provider,
    BuildContext context,
  ) {
    return ListTile(
      title: Text(title),
      trailing: provider.locale == locale
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        provider.setLocale(locale);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Navy Header Background
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: const BoxDecoration(
              color: AppColors.govNavy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(60),
                bottomRight: Radius.circular(60),
              ),
            ),
          ),

          // Search Language Button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton.icon(
              onPressed: () => _showLanguageSelector(context),
              icon: const Icon(
                Icons.language_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                provider.locale.languageCode == 'en'
                    ? 'English'
                    : provider.locale.languageCode == 'uz'
                    ? 'O\'zbekcha'
                    : 'Русский',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // Emblem / Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      size: 50,
                      color: AppColors.govNavy,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'PORTALGA KIRISH',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'O\'ZBEKISTON RESPUBLIKASI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.5,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tizimga kirish',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.govNavy,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form Fields
                        _buildFormField(
                          controller: _emailController,
                          label: 'Foydalanuvchi nomi',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 20),
                        _buildFormField(
                          controller: _passwordController,
                          label: 'Parol',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                        ),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: AppColors.govNavy,
                                    onChanged: (v) =>
                                        setState(() => _rememberMe = v!),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Eslab qolish',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Parolni unutdingizmi?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.govNavy,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Login Button
                        Consumer<AppProvider>(
                          builder: (context, provider, child) {
                            return ElevatedButton(
                              onPressed: provider.isLoading
                                  ? null
                                  : () async {
                                      bool success = await provider.login(
                                        _emailController.text,
                                        _passwordController.text,
                                      );

                                      if (!context.mounted) return;

                                      if (success) {
                                        _navigateToDashboard(provider);
                                      } else {
                                        _showError(context);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.govNavy,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: provider.isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'KIRISH',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  // Footer
                  const Opacity(
                    opacity: 0.5,
                    child: Text(
                      'Monitoring va Hatlov Tizimi\n© 2026 O\'zbekiston Respublikasi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: AppColors.govNavy),
            fillColor: Colors.grey.shade50,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.govNavy,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToDashboard(AppProvider provider) {
    Widget next;
    if (provider.currentUserRole == UserRole.surveyor) {
      next = const SurveyorDashboard();
    } else {
      next = const DriverDashboard();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => next),
    );
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login yoki parol xato.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
