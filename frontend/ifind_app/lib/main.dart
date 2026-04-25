import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_profile_provider.dart';
import 'services/api_service.dart';
import 'views/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProfileProvider(),
      child: MaterialApp(
        title: 'IFind',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFF101622),
          appBarTheme: const AppBarTheme(elevation: 0),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({super.key});

  @override
  State<ConnectionTestScreen> createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  bool _isLoading = false;
  String? _resultMessage;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    final success = await ApiService().pingServer();

    setState(() {
      _isLoading = false;
      _resultMessage = success ? 'Connected to Backend!' : 'Connection Failed';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A8C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'IFind',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1A1A8C),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Test Connection',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 30),
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.white),
            if (_resultMessage != null)
              Text(
                _resultMessage!,
                style: TextStyle(
                  color: _resultMessage!.contains('Connected')
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
