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
  });

  // copyWith 메서드 추가
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
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng({required this.latitude, required this.longitude});
}
