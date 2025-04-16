import 'dart:io';
import '../models/dog_breed_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show json, utf8;
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:async/async.dart';
import 'image_cache_service.dart';

class DogBreedService {
  static final DogBreedService _instance = DogBreedService._internal();
  factory DogBreedService() => _instance;
  DogBreedService._internal();

  // 실제 서버 주소로 변경
  static const String baseUrl = 'http://10.0.2.2:8080'; // Android 에뮬레이터용
  // static const String baseUrl = 'http://localhost:8080'; // 웹용
  // static const String baseUrl = 'http://127.0.0.1:8080'; // iOS 시뮬레이터용

  final ImageCacheService _imageCache = ImageCacheService();
  final Map<String, String> _contentCache = {};
  final Map<String, String?> _imageUrlCache = {};
  final Map<String, DogBreed> _breedCache = {};
  final http.Client _httpClient = http.Client();
  static const int _maxCacheSize = 100;

  // Flask 서버 URL (실제 서버 주소로 변경 필요)
  // 실제 기기나 iOS 시뮬레이터에서는 실제 IP 주소 사용 필요
  // final String baseUrl = 'http://10.100.201.41:5000';

  // 영어 견종 이름을 한글로 변환하는 메서드
  String _convertBreedNameToKorean(String englishName) {
    // 영어-한글 견종 이름 매핑
    final Map<String, String> breedNameMap = {
      'Golden Retriever': '골든 리트리버',
      'Welsh Corgi': '웰시 코기',
      'Jindo Dog': '진돗개',
      'Shiba Inu': '시바견',
      'Chihuahua': '치와와 (개)',
      'Dachshund': '닥스훈트',
      'Labrador Retriever': '래브라도 리트리버',
      'German Shepherd': '저먼 셰퍼드',
      'Poodle': '푸들',
      'Beagle': '비글',
      'Bulldog': '불독',
      'Pomeranian': '포메라니안',
      'Husky': '허스키',
      'Maltese': '말티즈',
      'Shih Tzu': '시추',
      'Yorkshire Terrier': '요크셔 테리어',
      'Bichon Frise': '비숑 프리제',
      'Cocker Spaniel': '코커 스패니얼',
      'Border Collie': '보더 콜리',
      'Samoyed': '사모예드',
    };

    return breedNameMap[englishName] ?? englishName;
  }

