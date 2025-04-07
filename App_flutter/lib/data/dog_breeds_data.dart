// lib/data/dog_breeds_data.dart
import '../models/dog_breed_model.dart';

class DogBreedsData {
  static List<DogBreed> getInitialBreeds() {
    return [
      DogBreed(
        id: '1',
        name: '골든 리트리버',
        origin: '영국',
        description: '친절하고 충성스러운 견종입니다.',
      ),
      DogBreed(
        id: '2',
        name: '웰시 코기',
        origin: '웨일스',
        description: '활발하고 지능적인 견종으로 짧은 다리와 긴 몸통이 특징입니다.',
      ),
      DogBreed(
          id: '3',
          name: '진돗개',
          origin: '진도',
          description: 'description'
      ),
    ];
  }
}
