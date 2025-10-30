import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '09199541276');
  final _passwordController = TextEditingController(text: 'asghar');
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Default credentials
  static const String _defaultPhone = '09199541276';
  static const String _defaultPassword = 'asghar';

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startBackgroundSync() {
    // Start sync after a short delay
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        // Load full details for farmers that only have names
        await SupabaseService.loadFullDetailsInBackground();
      } catch (e) {
        // Silently fail - don't disturb user
      }
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    // Check credentials
    if (_phoneController.text == _defaultPhone &&
        _passwordController.text == _defaultPassword) {
      // Login successful - navigate to home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      
      // Start background sync after login
      _startBackgroundSync();
    } else {
      // Login failed
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('شماره تلفن یا رمز عبور اشتباه است'),
          backgroundColor: Colors.red,
        ),
      );
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                      child: const Icon(
                        Icons.agriculture,
                        size: 80,
                        color: Color(0xFF66BB6A),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'مدیریت درآمد تراکتور',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ورود به حساب کاربری',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Login Card
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Phone Number Field
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(11),
                              ],
                              decoration: InputDecoration(
                                labelText: 'شماره تلفن',
                                hintText: '09123456789',
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'لطفا شماره تلفن را وارد کنید';
                                }
                                if (value.length != 11) {
                                  return 'شماره تلفن باید 11 رقم باشد';
                                }
                                if (!value.startsWith('09')) {
                                  return 'شماره تلفن باید با 09 شروع شود';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'رمز عبور',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'لطفا رمز عبور را وارد کنید';
                                }
                                if (value.length < 3) {
                                  return 'رمز عبور باید حداقل 3 کاراکتر باشد';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF66BB6A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'ورود',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'اطلاعات پیش‌فرض:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'شماره: 09199541276',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            'رمز: asghar',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
