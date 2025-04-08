// lib/screens/language_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_provider.dart';
import '../services/app_localizations.dart';

class LanguageSettingsScreen extends StatelessWidget {
  final Map<String, String> _languageCodes = {
    '한국어': 'ko',
    'English': 'en',
    '日本語': 'ja',
    '中文': 'zh',
  };

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('language_settings')),
        backgroundColor: Colors.brown,
      ),
      body: ListView.builder(
        itemCount: _languageCodes.length,
        itemBuilder: (context, index) {
          final languageName = _languageCodes.keys.elementAt(index);
          final languageCode = _languageCodes[languageName];

          return ListTile(
            title: Text(languageName),
            trailing: localeProvider.locale.languageCode == languageCode
                ? Icon(Icons.check, color: Colors.brown)
                : null,
            onTap: () {
              localeProvider.setLocale(languageCode!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('언어가 $languageName(으)로 변경되었습니다.')),
              );
            },
          );
        },
      ),
    );
  }
}
