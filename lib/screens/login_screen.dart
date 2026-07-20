import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../mock_data/inventory_store.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import 'nav_shell.dart';

const String _authEmailDomain = 'glomags.internal';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: '$username@$_authEmailDomain',
        password: password,
      );
      await InventoryStore.instance.login();

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        FadeSlideRoute(page: const NavShell()),
      );
    } on FirebaseAuthException catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error),
              SizedBox(width: 12),
              Expanded(child: Text('Invalid credentials. Please try again.')),
            ],
          ),
        ),
      );
    } catch (e) {
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not log in: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Logo
                        const AppLogo(size: 120),

                        const SizedBox(height: 32),

                        // Main Header Text
                        const Text(
                          'GWC SYNC',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'MULTI-BRANCH INVENTORY SYNC',
                          style: TextStyle(
                            color: Colors.grey,
                            letterSpacing: 1.5,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Orange accent line
                        Container(
                          width: 45,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Login Card Container
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xff1e1e1e), // Dark container style
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SECURE ACCESS',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Username Header
                              const Text(
                                'USERNAME',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _usernameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Enter your username',
                                  hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
                                  prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                                  filled: true,
                                  fillColor: const Color(0xff272727),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                                  ),
                                ),
                                validator: (value) => (value == null || value.trim().isEmpty)
                                    ? 'Please enter your username'
                                    : null,
                              ),

                              const SizedBox(height: 20),

                              // Password Header
                              const Text(
                                'PASSWORD',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Enter your password',
                                  hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
                                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                                  filled: true,
                                  fillColor: const Color(0xff272727),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (value) => (value == null || value.isEmpty)
                                    ? 'Please enter your password'
                                    : null,
                              ),

                              const SizedBox(height: 20),

                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accent.withValues(alpha: 0.25),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      )
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.black87,
                                            ),
                                          )
                                        : const Text(
                                            'LOG IN',
                                            style: TextStyle(
                                              fontSize: 15,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),
                        Text(
                          'GWC Sync — Mobile Application',
                          style: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.6),
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}