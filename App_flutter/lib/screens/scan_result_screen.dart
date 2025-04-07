// lib/screens/scan_result_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';  // File 클래스를 사용하기 위해 추가
import '../models/dog_breed_model.dart';

class ScanResultScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 이전 화면에서 전달받은 결과 데이터
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final List<DogBreed> results = args['results'];
    final String imagePath = args['imagePath'];

    return Scaffold(
      appBar: AppBar(
        title: Text('분석 결과'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 분석된 이미지 표시
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              SizedBox(height: 24),

              Text(
                '분석 결과',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 16),

              // 상위 3개 결과 표시
              ...List.generate(
                results.length > 3 ? 3 : results.length,
                    (index) => _buildResultItem(context, results[index], index),
              ),

              SizedBox(height: 24),

              // 백과사전 바로가기 버튼
              if (results.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/encyclopedia',
                      arguments: {'breed': results[0]},
                    );
                  },
                  icon: Icon(Icons.book),
                  label: Text('백과사전에서 더 알아보기'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 결과 아이템 위젯
  Widget _buildResultItem(BuildContext context, DogBreed breed, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: breed.imageUrl != null
              ? NetworkImage(breed.imageUrl!)
              : AssetImage('assets/images/dog_placeholder.png') as ImageProvider,
        ),
        title: Text(
          '${index + 1}. ${breed.name}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('원산지: ${breed.origin}'),
        trailing: Text(
          '일치도: ${(0.9 - (index * 0.15)).toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/breed_detail',
            arguments: {'breed': breed},
          );
        },
      ),
    );
  }
}
