// lib/screens/scan_result_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/dog_breed_model.dart';
import '../services/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/locale_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'breed_detail_screen.dart';
import '../services/dog_breed_service.dart';

class ScanResultScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final List<DogBreed> results = args['results'];
    final String imagePath = args['imagePath'];
    final localizations = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.translate('analysis_result'))),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.35,
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
                  child: Image.file(File(imagePath), fit: BoxFit.cover),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.03),

              Text(
                localizations.translate('analysis_result'),
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.06,
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
                              backgroundImage: AssetImage(
                                'assets/images/error.png',
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '다른 이미지로 시도해주세요!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '옷을 입지 않은 전신사진을 넣어주세요!!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
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
                ..._getFilteredResults(results).map(
                  (breed) =>
                      _buildResultItem(context, breed, results.indexOf(breed)),
                ),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  List<DogBreed> _getFilteredResults(List<DogBreed> results) {
    // 정상 결과만 필터링
    final validResults =
        results.where((breed) => (breed.confidence ?? 0) >= 30).toList();

    if (validResults.isEmpty) {
      // 모든 결과가 분석 오류인 경우 첫 번째 결과만 반환
      return [results.first];
    } else {
      // 정상 결과가 있는 경우 상위 2개 결과만 반환
      validResults.sort(
        (a, b) => (b.confidence ?? 0).compareTo(a.confidence ?? 0),
      );
      return validResults.take(2).toList();
    }
  }

  String _cleanBreedName(String name) {
    return name.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  }

  Widget _buildResultItem(BuildContext context, DogBreed breed, int index) {
    final localizations = AppLocalizations.of(context);
    final bool isError = (breed.confidence ?? 0) < 30;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return GestureDetector(
      onTap:
          isError
              ? null
              : () async {
                // 데이터베이스에서 견종 정보 가져오기
                final breedService = DogBreedService();
                List<DogBreed> allBreeds = await breedService.getAllBreeds();
                DogBreed? matchingBreed = allBreeds.firstWhere(
                  (b) => b.nameEn.toLowerCase().trim() == breed.nameEn.toLowerCase().trim() ||
                        b.nameKo == breed.nameKo,
                  orElse: () => breed,
                );

                // 데이터베이스에서 가져온 정보로 업데이트
                final updatedBreed = DogBreed(
                  id: matchingBreed.id,
                  nameEn: matchingBreed.nameEn,
                  nameKo: matchingBreed.nameKo,
                  originEn: matchingBreed.originEn,
                  originKo: matchingBreed.originKo,
                  sizeEn: matchingBreed.sizeEn,
                  sizeKo: matchingBreed.sizeKo,
                  lifespanEn: matchingBreed.lifespanEn,
                  lifespanKo: matchingBreed.lifespanKo,
                  weight: matchingBreed.weight,
                  descriptionEn: matchingBreed.descriptionEn,
                  descriptionKo: matchingBreed.descriptionKo,
                  imageUrl: 'assets/images/dog/${matchingBreed.nameKo}.jpg',
                  confidence: breed.confidence,
                );

                Navigator.pushNamed(
                  context,
                  '/breed_detail',
                  arguments: {'breed': updatedBreed},
                );
              },
      child: Card(
        margin: EdgeInsets.only(bottom: 12),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: isError
                        ? Image.asset(
                            'assets/images/error.png',
                            width: MediaQuery.of(context).size.width * 0.12,
                            height: MediaQuery.of(context).size.width * 0.12,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'assets/images/dog/${breed.nameKo}.jpg',
                            width: MediaQuery.of(context).size.width * 0.12,
                            height: MediaQuery.of(context).size.width * 0.12,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image: $error');
                              return Container(
                                width: MediaQuery.of(context).size.width * 0.12,
                                height: MediaQuery.of(context).size.width * 0.12,
                                color: Colors.grey[300],
                                child: Icon(Icons.pets, color: Colors.grey[600]),
                              );
                            },
                          ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isError
                              ? '다른 이미지로 시도해주세요!'
                              : '${index + 1}. ${_cleanBreedName(localeProvider.locale.languageCode == 'ko' ? breed.nameKo : breed.nameEn)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isError ? Colors.black : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // 신뢰도 표시 바
              if (!isError)
                Column(
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
              SizedBox(height: 12),
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
