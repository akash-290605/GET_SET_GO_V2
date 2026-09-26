import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../main.dart';

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
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // User Profile Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: isGuest ? AppColors.accentAmber : AppColors.primary,
                          child: Icon(
                            isGuest ? Icons.person_outline_rounded : Icons.person_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'Guest Explorer',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.email ?? 'guest@getsetgo.app',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isGuest ? AppColors.accentAmber : AppColors.accentGreen)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: (isGuest ? AppColors.accentAmber : AppColors.accentGreen)
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  isGuest
                                      ? '⚡ Guest Mode'
                                      : (user.authProvider == 'google'
                                          ? '🛡️ Google Verified'
                                          : '✉️ Email Account'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isGuest ? AppColors.accentAmber : AppColors.accentGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Firebase Cloud Sync Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cloud_done_rounded, color: AppColors.secondary, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Firebase Cloud Sync',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                syncService.projectId,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          syncService.lastSyncTime != null
                              ? 'Last Synced: ${syncService.lastSyncTime!.hour.toString().padLeft(2, "0")}:${syncService.lastSyncTime!.minute.toString().padLeft(2, "0")} • ${syncService.lastSyncTime!.day}/${syncService.lastSyncTime!.month}/${syncService.lastSyncTime!.year}'
                              : 'No cloud sync recorded yet.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        if (syncService.lastErrorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            syncService.lastErrorMessage!,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.accentRose),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: const Color(0xFF070B14),
                            ),
                            onPressed: syncService.status == CloudSyncStatus.syncing
                                ? null
                                : () async {
                                    final success = await CloudSyncService.instance.syncWithFirebase();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor:
                                              success ? AppColors.accentGreen : AppColors.accentRose,
                                          content: Text(
                                            success
                                                ? 'Cloud Sync Complete! Data safely backed up to get-set-go-ad19f.'
                                                : (CloudSyncService.instance.lastErrorMessage ??
                                                    'Sync failed. Saved to local vault.'),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            icon: syncService.status == CloudSyncStatus.syncing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : const Icon(Icons.sync_rounded, size: 18),
                            label: Text(
                              syncService.status == CloudSyncStatus.syncing
                                  ? 'Syncing to Firebase...'
                                  : 'Sync Now with Cloud',
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Local Hierarchical JSON Vault Export
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
                          children: [
                            Icon(Icons.folder_zip_rounded, color: AppColors.accentAmber, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Local JSON Hierarchical Vault',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Creates a structured backup organized by Year > Month > Week > Day.',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                                    final res = await HierarchicalStorageManager.exportFullTreeBackup();
                                    if (mounted) {
                                      setState(() {
                                        _isBackingUp = false;
                                        _backupMessage = res;
                                      });
                                    }
                                  },
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: Text(_isBackingUp ? 'Exporting Vault...' : 'Export JSON Backup Vault'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sign Out / Switch Account Button
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
