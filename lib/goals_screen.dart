import 'package:flutter/material.dart';
import 'theme/app_colors.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() =>
      _GoalsScreenState();
}

class _GoalsScreenState
    extends State<GoalsScreen> {

  List<String> goals = [];

  void addGoal() {

    TextEditingController controller =
        TextEditingController();

    showDialog(
      context: context,

      builder: (context) {

        return AlertDialog(

          title: const Text(
            "Add Goal",
          ),

          content: TextField(
            controller: controller,

            decoration:
                const InputDecoration(
              hintText:
                  "Enter Goal",
            ),
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                "Cancel",
              ),
            ),

            ElevatedButton(
              onPressed: () {

                if (controller.text
                    .trim()
                    .isNotEmpty) {

                  setState(() {

                    goals.add(
                      controller.text.trim(),
                    );

                  });
                }

                Navigator.pop(context);

              },

              child: const Text(
                "Save",
              ),
            ),

          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      floatingActionButton:
          FloatingActionButton(

        backgroundColor:
            AppColors.primary,

        foregroundColor:
            Colors.white,

        onPressed: addGoal,

        child: const Icon(
          Icons.add,
        ),

      ),

      body: SafeArea(

        child: Padding(
          padding:
              const EdgeInsets.all(16),

          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const Text(
                "Goals",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              Expanded(

                child: goals.isEmpty

                    ? const Center(
                        child: Text(
                          "No Goals Yet",
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      )

                    : ListView.builder(

                        itemCount:
                            goals.length,

                        itemBuilder:
                            (context, index) {

                          return Card(

                            margin:
                                const EdgeInsets.only(
                              bottom: 10,
                            ),

                            child: ListTile(

                              leading:
                                  const CircleAvatar(
                                child: Icon(
                                  Icons.flag,
                                ),
                              ),

                              title: Text(
                                goals[index],
                              ),

                            ),
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