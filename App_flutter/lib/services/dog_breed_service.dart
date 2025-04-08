import 'dart:io';
import '../models/dog_breed_model.dart';
import '../data/dog_breeds_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class DogBreedService {
  Future<List<DogBreed>> analyzeImage(File image) async {
    // 이미지 분석 로직 구현
    return [
      DogBreed(
        id: '1',
        name: '골든 리트리버',
        origin: '영국',
        description: '친절하고 충성스러운 견종입니다.',
        imageUrl: 'https://example.com/golden.jpg',
      ),
    ];
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

    // 각 견종에 대해 위키백과 이미지 가져오기
    for (var i = 0; i < breeds.length; i++) {
      final imageUrl = await getWikipediaImage(breeds[i].name, languageCode);
      if (imageUrl != null) {
        breeds[i] = breeds[i].copyWith(imageUrl: imageUrl);
      }
    }

    return breeds;
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
                return getNoInfoMessage(languageCode) + ' ' + enExtract;
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
      case 'ja':
        return '(英語)';
      case 'zh':
        return '(英文)';
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
      case 'ja':
        return 'この犬種についてのウィキペディア情報が見つかりません。';
      case 'zh':
        return '找不到关于这个品种的维基百科信息。';
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
      case 'ja':
        return 'ウィキペディア情報の取得中にエラーが発生しました: $error';
      case 'zh':
        return '获取维基百科信息时发生错误: $error';
      default:
        return 'Error occurred while fetching Wikipedia information: $error';
    }
  }
}
