import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_localizations.dart';
import 'home_screen.dart';
import 'dog_encyclopedia_screen.dart';
import 'profile_screen.dart';
import '../services/locale_provider.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  // 탭에 표시할 화면들
  final List<Widget> _screens = [
    HomeScreen(),
    DogEncyclopediaScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return WillPopScope(
      onWillPop: () async => false, // 뒤로가기 방지
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.brown,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.pets),
              label: localizations.translate('dog_scan'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: localizations.translate('encyclopedia'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: localizations.translate('profile'),
            ),
          ],
        ),
      ),
    );
  }
} 