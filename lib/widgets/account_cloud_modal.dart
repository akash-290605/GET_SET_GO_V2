import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/theme_service.dart';

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
  final TextEditingController _importController = TextEditingController();
  bool _isImportMode = false;

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = AuthService.instance.currentUser;
    final isGuest = AuthService.instance.isGuest;
    final syncService = CloudSyncService.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([AuthService.instance, syncService]),
      builder: (context, _) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B22) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ThemeService.primaryCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.cloud_sync_rounded,
                          color: ThemeService.primaryCyan,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cloud Sync & Vault',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Firebase: ${syncService.firebaseProjectId}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // User Profile Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: ThemeService.primaryCyan.withValues(alpha: 0.2),
                          backgroundImage: user?.photoUrl.isNotEmpty == true ? NetworkImage(user!.photoUrl) : null,
                          child: user?.photoUrl.isEmpty == true ? const Icon(Icons.person, color: ThemeService.primaryCyan, size: 28) : null,
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
                                      user?.displayName ?? 'Athlete',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (!isGuest)
                                    const Icon(Icons.verified, color: ThemeService.primaryCyan, size: 16),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isGuest ? 'Guest Session (Local Storage)' : (user?.email ?? 'Signed in'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isGuest ? Colors.amber : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isGuest)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              // Trigger Google Sign in
                              AuthService.instance.signInWithGoogle();
                            },
                            child: const Text('Connect', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cloud Firestore Sync Section
                  const Text(
                    'FIREBASE FIRESTORE SYNC',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              syncService.status == CloudSyncStatus.synced
                                  ? Icons.check_circle
                                  : syncService.status == CloudSyncStatus.syncing
                                      ? Icons.sync
                                      : Icons.cloud_queue,
                              color: syncService.status == CloudSyncStatus.synced
                                  ? ThemeService.primaryEmerald
                                  : ThemeService.primaryCyan,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                syncService.status == CloudSyncStatus.synced
                                    ? 'All local data synced with Cloud Firestore'
                                    : syncService.status == CloudSyncStatus.syncing
                                        ? 'Synchronizing ledger & workout split...'
                                        : 'Cloud Sync Ready',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          syncService.lastSyncedAt != null
                              ? 'Last sync: ${syncService.lastSyncedAt!.toLocal().toString().split('.')[0]}'
                              : 'No previous cloud snapshot logged',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: syncService.status == CloudSyncStatus.syncing
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : const Icon(Icons.cloud_upload_outlined, size: 18),
                            label: Text(syncService.status == CloudSyncStatus.syncing ? 'Syncing...' : 'Sync to Firebase Cloud Now'),
                            onPressed: syncService.status == CloudSyncStatus.syncing
                                ? null
                                : () async {
                                    final ok = await syncService.syncWithFirebaseCloud();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(ok ? 'Cloud Sync Completed Successfully!' : syncService.lastErrorMessage),
                                          backgroundColor: ok ? ThemeService.primaryEmerald : Colors.red,
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Offline JSON Vault Section
                  const Text(
                    'PORTABLE JSON BACKUP VAULT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Export and import complete app state (workouts, expenses, macros, profile) with zero vendor lock-in.',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Copy JSON Vault', style: TextStyle(fontSize: 12)),
                                onPressed: () {
                                  final jsonVault = syncService.exportCompleteVaultJson();
                                  Clipboard.setData(ClipboardData(text: jsonVault));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Complete JSON Vault copied to clipboard!'),
                                      backgroundColor: ThemeService.primaryEmerald,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.file_download_outlined, size: 16),
                                label: Text(_isImportMode ? 'Cancel' : 'Import Vault', style: const TextStyle(fontSize: 12)),
                                onPressed: () {
                                  setState(() {
                                    _isImportMode = !_isImportMode;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_isImportMode) ...[
                          const SizedBox(height: 14),
                          TextField(
                            controller: _importController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Paste valid GetSetGo JSON vault string here...',
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: ThemeService.primaryEmerald),
                              onPressed: () async {
                                final text = _importController.text.trim();
                                if (text.isEmpty) return;
                                final success = await syncService.importCompleteVaultJson(text);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success ? 'Vault successfully restored!' : 'Invalid JSON vault payload.'),
                                      backgroundColor: success ? ThemeService.primaryEmerald : Colors.red,
                                    ),
                                  );
                                  if (success) {
                                    setState(() {
                                      _isImportMode = false;
                                      _importController.clear();
                                    });
                                  }
                                }
                              },
                              child: const Text('Execute Restore'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
