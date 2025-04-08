// lib/screens/scan_result_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/dog_breed_model.dart';
import '../services/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/locale_provider.dart';

class ScanResultScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final List<DogBreed> results = args['results'];
    final String imagePath = args['imagePath'];
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('analysis_result')),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              SizedBox(height: 24),

              Text(
                localizations.translate('analysis_result'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 16),

              ...List.generate(
                results.length > 3 ? 3 : results.length,
                    (index) => _buildResultItem(context, results[index], index),
              ),

              SizedBox(height: 24),

              if (results.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/encyclopedia',
                      arguments: {'breed': results[0]},
                    );
                  },
                  icon: Icon(Icons.book),
                  label: Text(localizations.translate('learn_more_in_encyclopedia')),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(BuildContext context, DogBreed breed, int index) {
    final localizations = AppLocalizations.of(context);
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: breed.imageUrl != null
              ? NetworkImage(breed.imageUrl!)
              : AssetImage('assets/images/dog_placeholder.png') as ImageProvider,
        ),
        title: Text(
          '${index + 1}. ${breed.name}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${localizations.translate('origin')}: ${breed.origin}'),
        trailing: Text(
          '${localizations.translate('match_rate')}: ${(0.9 - (index * 0.15)).toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/breed_detail',
            arguments: {'breed': breed},
          );
        },
      ),
    );
  }
}
