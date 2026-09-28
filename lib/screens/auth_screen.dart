import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../widgets/glass_card.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController(text: 'Akash K');
  final _emailController = TextEditingController(text: 'akash.titan@gmail.com');
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final user = AuthService.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName;
      _emailController.text = user.email;
    }
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
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signInWithGoogle(
        name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Akash K',
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : 'akash.titan@gmail.com',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Successfully signed in with Google!'),
            backgroundColor: AppColors.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e'), backgroundColor: AppColors.accentRose),
        );
      }
    }
  }

  Future<void> _handleEmailSignIn() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address'), backgroundColor: AppColors.accentAmber),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signInWithEmail(
        email,
        _passwordController.text.trim(),
        displayName: name.isNotEmpty ? name : email.split('@').first,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Signed in successfully!'),
            backgroundColor: AppColors.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e'), backgroundColor: AppColors.accentRose),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeService.instance.isDarkMode(context);
    final user = AuthService.instance.currentUser;
    final isSignedIn = AuthService.instance.isSignedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Authentication', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.bolt_rounded, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 18),
                const Text(
                  'GET SET GO',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fitness, Progressive Overload & Finance',
                  style: TextStyle(fontSize: 13, color: theme.hintColor),
                ),
                const SizedBox(height: 24),

                // If currently signed in, show Profile Card
                if (isSignedIn && user != null) ...[
                  GlassCard(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                              child: Text(
                                user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'A',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          user.displayName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentGreen.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text('ACTIVE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(user.email, style: TextStyle(fontSize: 12, color: theme.hintColor)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Provider: ${user.authProvider.toUpperCase()}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('Update Info', style: TextStyle(fontSize: 12.5)),
                                onPressed: () {
                                  AuthService.instance.updateProfile(
                                    displayName: _nameController.text.trim(),
                                    email: _emailController.text.trim(),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Profile updated!'), backgroundColor: AppColors.accentGreen),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentRose.withValues(alpha: 0.15),
                                  foregroundColor: AppColors.accentRose,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.logout_rounded, size: 16),
                                label: const Text('Sign Out', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  await AuthService.instance.signOut();
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Tabs for Google Sign-In & Email Sign-In
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: theme.hintColor,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  tabs: const [
                    Tab(icon: Icon(Icons.g_mobiledata_rounded, size: 22), text: 'Google Sign In'),
                    Tab(icon: Icon(Icons.email_outlined, size: 18), text: 'Email & Name'),
                  ],
                ),
                const SizedBox(height: 20),

                // Name & Email Fields
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),

                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('1-Tap Sign In with Google', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: _handleGoogleSignIn,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.mail_outline_rounded, size: 18),
                      label: const Text('Sign In with Email Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      onPressed: _handleEmailSignIn,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () async {
                      await AuthService.instance.continueAsGuest();
                      if (mounted) Navigator.pop(context);
                    },
                    child: Text('Continue as Guest (Local Offline Mode)', style: TextStyle(color: theme.hintColor, fontSize: 12.5)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
