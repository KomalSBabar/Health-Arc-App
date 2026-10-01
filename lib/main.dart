import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StepCounterScreen(),
    );
  }
}

class StepCounterScreen extends StatefulWidget {
  const StepCounterScreen({super.key});

  @override
  State<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen> {
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
            const Text(
              "Today's Steps",
              style: TextStyle(
                fontSize: 24,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "$todaySteps",
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              isCounting ? "Counting..." : "Stopped",
              style: const TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Current Session: $sessionSteps",
              style: const TextStyle(
                fontSize: 18,
              ),
            ),  
            

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: startCounting,
              child: const Text("START"),
            ),

            const SizedBox(height: 30),

            const Text(
              "Today's Sessions",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: todaySessions.length,
                itemBuilder: (context, index) {

                  final session = todaySessions[index];

                  return ListTile(
                    title: Text(
                      "${session["steps"]} Steps",
                    ),
                    subtitle: Text(
                      "${session["start"]}\n${session["end"]}",
                    ),
                  );
                },
              ),
            ),

            ElevatedButton(
              onPressed: () {

                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (context) =>
                        HistoryScreen(
                      history: history,
                    ),
                  ),
                );

              },

              child: const Text(
                "View History",
              ),
            ),



            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: stopCounting,
              child: const Text("STOP"),
            ),
          ],
        ),
      ),
    );
  }


  // helper method 

  String getTodayDate() {
   final now = DateTime.now();
    return  "${now.year}-${now.month}-${now.day}";
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

}