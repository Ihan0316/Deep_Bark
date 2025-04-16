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
  late LocaleProvider _localeProvider;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isMapReady = false;

  String _cleanBreedName(String name) {
    return name.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _localeProvider = Provider.of<LocaleProvider>(context, listen: false);
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
      setState(() {
        _isLoading = true;
      });

      final breeds = await _breedService.getAllBreeds();

      // 국가별 좌표 매핑
      final Map<String, models.LatLng> countryCoordinates = {
        // 한글 국가명
        '영국': models.LatLng(latitude: 51.5074, longitude: -0.1278),
        '독일': models.LatLng(latitude: 52.5200, longitude: 13.4050),
        '프랑스': models.LatLng(latitude: 48.8566, longitude: 2.3522),
        '미국': models.LatLng(latitude: 37.0902, longitude: -95.7129),
        '일본': models.LatLng(latitude: 35.6762, longitude: 139.6503),
        '대한민국': models.LatLng(latitude: 37.5665, longitude: 126.9780),
        '중국': models.LatLng(latitude: 35.8617, longitude: 104.1954),
        '러시아': models.LatLng(latitude: 55.7558, longitude: 37.6173),
        '이탈리아': models.LatLng(latitude: 41.9028, longitude: 12.4964),
        '몰타': models.LatLng(latitude: 35.9375, longitude: 14.3754),
        '멕시코': models.LatLng(latitude: 23.6345, longitude: -102.5528),
        // 깨진 문자열에 대한 매핑 추가
        'íëì¤': models.LatLng(latitude: 48.8566, longitude: 2.3522), // 프랑스
        'ì¤êµ­': models.LatLng(latitude: 35.8617, longitude: 104.1954), // 중국
        'ìêµ­': models.LatLng(latitude: 51.5074, longitude: -0.1278), // 영국
        'ëì¼': models.LatLng(latitude: 52.5200, longitude: 13.4050), // 독일
        'ë¬ìì': models.LatLng(latitude: 55.7558, longitude: 37.6173), // 러시아
        'ì¼ë³¸': models.LatLng(latitude: 35.6762, longitude: 139.6503), // 일본
      };

      List<models.DogBreed> updatedBreeds = [];
      for (var breed in breeds) {
        if (breed.originLatLng == null) {
          try {
            // 국가 이름 추출 및 정제
            String originText = breed.originKo;
            String countryName = '';

            // 괄호 안의 내용 제거
            originText = originText.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
            
            // 쉼표나 공백으로 구분된 경우 첫 번째 부분만 사용
            if (originText.contains(',')) {
              countryName = originText.split(',')[0].trim();
            } else if (originText.contains(' ')) {
              countryName = originText.split(' ')[0].trim();
            } else {
              countryName = originText;
            }

            // 매핑된 좌표가 있는지 확인
            if (countryCoordinates.containsKey(countryName)) {
              updatedBreeds.add(breed.copyWith(originLatLng: countryCoordinates[countryName]));
            } else {
              print('좌표를 찾을 수 없음: ${breed.nameEn} (원산지: $countryName)');
              // 깨진 문자열로도 한번 더 시도
              if (countryCoordinates.containsKey(breed.originKo)) {
                updatedBreeds.add(breed.copyWith(originLatLng: countryCoordinates[breed.originKo]));
              } else {
                // 국가 이름 매핑 시도
                String? mappedCountry = _mapCountryName(countryName);
                if (mappedCountry != null && countryCoordinates.containsKey(mappedCountry)) {
                  updatedBreeds.add(breed.copyWith(originLatLng: countryCoordinates[mappedCountry]));
                } else {
                  updatedBreeds.add(breed);
                }
              }
            }
          } catch (e) {
            print('좌표 처리 오류 (${breed.nameEn}): ${e.toString()}');
            updatedBreeds.add(breed);
          }
        } else {
          updatedBreeds.add(breed);
        }
      }

      if (mounted) {
        setState(() {
          _breeds = updatedBreeds;
          _filteredBreeds = updatedBreeds;
          _isLoading = false;
        });

        await _setupMarkers();
      }
    } catch (e) {
      print('견종 목록 로딩 에러: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _breeds = [];
          _filteredBreeds = [];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('데이터를 불러오는데 실패했습니다'),
                SizedBox(height: 4),
                Text(
                  '네트워크 연결을 확인하고 다시 시도해주세요',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            action: SnackBarAction(
              label: '다시 시도',
              onPressed: () {
                _loadBreeds();
              },
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }
    }
  }

  Future<void> _setupMarkers() async {
    _markers = Set<Marker>();
    for (var breed in _filteredBreeds.where((breed) => breed.originLatLng != null)) {
      Marker pawMarker = await GoogleMapsCustomMarker.createCustomMarker(
        marker: Marker(
          markerId: MarkerId(breed.id.toString()),
          position: LatLng(
              breed.originLatLng!.latitude,
              breed.originLatLng!.longitude
          ),
          infoWindow: InfoWindow(
            title: _cleanBreedName(_localeProvider.locale.languageCode == 'ko' ? breed.nameKo : breed.nameEn),
            snippet: _localeProvider.locale.languageCode == 'ko' ? breed.originKo : breed.originEn,
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
          return (_localeProvider.locale.languageCode == 'ko' ? breed.nameKo : breed.nameEn)
              .toLowerCase()
              .contains(query.toLowerCase()) ||
              (_localeProvider.locale.languageCode == 'ko' ? breed.originKo : breed.originEn)
              .toLowerCase()
              .contains(query.toLowerCase());
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
                        child: Image.asset(
                          breed.imageUrl!,
                          width: MediaQuery.of(context).size.width * 0.12,
                          height: MediaQuery.of(context).size.width * 0.12,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');
                            return Container(
                              width: MediaQuery.of(context).size.width * 0.12,
                              height: MediaQuery.of(context).size.width * 0.12,
                              color: Colors.grey[300],
                              child: Icon(Icons.pets, color: Colors.grey[600]),
                            );
                          },
                        ),
                      )
                          : Container(
                        width: MediaQuery.of(context).size.width * 0.12,
                        height: MediaQuery.of(context).size.width * 0.12,
                        color: Colors.grey[300],
                        child: Icon(Icons.pets, color: Colors.grey[600]),
                      ),
                      title: Text(
                        _cleanBreedName(_localeProvider.locale.languageCode == 'ko' ? breed.nameKo : breed.nameEn),
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                        ),
                      ),
                      subtitle: Text(
                        '${localizations.translate('origin')}: ${_localeProvider.locale.languageCode == 'ko' ? breed.originKo : breed.originEn}',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.035,
                        ),
                      ),
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

  // 국가 이름 매핑 함수 추가
  String? _mapCountryName(String countryName) {
    final Map<String, String> countryNameMap = {
      'íëì¤': '프랑스',
      'ì¤êµ­': '중국',
      'ìêµ­': '영국',
      'ëì¼': '독일',
      'ë¬ìì': '러시아',
      'ì¼ë³¸': '일본',
      '프랑스': '프랑스',
      '중국': '중국',
      '영국': '영국',
      '독일': '독일',
      '러시아': '러시아',
      '일본': '일본',
      '대한민국': '대한민국',
      '이탈리아': '이탈리아',
      '몰타': '몰타',
      '멕시코': '멕시코',
    };
    return countryNameMap[countryName];
  }
}
