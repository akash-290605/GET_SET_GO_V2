import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../widgets/live_animated_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoadingGoogle = false;
  bool _isLoadingForm = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _isSignUp = _tabController.index == 1;
          AuthService.instance.clearError();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoadingGoogle = true);
    final success = await AuthService.instance.signInWithGoogle();
    if (mounted) {
      setState(() => _isLoadingGoogle = false);
      if (!success && AuthService.instance.errorMessage != null) {
        _showSnackBar(AuthService.instance.errorMessage!, isError: true);
      }
    }
  }

  Future<void> _handleFormSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoadingForm = true);
    bool success;
    if (_isSignUp) {
      success = await AuthService.instance.signUpWithEmail(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );
    } else {
      success = await AuthService.instance.signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );
    }

    if (mounted) {
      setState(() => _isLoadingForm = false);
      if (!success && AuthService.instance.errorMessage != null) {
        _showSnackBar(AuthService.instance.errorMessage!, isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.accentRose : AppColors.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiveAnimatedBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF11182B).withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.40)
                          : const Color(0xFF1E40AF).withValues(alpha: 0.08),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, size: 18, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'GET SET GO',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 1.2,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Title & Subtitle
                    Text(
                      _isSignUp ? 'Create Your Account' : 'Welcome Back',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary(isDark),
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your all-in-one AI fitness, nutrition, habits & productivity command center.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary(isDark),
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Tab Selector: Sign In / Sign Up
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceHighlight
                            : AppColors.lightSurfaceHighlight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.textSecondary(isDark),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Sign In'),
                          Tab(text: 'Sign Up'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Google Sign In Button
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white.withValues(alpha: 0.8),
                      ),
                      onPressed: _isLoadingGoogle ? null : _handleGoogleSignIn,
                      child: _isLoadingGoogle
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildGoogleIcon(),
                                const SizedBox(width: 10),
                                Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary(isDark),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 18),

                    // Divider: OR
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR WITH EMAIL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMutedDynamic(isDark),
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isSignUp) ...[
                            _buildInputField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_rounded,
                              isDark: isDark,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                          _buildInputField(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            isDark: isDark,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!val.contains('@') || !val.contains('.')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildInputField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_rounded,
                            obscureText: _obscurePassword,
                            isDark: isDark,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                size: 19,
                                color: AppColors.textSecondary(isDark),
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your password';
                              }
                              if (val.trim().length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),

                          // Submit Action Button
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _isLoadingForm ? null : _handleFormSubmit,
                              child: _isLoadingForm
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isSignUp ? Icons.person_add_rounded : Icons.arrow_forward_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isSignUp ? 'Create Free Account' : 'Sign In to Get Set Go',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Quick switch helper
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                            _tabController.index = _isSignUp ? 1 : 0;
                            AuthService.instance.clearError();
                          });
                        },
                        child: Text(
                          _isSignUp
                              ? 'Already have an account? Sign In'
                              : "Don't have an account? Create one",
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary(isDark),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary(isDark),
        ),
        prefixIcon: Icon(icon, size: 19, color: AppColors.primary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accentRose),
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontWeight: FontWeight.w900,
            fontSize: 14,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }
}
