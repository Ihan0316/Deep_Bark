import 'dart:io';
import '../models/dog_breed_model.dart';
import '../data/dog_breeds_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:async/async.dart';

class DogBreedService {
  // Flask 서버 URL (실제 서버 주소로 변경 필요)
  final String baseUrl = 'http://10.0.2.2:5000'; // Android 에뮬레이터에서 로컬호스트 접근용
  // 실제 기기나 iOS 시뮬레이터에서는 실제 IP 주소 사용 필요
  // 예: final String baseUrl = 'http://192.168.0.100:5000';

  // 영어 견종 이름을 한글로 변환하는 메서드
  String _convertBreedNameToKorean(String englishName) {
    // 영어-한글 견종 이름 매핑
    final Map<String, String> breedNameMap = {
      'Golden Retriever': '골든 리트리버',
      'Welsh Corgi': '웰시 코기',
      'Korean Jindo': '진돗개',
      'Shiba Inu': '시바견',
      'Chihuahua': '치와와',
      'Dachshund': '닥스훈트',
      'Labrador Retriever': '래브라도 리트리버',
      'German Shepherd': '저먼 셰퍼드',
      'Poodle': '푸들',
      'Beagle': '비글',
      'Bulldog': '불독',
      'Pomeranian': '포메라니안',
      'Husky': '허스키',
      'Maltese': '말티즈',
      'Shih Tzu': '시츄',
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
      // 멀티파트 요청 생성
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/classify'),
      );

      // 파일 스트림 생성
      var stream = http.ByteStream(DelegatingStream.typed(image.openRead()));
      var length = await image.length();

      // 멀티파트 파일 생성
      var multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: basename(image.path),
      );

      // 요청에 파일 추가
      request.files.add(multipartFile);

      // 요청 전송
      var response = await request.send();

      // 응답 처리
      if (response.statusCode == 200) {
        // 응답 본문 읽기
        var responseData = await response.stream.bytesToString();
        var result = json.decode(responseData);

        // 결과 리스트 생성
        List<DogBreed> breeds = [];

        // 상위 2개 예측 결과 처리
        List<dynamic> predictions = result['predictions'];

        // 각 예측 결과에 대해 견종 정보 생성
        for (var i = 0; i < predictions.length; i++) {
          var prediction = predictions[i];
          String englishBreedName = prediction['class'];
          String koreanBreedName = _convertBreedNameToKorean(englishBreedName);
          double confidence = prediction['confidence'];

          // 견종 이름을 기반으로 추가 정보 가져오기
          String description = await getWikipediaContent(koreanBreedName);
          String? imageUrl = await getWikipediaImage(koreanBreedName);

          // 모든 견종 데이터에서 해당 견종 정보 가져오기
          List<DogBreed> allBreeds = await getAllBreeds('ko');
          DogBreed? matchingBreed = allBreeds.firstWhere(
            (breed) => breed.name.toLowerCase() == koreanBreedName.toLowerCase(),
            orElse: () => DogBreed(
              id: (i + 1).toString(),
              name: koreanBreedName,
              origin: '알 수 없음',
              description: description,
              size: '-',
              weight: '-',
              lifespan: '-',
              temperament: '-',
            ),
          );

          breeds.add(
            DogBreed(
              id: (i + 1).toString(),
              name: koreanBreedName,
              origin: matchingBreed.origin,
              description: description,
              imageUrl: imageUrl ?? matchingBreed.imageUrl,
              size: matchingBreed.size ?? '-',
              weight: matchingBreed.weight ?? '-',
              lifespan: matchingBreed.lifespan ?? '-',
              temperament: matchingBreed.temperament ?? '-',
              confidence: confidence,
            ),
          );
        }

        return breeds;
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('이미지 분석 오류: $e');
      // 오류 발생 시 기본 데이터 반환
      return [
        DogBreed(
          id: '1',
          name: '분석 오류',
          origin: '알 수 없음',
          description: '이미지 분석 중 오류가 발생했습니다: $e',
          imageUrl: 'https://example.com/error.jpg',
        ),
      ];
    }
  }

  Future<String?> getWikipediaImage(
      String breedName, [
        String languageCode = 'ko',
      ]) async {
    try {
      // 위키백과 API를 사용하여 이미지 정보 가져오기
      final url = Uri.parse(
        'https://${languageCode}.wikipedia.org/w/api.php?action=query&prop=pageimages&format=json&piprop=original&titles=${Uri.encodeComponent(breedName)}',
      );
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'MyApp/1.0 (https://myapp.com; myapp@example.com)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']['pages'];
        final pageId = pages.keys.first;

        // 페이지가 존재하고 이미지가 있는 경우
        if (pageId != '-1' && pages[pageId]['original'] != null) {
          return pages[pageId]['original']['source'];
        }

        // 현재 언어 위키백과에 없는 경우 영어 위키백과 시도
        if (languageCode != 'en') {
          final enUrl = Uri.parse(
            'https://en.wikipedia.org/w/api.php?action=query&prop=pageimages&format=json&piprop=original&titles=${Uri.encodeComponent(breedName)}',
          );

          final enResponse = await http.get(
            enUrl,
            headers: {
              'User-Agent': 'MyApp/1.0 (https://myapp.com; myapp@example.com)',
            },
          );

          if (enResponse.statusCode == 200) {
            final enData = json.decode(enResponse.body);
            final enPages = enData['query']['pages'];
            final enPageId = enPages.keys.first;

            if (enPageId != '-1' && enPages[enPageId]['original'] != null) {
              return enPages[enPageId]['original']['source'];
            }
          }
        }
      }

      return null;
    } catch (e) {
      print('위키백과 이미지를 가져오는 중 오류 발생: $e');
      return null;
    }
  }

  Future<List<DogBreed>> getAllBreeds([String languageCode = 'ko']) async {
    // 초기 견종 데이터 가져오기 - 언어 코드 전달
    List<DogBreed> breeds = DogBreedsData.getInitialBreeds(languageCode);

    // 모든 견종에 대해 위키백과 이미지를 병렬로 가져오기
    List<Future<DogBreed>> breedFutures = breeds.map((breed) async {
      final imageUrl = await getWikipediaImage(breed.name, languageCode);
      return imageUrl != null ? breed.copyWith(imageUrl: imageUrl) : breed;
    }).toList();

    // 모든 Future가 완료될 때까지 기다림
    return await Future.wait(breedFutures);
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
      final response = await http.get(url);
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

          final enResponse = await http.get(enUrl);

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
}
