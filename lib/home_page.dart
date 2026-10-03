import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_screen.dart';
import 'package:intl/intl.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage  extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription<StepCount>? _subscription;

  int todaySteps = 0; 
  int sessionSteps = 0;
  int startSteps = 0;

  DateTime? sessionStartTime;
  List<Map<String, dynamic>> todaySessions = [];
  List<Map<String, dynamic>> history = [];
  bool isCounting = false;
  String savedDate = "";

  @override
  void initState() {
    super.initState();
    loadSavedSteps();
  }

  Future<void> loadSavedSteps() async {

    final prefs = await SharedPreferences.getInstance();

    String sessionData =
        prefs.getString('todaySessions') ?? '[]';

    String historyData =
        prefs.getString('history') ?? '[]';

    savedDate = prefs.getString('savedDate') ?? '';    
    // savedDate = "2026-09-30";

    setState(() {

      todaySteps =
          prefs.getInt('todaySteps') ?? 0;

      isCounting =
          prefs.getBool('isCounting') ?? false;

      todaySessions =
          List<Map<String, dynamic>>.from(
            jsonDecode(sessionData),
          );

      history =
        List<Map<String, dynamic>>.from(
          jsonDecode(historyData),
        );

    });

    if (savedDate.isEmpty) {

      savedDate = getTodayDate();

      await saveSteps();

    }

    await checkForNewDay();

  }

  Future<void> saveSteps() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('todaySteps', todaySteps);
    await prefs.setBool('isCounting', isCounting);
    await prefs.setString('savedDate', savedDate);
    await prefs.setString('history', jsonEncode(history),);

    await prefs.setString(
      'todaySessions',
      jsonEncode(todaySessions),
    );

  }

  Future<void> startCounting() async {
    final status =
        await Permission.activityRecognition.request();

    if (!status.isGranted) {
      print("Permission Denied");
      return;
    }

    setState(() {
      isCounting = true;
      sessionStartTime = DateTime.now();
    });

    await saveSteps();

    _subscription?.cancel();

    _subscription = Pedometer.stepCountStream.listen(
      (StepCount event) {
        print("Sensor Steps: ${event.steps}");

        if (startSteps == 0) {
          startSteps = event.steps;
        }

        setState(() {
          sessionSteps  = event.steps - startSteps;
        });

        saveSteps();
      },
      onError: (error) {
        print("Sensor Error: $error");
      },
    );
  }

  Future<void> stopCounting() async {

    _subscription?.cancel();

    setState(() {

      if (sessionSteps > 0 && sessionStartTime != null) {
        todaySessions.add({
          "start": sessionStartTime.toString(),
          "end": DateTime.now().toString(),
          "steps": sessionSteps,
        });
      }

      todaySteps += sessionSteps;

      sessionSteps = 0;

      startSteps = 0;

      isCounting = false;

    });

    await saveSteps();

  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Step Counter"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

             Card(
                margin: const EdgeInsets.all(16),

                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    children: [

                      const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [

                          Icon(
                            Icons.directions_walk,
                            size: 30,
                          ),

                          SizedBox(width: 10),

                          Text(
                            "Today's Steps",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      Text(
                        NumberFormat(
                          '#,###',
                        ).format(todaySteps),

                        style: const TextStyle(
                          fontSize: 55,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),

                        decoration: BoxDecoration(
                          color: isCounting
                              ? Colors.green.shade100
                              : Colors.red.shade100,

                          borderRadius:
                              BorderRadius.circular(20),
                        ),

                        child: Text(
                          isCounting
                              ? "Counting..."
                              : "Stopped",
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 10),

            Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
              ),

              child: Padding(
                padding: const EdgeInsets.all(18),

                child: Column(
                  children: [

                    const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [

                        Icon(
                          Icons.timer,
                        ),

                        SizedBox(width: 8),

                        Text(
                          "Current Session",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    Text(
                      "$sessionSteps Steps",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  ],
                ),
              ),
            ),
            


            const SizedBox(height: 30),

            const Padding(
                padding: EdgeInsets.only(
                  left: 16,
                ),

                child: Align(
                  alignment: Alignment.centerLeft,

                  child: Text(
                    "Today's Sessions",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: todaySessions.length,
                itemBuilder: (context, index) {

                  final session = todaySessions[index];

                  return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),

                      child: ListTile(

                        leading: const CircleAvatar(
                          child: Icon(
                            Icons.directions_walk,
                          ),
                        ),

                        title: Text(
                          "${session["steps"]} Steps",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        subtitle: Text(
                          "${formatTime(session["start"])} - "
                          "${formatTime(session["end"])}",
                        ),
                      ),
                    );
                },
              ),
            ),



            const SizedBox(height: 10),

           Row(
              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: startCounting,

                    icon: const Icon(
                      Icons.play_arrow,
                    ),

                    label: const Text(
                      "START",
                    ),

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.primary,
                      foregroundColor:
                          Colors.white,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: stopCounting,

                    icon: const Icon(
                      Icons.stop,
                    ),

                    label: const Text(
                      "STOP",
                    ),

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.danger,
                      foregroundColor:
                          Colors.white,
                    ),
                  ),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }


  // helper method 

String getTodayDate() {
  return DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime.now());
}

  Future<void> checkForNewDay() async {

    String today = getTodayDate();

    if (savedDate.isNotEmpty &&
        savedDate != today) {

      history.add({
        "date": savedDate,
        "totalSteps": todaySteps,
        "sessions": todaySessions,
      });

      todaySteps = 0;

      todaySessions = [];

      savedDate = today;

      await saveSteps();
    }
  }

  String formatTime(String dateTime) {
    final parsedDateTime =
        DateTime.parse(dateTime);

    return DateFormat(
      'hh:mm a',
    ).format(parsedDateTime);
  }

}