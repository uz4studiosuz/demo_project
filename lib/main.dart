import 'package:beemor/pages/login.dart';
import 'package:beemor/theme/app_theme.dart';
import 'package:beemor/utils/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:beemor/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:beemor/providers/app_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beemor/services/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

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
      home: const LoginPage(),
    );
  }
}
