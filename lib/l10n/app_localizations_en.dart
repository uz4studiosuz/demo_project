// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get hello => 'Hello!';

  @override
  String get secure => 'Securely log in with your email and password.';

  @override
  String get signin => 'Sign in';

  @override
  String get email => 'Enter your mail';

  @override
  String get password => 'Enter your Password';

  @override
  String get remember => 'Remember me';

  @override
  String get forgot => 'Forgot password?';

  @override
  String get select => 'Select Language';
}
