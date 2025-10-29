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

      // Check server data
      setState(() {
        _statusMessage = 'بررسی داده‌های سرور...';
      });
      await Future.delayed(const Duration(milliseconds: 500));

      final hasConnection = await SupabaseService.checkConnection();

      if (hasConnection) {
        // Get server data count
        final serverFarmersCount =
            await SupabaseService.getServerFarmersCount();
        final localFarmersCount = DatabaseService.getAllFarmers().length;

        if (mounted) {
          if (serverFarmersCount > 0 && localFarmersCount == 0) {
            // Server has data, local is empty - ask to load
            await _showLoadFromServerDialog(serverFarmersCount);
          } else if (serverFarmersCount > 0 && localFarmersCount > 0) {
            // Both have data - show comparison
            await _showDataComparisonDialog(
                localFarmersCount, serverFarmersCount);
          }
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

  Future<void> _showLoadFromServerDialog(int serverCount) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_download, color: Color(0xFF66BB6A)),
            SizedBox(width: 8),
            Text('داده‌های سرور'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$serverCount کشاورز در سرور یافت شد.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'آیا می‌خواهید داده‌های سرور را بارگذاری کنید؟',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('خیر، بعداً'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('بله، بارگذاری کن'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _statusMessage = 'بارگذاری از سرور...';
      });
      try {
        await SupabaseService.loadAllFromSupabase();
      } catch (e) {
        // Ignore error, will continue to app
      }
    }
  }

  Future<void> _showDataComparisonDialog(
      int localCount, int serverCount) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sync, color: Color(0xFF66BB6A)),
            SizedBox(width: 8),
            Text('همگام‌سازی داده‌ها'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('داده‌های محلی:'),
                      Text(
                        '$localCount کشاورز',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('داده‌های سرور:'),
                      Text(
                        '$serverCount کشاورز',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'کدام داده‌ها را می‌خواهید استفاده کنید؟',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'skip'),
            child: const Text('بعداً'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'merge'),
            icon: const Icon(Icons.merge_type),
            label: const Text('ترکیب هر دو'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF66BB6A),
            ),
          ),
        ],
      ),
    );

    if (result == 'merge' && mounted) {
      setState(() {
        _statusMessage = 'همگام‌سازی هوشمند...';
      });
      try {
        await SupabaseService.smartSync();
      } catch (e) {
        // Ignore error
      }
    }
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
// لهف