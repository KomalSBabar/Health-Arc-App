
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_colors.dart';

class LongTermGoalScreen extends StatefulWidget {
  const LongTermGoalScreen({super.key});

  @override
  State<LongTermGoalScreen> createState() =>
      _LongTermGoalScreenState();
}

class _LongTermGoalScreenState extends State<LongTermGoalScreen> {
  List<Map<String, dynamic>> goals = [];

  bool isLoading = true;

  static const String storageKey = 'long_term_goals';

  final List<String> categories = [
    'Personal',
    'Career',
    'Health & Fitness',
    'Finance',
    'Education',
    'Other',
  ];

  final List<String> priorities = [
    'Low',
    'Medium',
    'High',
  ];

  final List<String> statuses = [
    'Not Started',
    'In Progress',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    loadGoals();
  }

  // Load saved goals
  Future<void> loadGoals() async {
    final prefs = await SharedPreferences.getInstance();

    final savedGoals = prefs.getString(storageKey);

    if (savedGoals != null) {
      final List<dynamic> decoded = jsonDecode(savedGoals);

      goals = decoded
          .map((goal) => Map<String, dynamic>.from(goal))
          .toList();
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Save goals
  Future<void> saveGoals() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      storageKey,
      jsonEncode(goals),
    );
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<DateTime?> pickDate(
    BuildContext context,
    DateTime initialDate,
  ) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  // Add or edit a goal
  Future<void> showGoalDialog({int? index}) async {
    final isEditing = index != null;

    final existingGoal =
        isEditing ? goals[index] : <String, dynamic>{};

    final titleController = TextEditingController(
      text: existingGoal['title'] ?? '',
    );

    final descriptionController = TextEditingController(
      text: existingGoal['description'] ?? '',
    );

    String selectedCategory =
        existingGoal['category'] ?? categories.first;

    String selectedPriority =
        existingGoal['priority'] ?? 'Medium';

    String selectedStatus =
        existingGoal['status'] ?? 'Not Started';

    DateTime startDate = existingGoal['startDate'] != null
        ? DateTime.parse(existingGoal['startDate'])
        : DateTime.now();

    DateTime targetDate = existingGoal['targetDate'] != null
        ? DateTime.parse(existingGoal['targetDate'])
        : DateTime.now().add(const Duration(days: 30));

    double progress =
        (existingGoal['progress'] ?? 0).toDouble();

    if (selectedStatus == 'Completed') {
      progress = 100;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Edit Goal' : 'Add Long-Term Goal',
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Goal Title *',
                          hintText: 'e.g. Buy a house',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Describe your goal...',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedCategory = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                        items: priorities.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Text(priority),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedPriority = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: statuses.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedStatus = value;

                              if (value == 'Completed') {
                                progress = 100;
                              } else if (progress == 100) {
                                progress = 0;
                              }
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Start date
                      const Text(
                        'Start Date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(formatDate(startDate)),
                        onPressed: () async {
                          final date = await pickDate(
                            context,
                            startDate,
                          );

                          if (date != null) {
                            setDialogState(() {
                              startDate = date;

                              if (targetDate.isBefore(startDate)) {
                                targetDate = startDate;
                              }
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      // Target date
                      const Text(
                        'Target Date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      OutlinedButton.icon(
                        icon: const Icon(Icons.flag),
                        label: Text(formatDate(targetDate)),
                        onPressed: () async {
                          final date = await pickDate(
                            context,
                            targetDate,
                          );

                          if (date != null) {
                            setDialogState(() {
                              targetDate = date;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Progress
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progress',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('${progress.round()}%'),
                        ],
                      ),

                      Slider(
                        value: progress,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        label: '${progress.round()}%',
                        onChanged: selectedStatus == 'Completed'
                            ? null
                            : (value) {
                                setDialogState(() {
                                  progress = value;

                                  if (progress == 100) {
                                    selectedStatus = 'Completed';
                                  } else if (selectedStatus ==
                                      'Completed') {
                                    selectedStatus = 'In Progress';
                                  } else if (progress > 0) {
                                    selectedStatus = 'In Progress';
                                  } else {
                                    selectedStatus = 'Not Started';
                                  }
                                });
                              },
                      ),
                    ],
                  ),
                ),
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
                        final title = titleController.text.trim();

                        if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                            content: Text('Please enter a goal title'),
                            ),
                        );
                        return;
                        }

                        final goal = <String, dynamic>{
                        'title': title,
                        'description': descriptionController.text.trim(),
                        'category': selectedCategory,
                        'priority': selectedPriority,
                        'status': selectedStatus,
                        'startDate': startDate.toIso8601String(),
                        'targetDate': targetDate.toIso8601String(),
                        'progress': progress.round(),
                        };

                        // Close dialog and return the goal data.
                        Navigator.pop(dialogContext, goal);
                    },
                    child: Text(isEditing ? 'Update' : 'Add Goal'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
        setState(() {
            if (isEditing) {
            goals[index] = result;
            } else {
            goals.add(result);
            }
        });

        await saveGoals();
    }

    titleController.dispose();
    descriptionController.dispose();
  }

  // Delete goal
  Future<void> deleteGoal(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Goal'),
          content: const Text(
            'Are you sure you want to delete this goal?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        goals.removeAt(index);
      });

      await saveGoals();
    }
  }

  Color priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedGoals = goals
        .where((goal) => goal['status'] == 'Completed')
        .length;

    return Scaffold(
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : goals.isEmpty
              ? _buildEmptyState()
              : _buildGoalsList(),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showGoalDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Goal'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 16),

            const Text(
              'No Long-Term Goals Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Create a goal and track your progress over time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () => showGoalDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Goal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsList() {
    final completedGoals = goals
        .where((goal) => goal['status'] == 'Completed')
        .length;

    return Column(
      children: [
        // Summary card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Long-Term Goals',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '${goals.length} total goals • '
                '$completedGoals completed',
              ),

              const SizedBox(height: 10),

              LinearProgressIndicator(
                value: goals.isEmpty
                    ? 0
                    : completedGoals / goals.length,
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        ),

        // Goal cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];

              final title = goal['title'] ?? '';
              final description = goal['description'] ?? '';
              final category = goal['category'] ?? 'Other';
              final priority = goal['priority'] ?? 'Medium';
              final status = goal['status'] ?? 'Not Started';
              final progress =
                  ((goal['progress'] ?? 0) as num).toDouble();

              final startDate = DateTime.parse(
                goal['startDate'],
              );

              final targetDate = DateTime.parse(
                goal['targetDate'],
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and action buttons
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              showGoalDialog(index: index);
                            },
                          ),

                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => deleteGoal(index),
                          ),
                        ],
                      ),

                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Category, priority and status chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChip(
                            category,
                            Colors.purple,
                          ),

                          _buildChip(
                            priority,
                            priorityColor(priority),
                          ),

                          _buildChip(
                            status,
                            statusColor(status),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Dates
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            size: 18,
                          ),

                          const SizedBox(width: 6),

                          Expanded(
                            child: Text(
                              '${formatDate(startDate)} - '
                              '${formatDate(targetDate)}',
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Progress
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progress',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text('${progress.round()}%'),
                        ],
                      ),

                      const SizedBox(height: 6),

                      LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(10),
                        color: statusColor(status),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
