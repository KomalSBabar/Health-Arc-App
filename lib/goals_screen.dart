
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_colors.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<Map<String, dynamic>> goals = [];

  @override
  void initState() {
    super.initState();
    loadGoals();
  }

  Future<void> loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalData = prefs.getString('goals') ?? '[]';

    try {
      final decoded = jsonDecode(goalData) as List;

      final loadedGoals = decoded.map<Map<String, dynamic>>((item) {
        // Support goals saved by the previous version.
        if (item is String) {
          return {
            'title': item,
            'completed': false,
          };
        }

        // Support goals saved with completion status.
        return {
          'title': item['title']?.toString() ?? '',
          'completed': item['completed'] == true,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        goals = loadedGoals;
      });

      // Save everything in the new format.
      // await saveGoals();
    } catch (e) {
      debugPrint('Error loading goals: $e');
    }
  }

  Future<void> saveGoals() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'goals',
      jsonEncode(goals),
    );
  }

  Future<void> addGoal() async {
    final controller = TextEditingController();

    try {
      final String? title = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Add Goal'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Enter Goal',
              ),
              onSubmitted: (value) {
                Navigator.pop(dialogContext, value.trim());
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    controller.text.trim(),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (!mounted || title == null || title.isEmpty) {
        return;
      }

      setState(() {
        goals.add({
          'title': title,
          'completed': false,
        });
      });

      await saveGoals();
    } finally {
      // Dispose after the dialog's exit animation finishes.
      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      );
      controller.dispose();
    }
  }

  Future<void> toggleGoal(int index, bool? value) async {
    setState(() {
      goals[index]['completed'] = value ?? false;
    });

    await saveGoals();
  }

  
  Future<void> deleteGoal(int index) async {
    if (index < 0 || index >= goals.length) return;

    final removedGoal = goals[index];

    setState(() {
      goals.removeAt(index);
    });

    try {
      await saveGoals();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        goals.insert(index.clamp(0, goals.length), removedGoal);
      });

      debugPrint('Error deleting goal: $e');
    }
  }


  Future<void> confirmDeleteGoal(int index) async {
      if (index < 0 || index >= goals.length) return;
    
    final goalTitle = goals[index]['title'] as String;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Goal?'),
          content: Text(
             'Are you sure you want to delete "$goalTitle"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldDelete != true) return;

    await deleteGoal(index);
  }

  
  Future<void> editGoal(int index) async {
    if (index < 0 || index >= goals.length) return;

    final controller = TextEditingController(
      text: goals[index]['title'] as String,
    );

    String? updatedTitle;

    try {
      updatedTitle = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Edit Goal'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Enter goal title',
              ),
              onSubmitted: (value) {
                Navigator.pop(dialogContext, value.trim());
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    controller.text.trim(),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    } finally {
      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      );
      controller.dispose();
    }

    if (!mounted ||
        updatedTitle == null ||
        updatedTitle.isEmpty) {
      return;
    }

    final oldTitle = goals[index]['title'];

    setState(() {
      goals[index]['title'] = updatedTitle;
    });

    try {
      await saveGoals();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        goals[index]['title'] = oldTitle;
      });

      debugPrint('Error updating goal: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: addGoal,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Goals',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              
              Expanded(
                child: goals.isEmpty
                    ? const Center(
                        child: Text(
                          'No Goals Yet',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          final sortedGoals = [...goals]
                            ..sort((a, b) {
                              final aCompleted = a['completed'] == true;
                              final bCompleted = b['completed'] == true;

                              if (aCompleted == bCompleted) return 0;
                              return aCompleted ? 1 : -1;
                            });

                          return ListView.builder(
                            itemCount: sortedGoals.length,
                            itemBuilder: (context, index) {
                              final goal = sortedGoals[index];
                              final isCompleted = goal['completed'] == true;
                              final originalIndex = goals.indexOf(goal);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: CheckboxListTile(
                                        value: isCompleted,
                                        activeColor: AppColors.primary,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        title: Text(
                                          goal['title'] as String,
                                          style: TextStyle(
                                            decoration: isCompleted
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                            color:
                                                isCompleted ? Colors.grey : null,
                                          ),
                                        ),
                                        subtitle: Text(
                                          isCompleted ? 'Completed' : 'Pending',
                                        ),
                                        onChanged: (value) {
                                          toggleGoal(originalIndex, value);
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: 'Edit goal',
                                      onPressed: () {
                                        editGoal(originalIndex);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Delete goal',
                                      onPressed: () {
                                        confirmDeleteGoal(originalIndex);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
