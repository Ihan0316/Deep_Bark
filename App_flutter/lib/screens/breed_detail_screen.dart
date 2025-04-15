// lib/screens/breed_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/dog_breed_model.dart';
import '../services/dog_breed_service.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/locale_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BreedDetailScreen extends StatefulWidget {
  @override
  _BreedDetailScreenState createState() => _BreedDetailScreenState();
}

class _BreedDetailScreenState extends State<BreedDetailScreen> {
  final DogBreedService _breedService = DogBreedService();
  bool _isLoading = false;
  String? _wikiContent;
  bool _showWebView = false;
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWikiContent();
    });
  }

  Future<void> _loadWikiContent() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final DogBreed breed = args['breed'];
    final localizations = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      // 현재 언어 코드를 전달
      final content = await _breedService.getWikipediaContent(
          breed.name,
          localeProvider.locale.languageCode
      );
      setState(() {
        _wikiContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.translate('load_info_failed')}: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final DogBreed breed = args['breed'];
    final localizations = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    String getWikipediaUrl() {
      String langCode = localeProvider.locale.languageCode;
      switch(langCode) {
        case 'ko': return 'https://ko.wikipedia.org/wiki/${breed.name}';
        case 'en': return 'https://en.wikipedia.org/wiki/${breed.name}';
        default: return 'https://ko.wikipedia.org/wiki/${breed.name}';
      }
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(breed.name),
          actions: _showWebView ? [
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _showWebView = false;
                });
              },
            )
          ] : null,
        ),
        body: _showWebView
            ? WebViewWidget(controller: _webViewController)
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (breed.imageUrl != null)
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: CachedNetworkImage(
                    imageUrl: breed.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(Icons.pets, size: MediaQuery.of(context).size.width * 0.2, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.translate('basic_info'),
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.05,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            _buildInfoRow(localizations.translate('origin'), breed.origin ?? '-'),
                            _buildInfoRow(localizations.translate('size'), breed.size ?? '-'),
                            _buildInfoRow(localizations.translate('weight'), breed.weight ?? '-'),
                            _buildInfoRow(localizations.translate('lifespan'), breed.lifespan ?? '-'),
                            _buildInfoRow(localizations.translate('temperament'), breed.temperament ?? '-'),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    Text(
                      localizations.translate('detailed_description'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),

                    _isLoading
                        ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                        : _wikiContent == null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                localizations.translate('cannot_load_details'),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              _wikiContent!,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),

                    SizedBox(height: 20),

                    OutlinedButton.icon(
                      onPressed: () {
                        final String wikipediaUrl = getWikipediaUrl();
                        _webViewController.loadRequest(Uri.parse(wikipediaUrl));
                        setState(() {
                          _showWebView = true;
                        });
                      },
                      icon: Icon(Icons.open_in_new),
                      label: Text(localizations.translate('view_more_on_wikipedia')),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        foregroundColor: Colors.brown,
                        side: BorderSide(color: Colors.brown),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        )
    );
  }
}
