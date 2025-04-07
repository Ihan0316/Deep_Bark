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
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng({required this.latitude, required this.longitude});
}
