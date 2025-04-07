import 'dart:io';
import '../models/dog_breed_model.dart';

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
      )
    ];
  }

  Future<List<DogBreed>> getAllBreeds() async {
    // 모든 견종 정보 가져오기
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

  Future<String> getWikipediaContent(String breedName) async {
    // 위키백과 내용 가져오기 로직
    await Future.delayed(Duration(seconds: 1)); // 임시 지연
    return '이 견종은 매우 친절하고 충성스러운 성격을 가지고 있습니다. 가족과 함께 지내기 좋은 견종으로 알려져 있습니다.';
  }
}
