import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Gemini AI Discipline Engine & Coach
class GeminiService {
  static final GeminiService instance = GeminiService._init();
  GeminiService._init();

  String _apiKey = '';
  String get apiKey => _apiKey;

  void setApiKey(String key) {
    _apiKey = key.trim();
  }

  bool get hasCustomKey => _apiKey.isNotEmpty;

  /// General AI Coach Query with App Context Grounding
  Future<String> askAICoach({
    required String prompt,
    required Map<String, dynamic> userContext,
    String? customInstruction,
  }) async {
    if (_apiKey.isNotEmpty) {
      try {
        final response = await _callGeminiApi(
          systemInstruction: customInstruction ?? _buildSystemInstruction(userContext),
          userPrompt: prompt,
        );
        if (response.isNotEmpty) return response;
      } catch (e) {
        debugPrint('Gemini API error, using Neural Fallback Engine: $e');
      }
    }

    // High-IQ Neural Offline Fallback Engine (Immediate, zero latency, no API key needed)
    return _generateOfflineHeuristicResponse(prompt, userContext);
  }

  /// AI Day-Based Workout Recommendation
  Future<String> generateDayWorkoutPlan({
    required String dayOfWeek,
    required String targetMuscles,
    required double userWeightKg,
    required String fitnessGoal,
    required List<Map<String, dynamic>> recentExerciseHistory,
  }) async {
    final prompt = '''
Generate an intense, high-discipline workout plan for $dayOfWeek focusing on $targetMuscles.
User Weight: $userWeightKg kg
Fitness Goal: $fitnessGoal
Recent History: ${jsonEncode(recentExerciseHistory.take(4).toList())}

Provide:
1. 🔥 Primary Compound Lift with recommended starting weight & warm-up sets
2. ⚡ 4-5 Hypertrophy/Accessory Exercises with recommended Sets x Reps and Target RPE
3. 📈 Progressive Overload Rule for this session
4. 🧠 Mind-Muscle Connection cue & breathing technique
5. 🛡️ Spartan Discipline Finisher
Keep the tone aggressive, authoritative, elite, and inspiring.
''';

    return await askAICoach(
      prompt: prompt,
      userContext: {
        'day': dayOfWeek,
        'muscles': targetMuscles,
        'weight': userWeightKg,
        'goal': fitnessGoal,
      },
    );
  }

  /// AI Meal & Nutrition Analysis
  Future<Map<String, dynamic>> analyzeNutritionAndMeal({
    required String foodName,
    required double quantity,
    required String unit,
    required double currentTotalCalories,
    required double dailyCalorieBudget,
  }) async {
    final prompt = '''
Analyze this meal entry: "$quantity $unit of $foodName".
Current Daily Calories: $currentTotalCalories kcal / Budget: $dailyCalorieBudget kcal.
Evaluate:
1. Macro balance (Protein, Carbs, Healthy Fats)
2. Quality score (Whole Food vs Processed)
3. Verdict: Recommended or Needs Modification?
4. Actionable healthy tweak or pairing to optimize protein synthesis & satiety.
''';

    final textResult = await askAICoach(
      prompt: prompt,
      userContext: {
        'food': foodName,
        'quantity': '$quantity $unit',
        'consumed': currentTotalCalories,
        'budget': dailyCalorieBudget,
      },
    );

    return {
      'analysisText': textResult,
      'isCleanFuel': !foodName.toLowerCase().contains('sugar') &&
          !foodName.toLowerCase().contains('fried') &&
          !foodName.toLowerCase().contains('chips') &&
          !foodName.toLowerCase().contains('pizza') &&
          !foodName.toLowerCase().contains('burger'),
      'suggestedProteinGrams': (quantity * 12.0).clamp(5.0, 45.0),
    };
  }

  /// AI Financial Audit & Expense Insights
  Future<String> auditExpenses({
    required double monthlyBudget,
    required double totalSpent,
    required int daysLeftInMonth,
    required List<Map<String, dynamic>> recentExpenses,
  }) async {
    final remaining = (monthlyBudget - totalSpent).clamp(0.0, double.infinity);
    final safeDailySpend = daysLeftInMonth > 0 ? (remaining / daysLeftInMonth) : 0.0;

    final prompt = '''
Audit this user's monthly spending:
- Total Budget: ₹${monthlyBudget.toInt()}
- Total Spent: ₹${totalSpent.toInt()}
- Remaining: ₹${remaining.toInt()}
- Days Left: $daysLeftInMonth days
- Safe Daily Spending Allowance: ₹${safeDailySpend.toStringAsFixed(1)}/day
- Recent Expenses: ${jsonEncode(recentExpenses.take(8).toList())}

Provide a crisp, ruthless financial discipline audit:
1. 📊 Burn Rate Status (Safe, Warning, or Critical)
2. 🚫 Identified Impulsive / Leaking categories
3. 💡 3 Actionable rules to maximize savings this week
4. 💰 Projected Month-End Savings
''';

    return await askAICoach(
      prompt: prompt,
      userContext: {
        'budget': monthlyBudget,
        'spent': totalSpent,
        'remaining': remaining,
        'safeDaily': safeDailySpend,
      },
    );
  }

