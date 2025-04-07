// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _userId = '';
  String _userEmail = 'user@example.com';
  String _userName = '사용자';
  bool _notificationsEnabled = true;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String get userId => _userId;
  String get userEmail => _userEmail;
  String get userName => _userName;
  bool get notificationsEnabled => _notificationsEnabled;

  // Methods
  Future<bool> login(String email, String password) async {
    // 로그인 로직 구현
    _isLoggedIn = true;
    _userId = 'user123';
    _userEmail = email;
    notifyListeners();
    return true;
  }

  Future<bool> signup(String email, String password, String name) async {
    // 회원가입 로직 구현
    _isLoggedIn = true;
    _userId = 'user123';
    _userEmail = email;
    _userName = name;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userId = '';
    notifyListeners();
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    return await login(email, password);
  }

  Future<bool> signUpWithEmailAndPassword(String email, String password, String name) async {
    return await signup(email, password, name);
  }

  Future<bool> signInWithGoogle() async {
    // Google 로그인 로직 구현
    _isLoggedIn = true;
    _userId = 'google_user';
    _userEmail = 'google_user@gmail.com';
    _userName = 'Google 사용자';
    notifyListeners();
    return true;
  }

  Future<bool> signInWithFacebook() async {
    // Facebook 로그인 로직 구현
    _isLoggedIn = true;
    _userId = 'facebook_user';
    _userEmail = 'facebook_user@facebook.com';
    _userName = 'Facebook 사용자';
    notifyListeners();
    return true;
  }

  // 추가 메서드
  void updateUserName(String newName) {
    _userName = newName;
    notifyListeners();
  }

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    // 계정 삭제 로직 구현
    _isLoggedIn = false;
    _userId = '';
    _userEmail = '';
    _userName = '';
    notifyListeners();
  }
}
