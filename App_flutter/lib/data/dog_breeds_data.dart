// lib/data/dog_breeds_data.dart
import '../models/dog_breed_model.dart';
class DogBreedsData {
  static List<DogBreed> getInitialBreeds([String languageCode = 'ko']) {
    switch (languageCode) {
      case 'en':
        return _getEnglishBreeds();
      case 'ko':
      default:
        return _getKoreanBreeds();
    }
  }
  static List<DogBreed> _getKoreanBreeds() {
    return [
      DogBreed(
        id: '1',
        name: '골든 리트리버',
        origin: '영국',
        description: '친절하고 충성스러운 견종입니다.',
        size: '중형~대형',
        weight: '25-34kg',
        lifespan: '10-12년',
        temperament: '친절함, 충성스러움, 지능적',
      ),
      DogBreed(
        id: '2',
        name: '웰시 코기',
        origin: '웨일스',
        description: '활발하고 지능적인 견종으로 짧은 다리와 긴 몸통이 특징입니다.',
        size: '소형',
        weight: '10-14kg',
        lifespan: '12-15년',
        temperament: '활발함, 지능적, 충성스러움',
      ),
      DogBreed(
        id: '3',
        name: '진돗개',
        origin: '대한민국 진도',
        description: '용맹하고 충성스러운 한국 토종견으로 사냥 능력이 뛰어납니다.',
        size: '중형',
        weight: '18-23kg',
        lifespan: '12-14년',
        temperament: '용맹함, 충성스러움, 독립적',
      ),
      DogBreed(
        id: '4',
        name: '시바견',
        origin: '일본',
        description: '독립적이고 용맹한 일본의 토종견으로 여우와 비슷한 외모가 특징입니다.',
        size: '소형',
        weight: '8-10kg',
        lifespan: '12-15년',
        temperament: '독립적, 용맹함, 경계심',
      ),
      DogBreed(
        id: '5',
        name: '치와와',
        origin: '멕시코',
        description: '세계에서 가장 작은 견종 중 하나로, 용감하고 활기찬 성격을 가진 멕시코 원산의 견종입니다.',
        size: '소형',
        weight: '1.5-3kg',
        lifespan: '12-20년',
        temperament: '경계심 강한, 용감한, 충성스러운, 활발한',
      ),

    ];
  }
  static List<DogBreed> _getEnglishBreeds() {
    return [
      DogBreed(
        id: '1',
        name: 'Golden Retriever',
        origin: 'United Kingdom',
        description: 'A friendly and loyal breed.',
        size: 'Medium to Large',
        weight: '25-34kg',
        lifespan: '10-12 years',
        temperament: 'Friendly, Loyal, Intelligent',
      ),
      DogBreed(
        id: '2',
        name: 'Welsh Corgi',
        origin: 'Wales',
        description: 'An active and intelligent breed with short legs and a long body.',
        size: 'Small',
        weight: '10-14kg',
        lifespan: '12-15 years',
        temperament: 'Active, Intelligent, Loyal',
      ),
      DogBreed(
        id: '3',
        name: 'Korean Jindo',
        origin: 'Jindo, South Korea',
        description: 'A brave and loyal Korean native breed with excellent hunting abilities.',
        size: 'Medium',
        weight: '18-23kg',
        lifespan: '12-14 years',
        temperament: 'Brave, Loyal, Independent',
      ),
      DogBreed(
        id: '4',
        name: 'Shiba Inu',
        origin: 'Japan',
        description: 'An independent and brave Japanese native breed with a fox-like appearance.',
        size: 'Small',
        weight: '8-10kg',
        lifespan: '12-15 years',
        temperament: 'Independent, Brave, Alert',
      ),
      DogBreed(
        id: '5',
        name: 'Chihuahua',
        origin: 'Mexico',
        description: 'One of the smallest dog breeds in the world, known for its courageous and lively temperament. Native to Mexico.',
        size: 'Small',
        weight: '1.5-3kg',
        lifespan: '12-20 years',
        temperament: 'Alert, Courageous, Loyal, Lively',
      ),
    ];
  }
}