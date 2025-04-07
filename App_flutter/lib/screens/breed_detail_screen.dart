// lib/screens/breed_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/dog_breed_model.dart';
import '../services/dog_breed_service.dart';

class BreedDetailScreen extends StatefulWidget {
  @override
  _BreedDetailScreenState createState() => _BreedDetailScreenState();
}

class _BreedDetailScreenState extends State<BreedDetailScreen> {
  final DogBreedService _breedService = DogBreedService();
  bool _isLoading = false;
  String? _wikiContent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWikiContent();
    });
  }

  Future<void> _loadWikiContent() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final DogBreed breed = args['breed'];

    setState(() {
      _isLoading = true;
    });

    try {
      final content = await _breedService.getWikipediaContent(breed.name);
      setState(() {
        _wikiContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('정보를 불러오는데 실패했습니다: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final DogBreed breed = args['breed'];

    return Scaffold(
      appBar: AppBar(
        title: Text(breed.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 품종 이미지
            if (breed.imageUrl != null)
              Container(
                width: double.infinity,
                height: 250,
                child: Image.network(
                  breed.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(Icons.pets, size: 80, color: Colors.grey[600]),
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 품종 기본 정보
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '기본 정보',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildInfoRow('원산지', breed.origin),
                          _buildInfoRow('크기', breed.size ?? '정보 없음'),
                          _buildInfoRow('무게', breed.weight ?? '정보 없음'),
                          _buildInfoRow('수명', breed.lifespan ?? '정보 없음'),
                          _buildInfoRow('성격', breed.temperament ?? '정보 없음'),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // 위키백과 내용
                  Text(
                    '상세 설명',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),

                  _isLoading
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                      : _wikiContent == null
                      ? Text('상세 정보를 불러올 수 없습니다.')
                      : Text(
                    _wikiContent!,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: 20),

                  // 위키백과 링크 버튼
                  OutlinedButton.icon(
                    onPressed: () {
                      // 위키백과 링크 열기 (URL 런처 사용)
                      // 실제 구현 시에는 url_launcher 패키지를 사용해야 합니다
                    },
                    icon: Icon(Icons.open_in_new),
                    label: Text('위키백과에서 더 보기'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      foregroundColor: Colors.brown,
                      side: BorderSide(color: Colors.brown),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
