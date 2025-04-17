import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Android 에뮬레이터에서 로컬호스트 접근용
  static const String baseUrl = 'http://10.0.2.2:8080';
  // 실제 기기나 iOS 시뮬레이터에서는 아래 주소 사용
  // static const String baseUrl = 'http://10.100.201.41:8080';

  Future<Map<String, dynamic>> registerUser(String email, String password, String username, String name) async {
    try {
      print('회원가입 API 요청 시작');
      final url = Uri.parse('$baseUrl/api/auth/register');
      print('요청 URL: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'username': username,
          'name': name
        }),
      );

      print('회원가입 응답 상태 코드: ${response.statusCode}');
      print('회원가입 응답 헤더: ${response.headers}');
      print('회원가입 응답 내용: ${response.body}');

      final responseBody = utf8.decode(response.bodyBytes);
      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['error'] ?? '회원가입에 실패했습니다.');
      }
    } catch (e) {
      print('회원가입 요청 중 오류 발생: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    try {
      print('로그인 요청: $baseUrl/api/auth/login');
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('로그인 응답 상태 코드: ${response.statusCode}');
      print('로그인 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseBody = utf8.decode(response.bodyBytes);
          final responseData = jsonDecode(responseBody);
          
          // 응답 데이터 검증
          if (responseData['token'] == null || responseData['user'] == null) {
            print('로그인 실패: 유효하지 않은 응답 데이터');
            return {'success': false, 'message': '서버 응답이 올바르지 않습니다.'};
          }
          
          // 사용자 정보 검증
          final userData = responseData['user'];
          if (userData['id'] == null || userData['username'] == null) {
            print('로그인 실패: 유효하지 않은 사용자 정보');
            return {'success': false, 'message': '사용자 정보가 올바르지 않습니다.'};
          }
          
          return {'success': true, ...responseData};
        } catch (e) {
          print('JSON 디코딩 오류: $e');
          return {'success': false, 'message': '서버 응답을 처리하는 중 오류가 발생했습니다.'};
        }
      } else {
        try {
          final responseBody = utf8.decode(response.bodyBytes);
          final errorData = jsonDecode(responseBody);
          return {
            'success': false,
            'message': errorData['message'] ?? '로그인에 실패했습니다.'
          };
        } catch (e) {
          return {
            'success': false,
            'message': '로그인에 실패했습니다. (상태 코드: ${response.statusCode})'
          };
        }
      }
    } catch (e) {
      print('로그인 API 오류: $e');
      return {
        'success': false,
        'message': '서버 연결에 실패했습니다.'
      };
    }
  }

  Future<bool> checkUsernameAvailability(String username) async {
    try {
      print('사용자 이름 중복 검사 요청: $baseUrl/api/auth/check-username');
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/check-username'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode({
          'username': username,
        }),
      );

      print('사용자 이름 중복 검사 응답 상태 코드: ${response.statusCode}');
      print('사용자 이름 중복 검사 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final responseData = jsonDecode(responseBody);
        return responseData['available'] ?? false;
      } else {
        throw Exception('사용자 이름 중복 검사에 실패했습니다.');
      }
    } catch (e) {
      print('사용자 이름 중복 검사 오류: $e');
      throw e;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/api/users/$userId');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('사용자 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('사용자 삭제 요청 중 오류 발생: $e');
      rethrow;
    }
  }
} 