// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isCheckingAuth = false;

  @override
  void initState() {
    super.initState();
    // 중복 호출 방지를 위한 플래그 사용
    if (!_isCheckingAuth) {
      _checkLoginStatus();
    }
  }

  Future<void> _checkLoginStatus() async {
    _isCheckingAuth = true;

    // 스플래시 화면 표시 시간
    await Future.delayed(Duration(seconds: 2));

    // 컨텍스트가 유효한지 확인
    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }

    _isCheckingAuth = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
