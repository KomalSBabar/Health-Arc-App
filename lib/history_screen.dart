import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {

  final List<Map<String, dynamic>> history;

  const HistoryScreen({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
      ),

      body: ListView.builder(
        itemCount: history.length,

        itemBuilder: (context, index) {

          final day = history[index];
          final sessions =
            List<Map<String, dynamic>>.from(
            day["sessions"] ?? [],
            );

            return Card(
                margin: const EdgeInsets.all(10),

                child: ExpansionTile(

                    title: Text(
                    day["date"],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                    ),
                    ),

                    subtitle: Text(
                    "${day["totalSteps"]} Steps",
                    ),

                    children: [

                    ...sessions.map((session) {

                        return ListTile(

                        leading: const Icon(
                            Icons.directions_walk,
                        ),

                        title: Text(
                            "${session["steps"]} Steps",
                        ),

                        subtitle: Text(
                            "${session["start"]}\n${session["end"]}",
                        ),

                        );

                    }),

                    ],

                ),
            );



        },
      ),
    );
  }
}