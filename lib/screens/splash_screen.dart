import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../database/database_helper.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkDatabaseAndNavigate();
  }

  Future<void> _checkDatabaseAndNavigate() async {
    try {
      // Initialize database
      final dbHelper = DatabaseHelper();
      await dbHelper.database;

      // Wait for 2 seconds to show splash screen
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Navigate to login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('❌ Splash screen error: $e');
      if (mounted) {
        // Show error and retry option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing database: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _checkDatabaseAndNavigate();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF26A69A), // Teal
              Color(0xFF004D40), // Dark Teal
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.storage,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              // App title
              const Text(
                'Offline Posts Manager',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              // Subtitle
              const Text(
                'Store Your Posts Locally',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 50),
              // Loading indicator
              const SpinKitFadingCircle(
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 20),
              // Loading text
              const Text(
                'Initializing Database...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
