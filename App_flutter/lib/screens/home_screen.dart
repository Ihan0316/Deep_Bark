// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/dog_breed_service.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isAnalyzing = false;
  final DogBreedService _dogBreedService = DogBreedService();
  final AuthService _authService = AuthService();

  Future _getImageFromCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _image = File(photo.path);
      });
    }
  }

  Future _getImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  Future _analyzeImage() async {
    if (_image == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final results = await _dogBreedService.analyzeImage(_image!);

      Navigator.pushNamed(
        context,
        '/result',
        arguments: {
          'results': results,
          'imagePath': _image!.path,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 분석 중 오류가 발생했습니다: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 뒤로가기 동작 방지
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,  // 뒤로가기 버튼 비활성화
          title: Text("멍멍스캔"),
          backgroundColor: Colors.brown,
          actions: [
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                Navigator.pushNamed(context, "/profile");
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Text(
                  "반려견 품종을 스캔해보세요!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 30),
                // 이미지 표시 영역
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _image == null
                      ? Center(
                    child: Icon(
                      Icons.pets,
                      size: 100,
                      color: Colors.grey[400],
                    ),
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(
                      _image!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                // 이미지 업로드 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _getImageFromCamera,
                      icon: Icon(Icons.camera_alt),
                      label: Text("카메라"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: _getImageFromGallery,
                      icon: Icon(Icons.photo_library),
                      label: Text("갤러리"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                // 분석 버튼
                _isAnalyzing
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _image == null ? null : _analyzeImage,
                  child: Text("품종 분석하기"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    minimumSize: Size(double.infinity, 50),
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
                SizedBox(height: 30),
                // 멍멍백서 바로가기
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, "/encyclopedia");
                  },
                  icon: Icon(Icons.book),
                  label: Text("멍멍백서 보러가기"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.brown,
                    side: BorderSide(color: Colors.brown),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          selectedItemColor: Colors.brown,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.pets),
              label: "멍멍스캔",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: "멍멍백서",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "마이페이지",
            ),
          ],
          onTap: (index) {
            if (index == 0) {
              // 현재 화면이므로 아무 동작 안함
            } else if (index == 1) {
              Navigator.pushNamed(context, "/encyclopedia");
            } else if (index == 2) {
              Navigator.pushNamed(context, "/profile");
            }
          },
        ),
      ),
    );
  }
}
