// lib/main.dart
import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart'; // 주석 처리

// 화면 import
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scan_result_screen.dart';
import 'screens/dog_encyclopedia_screen.dart';
import 'screens/breed_detail_screen.dart';
import 'screens/profile_screen.dart';

// 서비스 import
import 'services/auth_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase 초기화 코드 주석 처리
  // try {
  //   await Firebase.initializeApp();
  // } catch (e) {
  //   print('Firebase 초기화 오류: $e');
  // }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: '멍멍스캔',
        theme: ThemeData(
          primarySwatch: Colors.brown,
          fontFamily: 'NotoSansKR',
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.brown,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/', // 초기 화면을 스플래시 화면으로 변경
        routes: {
          '/': (context) => SplashScreen(), // 루트 경로를 SplashScreen으로 설정
          '/login': (context) => LoginScreen(),
          '/signup': (context) => SignupScreen(),
          '/home': (context) => HomeScreen(),
          '/result': (context) => ScanResultScreen(),
          '/encyclopedia': (context) => DogEncyclopediaScreen(),
          '/breed_detail': (context) => BreedDetailScreen(),
          '/profile': (context) => ProfileScreen(),
        },
      ),
    );
  }
}
