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

  void _showChangePasswordDialog() {
    final localizations = AppLocalizations.of(context);
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(localizations.translate('change_password')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    decoration: InputDecoration(
                      labelText: localizations.translate('current_password'),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newPasswordController,
                    decoration: InputDecoration(
                      labelText: localizations.translate('new_password'),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: localizations.translate('confirm_new_password'),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text(localizations.translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (newPasswordController.text != confirmPasswordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(localizations.translate('passwords_do_not_match')),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() => isLoading = true);

                          try {
                            final authService = Provider.of<AuthService>(context, listen: false);
                            await authService.changePassword(
                              currentPasswordController.text,
                              newPasswordController.text,
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(localizations.translate('password_changed_successfully')),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => isLoading = false);
                            }
                          }
                        },
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : Text(localizations.translate('change')),
                ),
              ],
            );
          },
        );
      },
    );
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
                  radius: MediaQuery.of(context).size.width * 0.15, // 화면 너비의 15%로 조정
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
                            size: MediaQuery.of(context).size.width * 0.15, // 화면 너비의 15%로 조정
                            color: Colors.grey[600],
                          )
                          : null,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03), // 화면 높이의 3%로 조정

              // 로그인 정보 표시 (소셜 로그인 포함)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 로그인 타입 표시
                      if (authService.isGoogleLogin())
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Icon(Icons.g_mobiledata, color: Colors.blue, size: 30),
                              SizedBox(width: 8),
                              Text(
                                localizations.translate('logged_in_with_google'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (authService.isKakaoLogin())
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Icon(Icons.chat, color: Colors.yellow[900], size: 30),
                              SizedBox(width: 8),
                              Text(
                                localizations.translate('logged_in_with_kakao'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.yellow[900],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (authService.isEmailLogin())
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Icon(Icons.email, color: Colors.grey[800], size: 30),
                              SizedBox(width: 8),
                              Text(
                                localizations.translate('logged_in_with_email'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 사용자 정보 표시
                      Text(
                        authService.userName,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.05, // 화면 너비의 5%로 조정
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.01), // 화면 높이의 1%로 조정
                      Text(
                        authService.userEmail,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04, // 화면 너비의 4%로 조정
                          color: Colors.grey[600],
                        ),
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
                      ListTile(
                        leading: const Icon(Icons.lock),
                        title: Text(localizations.translate('change_password')),
                        onTap: _showChangePasswordDialog,
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
