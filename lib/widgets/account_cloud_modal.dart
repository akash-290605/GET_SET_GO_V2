import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';

/// Account, Authentication & Cloud Sync Modal
class AccountAndCloudSyncModal extends StatefulWidget {
  const AccountAndCloudSyncModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => const AccountAndCloudSyncModal(),
    );
  }

  @override
  State<AccountAndCloudSyncModal> createState() => _AccountAndCloudSyncModalState();
}

class _AccountAndCloudSyncModalState extends State<AccountAndCloudSyncModal> {
  bool _isEditingProfile = false;
  bool _isAuthMode = false;
  bool _isSignUp = false;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();

  String _selectedEmoji = '⚡';
  final List<String> _emojiOptions = ['⚡', '🦁', '🛡️', '⚔️', '🦅', '👑', '🔥', '💪'];

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    final u = AuthService.instance.currentUser;
    _nameCtrl.text = u.displayName;
    _emailCtrl.text = u.email;
    _weightCtrl.text = u.weightKg.toStringAsFixed(1);
    _heightCtrl.text = u.heightCm.toStringAsFixed(0);
    _goalCtrl.text = u.fitnessGoal;
    _budgetCtrl.text = u.monthlyExpenseBudget.toStringAsFixed(0);
    _selectedEmoji = u.avatarEmoji;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _goalCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  void _handleSyncNow() async {
    final result = await CloudSyncService.instance.syncAllToCloud();
    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text('🟢 Cloud Vault Synced! (${result['itemsCount']} items backed up)', style: const TextStyle(color: AppColors.accentGreen)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cloud Sync failed: ${result['error']}')),
        );
      }
      setState(() {});
    }
  }

  void _handleRestoreNow() async {
    final success = await CloudSyncService.instance.restoreFromCloud();
    if (mounted) {
      if (success) {
        AppSyncBus.notifyDataChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text('🛡️ Data successfully restored from Cloud Vault!', style: TextStyle(color: AppColors.secondary)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cloud backup found or restore failed.')),
        );
      }
      setState(() {});
    }
  }

  void _saveProfile() async {
    final w = double.tryParse(_weightCtrl.text.trim()) ?? 72.0;
    final h = double.tryParse(_heightCtrl.text.trim()) ?? 178.0;
    final b = double.tryParse(_budgetCtrl.text.trim()) ?? 25000.0;

    await AuthService.instance.updateProfile(
      displayName: _nameCtrl.text.trim(),
      avatarEmoji: _selectedEmoji,
      weightKg: w,
      heightCm: h,
      fitnessGoal: _goalCtrl.text.trim(),
      monthlyBudget: b,
    );

    setState(() => _isEditingProfile = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profile & Biometrics updated!')),
      );
    }
  }

  void _handleAuthAction() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide Email and Password.')));
      return;
    }

    if (_isSignUp) {
      await AuthService.instance.signUp(
        email: email,
        password: pass,
        displayName: _nameCtrl.text.trim().isEmpty ? 'Titan Athlete' : _nameCtrl.text.trim(),
        weightKg: double.tryParse(_weightCtrl.text.trim()) ?? 72.0,
        heightCm: double.tryParse(_heightCtrl.text.trim()) ?? 178.0,
        fitnessGoal: _goalCtrl.text.trim().isEmpty ? 'Peak Athletic Performance' : _goalCtrl.text.trim(),
        monthlyBudget: double.tryParse(_budgetCtrl.text.trim()) ?? 25000.0,
        avatarEmoji: _selectedEmoji,
      );
    } else {
      await AuthService.instance.signIn(email: email, password: pass);
    }

    setState(() {
      _isAuthMode = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text(_isSignUp ? '🎉 Welcome to GetSetGo Cloud Account!' : '⚡ Welcome back, Titan! Cloud connected.', style: const TextStyle(color: AppColors.accentGreen)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              // Account Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1538), Color(0xFF131D33)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.2),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 16),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 10),
                        ],
                      ),
                      child: Center(
                        child: Text(user.avatarEmoji, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.displayName, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Colors.white)),
                          const SizedBox(height: 3),
                          Text(user.email, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              user.disciplineRank,
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppColors.secondary, letterSpacing: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isEditingProfile ? Icons.close_rounded : Icons.edit_rounded, color: AppColors.secondary),
                      tooltip: 'Edit Profile',
                      onPressed: () => setState(() => _isEditingProfile = !_isEditingProfile),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Profile Editor Form
              if (_isEditingProfile) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Edit Profile & Biometrics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white)),
                      const SizedBox(height: 10),

                      // Avatar Picker
                      Wrap(
                        spacing: 8,
                        children: _emojiOptions.map((emoji) {
                          final isSel = _selectedEmoji == emoji;
                          return InkWell(
                            onTap: () => setState(() => _selectedEmoji = emoji),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.primary.withValues(alpha: 0.3) : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSel ? AppColors.primary : AppColors.borderLight),
                              ),
                              child: Text(emoji, style: const TextStyle(fontSize: 20)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Display Name')),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: _weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (kg)'))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: _heightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Height (cm)'))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(controller: _goalCtrl, decoration: const InputDecoration(labelText: 'Fitness & Growth Goal')),
                      const SizedBox(height: 10),
                      TextField(controller: _budgetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Expense Budget (₹) ')),
                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          child: const Text('Save Profile Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Cloud Sync Status & Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.cloud_done_rounded, color: AppColors.accentGreen, size: 20),
                            SizedBox(width: 8),
                            Text('Cloud Storage Vault', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('PROTECTED 🛡️', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'All workouts, weights, food macros, strict habits, and expenses are encrypted and synced across Web & Mobile.',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.35),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _handleSyncNow,
                            icon: const Icon(Icons.sync_rounded, size: 18),
                            label: const Text('Sync Cloud Now', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _handleRestoreNow,
                            icon: const Icon(Icons.cloud_download_rounded, size: 18, color: AppColors.secondary),
                            label: const Text('Restore Backup', style: TextStyle(color: AppColors.secondary)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Switch / Sign In Account Card
              if (_isAuthMode) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isSignUp ? 'Create Cloud Account' : 'Sign In to Cloud Account', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      const SizedBox(height: 10),
                      TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
                      const SizedBox(height: 10),
                      TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleAuthAction,
                          child: Text(_isSignUp ? 'Register & Connect Cloud' : 'Sign In & Sync'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () => setState(() => _isSignUp = !_isSignUp),
                          child: Text(_isSignUp ? 'Already have an account? Sign In' : 'Need a new account? Sign Up', style: const TextStyle(color: AppColors.secondary)),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _isAuthMode = true;
                        _isSignUp = false;
                      }),
                      icon: const Icon(Icons.switch_account_rounded, size: 16, color: AppColors.secondary),
                      label: const Text('Switch / Sign In Account', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await AuthService.instance.signOut();
                        setState(() => _populateFields());
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Switched to Offline Mode.')));
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.accentRose),
                      label: const Text('Sign Out', style: TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
