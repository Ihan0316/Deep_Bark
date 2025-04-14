// lib/screens/dog_encyclopedia_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/dog_breed_service.dart';
import '../models/dog_breed_model.dart' as models;
import 'package:geocoding/geocoding.dart';
import '../services/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/locale_provider.dart';
import 'package:google_maps_custom_marker/google_maps_custom_marker.dart';

class DogEncyclopediaScreen extends StatefulWidget {
  @override
  _DogEncyclopediaScreenState createState() => _DogEncyclopediaScreenState();
}

class _DogEncyclopediaScreenState extends State<DogEncyclopediaScreen>
    with SingleTickerProviderStateMixin {
  final DogBreedService _breedService = DogBreedService();
  List<models.DogBreed> _breeds = [];
  List<models.DogBreed> _filteredBreeds = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadBreeds();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.index == 1) {
      _setupMarkers().then((_) => setState(() {}));
    }
  }

  Future<void> _loadBreeds() async {
    try {
      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
      final languageCode = localeProvider.locale.languageCode;

      final breeds = await _breedService.getAllBreeds(languageCode);

      List<models.DogBreed> updatedBreeds = [];
      for (var breed in breeds) {
        if (breed.originLatLng == null) {
          try {
            final locations = await locationFromAddress(breed.origin);
            if (locations.isNotEmpty) {
              final location = locations.first;
              final latLng = models.LatLng(
                  latitude: location.latitude,
                  longitude: location.longitude
              );
              updatedBreeds.add(breed.copyWith(originLatLng: latLng));
            } else {
              updatedBreeds.add(breed);
            }
          } catch (e) {
            print('지오코딩 오류: ${e.toString()}');
            updatedBreeds.add(breed);
          }
        } else {
          updatedBreeds.add(breed);
        }
      }

      setState(() {
        _breeds = updatedBreeds;
        _filteredBreeds = updatedBreeds;
      });

      _setupMarkers().then((_) => setState(() {
        _isLoading = false;
      }));
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            localizations.translate('failed_to_load_breeds') +
                ': ${e.toString()}')),
      );
    }
  }

  Future<void> _setupMarkers() async {
    _markers = Set<Marker>();
    for (var breed in _filteredBreeds.where((breed) => breed.originLatLng != null)) {
      Marker pawMarker = await GoogleMapsCustomMarker.createCustomMarker(
        marker: Marker(
          markerId: MarkerId(breed.id),
          position: LatLng(
              breed.originLatLng!.latitude,
              breed.originLatLng!.longitude
          ),
          infoWindow: InfoWindow(
            title: breed.name,
            snippet: breed.origin,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/breed_detail',
                arguments: {'breed': breed},
              );
            },
          ),
        ),
        shape: MarkerShape.circle,
        backgroundColor: Colors.white,
        title: '🐾',
        textStyle: TextStyle(fontSize: 15, color: Colors.brown)
      );
      _markers.add(pawMarker);
    }
  }

  void _filterBreeds(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBreeds = _breeds;
      } else {
        _filteredBreeds = _breeds.where((breed) {
          return breed.name.toLowerCase().contains(query.toLowerCase()) ||
              breed.origin.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
      _setupMarkers().then((_) => setState(() {}));
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('dog_encyclopedia')),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          splashFactory: NoSplash.splashFactory,
          tabs: [
            Tab(icon: Icon(Icons.list), text: localizations.translate('list')),
            Tab(icon: Icon(Icons.map), text: localizations.translate('world_map')),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.white,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: localizations.translate('search_breed_or_origin'),
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _filterBreeds,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _filteredBreeds.isEmpty
                    ? Center(child: Text(localizations.translate('no_search_results')))
                    : ListView.builder(
                  itemCount: _filteredBreeds.length,
                  itemBuilder: (context, index) {
                    final breed = _filteredBreeds[index];
                    return ListTile(
                      leading: breed.imageUrl != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          breed.imageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[300],
                              child: Icon(Icons.pets, color: Colors.grey[600]),
                            );
                          },
                        ),
                      )
                          : Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[300],
                        child: Icon(Icons.pets, color: Colors.grey[600]),
                      ),
                      title: Text(breed.name),
                      subtitle: Text('${localizations.translate('origin')}: ${breed.origin}'),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/breed_detail',
                          arguments: {'breed': breed},
                        );
                      },
                    );
                  },
                ),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(30, 0),
                    zoom: 2,
                  ),
                  markers: _markers,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    // 지도 스타일 최적화
                    controller.setMapStyle('''[
                      {
                        "featureType": "all",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#f5f5f5"
                          }
                        ]
                      },
                      {
                        "featureType": "water",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#c9c9c9"
                          }
                        ]
                      }
                    ]''');
                  },
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                  // 지도 성능 최적화 설정
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                  minMaxZoomPreference: MinMaxZoomPreference(1, 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
