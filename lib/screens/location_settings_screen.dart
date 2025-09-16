import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider.dart';
import '../models/location_context.dart';

class LocationSettingsScreen extends ConsumerStatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  ConsumerState<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends ConsumerState<LocationSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countryController = TextEditingController();
  final _regionController = TextEditingController();
  final _cityController = TextEditingController();
  final _localeController = TextEditingController();
  
  bool _locationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final locationState = ref.read(locationProvider);
    final location = locationState.location;
    
    if (location != null) {
      _countryController.text = location.country;
      _regionController.text = location.region ?? '';
      _cityController.text = location.city ?? '';
      _localeController.text = location.locale ?? '';
      _locationEnabled = true;
    }
  }

  @override
  void dispose() {
    _countryController.dispose();
    _regionController.dispose();
    _cityController.dispose();
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location & Language'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Location Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Location',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (locationState.location != null) ...[
                    _buildInfoRow('Country', locationState.location!.country),
                    if (locationState.location!.region != null)
                      _buildInfoRow('Region', locationState.location!.region!),
                    if (locationState.location!.city != null)
                      _buildInfoRow('City', locationState.location!.city!),
                    _buildInfoRow('Locale', locationState.location!.locale ?? 'Auto'),
                    _buildInfoRow('Confidence', '${(locationState.location!.confidence * 100).toInt()}%'),
                    _buildInfoRow('Source', locationState.location!.source.join(', ')),
                  ] else ...[
                    const Text(
                      'Location not detected',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Location Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Enable/Disable Location
                  SwitchListTile(
                    title: const Text(
                      'Use Location for Personalization',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Allow app to use your location to show regional content',
                      style: TextStyle(color: Colors.grey),
                    ),
                    value: _locationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _locationEnabled = value;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Refresh Location Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: locationState.isLoading ? null : _refreshLocation,
                      icon: locationState.isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(locationState.isLoading ? 'Detecting...' : 'Refresh Location'),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Manual Override
                  ExpansionTile(
                    title: const Text(
                      'Manual Override',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Override detected location',
                      style: TextStyle(color: Colors.grey),
                    ),
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _countryController,
                              decoration: const InputDecoration(
                                labelText: 'Country (e.g., IN, US)',
                                labelStyle: TextStyle(color: Colors.grey),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                            TextFormField(
                              controller: _regionController,
                              decoration: const InputDecoration(
                                labelText: 'Region (e.g., MH, CA)',
                                labelStyle: TextStyle(color: Colors.grey),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                            TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'City (optional)',
                                labelStyle: TextStyle(color: Colors.grey),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                            TextFormField(
                              controller: _localeController,
                              decoration: const InputDecoration(
                                labelText: 'Locale (e.g., hi-IN, en-US)',
                                labelStyle: TextStyle(color: Colors.grey),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveManualLocation,
                                child: const Text('Save Manual Location'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Privacy Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[900]?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.privacy_tip, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Privacy Notice',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• We only store coarse location (country/region/city)\n'
                    '• No GPS coordinates or precise location is stored\n'
                    '• Location is used only for content personalization\n'
                    '• You can disable location tracking anytime',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshLocation() async {
    await ref.read(locationProvider.notifier).refreshLocation();
  }

  void _saveManualLocation() {
    if (_formKey.currentState!.validate()) {
      final location = LocationContext(
        source: ['manual_override'],
        country: _countryController.text.trim().toUpperCase(),
        region: _regionController.text.trim().isNotEmpty 
            ? _regionController.text.trim().toUpperCase() 
            : null,
        city: _cityController.text.trim().isNotEmpty 
            ? _cityController.text.trim() 
            : null,
        locale: _localeController.text.trim().isNotEmpty 
            ? _localeController.text.trim() 
            : null,
        confidence: 1.0, // Manual override has full confidence
      );
      
      ref.read(locationProvider.notifier).setLocation(location);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