  Future<List<DogBreed>> analyzeImage(File image) async {
    try {
      print('=== 이미지 분석 API 요청 ===');
      print('요청 URL: $baseUrl/api/analyze');
      
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/analyze'));
      var stream = http.ByteStream(DelegatingStream.typed(image.openRead()));
      var length = await image.length();
      var multipartFile = http.MultipartFile('image', stream, length, filename: basename(image.path));
      request.files.add(multipartFile);

      print('이미지 파일 정보:');
      print('- 파일명: ${basename(image.path)}');
      print('- 파일 크기: $length bytes');

      var response = await _httpClient.send(request);
      print('=== 이미지 분석 API 응답 ===');
      print('상태 코드: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        print('응답 내용: $responseData');
        
        var result = json.decode(responseData);
        List<dynamic> predictions = result['predictions'];

        // 병렬 처리를 위한 Future 리스트
        List<Future<DogBreed>> breedFutures = predictions.map((prediction) async {
          String englishBreedName = prediction['class'];
          String koreanBreedName = _convertBreedNameToKorean(englishBreedName);
          double confidence = prediction['confidence'];

          print('예측 결과:');
          print('- 견종(영문): $englishBreedName');
          print('- 견종(한글): $koreanBreedName');
          print('- 신뢰도: $confidence%');

          // 캐시된 견종 정보 확인
          if (_breedCache.containsKey(koreanBreedName)) {
            return _breedCache[koreanBreedName]!.copyWith(confidence: confidence);
          }

          // 캐시된 내용 확인
          String? cachedContent = _contentCache[koreanBreedName];
          String? cachedImageUrl = _imageUrlCache[koreanBreedName];

          // 캐시된 내용이 없는 경우에만 API 호출
          String description = cachedContent ?? await getWikipediaContent(koreanBreedName);
          String? imageUrl = cachedImageUrl ?? await getWikipediaImage(koreanBreedName);

          // 캐시 업데이트
          if (cachedContent == null) _contentCache[koreanBreedName] = description;
          if (cachedImageUrl == null) _imageUrlCache[koreanBreedName] = imageUrl;

          List<DogBreed> allBreeds = await getAllBreeds();
          DogBreed? matchingBreed = allBreeds.firstWhere(
            (breed) => breed.nameEn.toLowerCase() == englishBreedName.toLowerCase(),
            orElse: () => DogBreed(
              id: predictions.indexOf(prediction),
              nameEn: englishBreedName,
              nameKo: koreanBreedName,
              originEn: '알 수 없음',
              originKo: '알 수 없음',
              sizeEn: '-',
              sizeKo: '-',
              lifespanEn: '-',
              lifespanKo: '-',
              weight: '-',
              descriptionEn: '이 견종에 대한 위키백과 정보를 찾을 수 없습니다.',
              descriptionKo: '이 견종에 대한 위키백과 정보를 찾을 수 없습니다.',
              imageUrl: 'assets/images/error.png',
            ),
          );

          final breed = DogBreed(
            id: predictions.indexOf(prediction),
            nameEn: englishBreedName,
            nameKo: koreanBreedName,
            originEn: matchingBreed.originEn,
            originKo: matchingBreed.originKo,
            sizeEn: matchingBreed.sizeEn,
            sizeKo: matchingBreed.sizeKo,
            lifespanEn: matchingBreed.lifespanEn,
            lifespanKo: matchingBreed.lifespanKo,
            weight: matchingBreed.weight,
            descriptionEn: description,
            descriptionKo: description,
            imageUrl: imageUrl ?? matchingBreed.imageUrl,
            confidence: confidence,
          );

          // 견종 정보 캐시
          _addToBreedCache(koreanBreedName, breed);
          return breed;
        }).toList();

        return await Future.wait(breedFutures);
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('이미지 분석 오류: $e');
      return [
        DogBreed(
          id: 1,
          nameEn: '다른 이미지로 시도해주세요! $e\n옷을 입지 않은 전신사진을 넣어주세요!!',
          nameKo: '다른 이미지로 시도해주세요! $e\n옷을 입지 않은 전신사진을 넣어주세요!!',
          originEn: '알 수 없음',
          originKo: '알 수 없음',
          sizeEn: '-',
          sizeKo: '-',
          lifespanEn: '-',
          lifespanKo: '-',
          weight: '-',
          descriptionEn: '이미지 분석 중 오류가 발생했습니다:',
          descriptionKo: '이미지 분석 중 오류가 발생했습니다:',
          imageUrl: 'assets/images/error.png',
        ),
      ];
    }
  }

  void _addToBreedCache(String name, DogBreed breed) {
    if (_breedCache.length >= _maxCacheSize) {
      _breedCache.remove(_breedCache.keys.first);
    }
    _breedCache[name] = breed;
  }

  Future<String?> getWikipediaImage(String breedName, [String languageCode = 'ko']) async {
    if (_imageUrlCache.containsKey(breedName)) {
      return _imageUrlCache[breedName];
    }

    try {
      final url = Uri.parse(
        'https://${languageCode}.wikipedia.org/w/api.php?action=query&prop=pageimages&format=json&piprop=original&titles=${Uri.encodeComponent(breedName)}',
      );
      final response = await _httpClient.get(
        url,
        headers: {'User-Agent': 'MyApp/1.0 (https://myapp.com; myapp@example.com)'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']['pages'];
        final pageId = pages.keys.first;

        if (pageId != '-1' && pages[pageId]['original'] != null) {
          final imageUrl = pages[pageId]['original']['source'];
          _imageUrlCache[breedName] = imageUrl;
          return imageUrl;
        }

        if (languageCode != 'en') {
          final enUrl = Uri.parse(
            'https://en.wikipedia.org/w/api.php?action=query&prop=pageimages&format=json&piprop=original&titles=${Uri.encodeComponent(breedName)}',
          );

          final enResponse = await _httpClient.get(
            enUrl,
            headers: {'User-Agent': 'MyApp/1.0 (https://myapp.com; myapp@example.com)'},
          );

          if (enResponse.statusCode == 200) {
            final enData = json.decode(enResponse.body);
            final enPages = enData['query']['pages'];
            final enPageId = enPages.keys.first;

            if (enPageId != '-1' && enPages[enPageId]['original'] != null) {
              final imageUrl = enPages[enPageId]['original']['source'];
              _imageUrlCache[breedName] = imageUrl;
              return imageUrl;
            }
          }
        }
      }

      _imageUrlCache[breedName] = null;
      return null;
    } catch (e) {
      print('위키백과 이미지를 가져오는 중 오류 발생: $e');
      return null;
    }
  }

  Future<List<DogBreed>> getAllBreeds() async {
    try {
      // 서버 연결 상태 확인
      bool isConnected = await checkServerConnection();
      if (!isConnected) {
        throw Exception('서버에 연결할 수 없습니다. 네트워크 연결을 확인해주세요.');
      }

      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/breeds'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
        return jsonList.map((json) {
          String nameKo = json['nameKo'];
          return DogBreed(
            id: json['id'] is String ? int.parse(json['id']) : json['id'],
            nameEn: json['nameEn'],
            nameKo: nameKo,
            originEn: json['originEn'],
            originKo: json['originKo'],
            sizeEn: json['sizeEn'],
            sizeKo: json['sizeKo'],
            lifespanEn: json['lifespanEn'],
            lifespanKo: json['lifespanKo'],
            weight: json['weight'],
            descriptionEn: json['descriptionEn'],
            descriptionKo: json['descriptionKo'],
            imageUrl: 'assets/images/dog/${nameKo}.jpg',
          );
        }).toList();
      } else {
        print('서버 응답 코드: ${response.statusCode}');
        print('서버 응답 내용: ${response.body}');
        throw Exception('견종 목록을 불러오는데 실패했습니다. (상태 코드: ${response.statusCode})');
      }
    } catch (e) {
      print('견종 목록 로딩 에러: $e');
      rethrow;
    }
  }

  Future<List<DogBreed>> searchBreeds(String query) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/breeds/search?query=$query'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
        return jsonList.map((json) {
          String nameKo = json['nameKo'];
          return DogBreed(
            id: json['id'] is String ? int.parse(json['id']) : json['id'],
            nameEn: json['nameEn'],
            nameKo: nameKo,
            originEn: json['originEn'],
            originKo: json['originKo'],
            sizeEn: json['sizeEn'],
            sizeKo: json['sizeKo'],
            lifespanEn: json['lifespanEn'],
            lifespanKo: json['lifespanKo'],
            weight: json['weight'],
            descriptionEn: json['descriptionEn'],
            descriptionKo: json['descriptionKo'],
            imageUrl: 'assets/images/dog/${nameKo}.jpg',
          );
        }).toList();
      } else {
        print('검색 응답 코드: ${response.statusCode}');
        print('검색 응답 내용: ${response.body}');
        throw Exception('견종 검색에 실패했습니다. (상태 코드: ${response.statusCode})');
      }
    } catch (e) {
      print('견종 검색 에러: $e');
      rethrow;
    }
  }

  Future<String> getWikipediaContent(
      String breedName, [
        String languageCode = 'ko',
      ]) async {
    try {
      // 언어 코드에 따라 적절한 위키피디아 API URL 생성
      final url = Uri.parse(
        'https://${languageCode}.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&exintro=true&explaintext=true&titles=${Uri.encodeComponent(breedName)}',
      );
      final response = await _httpClient.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']['pages'];
        final pageId = pages.keys.first;

        // 페이지가 존재하는 경우
        if (pageId != '-1') {
          final extract = pages[pageId]['extract'];
          if (extract != null && extract.isNotEmpty) {
            return extract;
          }
        }

        // 현재 언어 위키백과에 없는 경우 영어 위키백과 시도
        if (languageCode != 'en') {
          final enUrl = Uri.parse(
            'https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&exintro=true&explaintext=true&titles=${Uri.encodeComponent(breedName)}',
          );

          final enResponse = await _httpClient.get(enUrl);

          if (enResponse.statusCode == 200) {
            final enData = json.decode(enResponse.body);
            final enPages = enData['query']['pages'];
            final enPageId = enPages.keys.first;

            if (enPageId != '-1') {
              final enExtract = enPages[enPageId]['extract'];
              if (enExtract != null && enExtract.isNotEmpty) {
                // 한국어인 경우 영어 내용임을 표시
                if (languageCode == 'ko') {
                  return '(영문) ' + enExtract;
                }
                return enExtract;
              }
            }
          }
        }
      }

      return getNoWikipediaInfoMessage(languageCode);
    } catch (e) {
      return getWikipediaErrorMessage(languageCode, e.toString());
    }
  }

  // 각 언어별 메시지 반환
  String getNoInfoMessage(String languageCode) {
    switch (languageCode) {
      case 'ko':
        return '(영문)';
      case 'en':
        return '(English)';
      default:
        return '(English)';
    }
  }

  String getNoWikipediaInfoMessage(String languageCode) {
    switch (languageCode) {
      case 'ko':
        return '이 견종에 대한 위키백과 정보를 찾을 수 없습니다.';
      case 'en':
        return 'No Wikipedia information found for this breed.';
      default:
        return 'No Wikipedia information found for this breed.';
    }
  }

  String getWikipediaErrorMessage(String languageCode, String error) {
    switch (languageCode) {
      case 'ko':
        return '위키백과 정보를 가져오는 중 오류가 발생했습니다: $error';
      case 'en':
        return 'Error occurred while fetching Wikipedia information: $error';
      default:
        return 'Error occurred while fetching Wikipedia information: $error';
    }
  }

  // 서버 연결 상태 확인
  Future<bool> checkServerConnection() async {
    try {
      final response = await _httpClient.get(Uri.parse('$baseUrl/api/health'));
      return response.statusCode == 200;
    } catch (e) {
      print('서버 연결 확인 실패: $e');
      return false;
    }
  }

  void dispose() {
    _httpClient.close();
    _contentCache.clear();
    _imageUrlCache.clear();
    _breedCache.clear();
  }
}
