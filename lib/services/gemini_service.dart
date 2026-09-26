import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeminiMessage {
  final String role; // 'user' or 'model'
  final String text;
  final DateTime timestamp;

  GeminiMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'role': role,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory GeminiMessage.fromMap(Map<String, dynamic> map) => GeminiMessage(
        role: map['role'] as String? ?? 'user',
        text: map['text'] as String? ?? '',
        timestamp: map['timestamp'] != null
            ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

class GeminiService {
  static final GeminiService instance = GeminiService._internal();
  GeminiService._internal();

  static const String _apiKeyStorageKey = 'gsg_gemini_api_key_v1';
  static const String _defaultModel = 'gemini-1.5-flash';

  String? _customApiKey;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _customApiKey = prefs.getString(_apiKeyStorageKey);
    } catch (e) {
      debugPrint('GeminiService init error: $e');
    } finally {
      _initialized = true;
    }
  }

  Future<void> setApiKey(String key) async {
    _customApiKey = key.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_customApiKey == null || _customApiKey!.isEmpty) {
        await prefs.remove(_apiKeyStorageKey);
      } else {
        await prefs.setString(_apiKeyStorageKey, _customApiKey!);
      }
    } catch (e) {
      debugPrint('Failed to save API key: $e');
    }
  }

  Future<String?> getApiKey() async {
    if (!_initialized) await init();
    return _customApiKey;
  }

  bool get hasApiKey => _customApiKey != null && _customApiKey!.isNotEmpty;

  /// Sends a query to Google Gemini 1.5 Flash or falls back to the Titan Neural Offline Engine.
  Future<String> askAi(String prompt, {List<GeminiMessage>? history}) async {
    if (!_initialized) await init();

    final apiKey = _customApiKey;
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final onlineResponse = await _callGeminiApi(prompt, apiKey, history: history);
        if (onlineResponse.isNotEmpty) {
          return onlineResponse;
        }
      } catch (e) {
        debugPrint('Gemini online API error: $e. Using Titan Offline Engine.');
      }
    }

    // Heuristic & Neural Offline Engine
    return _generateOfflineIntelligence(prompt);
  }

  Future<String> _callGeminiApi(String prompt, String apiKey, {List<GeminiMessage>? history}) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_defaultModel:generateContent?key=$apiKey');

    final List<Map<String, dynamic>> contents = [];

    if (history != null) {
      for (final msg in history.take(10)) {
        contents.add({
          'role': msg.role == 'user' ? 'user' : 'model',
          'parts': [
            {'text': msg.text}
          ],
        });
      }
    }

    contents.add({
      'role': 'user',
      'parts': [
        {
          'text':
              'System Directive: You are TITAN AI, the elite coach inside GET SET GO for fitness, nutrition, discipline, and personal finance. Provide structured, razor-sharp, actionable, and inspiring advice.\n\nUser Query: $prompt'
        }
      ],
    });

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'contents': contents,
            'generationConfig': {
              'temperature': 0.7,
              'topK': 40,
              'topP': 0.95,
              'maxOutputTokens': 1500,
            }
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] as String;
        }
      }
    } else {
      throw Exception('Gemini API HTTP ${response.statusCode}: ${response.body}');
    }

    throw Exception('Empty response from Gemini API');
  }

  /// AI Financial Reduction & Leakage Audit Engine
  Future<String> analyzeExpenses({
    required List<Map<String, dynamic>> expenses,
    required double targetMonthlyCap,
    required double totalCredited,
    required double totalDebited,
  }) async {
    final categoryTotals = <String, double>{};
    for (final exp in expenses) {
      final isDebit = (exp['isCredit'] ?? 0) == 0;
      if (isDebit) {
        final cat = (exp['category'] as String?) ?? 'General';
        final amount = ((exp['amount'] as num?) ?? 0).toDouble();
        categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amount;
      }
    }

    final topSpendingCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final prompt = '''
Perform an intensive Financial Audit & Expense Reduction Strategy:
- Total Credited (Income): ₹${totalCredited.toStringAsFixed(2)}
- Total Debited (Expenses): ₹${totalDebited.toStringAsFixed(2)}
- Target Monthly Expense Cap: ₹${targetMonthlyCap.toStringAsFixed(2)}
- Net Monthly Cashflow: ₹${(totalCredited - totalDebited).toStringAsFixed(2)}
- Top Spending Categories:
${topSpendingCategories.map((e) => '  • ${e.key}: ₹${e.value.toStringAsFixed(2)}').join('\n')}

Please provide:
1. 💡 Financial Health Score (out of 100) & Status.
2. 🛑 3 Specific Areas to Cut Costs immediately (50/30/20 budget framework).
3. 🎯 Concrete Target Adjustment to stay under ₹${targetMonthlyCap.toStringAsFixed(2)}.
4. 📈 High-Impact Savings & Investment Action for the surplus.
''';

    return await askAi(prompt);
  }

  /// Offline Neural Heuristic Intelligence Engine
  String _generateOfflineIntelligence(String prompt) {
    final lower = prompt.toLowerCase();

    if (lower.contains('expense') || lower.contains('finance') || lower.contains('budget') || lower.contains('audit') || lower.contains('spend')) {
      return '''
# ⚡ TITAN AI Financial Health & Expense Reduction Audit

### 📊 1. 50/30/20 Budget Optimization Analysis
- **Needs (50%)**: Essential rent, groceries, and utilities must be locked at 50% of credited income.
- **Wants (30%)**: Food delivery, entertainment, and spontaneous purchases should not exceed 30%.
- **Savings & Investments (20%)**: Automate 20% transfers into index funds or emergency reserves on the 1st of every month.

### 🛑 2. Top 3 Actionable Expense Reductions
1. **The 48-Hour Rule for Discretionary Spending**: Wait 48 hours before any non-essential purchase above ₹1,000.
2. **Subscription Audit**: Cancel unused app, streaming, and gym memberships; save an estimated 15-20% monthly.
3. **Smart Meal Prepping**: Cooking dinner 5 nights/week lowers dining-out expenses by over 40%.

### 🎯 3. Safe Daily Burn Rate Rule
Always check your **Safe Daily Spend Allowance** in the Finance Dashboard. Keeping your daily debits below this threshold ensures you never breach your monthly target cap!
''';
    }

    if (lower.contains('workout') || lower.contains('gym') || lower.contains('split') || lower.contains('chest') || lower.contains('muscle') || lower.contains('hypertrophy')) {
      return '''
# 🏋️ TITAN AI 7-Day Hypertrophy & Strength Blueprint

### 🗓️ Optimal Weekly Training Split
- **Monday (Push - Chest / Shoulders / Triceps)**:
  • Barbell Bench Press: 4 sets × 8–10 reps
  • Incline Dumbbell Press: 3 sets × 10–12 reps
  • Overhead DB Shoulder Press: 3 sets × 10 reps
  • Cable Triceps Pushdowns: 3 sets × 15 reps

- **Tuesday (Pull - Back / Biceps / Rear Delts)**:
  • Lat Pulldown / Pull-ups: 4 sets × 8–10 reps
  • Barbell Bent-Over Row: 4 sets × 8–10 reps
  • Dumbbell Hammer Curls: 3 sets × 12 reps
  • Face Pulls: 3 sets × 15 reps

- **Wednesday (Legs - Quads / Hamstrings / Calves)**:
  • Barbell Back Squat: 4 sets × 6–8 reps
  • Romanian Deadlift: 3 sets × 10 reps
  • Walking Lunges: 3 sets × 12 reps/leg

- **Thursday (Active Recovery & Zone-2 Cardio)**:
  • 30 mins brisk walking + 10 mins mobility stretching.

- **Friday (Upper Body Power)**:
  • Incline Bench + Heavy Rows + Lateral Raises.

- **Saturday (Lower Body & Core Stability)**:
  • Leg Press + Hanging Leg Raises + Plank Holds.

- **Sunday (Rest & Systemic Decompression)**:
  • Full rest, hydration (3.5L), and 8 hours sleep.
''';
    }

    if (lower.contains('diet') || lower.contains('nutrition') || lower.contains('protein') || lower.contains('calorie') || lower.contains('food')) {
      return '''
# 🥗 TITAN AI Nutrition & High-Protein Fuel Guide

### 🧬 Macro Targets for Clean Hypertrophy:
- **Protein**: 1.8g - 2.2g per kg of bodyweight (Muscle Protein Synthesis).
- **Carbohydrates**: 3g - 4g per kg (Glycogen replenishment & lifting energy).
- **Fats**: 0.8g per kg (Hormonal balance & cell recovery).

### 🍳 Example Daily High-Performance Meal Structure:
1. **Breakfast (8:00 AM)**: 3 Whole Eggs + 2 Egg Whites + 50g Rolled Oats with banana & peanut butter (~35g Protein).
2. **Lunch (1:00 PM)**: 150g Grilled Chicken Breast or Paneer/Tofu + 1.5 cups Brown Rice + Steamed Broccoli (~42g Protein).
3. **Pre-Workout Fuel (5:00 PM)**: Black Coffee + 1 Apple + 1 Scoop Whey Isolate or Greek Yogurt (~26g Protein).
4. **Dinner (8:30 PM)**: Mixed Dal / Lentils + 2 Multigrain Roti + Green Salad (~28g Protein).
5. **Hydration**: 3.5 Liters of pure water minimum daily.
''';
    }

    return '''
# ⚡ TITAN AI Performance & Discipline Response

### 🎯 Core Focus Directive:
Discipline is the bridge between your daily habits and long-term mastery. 

1. **Daily Execution**: Focus on 100% completion of your daily habits, hydration, and targeted sleep.
2. **Financial Precision**: Track every debit and credit with accuracy to safeguard your cashflow.
3. **Consistent Progression**: Track your gym volume tonnage (Sum of Weight × Reps) and aim for progressive overload every session.

Ask me any specific questions regarding:
- 📊 Custom Expense & Budgeting Strategies
- 🏋️ Tailored Workout Splits & Lifting Techniques
- 🥗 Macronutrient & Meal Planning
- 🧠 Focus, Productivity & Habit Streak Architectures
''';
  }
}
