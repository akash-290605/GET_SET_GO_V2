import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/profile_service.dart';
import '../services/theme_service.dart';

class BodyPhotoModal extends StatelessWidget {
  const BodyPhotoModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const BodyPhotoModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileService = ProfileService.instance;

    return AnimatedBuilder(
      animation: profileService,
      builder: (context, _) {
        final profile = profileService.profile;
        final photos = profile.bodyPhotos;

        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Modal Grab Handle & Header
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ThemeService.primaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: ThemeService.primaryCyan, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Body Progress Photos',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Weekly Check-In & Transformation Gallery (${photos.length} logged)',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Action Banner: Take Photo / Upload
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.photo_camera_rounded, size: 18),
                        label: const Text('Take Body Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeService.primaryCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _pickAndLogPhoto(context, ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        label: const Text('Choose Gallery'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: ThemeService.primaryCyan),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _pickAndLogPhoto(context, ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              ),

              // Photos Grid or Empty State
              Expanded(
                child: photos.isEmpty
                    ? _buildEmptyState(context, isDark)
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: photos.length,
                        itemBuilder: (ctx, i) {
                          final photo = photos[i];
                          return _buildPhotoCard(context, photo, isDark);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF21262D) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Body Photos Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Take a weekly check-in photo every Sunday to track physical transformation, muscle definition, and body composition alongside your BMI.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_a_photo_rounded, size: 18),
              label: const Text('Capture First Check-in Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeService.primaryCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () => _pickAndLogPhoto(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(BuildContext context, BodyPhotoEntry photo, bool isDark) {
    final dateStr = DateFormat('MMM dd, yyyy').format(photo.date);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Display
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _renderImage(photo.imageBase64),
                // Gradient Shadow overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Date Chip
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dateStr,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Delete button
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 18),
                    onPressed: () => _confirmDelete(context, photo.id),
                  ),
                ),
              ],
            ),
          ),

          // Metadata Footer
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${photo.weightKg.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ThemeService.primaryCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'BMI ${photo.bmi.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: ThemeService.primaryCyan,
                        ),
                      ),
                    ),
                  ],
                ),
                if (photo.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    photo.notes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderImage(String base64String) {
    if (base64String.isEmpty) {
      return Container(
        color: Colors.grey.withValues(alpha: 0.2),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
    try {
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) {
          return Container(
            color: Colors.grey.withValues(alpha: 0.2),
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } catch (_) {
      return Container(
        color: Colors.grey.withValues(alpha: 0.2),
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
  }

  Future<void> _pickAndLogPhoto(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (picked == null || !context.mounted) return;

      final bytes = await picked.readAsBytes();
      final base64String = base64Encode(bytes);

      if (!context.mounted) return;
      _showSavePhotoDialog(context, base64String);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not capture image: $e')),
        );
      }
    }
  }

  void _showSavePhotoDialog(BuildContext context, String base64String) {
    final profile = ProfileService.instance.profile;
    final weightCtrl = TextEditingController(text: profile.currentWeightKg.toStringAsFixed(1));
    final notesCtrl = TextEditingController(text: 'Weekly body check-in');
    final heightM = profile.heightCm / 100;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Save Weekly Body Check-In'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: _renderImage(base64String),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Current Bodyweight (kg)',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Observations',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ThemeService.primaryCyan, foregroundColor: Colors.black),
              onPressed: () {
                final weight = double.tryParse(weightCtrl.text.trim()) ?? profile.currentWeightKg;
                final calcBmi = heightM > 0 ? (weight / (heightM * heightM)) : profile.bmi;

                final entry = BodyPhotoEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  date: DateTime.now(),
                  imageBase64: base64String,
                  weightKg: weight,
                  bmi: calcBmi,
                  notes: notesCtrl.text.trim(),
                );

                ProfileService.instance.addBodyPhoto(entry);
                if (weight != profile.currentWeightKg) {
                  ProfileService.instance.logNewWeight(weight);
                }
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Weekly body check-in photo saved successfully!')),
                );
              },
              child: const Text('Save Check-In'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String photoId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('Are you sure you want to delete this weekly progress check-in photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              ProfileService.instance.deleteBodyPhoto(photoId);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
