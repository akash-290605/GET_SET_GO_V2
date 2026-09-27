import 'package:flutter/material.dart';
import '../screens/ai_coach_screen.dart';

class TitanAiSheet extends StatelessWidget {
  const TitanAiSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        child: SizedBox(
          height: 650,
          child: AiCoachScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const AiCoachScreen();
  }
}
