import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailLoginController = TextEditingController();
  final _passwordLoginController = TextEditingController();
  final _nameSignupController = TextEditingController();
  final _emailSignupController = TextEditingController();
  final _passwordSignupController = TextEditingController();

  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;
  String? _errorMsg;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailLoginController.dispose();
    _passwordLoginController.dispose();
    _nameSignupController.dispose();
    _emailSignupController.dispose();
    _passwordSignupController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final success = await AuthService.instance.signInWithGoogle();
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        CloudSyncService.instance.syncWithFirebase();
        widget.onAuthenticated();
      } else {
        setState(() {
          _errorMsg = AuthService.instance.errorMessage ?? 'Google Sign-In failed';
        });
      }
    }
  }

  Future<void> _handleEmailLogin() async {
    final email = _emailLoginController.text.trim();
    final password = _passwordLoginController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final success = await AuthService.instance.signInWithEmail(
      email: email,
      password: password,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        CloudSyncService.instance.syncWithFirebase();
        widget.onAuthenticated();
      } else {
        setState(() {
          _errorMsg = AuthService.instance.errorMessage ?? 'Invalid email or password.';
        });
      }
    }
  }

  Future<void> _handleEmailSignup() async {
    final name = _nameSignupController.text.trim();
    final email = _emailSignupController.text.trim();
    final password = _passwordSignupController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = 'Please fill out all fields.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final success = await AuthService.instance.signUpWithEmail(
      name: name,
      email: email,
      password: password,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        CloudSyncService.instance.syncWithFirebase();
        widget.onAuthenticated();
      } else {
        setState(() {
          _errorMsg = AuthService.instance.errorMessage ?? 'Account creation failed.';
        });
      }
    }
  }

  void _handleGuestMode() async {
    await AuthService.instance.signInAsGuest();
    widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF090D18);
    const surface = Color(0xFF11182B);
    const surfaceElevated = Color(0xFF18223C);
    const primary = Color(0xFF8B5CF6);
    const secondary = Color(0xFF06B6D4);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App Branding Logo
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [primary, secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'GET SET GO',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Titan Growth Engine & Habit Mastery',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Firebase Cloud status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.cloud_done_rounded, size: 14, color: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text(
                          'Firebase Cloud: get-set-go-ad19f',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Auth Card
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Google Sign-In Quick Button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                          child: InkWell(
                            onTap: _isLoading ? null : _handleGoogleSignIn,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: surfaceElevated,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: primary.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: const Icon(
                                      Icons.g_mobiledata_rounded,
                                      color: Color(0xFFEA4335),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Divider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'or use email',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                            ],
                          ),
                        ),

                        // Tab Bar (Login / Sign Up)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: surfaceElevated,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [primary, Color(0xFF7C3AED)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: const Color(0xFF94A3B8),
                            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                            tabs: const [
                              Tab(text: 'Sign In'),
                              Tab(text: 'Create Account'),
                            ],
                          ),
                        ),

                        // Error message
                        if (_errorMsg != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: Color(0xFFF43F5E), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMsg!,
                                      style: const TextStyle(
                                        color: Color(0xFFFDA4AF),
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Tab Bar Views
                        SizedBox(
                          height: 250,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // --- TAB 1: SIGN IN ---
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildTextField(
                                      controller: _emailLoginController,
                                      label: 'Email Address',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      controller: _passwordLoginController,
                                      label: 'Password',
                                      icon: Icons.lock_outline_rounded,
                                      isPassword: true,
                                      obscureText: _obscureLoginPassword,
                                      onToggleVisibility: () => setState(
                                          () => _obscureLoginPassword = !_obscureLoginPassword),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildSubmitButton(
                                      label: 'Sign In to Titan',
                                      onTap: _isLoading ? null : _handleEmailLogin,
                                    ),
                                  ],
                                ),
                              ),

                              // --- TAB 2: SIGN UP ---
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildTextField(
                                      controller: _nameSignupController,
                                      label: 'Full Name',
                                      icon: Icons.person_outline_rounded,
                                    ),
                                    const SizedBox(height: 10),
                                    _buildTextField(
                                      controller: _emailSignupController,
                                      label: 'Email Address',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 10),
                                    _buildTextField(
                                      controller: _passwordSignupController,
                                      label: 'Create Password (6+ chars)',
                                      icon: Icons.lock_outline_rounded,
                                      isPassword: true,
                                      obscureText: _obscureSignupPassword,
                                      onToggleVisibility: () => setState(
                                          () => _obscureSignupPassword = !_obscureSignupPassword),
                                    ),
                                    const SizedBox(height: 14),
                                    _buildSubmitButton(
                                      label: 'Create Titan Account',
                                      onTap: _isLoading ? null : _handleEmailSignup,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Guest / Explorer Button
                  TextButton.icon(
                    onPressed: _isLoading ? null : _handleGuestMode,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF94A3B8)),
                    label: const Text(
                      'Continue as Guest / Offline Demo',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
  }) {
    const surfaceElevated = Color(0xFF18223C);
    return Container(
      decoration: BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF94A3B8),
                    size: 18,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSubmitButton({required String label, required VoidCallback? onTap}) {
    const primary = Color(0xFF8B5CF6);
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4,
          shadowColor: primary.withValues(alpha: 0.5),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
