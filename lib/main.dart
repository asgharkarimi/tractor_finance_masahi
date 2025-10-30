import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/database_service.dart';
import 'services/supabase_service.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدیریت درآمد تراکتور',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [
        Locale('fa', 'IR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const InitializationScreen(),
    );
  }
}

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  String? _error;
  String _statusMessage = 'در حال بارگذاری...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Supabase
      setState(() {
        _statusMessage = 'اتصال به سرور...';
      });
      await SupabaseService.initialize();

      // Initialize local database
      setState(() {
        _statusMessage = 'بارگذاری داده‌های محلی...';
      });
      await DatabaseService.init();

      // Check if local database is empty
      final localFarmersCount = DatabaseService.getAllFarmers().length;

      if (localFarmersCount == 0) {
        // Local is empty, try to load from server
        setState(() {
          _statusMessage = 'بررسی داده‌های سرور...';
        });

        try {
          final hasConnection = await SupabaseService.checkConnection();

          if (hasConnection) {
            final serverFarmersCount =
                await SupabaseService.getServerFarmersCount();

            if (serverFarmersCount > 0) {
              // Load only farmer names first (fast)
              setState(() {
                _statusMessage = 'بارگذاری $serverFarmersCount کشاورز...';
              });
              await SupabaseService.loadFarmerNamesOnly();

              // Load full details in background after navigation
              _loadFullDetailsInBackground();
            }
          }
        } catch (e) {
          // Ignore server errors, continue with empty local data
        }
      }

      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  void _loadFullDetailsInBackground() {
    // Load full details after a short delay
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        await SupabaseService.loadFullDetailsInBackground();
      } catch (e) {
        // Silently fail
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF66BB6A),
              Color(0xFF81C784),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_error == null) ...[
                // Logo
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.agriculture,
                        size: 100,
                        color: Color(0xFF66BB6A),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'مدیریت درآمد تراکتور',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'خطا در بارگذاری',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                    });
                    _initialize();
                  },
                  child: const Text('تلاش مجدد'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


// echo "# tractor_finance_masahi" >> README.md
// git init
// git add README.md
// git commit -m "first commit"
// git branch -M main
// git remote add origin https://github.com/asgharkarimi/tractor_finance_masahi.git
// git push -u origin main