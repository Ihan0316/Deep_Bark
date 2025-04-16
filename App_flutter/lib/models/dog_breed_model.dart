class DogBreed {
  final int id;
  final String nameEn;
  final String nameKo;
  final String originEn;
  final String originKo;
  final String sizeEn;
  final String sizeKo;
  final String lifespanEn;
  final String lifespanKo;
  final String weight;
  final String descriptionEn;
  final String descriptionKo;
  final String imageUrl;
  final LatLng? originLatLng;
  final double? confidence;

  DogBreed({
    required this.id,
    required this.nameEn,
    required this.nameKo,
    required this.originEn,
    required this.originKo,
    required this.sizeEn,
    required this.sizeKo,
    required this.lifespanEn,
    required this.lifespanKo,
    required this.weight,
    required this.descriptionEn,
    required this.descriptionKo,
    required this.imageUrl,
    this.originLatLng,
    this.confidence,
  });

  DogBreed copyWith({
    int? id,
    String? nameEn,
    String? nameKo,
    String? originEn,
    String? originKo,
    String? sizeEn,
    String? sizeKo,
    String? lifespanEn,
    String? lifespanKo,
    String? weight,
    String? descriptionEn,
    String? descriptionKo,
    String? imageUrl,
    LatLng? originLatLng,
    double? confidence,
  }) {
    return DogBreed(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameKo: nameKo ?? this.nameKo,
      originEn: originEn ?? this.originEn,
      originKo: originKo ?? this.originKo,
      sizeEn: sizeEn ?? this.sizeEn,
      sizeKo: sizeKo ?? this.sizeKo,
      lifespanEn: lifespanEn ?? this.lifespanEn,
      lifespanKo: lifespanKo ?? this.lifespanKo,
      weight: weight ?? this.weight,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionKo: descriptionKo ?? this.descriptionKo,
      imageUrl: imageUrl ?? this.imageUrl,
      originLatLng: originLatLng ?? this.originLatLng,
      confidence: confidence ?? this.confidence,
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng({required this.latitude, required this.longitude});
}
