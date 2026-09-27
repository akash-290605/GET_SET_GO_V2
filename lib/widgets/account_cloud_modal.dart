import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db_helper.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/profile_service.dart';
import '../services/theme_service.dart';

void showAccountCloudModal(BuildContext context) {
  AccountCloudModal.show(context);
}

class AccountCloudModal extends StatefulWidget {
  const AccountCloudModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AccountCloudModal(),
    );
  }

  @override
  State<AccountCloudModal> createState() => _AccountCloudModalState();
}

class _AccountCloudModalState extends State<AccountCloudModal> {
  bool _isBackingUp = false;
  String? _backupMessage;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final isGuest = AuthService.instance.isGuest || user == null;
    final syncService = CloudSyncService.instance;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: AppColors.borderLight, width: 1.5),
              left: BorderSide(color: AppColors.borderLight, width: 1),
              right: BorderSide(color: AppColors.borderLight, width: 1),
            ),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([AuthService.instance, CloudSyncService.instance]),
            builder: (context, _) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header with Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ACCOUNT & CLOUD VAULT',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Firebase Firestore + Local Storage',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Profile / Account Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                              child: user?.photoURL == null
                                  ? const Icon(Icons.person_rounded, color: AppColors.primaryGlow, size: 26)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.displayName ?? (isGuest ? 'Guest User (Local Storage)' : 'User'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?.email ?? 'Sign in to enable automatic multi-device cloud sync',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isGuest) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                AuthService.instance.signInWithGoogle();
                              },
                              icon: const Icon(Icons.login_rounded, size: 18),
                              label: const Text('Sign In with Google for Cloud Backup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cloud Sync Status Card
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
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SYNC STATUS',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1.1),
                            ),
                            Icon(Icons.sync_rounded, color: AppColors.secondary, size: 16),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: syncService.status == CloudSyncStatus.synced
                                    ? AppColors.accentGreen
                                    : syncService.status == CloudSyncStatus.syncing
                                        ? AppColors.accentAmber
                                        : AppColors.accentRose,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              syncService.status == CloudSyncStatus.synced
                                  ? 'Fully Synced with Cloud Vault'
                                  : syncService.status == CloudSyncStatus.syncing
                                      ? 'Syncing in background...'
                                      : 'Offline / Local Cache Active',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.secondary,
                              side: const BorderSide(color: AppColors.secondary),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              await syncService.syncAll();
                            },
                            icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                            label: const Text('Force Cloud Sync Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Data Export / JSON Vault
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
                        const Text(
                          'DATA BACKUP & LOCAL VAULT',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGlow, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Export your entire fitness, finance, and nutrition history as structured JSON.',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                        if (_backupMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _backupMessage!,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.accentGreen),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isBackingUp
                                ? null
                                : () async {
                                    setState(() => _isBackingUp = true);
                                    final expenses = await DBHelper.instance.getExpenses();
                                    final meals = await DBHelper.instance.getMeals();
                                    final workouts = await DBHelper.instance.getWorkoutPlans();

                                    final backupJson = jsonEncode({
                                      'exportDate': DateTime.now().toIso8601String(),
                                      'profile': {
                                        'name': ProfileService.instance.userName,
                                        'weight': ProfileService.instance.weightKg,
                                        'targetWeight': ProfileService.instance.targetWeightKg,
                                        'budget': ProfileService.instance.monthlyBudgetCap,
                                      },
                                      'expenses': expenses,
                                      'meals': meals.map((m) => m.toMap()).toList(),
                                      'workouts': workouts.map((w) => w.toMap()).toList(),
                                    });

                                    await Clipboard.setData(ClipboardData(text: backupJson));

                                    if (mounted) {
                                      setState(() {
                                        _isBackingUp = false;
                                        _backupMessage = '✓ Backup copied to clipboard successfully!';
                                      });
                                    }
                                  },
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: Text(_isBackingUp ? 'Exporting Vault...' : 'Copy Full JSON Backup Vault'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sign Out / Switch Account Button
                  if (!isGuest)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accentRose,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          await AuthService.instance.signOut();
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text(
                          'Sign Out / Switch Account',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
