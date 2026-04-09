// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get hello => 'Привет!';

  @override
  String get secure => 'Безопасный вход с помощью вашей почты и пароля.';

  @override
  String get signin => 'Войти';

  @override
  String get email => 'Введите почту';

  @override
  String get password => 'Введите пароль';

  @override
  String get remember => 'Запомнить меня';

  @override
  String get forgot => 'Забыли пароль?';

  @override
  String get select => 'Выберите язык';
}
