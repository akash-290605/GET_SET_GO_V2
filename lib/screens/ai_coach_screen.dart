import 'package:flutter/material.dart';
import '../widgets/titan_ai_sheet.dart';

class AiCoachScreen extends StatelessWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: TitanAiSheet(),
      ),
    );
  }
}
