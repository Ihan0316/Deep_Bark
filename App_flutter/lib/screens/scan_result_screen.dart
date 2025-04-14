// lib/screens/scan_result_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/dog_breed_model.dart';
import '../services/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/locale_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ScanResultScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final List<DogBreed> results = args['results'];
    final String imagePath = args['imagePath'];
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('analysis_result')),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                localizations.translate('analysis_result'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 16),

              if (results.isEmpty)
                Card(
                  margin: EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: AssetImage('assets/images/error.png'),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('분석 오류 - 다른 이미지로 시도해주세요!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._getFilteredResults(results).map((breed) => _buildResultItem(context, breed, results.indexOf(breed))),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  List<DogBreed> _getFilteredResults(List<DogBreed> results) {
    // 정상 결과만 필터링
    final validResults = results.where((breed) => (breed.confidence ?? 0) >= 30).toList();
    
    if (validResults.isEmpty) {
      // 모든 결과가 분석 오류인 경우 첫 번째 결과만 반환
      return [results.first];
    } else {
      // 정상 결과가 있는 경우 상위 2개 결과만 반환
      validResults.sort((a, b) => (b.confidence ?? 0).compareTo(a.confidence ?? 0));
      return validResults.take(2).toList();
    }
  }

  Widget _buildResultItem(BuildContext context, DogBreed breed, int index) {
    final localizations = AppLocalizations.of(context);
    final bool isError = (breed.confidence ?? 0) < 30;

    return GestureDetector(
      onTap: isError ? null : () {
        Navigator.pushNamed(
          context,
          '/breed_detail',
          arguments: {'breed': breed},
        );
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 12),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: isError 
                      ? AssetImage('assets/images/error.png')
                      : (breed.imageUrl != null
                          ? (breed.imageUrl!.startsWith('assets/')
                              ? AssetImage(breed.imageUrl!)
                              : CachedNetworkImageProvider(breed.imageUrl!))
                          : AssetImage('assets/images/dog_placeholder.png') as ImageProvider),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isError ? '분석 오류 - 다른 이미지로 시도해주세요!' : '${index + 1}. ${breed.name}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isError ? Colors.black : null,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // 신뢰도 표시 바
              if (!isError) Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.translate('match_rate'),
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${breed.confidence?.toStringAsFixed(1) ?? 0}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (breed.confidence ?? 0) / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getConfidenceColor(breed.confidence ?? 0),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 신뢰도에 따른 색상 반환
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) {
      return Colors.green;
    } else if (confidence >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
