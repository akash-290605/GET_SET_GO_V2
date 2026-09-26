import 'package:flutter/material.dart';
import '../screens/ai_coach_screen.dart';
import '../main.dart';

class TitanAiSheet extends StatelessWidget {
  const TitanAiSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const TitanAiSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: AppColors.primaryGlow, width: 1.5),
              left: BorderSide(color: AppColors.borderLight, width: 1),
              right: BorderSide(color: AppColors.borderLight, width: 1),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
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
              Expanded(
                child: AiCoachScreen(
                  onBack: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
