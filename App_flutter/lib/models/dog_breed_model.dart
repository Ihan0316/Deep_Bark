class DogBreed {
  final String id;
  final String name;
  final String origin;
  final String description;
  final String? imageUrl;
  final String? size;
  final String? weight;
  final String? lifespan;
  final String? temperament;
  final LatLng? originLatLng;
  final double? confidence; // 신뢰도 필드 추가

  DogBreed({
    required this.id,
    required this.name,
    required this.origin,
    required this.description,
    this.imageUrl,
    this.size,
    this.weight,
    this.lifespan,
    this.temperament,
    this.originLatLng,
    this.confidence, // 생성자에 추가
  });

  // copyWith 메서드 수정
  DogBreed copyWith({
    String? id,
    String? name,
    String? origin,
    String? description,
    String? imageUrl,
    String? size,
    String? weight,
    String? lifespan,
    String? temperament,
    LatLng? originLatLng,
    double? confidence, // copyWith에 추가
  }) {
    return DogBreed(
      id: id ?? this.id,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      size: size ?? this.size,
      weight: weight ?? this.weight,
      lifespan: lifespan ?? this.lifespan,
      temperament: temperament ?? this.temperament,
      originLatLng: originLatLng ?? this.originLatLng,
      confidence: confidence ?? this.confidence, // 반환에 추가
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng({required this.latitude, required this.longitude});
}
