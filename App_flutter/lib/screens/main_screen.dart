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

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // 탭에 표시할 화면들
  final List<Widget> _screens = [
    HomeScreen(),
    DogEncyclopediaScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return WillPopScope(
      onWillPop: () async => false, // 뒤로가기 방지
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: _screens,
          physics: BouncingScrollPhysics(), // 수동 스와이프 활성화 및 바운스 효과 추가
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.brown,
          onTap: _onItemTapped,
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