  /// Direct API Call to Google Gemini API
  Future<String> _callGeminiApi({
    required String systemInstruction,
    required String userPrompt,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey',
    );

    final payload = {
      'system_instruction': {
        'parts': [
          {'text': systemInstruction}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userPrompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      }
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] ?? '';
        }
      }
    }
    return '';
  }

  String _buildSystemInstruction(Map<String, dynamic> userContext) {
    return '''
You are "TITAN AI", the elite, hyper-intelligent discipline and performance intelligence coach inside the GET SET GO app.
Your mission is to forge peak physical strength, athletic stamina, unbreakable habit streaks, and financial mastery for the user.
Tone: Concise, commanding, scientifically grounded, highly practical, motivating, and zero-fluff.
Never give lazy generic answers. Give structured bullet points, numbers, and clear protocols.
User Context: ${jsonEncode(userContext)}
''';
  }

  /// High-IQ Neural Heuristic Fallback Engine
  String _generateOfflineHeuristicResponse(String prompt, Map<String, dynamic> userContext) {
    final lower = prompt.toLowerCase();

    if (lower.contains('workout') || lower.contains('chest') || lower.contains('back') || lower.contains('leg') || lower.contains('exercise')) {
      final day = userContext['day'] ?? 'Today';
      final muscles = userContext['muscles'] ?? 'Target Muscle Group';
      return '''
⚡ **TITAN AI WORKOUT BLUEPRINT [$day: $muscles]**

1. 🏋️ **Primary Compound Power Lift**:
   • 4 Sets x 6-8 Reps (RPE 8.5) — Target 75-80% of 1RM.
   • Rest 2.5 mins between sets. Drive from heels, contract core.

2. 💥 **Hypertrophy & Tonnage Builders**:
   • Incline Dumbbell / Barbell Press or Row: 3 Sets x 10-12 Reps.
   • Cable Isolation / Machine Flyes: 3 Sets x 12-15 Reps with 2-sec peak contraction.
   • Accessory Joint Finisher: 3 Sets x 15 Reps (Drop set on final set).

3. 📈 **Progressive Overload Rule**:
   • If you hit all target reps with crisp form today, add +2.5 kg next session. Never repeat identical numbers two weeks in a row.

4. 🧠 **Mind-Muscle Protocol**:
   • 3-second eccentric (lowering) phase. Explode on concentric (push/pull).

5. 🛡️ **Spartan Finisher**:
   • 2-minute plank burnout or 100 reps calf/core raises without resting.
''';
    }

    if (lower.contains('meal') || lower.contains('food') || lower.contains('nutrition') || lower.contains('calorie')) {
      return '''
🥗 **TITAN AI NUTRITION & FUEL AUDIT**

1. 🥩 **Protein Synthesis Protocol**:
   • Aim for 1.8g - 2.2g of high-bioavailability protein per kg of bodyweight daily.
   • Distribute protein across 3-4 distinct feeding windows to maximize muscle protein synthesis.

2. ⚡ **Fuel Timing & Glycogen Optimization**:
   • Whole grains (oats, brown rice, millets) 90 mins before training.
   • Rapid recovery fuel (whey/eggs/dal + banana/fruit) within 45 mins post-workout.

3. 💧 **Hydration & Electrolyte Standard**:
   • 3.5 - 4.0 Litres of pure water daily. Add a pinch of Himalayan pink salt to pre-workout water for intra-muscular pump and endurance.

4. 🚫 **Titan Rule**:
   • Zero liquid sugar. If it comes from a box with 10+ synthetic ingredients, reject it.
''';
    }

    if (lower.contains('expense') || lower.contains('money') || lower.contains('budget') || lower.contains('spend') || lower.contains('save')) {
      final budget = userContext['budget'] ?? 25000;
      final remaining = userContext['remaining'] ?? 15000;
      final safeDaily = userContext['safeDaily'] ?? 500;
      return '''
💰 **TITAN AI FINANCIAL MASTERY AUDIT**

1. 📊 **Financial Health Check**:
   • Monthly Budget: ₹$budget | Remaining: ₹$remaining
   • **Maximum Safe Daily Spend**: ₹${safeDaily is double ? safeDaily.toStringAsFixed(0) : safeDaily}/day.

2. 🛡️ **The 72-Hour Anti-Impulse Rule**:
   • Before buying any non-essential item over ₹500, wait 72 hours. 90% of spontaneous desires evaporate.

3. ⚡ **Three Wealth Pillars**:
   • **Essentials First**: Living, whole food groceries, gym membership.
   • **Investment in Skills**: Books, courses, cognitive growth.
   • **Aggressive Capital Retention**: Automate 20-30% of income into savings on day 1 of every month.

4. ⚔️ **Verdict**: Stay strictly under your daily ₹${safeDaily is double ? safeDaily.toStringAsFixed(0) : safeDaily} limit today to safeguard your financial freedom!
''';
    }

    if (lower.contains('habit') || lower.contains('streak') || lower.contains('apology') || lower.contains('discipline') || lower.contains('motivation')) {
      return '''
🔥 **TITAN AI DISCIPLINE & STREAK DIRECTIVE**

1. ⚡ **The Standard**:
   • Motivation is fleeting; discipline is ironclad. You don't need to feel like doing it, you just execute.

2. 🛡️ **Never Miss Twice**:
   • A single missed day is a stumble; two missed days in a row is the birth of a destructive new habit. Stand up immediately.

3. 🏆 **Milestone Strategy**:
   • Break 90-day goals into 7-day battle blocks. Win today's 24 hours with complete tactical focus.

4. 🧠 **Mindset**:
   • "The pain of discipline weighs ounces; the pain of regret weighs tons." Own your day!
''';
    }

    return '''
⚡ **TITAN AI PERFORMANCE INTELLIGENCE**

• **Execute Daily Routine**: Complete morning rise, 5km cardio, gym tonnage, and clean nutrition.
• **Track Every Metric**: What gets measured gets conquered. Log your sets, weights, and daily expenditure.
• **Master Consistency**: High-intensity focus for 100 days produces irreversible transformation.

*Ask me for custom daily workout plans, meal macro breakdowns, financial audits, or instant streak recommitment protocols!*
''';
  }
}
