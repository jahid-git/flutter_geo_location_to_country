import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Your Country',
      home: CountryScreen(),
    );
  }
}

class CountryScreen extends StatefulWidget {
  const CountryScreen({super.key});

  @override
  CountryScreenState createState() => CountryScreenState();
}

class CountryScreenState extends State<CountryScreen> {
  String _country = 'Loading...';
  String? _error;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Location services are disabled';
          _country = 'Unable to determine location';
        });
        return;
      }

      // Check for location permissions
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Location permissions are denied';
            _country = 'Unable to determine location';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permissions are permanently denied';
          _country = 'Unable to determine location';
        });
        return;
      }

      // Get the current location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      _getCountryFromCoordinates(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _error = 'Error retrieving location: $e';
        _country = 'Unable to determine location';
      });
    }
  }

  Future<void> _getCountryFromCoordinates(double latitude, double longitude) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        if (address != null && address['country'] != null) {
          setState(() {
            _country = address['country'];
          });
        } else {
          setState(() {
            _country = 'Unable to determine country';
          });
        }
      } else {
        setState(() {
          _country = 'Unable to determine location';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching location data: $e';
        _country = 'Unable to determine location';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Country'),
      ),
      body: Center(
        child: _error != null
            ? Text(_error!)
            : Text(
                _country,
                style: const TextStyle(fontSize: 24),
              ),
      ),
    );
  }
}