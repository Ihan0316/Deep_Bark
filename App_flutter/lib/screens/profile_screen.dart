// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  final TextEditingController _nameController = TextEditingController();

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

    // 디버깅용 출력
    print('빌드 시 사용자 정보: ${authService.userName}, ${authService.userEmail}');

    return Scaffold(
      appBar: AppBar(
        title: Text("마이페이지"),
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
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : (authService.profileImageUrl.isNotEmpty
                      ? NetworkImage(authService.profileImageUrl) as ImageProvider
                      : null),
                  child: (_profileImage == null && authService.profileImageUrl.isEmpty)
                      ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                      : null,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "프로필 이미지 변경",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
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
                                "Google 계정으로 로그인됨",
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
                                "kakao 계정으로 로그인됨",
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
                        title: Text("이메일"),
                        subtitle: Text(
                          authService.userEmail,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Divider(),

                      // 이름 정보
                      ListTile(
                        leading: Icon(Icons.person),
                        title: Text("이름"),
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
                            builder: (context) => AlertDialog(
                              title: Text("이름 변경"),
                              content: TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  hintText: "새 이름을 입력하세요",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("취소"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final newName = _nameController.text;
                                    if (newName.isNotEmpty) {
                                      authService.updateUserName(newName);
                                    }
                                    Navigator.pop(context);
                                  },
                                  child: Text("변경"),
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
                        title: Text("알림 설정"),
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
                        title: Text("언어 설정"),
                        subtitle: Text("한국어"),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // 언어 설정 화면으로 이동
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
                child: Text("로그아웃"),
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
                    builder: (context) => AlertDialog(
                      title: Text("회원 탈퇴"),
                      content: Text("정말 탈퇴하시겠습니까? 이 작업은 되돌릴 수 없습니다."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("취소"),
                        ),
                        TextButton(
                          onPressed: () {
                            // 회원 탈퇴 처리
                            authService.deleteAccount().then((_) {
                              Navigator.pop(context);
                              Navigator.pushReplacementNamed(context, '/login');
                            });
                          },
                          child: Text("탈퇴"),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  "회원 탈퇴",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
