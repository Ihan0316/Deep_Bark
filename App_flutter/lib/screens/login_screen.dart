// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import '../services/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/locale_provider.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _emailError;
  String? _passwordError;

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
              if (_emailError != null)
                Container(
                  padding: EdgeInsets.all(8),
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email, color: Colors.orange[800]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _emailError!,
                          style: TextStyle(color: Colors.orange[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_passwordError != null)
                Container(
                  padding: EdgeInsets.all(8),
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: Colors.red[800]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _passwordError!,
                          style: TextStyle(color: Colors.red[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null && _emailError == null && _passwordError == null)
                Container(
                  padding: EdgeInsets.all(8),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[800]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              // 이메일 입력
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: localizations.translate('email'),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                  errorText: _emailError,
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
                  errorText: _passwordError,
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
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Text('비밀번호를 잊으셨나요?'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final localizations = AppLocalizations.of(context);

    setState(() {
      _errorMessage = null;
      _emailError = null;
      _passwordError = null;
    });

    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = localizations.translate('email_required');
      });
    }
    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = localizations.translate('password_required');
      });
    }
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
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
      String errorMessage = e.toString();
      
      // 서버에서 반환한 에러 메시지 파싱
      if (errorMessage.contains('"email":')) {
        setState(() {
          _emailError = errorMessage.split('"email":')[1].split('"')[1];
          _passwordError = null;
          _errorMessage = null;
        });
      } else if (errorMessage.contains('"password":')) {
        setState(() {
          _passwordError = errorMessage.split('"password":')[1].split('"')[1];
          _emailError = null;
          _errorMessage = null;
        });
      } else if (errorMessage.contains('"error":')) {
        setState(() {
          _errorMessage = errorMessage.split('"error":')[1].split('"')[1];
          _emailError = null;
          _passwordError = null;
        });
      } else {
        setState(() {
          _errorMessage = localizations.translate('login_failed');
          _emailError = null;
          _passwordError = null;
        });
      }
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
      _errorMessage = null;
    });

    try {
      bool success = await _authService.signInWithGoogle();
      if (success) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        setState(() {
          _errorMessage = localizations.translate('google_login_canceled');
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${localizations.translate('google_login_failed')}: ${e.toString()}';
      });
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
      _errorMessage = null;
    });

    try {
      bool success = await _authService.signInWithKakao();

      if (success) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        setState(() {
          _errorMessage = localizations.translate('kakao_login_canceled');
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${localizations.translate('kakao_login_failed')}: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
