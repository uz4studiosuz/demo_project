import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../providers/app_provider.dart';
import '../../models/user_role.dart';
import '../surveyor/surveyor_dashboard.dart';
import '../driver/driver_dashboard.dart';

class LoginViewModel extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _rememberMe = false;
  bool get rememberMe => _rememberMe;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<void> handleLogin(BuildContext context, {String? username, String? password}) async {
    final user = username ?? emailController.text;
    final pass = password ?? passwordController.text;
    
    // UI-dan berilgan bo'lsa teginmaymiz, bo'lmasa editordan olamiz
    if (username != null) {
      emailController.text = username;
    }
    if (password != null) {
      passwordController.text = password;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);

    bool success = await appProvider.login(user, pass);
    if (!context.mounted) return;

    if (success) {
      _navigateToDashboard(context, appProvider);
    } else {
      _showError(context);
    }
  }

  void _navigateToDashboard(BuildContext context, AppProvider provider) {
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
      SnackBar(
        content: const Row(
          children: [
            Icon(TablerIcons.alert_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Login yoki parol xato.'),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(24),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
