// lib/screens/dog_encyclopedia_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/dog_breed_service.dart';
import '../models/dog_breed_model.dart' as models;

class DogEncyclopediaScreen extends StatefulWidget {
  @override
  _DogEncyclopediaScreenState createState() => _DogEncyclopediaScreenState();
}

class _DogEncyclopediaScreenState extends State<DogEncyclopediaScreen> with SingleTickerProviderStateMixin {
  final DogBreedService _breedService = DogBreedService();
  List<models.DogBreed> _breeds = [];
  List<models.DogBreed> _filteredBreeds = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

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
      // 지도 탭으로 이동할 때 필요한 초기화 작업
      setState(() {
        _setupMarkers();
      });
    }
  }

  Future<void> _loadBreeds() async {
    try {
      final breeds = await _breedService.getAllBreeds();
      setState(() {
        _breeds = breeds;
        _filteredBreeds = breeds;
        _isLoading = false;
        _setupMarkers();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('품종 정보를 불러오는데 실패했습니다: ${e.toString()}')),
      );
    }
  }

  void _setupMarkers() {
    _markers = _breeds.where((breed) => breed.originLatLng != null).map((breed) {
      return Marker(
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
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      );
    }).toSet();
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('멍멍백서'),
        bottom: TabBar(
          controller: _tabController,
          splashFactory: NoSplash.splashFactory,
          tabs: [
            Tab(icon: Icon(Icons.list), text: '목록'),
            Tab(icon: Icon(Icons.map), text: '세계지도'),
          ],
          labelColor: Colors.white, // 선택된 탭의 텍스트 색상
          unselectedLabelColor: Colors.grey, // 선택되지 않은 탭의 텍스트 색상
          indicatorColor: Colors.white, // 선택된 탭 아래 표시되는 인디케이터 색상

        ),
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '품종 또는 원산지 검색',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _filterBreeds,
            ),
          ),

          // 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: NeverScrollableScrollPhysics(), // 탭 스와이프 비활성화
              children: [
                // 목록 탭
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _filteredBreeds.isEmpty
                    ? Center(child: Text('검색 결과가 없습니다'))
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
                      subtitle: Text(breed.origin),
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

                // 지도 탭
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(30, 0),
                        zoom: 2,
                      ),
                      markers: _markers,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                        Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
