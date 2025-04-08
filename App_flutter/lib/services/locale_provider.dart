// lib/services/locale_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = Locale('ko', '');  // 기본값: 한국어

  Locale get locale => _locale;

  // 저장된 로케일 로드
  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'ko';
    _locale = Locale(languageCode, '');
    notifyListeners();
  }

  // 로케일 변경
  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);
    _locale = Locale(languageCode, '');
    notifyListeners();
  }

  // 언어 코드를 언어 이름으로 변환
  String getLanguageName() {
    switch (_locale.languageCode) {
      case 'ko': return '한국어';
      case 'en': return 'English';
      case 'ja': return '日本語';
      case 'zh': return '中文';
      default: return '한국어';
    }
  }

  // 언어 이름을 언어 코드로 변환
  String getLanguageCode(String languageName) {
    switch (languageName) {
      case '한국어': return 'ko';
      case 'English': return 'en';
      case '日本語': return 'ja';
      case '中文': return 'zh';
      default: return 'ko';
    }
  }
}
