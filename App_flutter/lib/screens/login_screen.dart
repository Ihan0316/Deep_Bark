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
                trailing: localeProvider.locale.languageCode == 'ko'
                    ? Icon(Icons.check, color: Colors.brown)
                    : null,
                onTap: () {
                  localeProvider.setLocale('ko');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('English'),
                trailing: localeProvider.locale.languageCode == 'en'
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 언어 선택 버튼 추가
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.language),
                  onPressed: () => _showLanguageSelector(context),
                  tooltip: localizations.translate('language_settings'),
                ),
              ),
              // 로고
              Image.asset(
                'assets/images/logo.png',
                width: 150,
                height: 150,
              ),
              SizedBox(height: 30),
              // 이메일 입력
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: localizations.translate('email'),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 15),
              // 비밀번호 입력
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: localizations.translate('password'),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
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
              SizedBox(height: 15),
              // 회원가입 링크
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: Text(localizations.translate('no_account_signup')),
              ),
              SizedBox(height: 30),
              Text(localizations.translate('or_login_with_social')),
              SizedBox(height: 15),
              // 소셜 로그인 버튼들
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 구글 로그인
                  InkWell(
                    onTap: _googleLogin,
                    child: Image.asset(
                      'assets/images/android_light.png',
                      width: 300,
                    ),
                  ),
                  SizedBox(height: 20),
                  // 카카오 로그인
                  InkWell(
                    onTap: _kakaoLogin,
                    child: Image.asset(
                      'assets/images/kakao_login_medium_wide.png',
                      width: 300,
                    ),
                  ),
                ],
              ),
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
        SnackBar(content: Text(localizations.translate('enter_email_password'))),
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
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.translate('login_failed')}: ${e.toString()}')),
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
      if(success){
        Navigator.pushReplacementNamed(context, '/home');
      }
      else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.translate('google_login_canceled'))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.translate('google_login_failed')}: ${e.toString()}')),
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
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.translate('kakao_login_canceled'))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.translate('kakao_login_failed')}: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
