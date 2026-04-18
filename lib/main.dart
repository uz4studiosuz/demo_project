import 'package:beemor/pages/login/login_page.dart';
import 'package:beemor/theme/app_theme.dart';
import 'package:beemor/utils/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:beemor/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:beemor/providers/app_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beemor/services/supabase_config.dart';
import 'package:beemor/utils/location_data.dart';
import 'package:beemor/theme/colors.dart';
import 'package:beemor/models/user_role.dart';
import 'package:beemor/pages/surveyor/surveyor_dashboard.dart';
import 'package:beemor/pages/driver/driver_dashboard.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Hududlar va lokatsiyalarni keshdan o'qish hamda fonda yangilash
  await LocationData.initConfigs();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
        ChangeNotifierProvider(create: (context) => AppProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'Organization App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      locale: provider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('uz'), Locale('en'), Locale('ru')],
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.loadSession();
    if (mounted) {
      setState(() => _isInit = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.govNavy),
        ),
      );
    }

    final user = context.watch<AppProvider>().currentUser;
    if (user == null) {
      return const LoginPage();
    }

    if (user.role == UserRole.surveyor) {
      return const SurveyorDashboard();
    } else if (user.role == UserRole.driver) {
      return const DriverDashboard();
    }

    return const LoginPage();
  }
}
