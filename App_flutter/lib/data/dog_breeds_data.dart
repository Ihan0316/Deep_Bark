// lib/data/dog_breeds_data.dart
import '../models/dog_breed_model.dart';
class DogBreedsData {
  static List<DogBreed> getInitialBreeds([String languageCode = 'ko']) {
    switch (languageCode) {
      case 'en':
        return _getEnglishBreeds();
      case 'ja':
        return _getJapaneseBreeds();
      case 'zh':
        return _getChineseBreeds();
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
        name: '시바 이누',
        origin: '일본',
        description: '독립적이고 용맹한 일본의 토종견으로 여우와 비슷한 외모가 특징입니다.',
        size: '소형',
        weight: '8-10kg',
        lifespan: '12-15년',
        temperament: '독립적, 용맹함, 경계심',
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
    ];
  }
  static List<DogBreed> _getJapaneseBreeds() {
    return [
      DogBreed(
        id: '1',
        name: 'ゴールデン・レトリーバー',
        origin: 'イギリス',
        description: '優しく忠実な犬種です。',
        size: '中型〜大型',
        weight: '25-34kg',
        lifespan: '10-12年',
        temperament: '優しさ、忠実さ、知性',
      ),
      DogBreed(
        id: '2',
        name: 'ウェルシュ・コーギー',
        origin: 'ウェールズ',
        description: '活発で知的な犬種で、短い足と長い胴体が特徴です。',
        size: '小型',
        weight: '10-14kg',
        lifespan: '12-15年',
        temperament: '活発さ、知性、忠実さ',
      ),
      DogBreed(
        id: '3',
        name: '珍島犬',
        origin: '韓国 珍島',
        description: '勇敢で忠実な韓国原産の犬種で、優れた狩猟能力を持っています。',
        size: '中型',
        weight: '18-23kg',
        lifespan: '12-14年',
        temperament: '勇敢さ、忠実さ、独立心',
      ),
      DogBreed(
        id: '4',
        name: '柴犬',
        origin: '日本',
        description: '独立心が強く勇敢な日本原産の犬種で、キツネに似た外見が特徴です。',
        size: '小型',
        weight: '8-10kg',
        lifespan: '12-15年',
        temperament: '独立心、勇敢さ、警戒心',
      ),
    ];
  }
  static List<DogBreed> _getChineseBreeds() {
    return [
      DogBreed(
        id: '1',
        name: '金毛寻回犬',
        origin: '英国',
        description: '友善且忠诚的犬种。',
        size: '中型至大型',
        weight: '25-34公斤',
        lifespan: '10-12年',
        temperament: '友善、忠诚、聪明',
      ),
      DogBreed(
        id: '2',
        name: '威尔士柯基犬',
        origin: '威尔士',
        description: '活泼聪明的犬种，短腿长身是其特点。',
        size: '小型',
        weight: '10-14公斤',
        lifespan: '12-15年',
        temperament: '活泼、聪明、忠诚',
      ),
      DogBreed(
        id: '3',
        name: '珍岛犬',
        origin: '韩国珍岛',
        description: '勇敢忠诚的韩国本土犬种，拥有出色的狩猎能力。',
        size: '中型',
        weight: '18-23公斤',
        lifespan: '12-14年',
        temperament: '勇敢、忠诚、独立',
      ),
      DogBreed(
        id: '4',
        name: '柴犬',
        origin: '日本',
        description: '独立且勇敢的日本本土犬种，外形像狐狸。',
        size: '小型',
        weight: '8-10公斤',
        lifespan: '12-15年',
        temperament: '独立、勇敢、警惕',
      ),
    ];
  }
}