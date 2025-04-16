// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as KakaoSDK;
import '../models/user.dart' as MyAppUser;
import 'api_service.dart';
import 'dart:io';
import 'dart:async';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _userId = '0';  // String 타입으로 통일
  String _userEmail = 'user@example.com';
  String _userName = '사용자';
  bool _notificationsEnabled = true;
  String _profileImageUrl = '';
  String _loginProvider = ''; // 로그인 제공자 추적 (google, kakao, email)
  MyAppUser.User? _currentUser;

  final ApiService _apiService = ApiService();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Google Sign In 인스턴스
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  // Debounce timers
  Timer? _usernameDebounceTimer;
  Timer? _emailDebounceTimer;

  // Debounce duration in milliseconds
  static const int _debounceDuration = 500;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String get userId => _userId;
  String get userEmail => _userEmail;
  String get userName => _userName;
  bool get notificationsEnabled => _notificationsEnabled;
  String get profileImageUrl => _profileImageUrl;
  String get loginProvider => _loginProvider;

  // 헬퍼 메서드 수정
  bool _isGoogleUser() {
    return _loginProvider == 'google';
  }

  bool _isKakaoUser() {
    return _loginProvider == 'kakao';
  }

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
      _userId = prefs.getString('userId') ?? '0';
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
    try {
      // API를 통해 로그인 검증
      final loginResult = await _apiService.loginUser(email, password);
      
      if (loginResult != null && loginResult['token'] != null) {
        // 로그인 성공 시 사용자 정보 저장
        _isLoggedIn = true;
        _currentUser = MyAppUser.User.fromJson(loginResult['user']);
        _userId = _currentUser!.id.toString();  // int를 String으로 변환
        _userEmail = email;
        _userName = _currentUser!.username;
        _loginProvider = 'email';
        
        // 토큰 저장
        await _saveToken(loginResult['token']);
        // 사용자 정보 저장
        await _saveUserData(_currentUser!.toJson());
        await _saveUserToLocal();
        
        notifyListeners();
        return true;
      }
      print('로그인 실패: 유효하지 않은 응답');
      return false;
    } catch (e) {
      print('로그인 API 오류: $e');
      _isLoggedIn = false;
      _userId = '0';
      _userEmail = '';
      _userName = '';
      _loginProvider = '';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String email, String password, String username) async {
    try {
      // API를 통해 회원가입 요청
      final result = await _apiService.registerUser(email, password, username, username);  // username을 name으로도 사용
      
      if (result['success'] == true) {
        // 회원가입 성공 시 자동 로그인하지 않고 true 반환
        return true;
      }
      return false;
    } catch (e) {
      print('회원가입 오류: $e');
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      // 소셜 로그인 상태 확인 및 로그아웃
      if (isGoogleLogin()) {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
        }
      } else if (isKakaoLogin()) {
        try {
          await KakaoSDK.UserApi.instance.logout();
        } catch (e) {
          print('카카오 로그아웃 오류: $e');
        }
      }

      // 사용자 정보 초기화
      _isLoggedIn = false;
      _userId = '0';
      _userEmail = 'user@example.com';
      _userName = '사용자';
      _profileImageUrl = '';
      _loginProvider = '';

      // 로컬 저장소에서 사용자 정보 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      notifyListeners();
      print('로그아웃 완료');
      return true;
    } catch (e) {
      print('로그아웃 오류: $e');
      return false;
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _apiService.loginUser(email, password);
      
      if (result?['success'] == true) {
        _isLoggedIn = true;
        _currentUser = MyAppUser.User.fromJson(result!['user']);
        _userId = _currentUser!.id.toString();  // int를 String으로 변환
        _userEmail = _currentUser!.email;
        _userName = _currentUser!.username;
        _loginProvider = 'email';
        
        await _saveToken(result['token']);
        await _saveUserData(_currentUser!.toJson());
        await _saveUserToLocal();
        
        notifyListeners();
        return true;
      } else {
        throw Exception(result?['message'] ?? '로그인에 실패했습니다.');
      }
    } catch (e) {
      print('로그인 오류: $e');
      rethrow;
    }
  }

  Future<bool> signUpWithEmailAndPassword(String email, String password, String username, String name) async {
    try {
      print('회원가입 요청 데이터: {"email": "$email", "password": "$password", "username": "$username", "name": "$name"}');
      final result = await _apiService.registerUser(email, password, username, name);
      
      print('회원가입 응답: $result');
      
      if (result['success'] == true) {
        _isLoggedIn = true;
        _userId = result['user']['id'].toString();  // int를 String으로 변환
        _userEmail = email;
        _userName = username;
        await _saveUserData({
          'id': _userId,
          'email': email,
          'username': username,
          'name': name,
          'isLoggedIn': true
        });
        notifyListeners();
        return true;
      } else {
        final errorMessage = result['message'] ?? '회원가입에 실패했습니다.';
        print('회원가입 실패: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('회원가입 오류: $e');
      rethrow;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      print('구글 로그인 시작');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('사용자가 구글 로그인을 취소함');
        return false;
      }

      print('구글 사용자 정보: ${googleUser.displayName}, ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      _isLoggedIn = true;
      _currentUser = MyAppUser.User(
        id: googleUser.id,
        email: googleUser.email,
        username: googleUser.displayName ?? 'Google 사용자',
        profileImageUrl: googleUser.photoUrl ?? '',
        loginProvider: 'google'
      );
      _userId = _currentUser!.id.toString();
      _userEmail = googleUser.email;
      _userName = googleUser.displayName ?? 'Google 사용자';
      _profileImageUrl = googleUser.photoUrl ?? '';
      _loginProvider = 'google';

      print('저장된 사용자 정보: $_userName, $_userEmail, $_userId, $_loginProvider');

      await _saveUserToLocal();
      await _fetchAdditionalUserInfo(googleAuth.accessToken);

      notifyListeners();
      return true;
    } catch (error) {
      print('Google Sign In Error: $error');
      return false;
    }
  }

  Future<bool> signInWithKakao() async {
    try {
      bool isInstalled = await KakaoSDK.isKakaoTalkInstalled();

      KakaoSDK.OAuthToken token;
      if (isInstalled) {
        token = await KakaoSDK.UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await KakaoSDK.UserApi.instance.loginWithKakaoAccount();
      }

      KakaoSDK.User user = await KakaoSDK.UserApi.instance.me();

      _isLoggedIn = true;
      _currentUser = MyAppUser.User(
        id: user.id.toString(),
        email: user.kakaoAccount?.email ?? 'kakao_user@example.com',
        username: user.kakaoAccount?.profile?.nickname ?? '카카오 사용자',
        profileImageUrl: user.kakaoAccount?.profile?.profileImageUrl ?? '',
        loginProvider: 'kakao'
      );
      _userId = _currentUser!.id.toString();
      _userEmail = user.kakaoAccount?.email ?? 'kakao_user@example.com';
      _userName = user.kakaoAccount?.profile?.nickname ?? '카카오 사용자';
      _profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl ?? '';
      _loginProvider = 'kakao';

      await _saveUserToLocal();

      notifyListeners();
      return true;
    } catch (e) {
      print('Kakao Sign In Error: $e');
      return false;
    }
  }

  Future<bool> signInWithKakaoAccount() async {
    try {
      // 카카오계정으로 로그인
      KakaoSDK.OAuthToken token = await KakaoSDK.UserApi.instance.loginWithKakaoAccount();

      // 사용자 정보 가져오기
      KakaoSDK.User user = await KakaoSDK.UserApi.instance.me();

      // 사용자 정보 저장
      _isLoggedIn = true;
      _currentUser = MyAppUser.User(
        id: 'kakao_${user.id}',
        email: user.kakaoAccount?.email ?? 'kakao_user@example.com',
        username: user.kakaoAccount?.profile?.nickname ?? '카카오 사용자',
        profileImageUrl: user.kakaoAccount?.profile?.profileImageUrl ?? '',
        loginProvider: 'kakao'
      );
      _userId = _currentUser!.id;
      _userEmail = user.kakaoAccount?.email ?? 'kakao_user@example.com';
      _userName = user.kakaoAccount?.profile?.nickname ?? '카카오 사용자';
      _profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl ?? '';
      _loginProvider = 'kakao';

      // 로컬에 사용자 정보 저장
      await _saveUserToLocal();

      notifyListeners();
      return true;
    } catch (e) {
      print('Kakao Account Sign In Error: $e');
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

  // 추가 메서드
  Future<bool> updateUserName(String newName) async {
    try {
      if (_userId == '0') {
        print('사용자 ID가 없습니다.');
        return false;
      }

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/api/users/$_userId/name'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': newName}),
      );

      if (response.statusCode == 200) {
        _userName = newName;
        await _saveUserToLocal();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('이름 변경 실패: $e');
      return false;
    }
  }

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  Future<bool> deleteAccount() async {
    try {
      if (isGoogleLogin()) {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.disconnect();
        }
      } else if (isKakaoLogin()) {
        try {
          await KakaoSDK.UserApi.instance.unlink();
        } catch (e) {
          print('카카오 계정 연결 해제 오류: $e');
        }
      }

      _isLoggedIn = false;
      _userId = '0';
      _userEmail = '';
      _userName = '';
      _profileImageUrl = '';
      _loginProvider = '';

      // 로컬 저장소에서 사용자 정보 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      notifyListeners();
      print('계정 삭제 완료');
      return true;
    } catch (e) {
      print('계정 삭제 오류: $e');
      return false;
    }
  }

  // 현재 로그인 상태 확인
  Future<void> checkCurrentUser() async {
    try {
      await _loadUserFromLocal();

      if (_isLoggedIn) {
        print('로컬에 저장된 로그인 정보 발견: $_userName, $_userEmail, $_loginProvider');

        if (_isGoogleUser()) {
          final isSignedIn = await _googleSignIn.isSignedIn();
          if (isSignedIn) {
            final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
            if (account != null) {
              _currentUser = MyAppUser.User(
                id: account.id,
                email: account.email,
                username: account.displayName ?? 'Google 사용자',
                profileImageUrl: account.photoUrl ?? '',
                loginProvider: 'google'
              );
              _userId = _currentUser!.id.toString();
              _userEmail = account.email;
              _userName = account.displayName ?? 'Google 사용자';
              _profileImageUrl = account.photoUrl ?? '';

              print('구글 자동 로그인 성공: $_userName, $_userEmail');
              await _saveUserToLocal();
              notifyListeners();
            }
          } else {
            print('구글 로그인 상태가 아님, 로컬 정보 초기화');
            await logout();
          }
        } else if (_isKakaoUser()) {
          try {
            final user = await KakaoSDK.UserApi.instance.me();
            if (user != null) {
              _currentUser = MyAppUser.User(
                id: user.id.toString(),
                email: user.kakaoAccount?.email ?? 'kakao_user@example.com',
                username: user.kakaoAccount?.profile?.nickname ?? '카카오 사용자',
                profileImageUrl: user.kakaoAccount?.profile?.profileImageUrl ?? '',
                loginProvider: 'kakao'
              );
              _userId = _currentUser!.id.toString();
              _userEmail = user.kakaoAccount?.email ?? 'kakao_user@example.com';
              _userName = user.kakaoAccount?.profile?.nickname ?? '카카오 사용자';
              _profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl ?? '';

              print('카카오 자동 로그인 성공: $_userName, $_userEmail');
              await _saveUserToLocal();
              notifyListeners();
            }
          } catch (e) {
            print('카카오 로그인 상태가 아님, 로컬 정보 초기화');
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

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(userData));
  }

  // 프로필 이미지 업로드 메서드 추가
  Future<bool> uploadProfileImage(File imageFile) async {
    try {
      if (_userId == '0') {
        print('사용자 ID가 없습니다.');
        return false;
      }

      var uri = Uri.parse('${ApiService.baseUrl}/api/users/$_userId/profile-image');
      var request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer ${await _getToken()}'
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      var response = await request.send();
      
      if (response.statusCode == 200) {
        _profileImageUrl = await response.stream.bytesToString();
        await _saveUserToLocal();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('프로필 이미지 업로드 실패: $e');
      return false;
    }
  }

  // 토큰 가져오기 메서드 추가
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // 로그인 타입 체크 메서드 개선
  bool isGoogleLogin() => _loginProvider == 'google';
  bool isKakaoLogin() => _loginProvider == 'kakao';
  bool isEmailLogin() => _loginProvider == 'email';

  Future<bool> checkUsernameAvailability(String username) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/users/check-username?username=$username'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return responseData['available'] ?? false;
      } else {
        throw Exception('사용자 이름 확인 중 오류가 발생했습니다.');
      }
    } catch (e) {
      print('사용자 이름 확인 오류: $e');
      throw e;
    }
  }

  Future<bool> checkEmailAvailability(String email) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/users/check-email?email=$email'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return responseData['available'] ?? false;
      } else {
        throw Exception('이메일 확인 중 오류가 발생했습니다.');
      }
    } catch (e) {
      print('이메일 확인 오류: $e');
      throw e;
    }
  }

  // Debounced username check
  void debouncedCheckUsername(String username, Function(bool) onResult) {
    _usernameDebounceTimer?.cancel();
    _usernameDebounceTimer = Timer(Duration(milliseconds: _debounceDuration), () async {
      if (username.isEmpty) {
        onResult(false);
        return;
      }
      try {
        final result = await checkUsernameAvailability(username);
        onResult(result);
      } catch (e) {
        onResult(false);
      }
    });
  }

  // Debounced email check
  void debouncedCheckEmail(String email, Function(bool) onResult) {
    _emailDebounceTimer?.cancel();
    _emailDebounceTimer = Timer(Duration(milliseconds: _debounceDuration), () async {
      if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        onResult(false);
        return;
      }
      try {
        final result = await checkEmailAvailability(email);
        onResult(result);
      } catch (e) {
        onResult(false);
      }
    });
  }

  @override
  void dispose() {
    _usernameDebounceTimer?.cancel();
    _emailDebounceTimer?.cancel();
    super.dispose();
  }
}
