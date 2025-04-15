// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import '../services/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/locale_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 앱 해시 출력
    getAppHash();
  }

  // 앱 해시 확인 메서드
  Future<void> getAppHash() async {
    try {
      final String keyHash = await KakaoSdk.origin;
      print('카카오 앱 해시: $keyHash');
    } catch (e) {
      print('앱 해시 확인 실패: $e');
    }
  }

  // 언어 선택 다이얼로그 표시
  void _showLanguageSelector(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations.translate('language_settings')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('한국어'),
                trailing:
                    localeProvider.locale.languageCode == 'ko'
                        ? Icon(Icons.check, color: Colors.brown)
                        : null,
                onTap: () {
                  localeProvider.setLocale('ko');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('English'),
                trailing:
                    localeProvider.locale.languageCode == 'en'
                        ? Icon(Icons.check, color: Colors.brown)
                        : null,
                onTap: () {
                  localeProvider.setLocale('en');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.language, color: Colors.brown),
            onPressed: () => _showLanguageSelector(context),
            tooltip: localizations.translate('language_settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // 로고
              Image.asset(
                'assets/images/logo.png', 
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.width * 0.4,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              // 이메일 입력
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: localizations.translate('email'),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              // 비밀번호 입력
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: localizations.translate('password'),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                ),
                obscureText: true,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              // 로그인 버튼
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: Text(localizations.translate('login')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              // 회원가입 링크
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: Text(localizations.translate('no_account_signup')),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Text(localizations.translate('or_login_with_social')),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              // 소셜 로그인 버튼들
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 구글 로그인
                  InkWell(
                    onTap: _googleLogin,
                    child: Image.asset(
                      'assets/images/android_light.png',
                      width: MediaQuery.of(context).size.width * 0.8, // 화면 너비의 80%로 조정
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  // 카카오 로그인
                  InkWell(
                    onTap: _kakaoLogin,
                    child: Provider.of<LocaleProvider>(context).locale.languageCode == 'ko'
                        ? Image.asset(
                            'assets/images/kakao_login_medium_ko.png',
                            width: MediaQuery.of(context).size.width * 0.8, // 화면 너비의 80%로 조정
                          )
                        : Image.asset(
                            'assets/images/kakao_login_medium_en.png',
                            width: MediaQuery.of(context).size.width * 0.8, // 화면 너비의 80%로 조정
                          ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.05), // 하단 여백 추가
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final localizations = AppLocalizations.of(context);

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translate('enter_email_password')),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${localizations.translate('login_failed')}: ${e.toString()}',
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _googleLogin() async {
    final localizations = AppLocalizations.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await _authService.signInWithGoogle();
      if (success) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('google_login_canceled')),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${localizations.translate('google_login_failed')}: ${e.toString()}',
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _kakaoLogin() async {
    final localizations = AppLocalizations.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await _authService.signInWithKakao();

      if (success) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('kakao_login_canceled')),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${localizations.translate('kakao_login_failed')}: ${e.toString()}',
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
