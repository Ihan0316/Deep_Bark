// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:app_flutter/screens/language_settings_screen.dart';
import '../services/app_localizations.dart';
import '../services/locale_provider.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  final TextEditingController _nameController = TextEditingController();
  double? _matchPercentage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.checkCurrentUser(); // 사용자 정보 로드
      setState(() {}); // UI 갱신
    });
  }

  Future<void> _getImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final localizations = AppLocalizations.of(context);

    // 디버깅용 출력
    print('빌드 시 사용자 정보: ${authService.userName}, ${authService.userEmail}');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 뒤로가기 버튼 비활성화
        title: Text(localizations.translate('profile'))
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              // 프로필 이미지
              GestureDetector(
                onTap: _getImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      _profileImage != null
                          ? FileImage(_profileImage!)
                          : (authService.profileImageUrl.isNotEmpty
                              ? NetworkImage(authService.profileImageUrl)
                                  as ImageProvider
                              : null),
                  child:
                      (_profileImage == null &&
                              authService.profileImageUrl.isEmpty)
                          ? Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey[600],
                          )
                          : null,
                ),
              ),
              SizedBox(height: 30),

              // 로그인 정보 표시 (소셜 로그인 포함)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 로그인 타입 표시
                      if (authService.userId.startsWith('google'))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Icon(Icons.account_circle, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                localizations.translate(
                                  'logged_in_with_google',
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (authService.userId.startsWith('kakao'))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Icon(Icons.account_circle, color: Colors.indigo),
                              SizedBox(width: 8),
                              Text(
                                localizations.translate('logged_in_with_kakao'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 이메일 정보
                      ListTile(
                        leading: Icon(Icons.email),
                        title: Text(localizations.translate('email')),
                        subtitle: Text(
                          authService.userEmail,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Divider(),

                      // 이름 정보
                      ListTile(
                        leading: Icon(Icons.person),
                        title: Text(localizations.translate('name')),
                        subtitle: Text(
                          authService.userName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Icon(Icons.edit),
                        onTap: () {
                          // 이름 수정 다이얼로그 표시
                          _nameController.text = authService.userName;
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text(
                                    localizations.translate('change_name'),
                                  ),
                                  content: TextField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      hintText: localizations.translate(
                                        'enter_new_name',
                                      ),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        localizations.translate('cancel'),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        final newName = _nameController.text;
                                        if (newName.isNotEmpty) {
                                          authService.updateUserName(newName);
                                        }
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        localizations.translate('change'),
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.brown,
                                      ),
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // 앱 설정
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.notifications),
                        title: Text(
                          localizations.translate('notification_settings'),
                        ),
                        trailing: Switch(
                          value: authService.notificationsEnabled,
                          onChanged: (value) {
                            authService.setNotificationsEnabled(value);
                          },
                          activeColor: Colors.brown,
                        ),
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.language),
                        title: Text(
                          localizations.translate('language_settings'),
                        ),
                        subtitle: Text(localeProvider.getLanguageName()),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LanguageSettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30),

              // 로그아웃 버튼
              ElevatedButton(
                onPressed: () {
                  authService.logout().then((_) {
                    Navigator.pushReplacementNamed(context, '/login');
                  });
                },
                child: Text(localizations.translate('logout')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: Size(double.infinity, 50),
                ),
              ),

              SizedBox(height: 16),

              // 회원 탈퇴 버튼
              TextButton(
                onPressed: () {
                  // 회원 탈퇴 확인 다이얼로그 표시
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text(
                            localizations.translate('delete_account'),
                          ),
                          content: Text(
                            localizations.translate('delete_account_confirm'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(localizations.translate('cancel')),
                            ),
                            TextButton(
                              onPressed: () {
                                // 회원 탈퇴 처리
                                authService.deleteAccount().then((_) {
                                  Navigator.pop(context);
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/login',
                                  );
                                });
                              },
                              child: Text(localizations.translate('delete')),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                  );
                },
                child: Text(
                  localizations.translate('delete_account'),
                  style: TextStyle(color: Colors.grey),
                ),
              ),

              SizedBox(height: 20),

              _buildMatchCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard() {
    if (_matchPercentage == null) {
      return const SizedBox.shrink(); // 일치도가 없으면 아무것도 표시하지 않음
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '나와의 일치도',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '$_matchPercentage%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_matchPercentage ?? 0) / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
          ),
        ],
      ),
    );
  }
}
