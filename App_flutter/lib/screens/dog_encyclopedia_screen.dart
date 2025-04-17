// lib/screens/dog_encyclopedia_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/dog_breed_service.dart';
import '../models/dog_breed_model.dart' as models;
import '../services/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/locale_provider.dart';
import 'dart:math';

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
  
  // 확장된 마커 상태 관리
  String? _expandedMarkerId;
  Set<Marker> _expandedMarkers = {};
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isMapReady = false;
  Set<Polyline> _connectionLines = {};
  double _initialZoom = 2.0; // 초기 줌 레벨 저장

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
    _connectionLines.clear();
    
    // 국가별로 견종들을 그룹화
    Map<String, List<models.DogBreed>> breedsByCountry = {};
    for (var breed in _filteredBreeds.where((breed) => breed.originLatLng != null)) {
      String countryKey = '${breed.originLatLng!.latitude},${breed.originLatLng!.longitude}';
      if (!breedsByCountry.containsKey(countryKey)) {
        breedsByCountry[countryKey] = [];
      }
      breedsByCountry[countryKey]!.add(breed);
    }

    // 각 국가별로 마커 생성
    for (var entry in breedsByCountry.entries) {
      var breeds = entry.value;
      var coordinates = entry.key.split(',');
      var position = LatLng(
        double.parse(coordinates[0]),
        double.parse(coordinates[1])
      );

      _markers.add(
        Marker(
          markerId: MarkerId(entry.key),
          position: position,
          icon: await _createStackedMarker(breeds),
          onTap: () => _handleMarkerTap(entry.key, breeds, position),
          zIndex: 2,
        ),
      );
    }
  }

  Future<BitmapDescriptor> _createStackedMarker(List<models.DogBreed> breeds) async {
    final int size = 100;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // 흰색 원형 배경
    canvas.drawCircle(
      Offset(size/2, size/2),
      size/2,
      Paint()..color = Colors.white,
    );
    
    // 대표 이미지 (첫 번째 견종) 로드
    final imageProvider = AssetImage(breeds.first.imageUrl!);
    final ImageStream stream = imageProvider.resolve(ImageConfiguration());
    final Completer<void> completer = Completer<void>();
    late ImageInfo imageInfo;
    
    stream.addListener(ImageStreamListener((info, _) {
      imageInfo = info;
      completer.complete();
    }));
    
    await completer.future;
    
    // 이미지를 원형으로 클립
    canvas.clipPath(Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size/2, size/2),
        radius: size/2,
      )));
    
    // 이미지 그리기
    canvas.drawImageRect(
      imageInfo.image,
      Rect.fromLTWH(0, 0, imageInfo.image.width.toDouble(), imageInfo.image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      Paint(),
    );
    
    // 갈색 테두리
    canvas.drawCircle(
      Offset(size/2, size/2),
      size/2,
      Paint()
        ..color = Colors.brown
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    
    // 견종 수 표시
    if (breeds.length > 1) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '+${breeds.length - 1}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(2.0, 2.0),
                blurRadius: 3.0,
                color: Colors.brown,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size - textPainter.width - 10, size - textPainter.height - 10),
      );
    }
    
    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  void _handleMarkerTap(String markerId, List<models.DogBreed> breeds, LatLng position) async {
    // 하단 시트 표시
    _showBreedBottomSheet(context, breeds);

    if (_expandedMarkerId == markerId) {
      // 이미 확장된 마커를 다시 탭하면 확장 상태 해제
      setState(() {
        _expandedMarkerId = null;
        _expandedMarkers.clear();
        _connectionLines.clear();
      });
      return;
    }

    setState(() {
      _expandedMarkerId = markerId;
      _expandedMarkers.clear();
      _connectionLines.clear();
    });

    // 최대 7개까지 표시
    final displayBreeds = breeds.take(7).toList();
    final double radius = 0.003; // 약 300m
    final int count = displayBreeds.length;
    
    // 부채꼴의 시작 각도와 끝 각도 설정 (120도 범위로 확장)
    final double startAngle = -60.0; // 시작 각도
    final double totalSpread = 120.0; // 전체 펼침 각도

    List<LatLng> markerPositions = [];
    markerPositions.add(position); // 중앙 마커 위치 추가

    for (int i = 0; i < count; i++) {
      final breed = displayBreeds[i];
      // 부채꼴 내에서 균등하게 각도 분배
      final double angle = startAngle + (totalSpread / (count - 1)) * i;
      final double angleInRadians = angle * (pi / 180);
      
      // 위도/경도 계산
      final double lat = position.latitude + (radius * cos(angleInRadians));
      final double lng = position.longitude + (radius * sin(angleInRadians));
      final LatLng markerPosition = LatLng(lat, lng);
      markerPositions.add(markerPosition);

      final markerIcon = await _createBreedMarker(breed);
      
      setState(() {
        _expandedMarkers.add(
          Marker(
            markerId: MarkerId('${markerId}_expanded_$i'),
            position: markerPosition,
            icon: markerIcon,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/breed_detail',
                arguments: {'breed': breed},
              );
            },
            zIndex: 2, // 선보다 위에 표시
          ),
        );

        // 중앙 마커와 현재 마커를 연결하는 선 추가
        _connectionLines.add(
          Polyline(
            polylineId: PolylineId('connection_$i'),
            points: [position, markerPosition],
            color: Colors.brown.withOpacity(0.6),
            width: 2,
            patterns: [
              PatternItem.dash(10), // 점선 효과
              PatternItem.gap(5),
            ],
            zIndex: 1, // 마커보다 아래에 표시
          ),
        );
      });
    }

    // 지도 중심 이동 및 줌 레벨 조정
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 5.0,
        ),
      ),
    );
  }

  Future<BitmapDescriptor> _createBreedMarker(models.DogBreed breed) async {
    final int size = 80;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // 흰색 원형 배경
    canvas.drawCircle(
      Offset(size/2, size/2),
      size/2,
      Paint()..color = Colors.white,
    );
    
    // 이미지 로드
    final imageProvider = AssetImage(breed.imageUrl!);
    final ImageStream stream = imageProvider.resolve(ImageConfiguration());
    final Completer<void> completer = Completer<void>();
    late ImageInfo imageInfo;
    
    stream.addListener(ImageStreamListener((info, _) {
      imageInfo = info;
      completer.complete();
    }));
    
    await completer.future;
    
    // 이미지를 원형으로 클립
    canvas.clipPath(Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size/2, size/2),
        radius: size/2,
      )));
    
    // 이미지 그리기
    canvas.drawImageRect(
      imageInfo.image,
      Rect.fromLTWH(0, 0, imageInfo.image.width.toDouble(), imageInfo.image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      Paint(),
    );
    
    // 갈색 테두리
    canvas.drawCircle(
      Offset(size/2, size/2),
      size/2,
      Paint()
        ..color = Colors.brown
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    
    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  void _showBreedBottomSheet(BuildContext context, List<models.DogBreed> breeds) {
    // 견종 개수에 따른 시트 높이 계산
    double calculateSheetHeight() {
      const double headerHeight = 60.0; // 상단 헤더 높이 (드래그 핸들 + 국가명)
      const double padding = 32.0; // 상하 패딩
      const double gridSpacing = 16.0; // 그리드 간격
      
      if (breeds.length <= 3) {
        // 가로 스크롤 레이아웃일 때
        const double cardHeight = 160.0; // 카드 높이 (이미지 120 + 텍스트 40)
        return headerHeight + padding + cardHeight;
      } else {
        // 그리드 레이아웃일 때
        const double cardHeight = 140.0; // 카드 높이 (이미지 100 + 텍스트 40)
        int rows = (breeds.length / 3).ceil();
        return headerHeight + padding + (rows * cardHeight) + ((rows - 1) * gridSpacing);
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: calculateSheetHeight(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              height: 4,
              width: 40,
              margin: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              _localeProvider.locale.languageCode == 'ko' 
                ? breeds.first.originKo 
                : breeds.first.originEn,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: breeds.length <= 3
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.all(16),
                    itemCount: breeds.length,
                    itemBuilder: (context, index) {
                      final breed = breeds[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/breed_detail',
                            arguments: {'breed': breed},
                          );
                        },
                        child: Container(
                          width: 120,
                          margin: EdgeInsets.only(right: 16),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: Image.asset(
                                  breed.imageUrl!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _cleanBreedName(_localeProvider.locale.languageCode == 'ko' 
                                  ? breed.nameKo 
                                  : breed.nameEn),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: breeds.length,
                    itemBuilder: (context, index) {
                      final breed = breeds[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/breed_detail',
                            arguments: {'breed': breed},
                          );
                        },
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Image.asset(
                                breed.imageUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _cleanBreedName(_localeProvider.locale.languageCode == 'ko' 
                                ? breed.nameKo 
                                : breed.nameEn),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    ).then((_) {
      // 하단 시트가 닫힐 때 마커의 확장 상태 초기화 및 줌 레벨 복원
      setState(() {
        _expandedMarkerId = null;
        _expandedMarkers.clear();
        _connectionLines.clear();
      });
      
      // 지도 줌 레벨을 초기값으로 복원
      _mapController?.animateCamera(
        CameraUpdate.zoomTo(_initialZoom),
      );
    });
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
                    zoom: _initialZoom,
                  ),
                  markers: {..._markers, ..._expandedMarkers},
                  polylines: _connectionLines,
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
                  onTap: (_) {
                    // 지도를 탭하면 확장된 마커들과 선들 닫기
                    if (_expandedMarkerId != null) {
                      setState(() {
                        _expandedMarkerId = null;
                        _expandedMarkers.clear();
                        _connectionLines.clear();
                      });
                    }
                  },
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

  // dart:math의 pi 상수를 사용하기 위한 상수 정의
  static const double pi = 3.1415926535897932;
}
