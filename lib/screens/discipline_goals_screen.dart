import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../models/goal_models.dart';
import '../services/theme_service.dart';
import '../widgets/glass_card.dart';

class DisciplineGoalsScreen extends StatefulWidget {
  const DisciplineGoalsScreen({super.key});

  @override
  State<DisciplineGoalsScreen> createState() => _DisciplineGoalsScreenState();
}

class _DisciplineGoalsScreenState extends State<DisciplineGoalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<GoalItem> _goals = [];
  List<DeletedGoalRecord> _deletedGoals = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // 'All', 'Strict Only', 'Normal To-Do', 'Completed Today', 'Needs Action'

  final List<String> _categories = [
    'General',
    'Fitness & Health',
    'Study & Reading',
    'Career & Code',
    'Finance & Budget',
    'Mindfulness & Sleep',
    'Daily Habit',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final goalMaps = await DBHelper.instance.fetchGoals();
      final deletedMaps = await DBHelper.instance.fetchDeletedGoals();

      if (mounted) {
        setState(() {
          _goals = goalMaps.map((m) => GoalItem.fromMap(m)).toList();
          _deletedGoals = deletedMaps.map((m) => DeletedGoalRecord.fromMap(m)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<GoalItem> get _filteredGoals {
    return _goals.where((g) {
      if (_selectedFilter == 'Strict Only') return g.isStrict;
      if (_selectedFilter == 'Normal To-Do') return !g.isStrict;
      if (_selectedFilter == 'Completed Today') return g.isCompletedToday;
      if (_selectedFilter == 'Needs Action') return !g.isCompletedToday;
      return true;
    }).toList();
  }

  Future<void> _toggleGoalCompletion(GoalItem goal) async {
    final now = DateTime.now();

    if (goal.isCompletedToday) {
      // Toggle off / Undo
      final updatedStreak = (goal.currentStreak > 1) ? goal.currentStreak - 1 : 0;
      await DBHelper.instance.updateGoal(goal.id, updatedStreak, null);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unmarked goal completion for today.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Check if strict mode and streak was broken
    if (goal.isStrict && goal.isStreakBroken) {
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.accentRose, size: 26),
              SizedBox(width: 8),
              Expanded(
                child: Text('Strict Streak Reset Warning', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Text(
            '⚠️ Strict Discipline Rule:\nYou missed checking in yesterday. As per strict discipline rules, your streak of ${goal.currentStreak} days will reset to Day 1.\n\nDo you want to start fresh and restart Day 1 today?',
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRose,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset & Start Day 1'),
            ),
          ],
        ),
      );

      if (proceed != true) return;

      await DBHelper.instance.updateGoal(goal.id, 1, now.toIso8601String());
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Streak reset to Day 1. Stay committed! 🔥'),
            backgroundColor: AppColors.accentRose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Normal or consecutive completion
    final newStreak = goal.currentStreak + 1;
    await DBHelper.instance.updateGoal(goal.id, newStreak, now.toIso8601String());
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStreak >= goal.targetDays
                ? '🎉 Congratulations! You completed your ${goal.targetDays}-day target for "${goal.title}"!'
                : '🔥 Checked in for today! Streak is now $newStreak / ${goal.targetDays} days!',
          ),
          backgroundColor: newStreak >= goal.targetDays ? AppColors.accentGreen : AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddGoalDialog() {
    final titleCtrl = TextEditingController();
    int targetDays = 30;
    bool isStrict = true;
    String category = 'Fitness & Health';
    final customDaysCtrl = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: const Row(
                children: [
                  Icon(Icons.add_task_rounded, color: AppColors.primaryGlow),
                  SizedBox(width: 8),
                  Text('New Goal & Habit Tracker', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Goal Title / Habit Name',
                        hintText: 'e.g. 5 AM Wake Up, 75 Hard, 1 Hr Coding',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Mode Selection: Strict vs Normal
                    Text('Discipline Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).hintColor)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => isStrict = true),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isStrict ? AppColors.accentRose.withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isStrict ? AppColors.accentRose : Theme.of(context).dividerColor.withValues(alpha: 0.2),
                                  width: isStrict ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.local_fire_department_rounded, color: AppColors.accentRose, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'STRICT',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isStrict ? AppColors.accentRose : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Missed 1 day resets streak to 1. Deleting requires apology letter.',
                                    style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => isStrict = false),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: !isStrict ? AppColors.accentBlue.withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: !isStrict ? AppColors.accentBlue : Theme.of(context).dividerColor.withValues(alpha: 0.2),
                                  width: !isStrict ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.checklist_rounded, color: AppColors.accentBlue, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'NORMAL',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: !isStrict ? AppColors.accentBlue : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Flexible to-do list. Easily deletable without penalty.',
                                    style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Target Days Presets
                    Text('Target Duration (Days)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).hintColor)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [7, 14, 21, 30, 75, 90, 100].map((days) {
                        final selected = targetDays == days;
                        return ChoiceChip(
                          label: Text('$days Days'),
                          selected: selected,
                          selectedColor: AppColors.primary.withValues(alpha: 0.25),
                          onSelected: (val) {
                            setModalState(() {
                              targetDays = days;
                              customDaysCtrl.text = days.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: customDaysCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Custom Target Days',
                        border: OutlineInputBorder(),
                        suffixText: 'Days',
                      ),
                      onChanged: (val) {
                        final v = int.tryParse(val);
                        if (v != null && v > 0) {
                          setModalState(() => targetDays = v);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => category = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;

                    final finalDays = int.tryParse(customDaysCtrl.text) ?? targetDays;
                    final newGoal = GoalItem(
                      title: title,
                      targetDays: finalDays > 0 ? finalDays : 21,
                      isStrict: isStrict,
                      category: category,
                      currentStreak: 0,
                      createdDate: DateTime.now(),
                      auditHistory: [
                        '[${DateTime.now().toString().substring(0, 10)}] Goal created with $finalDays days target (${isStrict ? 'Strict Discipline' : 'Normal To-Do'}).'
                      ],
                    );

                    final nav = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(context);

                    await DBHelper.instance.insertGoal(newGoal.toMap());
                    await _loadData();

                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Created ${isStrict ? 'Strict' : 'Normal'} goal: "$title"'),
                        backgroundColor: AppColors.accentGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Create Goal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditGoalDialog(GoalItem goal) {
    if (goal.isStrict) {
      _showStrictEditDialog(goal);
    } else {
      _showNormalEditDialog(goal);
    }
  }

  void _showNormalEditDialog(GoalItem goal) {
    final titleCtrl = TextEditingController(text: goal.title);
    final targetCtrl = TextEditingController(text: goal.targetDays.toString());
    String category = goal.category;
    bool isStrict = goal.isStrict;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: const Text('Edit To-Do Goal', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Goal Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Target Days', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _categories.contains(category) ? category : _categories.first,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Convert to Strict Discipline Goal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Enforce daily streaks & accountability audits', style: TextStyle(fontSize: 11)),
                      value: isStrict,
                      activeThumbColor: AppColors.accentRose,
                      onChanged: (val) => setModalState(() => isStrict = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final t = titleCtrl.text.trim();
                    final d = int.tryParse(targetCtrl.text) ?? goal.targetDays;
                    if (t.isEmpty) return;

                    goal.title = t;
                    goal.targetDays = d;
                    goal.category = category;
                    goal.isStrict = isStrict;
                    goal.auditHistory.add('[${DateTime.now().toString().substring(0, 10)}] Updated goal details.');

                    final nav = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(context);

                    await DBHelper.instance.insertGoal(goal.toMap());
                    await _loadData();

                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Goal updated successfully!'), behavior: SnackBarBehavior.floating),
                    );
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showStrictEditDialog(GoalItem goal) {
    final titleCtrl = TextEditingController(text: goal.title);
    final targetCtrl = TextEditingController(text: goal.targetDays.toString());
    final reasonCtrl = TextEditingController();
    DateTime changeDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: const Row(
                children: [
                  Icon(Icons.shield_rounded, color: AppColors.accentAmber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Strict Goal Modification Protocol', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        '⚠️ Strict Discipline Rule:\nAll modifications require selecting a change date and entering a mandatory reason that will be permanently recorded in your audit history.',
                        style: TextStyle(fontSize: 11.5, height: 1.35),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Goal Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Target Days', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    // Date picker row
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: changeDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setModalState(() => changeDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Change Effective Date:', style: TextStyle(fontSize: 12.5, color: Theme.of(context).hintColor)),
                            Text('${changeDate.year}-${changeDate.month.toString().padLeft(2, '0')}-${changeDate.day.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Mandatory Reason for Change *',
                        hintText: 'e.g. Schedule adjustment due to semester exams...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentAmber,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    final t = titleCtrl.text.trim();
                    final reason = reasonCtrl.text.trim();
                    final d = int.tryParse(targetCtrl.text) ?? goal.targetDays;

                    if (t.isEmpty) return;
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚠️ Reason for change is mandatory in Strict Mode!'),
                          backgroundColor: AppColors.accentRose,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    final dateStr = '${changeDate.year}-${changeDate.month.toString().padLeft(2, '0')}-${changeDate.day.toString().padLeft(2, '0')}';
                    goal.title = t;
                    goal.targetDays = d;
                    goal.auditHistory.add('[$dateStr] Modified target to $d days. Reason: $reason');

                    final nav = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(context);

                    await DBHelper.instance.insertGoal(goal.toMap());
                    await _loadData();

                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Strict goal updated & change logged to audit record.'),
                        backgroundColor: AppColors.accentGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Log & Apply Change'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleDeleteGoal(GoalItem goal) {
    if (goal.isStrict) {
      _showStrictApologyProtocolDialog(goal);
    } else {
      _showNormalDeleteDialog(goal);
    }
  }

  void _showNormalDeleteDialog(GoalItem goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Delete To-Do Goal?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${goal.title}"? This is a normal goal and will be removed immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose, foregroundColor: Colors.white),
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);

              await DBHelper.instance.deleteGoal(goal.id);
              await _loadData();

              nav.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('Goal deleted.'), behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showStrictApologyProtocolDialog(GoalItem goal) {
    String selectedReason = 'Procrastination / Lost Motivation';
    final apologyCtrl = TextEditingController();

    final failureReasons = [
      'Procrastination / Lost Motivation',
      'Poor Time Management & Distractions',
      'Set an Overambitious Target',
      'Burnout & Physical Fatigue',
      'Life Shift / Change of Priorities',
      'Personal Emergency / Health Issue',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final textLen = apologyCtrl.text.trim().length;
            final isValid = textLen >= 15;

            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: const Row(
                children: [
                  Icon(Icons.gavel_rounded, color: AppColors.accentRose, size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Strict Apology Protocol', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accentRose)),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentRose.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🚨 GIVING UP ON STRICT COMMITMENT',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.accentRose, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Goal: "${goal.title}"\nStreak Achieved: ${goal.currentStreak} / ${goal.targetDays} Days\n\nTo delete this strict goal, you must select the failure cause and write an Apology Letter to yourself. It will be stored permanently in the Hall of Accountability.',
                            style: const TextStyle(fontSize: 12, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Failure Reason Dropdown
                    Text('Why are you abandoning this streak? *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).hintColor)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedReason,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      items: failureReasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12.5)))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedReason = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Apology Letter Text
                    Text('Apology Letter & Self-Reflection * (min 15 chars)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).hintColor)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: apologyCtrl,
                      maxLines: 4,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: 'I am quitting this goal because... I acknowledge that I lost discipline and I promise myself that next time I will...',
                        hintStyle: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor.withValues(alpha: 0.6)),
                        border: const OutlineInputBorder(),
                        helperText: 'Characters: $textLen / 15 required',
                        helperStyle: TextStyle(
                          color: isValid ? AppColors.accentGreen : AppColors.accentRose,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Back / Keep Goal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isValid ? AppColors.accentRose : Theme.of(context).disabledColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isValid
                      ? () async {
                          final record = DeletedGoalRecord(
                            title: goal.title,
                            streakAchieved: goal.currentStreak,
                            targetDays: goal.targetDays,
                            reason: selectedReason,
                            apologyLetter: apologyCtrl.text.trim(),
                            deletedAt: DateTime.now(),
                          );

                          final nav = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(context);

                          // Insert into deleted_goals table
                          await DBHelper.instance.insertDeletedGoal(record.toMap());
                          // Delete from active goals
                          await DBHelper.instance.deleteGoal(goal.id);
                          await _loadData();

                          nav.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Strict goal abandoned. Apology letter archived in Hall of Accountability.'),
                              backgroundColor: AppColors.accentRose,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          _tabController.animateTo(1);
                        }
                      : null,
                  child: const Text('Sign Apology & Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAuditHistoryDialog(GoalItem goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            const Icon(Icons.history_edu_rounded, color: AppColors.primaryGlow),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Audit History: "${goal.title}"', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: goal.auditHistory.isEmpty
              ? const Text('No modification records logged.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: goal.auditHistory.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (context, idx) {
                    final entry = goal.auditHistory[idx];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.accentAmber),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(entry, style: const TextStyle(fontSize: 12, height: 1.3)),
                        ),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Strict Discipline & Goals',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary(isDark),
          tabs: [
            Tab(
              icon: const Icon(Icons.track_changes_rounded),
              text: 'Active Goals (${_goals.length})',
            ),
            Tab(
              icon: const Icon(Icons.history_edu_rounded),
              text: 'Apology Archive (${_deletedGoals.length})',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGoalDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Goal'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveGoalsTab(isDark),
                _buildApologyArchiveTab(isDark),
              ],
            ),
    );
  }

  Widget _buildActiveGoalsTab(bool isDark) {
    final filtered = _filteredGoals;
    final completedCount = _goals.where((g) => g.isCompletedToday).length;
    final strictCount = _goals.where((g) => g.isStrict).length;
    final maxStreak = _goals.isEmpty ? 0 : _goals.map((g) => g.currentStreak).reduce((a, b) => a > b ? a : b);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Active Streaks',
                    value: '$completedCount / ${_goals.length}',
                    subtitle: 'Checked in today',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.accentGreen,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Best Streak',
                    value: '$maxStreak Days',
                    subtitle: '$strictCount strict active',
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.accentRose,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Strict Only', 'Normal To-Do', 'Completed Today', 'Needs Action'].map((f) {
                  final isSelected = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.primaryGlow,
                      onSelected: (_) => setState(() => _selectedFilter = f),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Goals List
            if (filtered.isEmpty)
              GlassCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.checklist_rounded, size: 48, color: AppColors.textSecondary(isDark)),
                    const SizedBox(height: 12),
                    Text('No goals found in this view', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
                    const SizedBox(height: 6),
                    Text('Tap "+ New Goal" to set a strict habit or to-do item.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark))),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final goal = filtered[index];
                  return _buildGoalCard(goal, isDark);
                },
              ),
            const SizedBox(height: 80), // Fab spacing
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return GlassCard(
      borderColor: color.withValues(alpha: 0.30),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary(isDark))),
                Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textSecondary(isDark))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(GoalItem goal, bool isDark) {
    final isDone = goal.isCompletedToday;
    final isBroken = goal.isStrict && goal.isStreakBroken;
    final progress = goal.progressPercentage;

    return GlassCard(
      borderRadius: 16,
      borderColor: isBroken
          ? AppColors.accentRose.withValues(alpha: 0.6)
          : isDone
              ? AppColors.accentGreen.withValues(alpha: 0.45)
              : (goal.isStrict
                  ? AppColors.accentRose.withValues(alpha: 0.25)
                  : AppColors.primary.withValues(alpha: 0.25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Badges & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: goal.isStrict ? AppColors.accentRose.withValues(alpha: 0.15) : AppColors.accentBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          goal.isStrict ? Icons.local_fire_department_rounded : Icons.checklist_rounded,
                          size: 13,
                          color: goal.isStrict ? AppColors.accentRose : AppColors.accentBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          goal.isStrict ? 'STRICT DISCIPLINE' : 'NORMAL TO-DO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: goal.isStrict ? AppColors.accentRose : AppColors.accentBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F0F172A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(goal.category, style: TextStyle(fontSize: 10, color: AppColors.textSecondary(isDark))),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded, size: 20, color: AppColors.textSecondary(isDark)),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showEditGoalDialog(goal);
                  } else if (val == 'delete') {
                    _handleDeleteGoal(goal);
                  } else if (val == 'audit') {
                    _showAuditHistoryDialog(goal);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Edit Goal', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  if (goal.auditHistory.isNotEmpty)
                    const PopupMenuItem(
                      value: 'audit',
                      child: Row(
                        children: [
                          Icon(Icons.history_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Audit Log', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.accentRose),
                        const SizedBox(width: 8),
                        Text(
                          goal.isStrict ? 'Delete (Apology Required)' : 'Delete To-Do',
                          style: const TextStyle(fontSize: 13, color: AppColors.accentRose),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title & Streak
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target: ${goal.targetDays} Days • Current Streak: ${goal.currentStreak} Days',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark)),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _toggleGoalCompletion(goal),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.accentGreen.withValues(alpha: 0.15)
                        : isBroken
                            ? AppColors.accentRose.withValues(alpha: 0.15)
                            : AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDone
                          ? AppColors.accentGreen
                          : isBroken
                              ? AppColors.accentRose
                              : AppColors.primary,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDone
                            ? Icons.check_circle_rounded
                            : isBroken
                                ? Icons.warning_amber_rounded
                                : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: isDone
                            ? AppColors.accentGreen
                            : isBroken
                                ? AppColors.accentRose
                                : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isDone
                            ? 'Done Today'
                            : isBroken
                                ? 'Streak Broken'
                                : 'Mark Done',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDone
                              ? AppColors.accentGreen
                              : isBroken
                                  ? AppColors.accentRose
                                  : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(progress * 100).toStringAsFixed(0)}% Complete', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary(isDark))),
              Text('${goal.currentStreak} / ${goal.targetDays} Days', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F0F172A),
              valueColor: AlwaysStoppedAnimation<Color>(
                isBroken
                    ? AppColors.accentRose
                    : isDone
                        ? AppColors.accentGreen
                        : AppColors.primary,
              ),
            ),
          ),

          if (isBroken) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentRose.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: AppColors.accentRose),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Missed check-in yesterday. Completing will restart streak from Day 1.',
                      style: TextStyle(fontSize: 10.5, color: AppColors.accentRose),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApologyArchiveTab(bool isDark) {
    if (_deletedGoals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_rounded, size: 54, color: AppColors.accentGreen),
              ),
              const SizedBox(height: 16),
              Text('Clean Record of Discipline! 🛡️', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
              const SizedBox(height: 6),
              Text(
                'You have not abandoned any strict discipline goals. Keep your commitments strong and unbreakable!',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary(isDark), height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _deletedGoals.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final record = _deletedGoals[index];
          final dateStr = '${record.deletedAt.day.toString().padLeft(2, '0')} ${_getMonthName(record.deletedAt.month)} ${record.deletedAt.year}';

          return GlassCard(
            borderRadius: 16,
            borderColor: AppColors.accentRose.withValues(alpha: 0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Stamp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentRose.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.history_edu_rounded, size: 12, color: AppColors.accentRose),
                          SizedBox(width: 4),
                          Text('ARCHIVED APOLOGY LETTER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.accentRose, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    Text(dateStr, style: TextStyle(fontSize: 11, color: AppColors.textSecondary(isDark))),
                  ],
                ),
                const SizedBox(height: 10),

                // Title & Failed Target
                Text(
                  record.title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, decoration: TextDecoration.lineThrough, color: AppColors.textPrimary(isDark)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Target was: ${record.targetDays} Days', style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark))),
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(color: AppColors.textSecondary(isDark))),
                    const SizedBox(width: 8),
                    Text('Achieved: ${record.streakAchieved} Days', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentRose)),
                  ],
                ),
                const SizedBox(height: 8),

                // Failure Reason Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F0F172A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Cause: ${record.reason}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark))),
                ),
                const Divider(height: 20),

                // Apology Letter Content
                Text('Letter to Self:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary(isDark))),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Text(
                    '"${record.apologyLetter}"',
                    style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, height: 1.4, color: AppColors.textPrimary(isDark)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }
}
