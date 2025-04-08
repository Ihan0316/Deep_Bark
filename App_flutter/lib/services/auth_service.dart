// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _userId = '';
  String _userEmail = 'user@example.com';
  String _userName = '사용자';
  bool _notificationsEnabled = true;
  String _profileImageUrl = '';
  String _loginProvider = ''; // 로그인 제공자 추적 (google, facebook, email)

  // Google Sign In 인스턴스
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String get userId => _userId;
  String get userEmail => _userEmail;
  String get userName => _userName;
  bool get notificationsEnabled => _notificationsEnabled;
  String get profileImageUrl => _profileImageUrl;
  String get loginProvider => _loginProvider;

  // 로컬 스토리지에 사용자 정보 저장
  Future<void> _saveUserToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', _isLoggedIn);
      await prefs.setString('userId', _userId);
      await prefs.setString('userEmail', _userEmail);
      await prefs.setString('userName', _userName);
      await prefs.setString('profileImageUrl', _profileImageUrl);
      await prefs.setString('loginProvider', _loginProvider);

      print('사용자 정보 로컬 저장 완료: $_userName, $_userEmail, $_loginProvider');
    } catch (e) {
      print('사용자 정보 저장 오류: $e');
    }
  }

  // 로컬 스토리지에서 사용자 정보 로드
  Future<void> _loadUserFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _userId = prefs.getString('userId') ?? '';
      _userEmail = prefs.getString('userEmail') ?? 'user@example.com';
      _userName = prefs.getString('userName') ?? '사용자';
      _profileImageUrl = prefs.getString('profileImageUrl') ?? '';
      _loginProvider = prefs.getString('loginProvider') ?? '';

      print('사용자 정보 로컬 로드 완료: $_userName, $_userEmail, $_loginProvider');
      notifyListeners();
    } catch (e) {
      print('사용자 정보 로드 오류: $e');
    }
  }

  // Methods
  Future<bool> login(String email, String password) async {
    // 로그인 로직 구현
    _isLoggedIn = true;
    _userId = 'email_user_${DateTime.now().millisecondsSinceEpoch}';
    _userEmail = email;
    _loginProvider = 'email';

    await _saveUserToLocal();
    notifyListeners();
    return true;
  }

  Future<bool> signup(String email, String password, String name) async {
    // 회원가입 로직 구현
    _isLoggedIn = true;
    _userId = 'email_user_${DateTime.now().millisecondsSinceEpoch}';
    _userEmail = email;
    _userName = name;
    _loginProvider = 'email';

    await _saveUserToLocal();
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    try {
      // 소셜 로그인 상태 확인 및 로그아웃
      if (_loginProvider == 'google') {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
        }
      }

      // 사용자 정보 초기화
      _isLoggedIn = false;
      _userId = '';
      _userEmail = 'user@example.com';
      _userName = '사용자';
      _profileImageUrl = '';
      _loginProvider = '';

      // 로컬 저장소에서 사용자 정보 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      notifyListeners();
      print('로그아웃 완료');
    } catch (e) {
      print('로그아웃 오류: $e');
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    return await login(email, password);
  }

  Future<bool> signUpWithEmailAndPassword(String email, String password, String name) async {
    return await signup(email, password, name);
  }

  Future<bool> signInWithGoogle() async {
    try {
      print('구글 로그인 시작');
      // 구글 로그인 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // 사용자가 로그인을 취소한 경우
      if (googleUser == null) {
        print('사용자가 구글 로그인을 취소함');
        return false;
      }

      print('구글 사용자 정보: ${googleUser.displayName}, ${googleUser.email}');

      // 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 사용자 정보 저장
      _isLoggedIn = true;
      _userId = 'google_${googleUser.id}';  // 구글 사용자임을 명확히 표시
      _userEmail = googleUser.email;
      _userName = googleUser.displayName ?? 'Google 사용자';
      _profileImageUrl = googleUser.photoUrl ?? '';
      _loginProvider = 'google';

      print('저장된 사용자 정보: $_userName, $_userEmail, $_userId, $_loginProvider');

      // 로컬에 사용자 정보 저장
      await _saveUserToLocal();

      // 추가 사용자 정보를 가져오기 위한 API 호출 (선택 사항)
      await _fetchAdditionalUserInfo(googleAuth.accessToken);

      notifyListeners();
      return true;
    } catch (error) {
      print('Google Sign In Error: $error');
      return false;
    }
  }

  // 추가 사용자 정보를 가져오는 메서드 (선택 사항)
  Future<void> _fetchAdditionalUserInfo(String? accessToken) async {
    if (accessToken == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        // 추가 정보 처리
        print('추가 사용자 정보: $userData');

        // 추가 정보가 있으면 업데이트
        if (userData['name'] != null && _userName.isEmpty) {
          _userName = userData['name'];
        }

        if (userData['picture'] != null && _profileImageUrl.isEmpty) {
          _profileImageUrl = userData['picture'];
        }

        await _saveUserToLocal();
        notifyListeners();
      }
    } catch (e) {
      print('추가 정보 가져오기 실패: $e');
    }
  }

  Future<bool> signInWithFacebook() async {
    // Facebook 로그인 로직 구현
    _isLoggedIn = true;
    _userId = 'facebook_user_${DateTime.now().millisecondsSinceEpoch}';
    _userEmail = 'facebook_user@facebook.com';
    _userName = 'Facebook 사용자';
    _loginProvider = 'facebook';

    await _saveUserToLocal();
    notifyListeners();
    return true;
  }

  // 추가 메서드
  void updateUserName(String newName) {
    _userName = newName;
    _saveUserToLocal();
    notifyListeners();
  }

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    // 계정 삭제 로직 구현
    try {
      if (_loginProvider == 'google') {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.disconnect(); // 구글 계정 연결 해제
        }
      }

      _isLoggedIn = false;
      _userId = '';
      _userEmail = '';
      _userName = '';
      _profileImageUrl = '';
      _loginProvider = '';

      // 로컬 저장소에서 사용자 정보 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      notifyListeners();
      print('계정 삭제 완료');
    } catch (e) {
      print('계정 삭제 오류: $e');
    }
  }

  // 현재 로그인 상태 확인
  Future<void> checkCurrentUser() async {
    try {
      // 먼저 로컬 스토리지에서 사용자 정보 로드
      await _loadUserFromLocal();

      // 이미 로그인된 상태라면 소셜 로그인 확인
      if (_isLoggedIn) {
        print('로컬에 저장된 로그인 정보 발견: $_userName, $_userEmail, $_loginProvider');

        // 구글 로그인 상태 확인
        if (_loginProvider == 'google') {
          final isSignedIn = await _googleSignIn.isSignedIn();
          if (isSignedIn) {
            final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
            if (account != null) {
              _userId = 'google_${account.id}';
              _userEmail = account.email;
              _userName = account.displayName ?? 'Google 사용자';
              _profileImageUrl = account.photoUrl ?? '';

              print('구글 자동 로그인 성공: $_userName, $_userEmail');
              await _saveUserToLocal();
              notifyListeners();
            }
          } else {
            // 구글 로그인 상태가 아니면 로컬 정보 초기화
            print('구글 로그인 상태가 아님, 로컬 정보 초기화');
            await logout();
          }
        }
      } else {
        print('로그인된 사용자 없음');
      }
    } catch (e) {
      print('자동 로그인 확인 오류: $e');
    }
  }
}
