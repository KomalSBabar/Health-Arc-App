import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {

  const HistoryScreen({
    super.key
  });

  @override
  State<HistoryScreen> createState() =>
    _HistoryScreenState();
}

    class _HistoryScreenState extends State<HistoryScreen> {
        List<Map<String, dynamic>> history = [];

        @override
        void initState() {
        super.initState();
        loadHistory();
        }

        Future<void> loadHistory() async {

            final prefs =
                await SharedPreferences.getInstance();

            String historyData =
                prefs.getString('history') ?? '[]';
            print(historyData);
            setState(() {

                history =
                    List<Map<String, dynamic>>.from(
                jsonDecode(historyData),
                );

            });
        }

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
                            formatDate(day["date"]),
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
                                    "${formatTime(session["start"])} - ${formatTime(session["end"])}",
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



  String formatDate(String date) {

        try {

            final parts = date.split('-');

            final fixedDate =
                "${parts[0]}-"
                "${parts[1].padLeft(2, '0')}-"
                "${parts[2].padLeft(2, '0')}";

            final parsedDate =
                DateTime.parse(fixedDate);

            return DateFormat(
            'dd MMM yyyy',
            ).format(parsedDate);

        } catch (e) {

            return date;

        }
    }

    String formatTime(String dateTime) {

  try {

    final parsedDateTime =
        DateTime.parse(dateTime);

    return DateFormat(
      'hh:mm a',
    ).format(parsedDateTime);

  } catch (e) {

    return dateTime;

  }

}
