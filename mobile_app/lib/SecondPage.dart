import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'history.dart';

class SecondPage extends StatefulWidget {
  const SecondPage({super.key});
  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  Map<String, dynamic> allDesks = {};
  List<String> deskKeys = [];
  int currentIndex = 0;
  bool isLoading = true;
  String lastUpdated = "";
  String? selectedActivity;
  Map<String, Map<String, String>> startEndData = {};
  Map<String, Map<String, dynamic>> deskStates = {};

  @override
  void initState() {
    super.initState();
    fetchDeskStatus();
    listenToDeskTimes();
  }

  Future<void> fetchDeskStatus() async {
    final ref = FirebaseDatabase.instance.ref();
    ref.child('desk_times').onValue.listen((event) async {
      final dataSnapshot = event.snapshot;
      if (!dataSnapshot.exists) return;

      final data = Map<String, dynamic>.from(dataSnapshot.value as Map);
      final updatedData = <String, dynamic>{};

      data.forEach((deskKey, activities) {
        updatedData[deskKey] = Map<String, dynamic>.from(activities);
      });

      final nowStr = DateFormat('hh:mm a').format(DateTime.now());

      setState(() {
        allDesks = updatedData;
        deskKeys = updatedData.keys.toList();
        if (currentIndex >= deskKeys.length) currentIndex = 0;
      });

      await loadStartEndTimes(deskKeys[currentIndex]);

      setState(() {
        isLoading = false;
        lastUpdated = nowStr;
      });
    });
  }

  Future<void> loadStartEndTimes(String deskName) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final basePath = 'desk_activity_logs/$deskName';

    final ref = FirebaseDatabase.instance.ref().child(basePath);
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      List<Map<String, dynamic>> allLogs = [];

      data.forEach((activityName, activityMap) {
        if (activityMap is Map && activityMap.containsKey(today)) {
          final dayMap = Map<String, dynamic>.from(activityMap[today]);

          dayMap.forEach((logId, logData) {
            final log = Map<String, dynamic>.from(logData);
            final start = log['start'];
            if (start != null) {
              allLogs.add({
                'activity': activityName,
                'start': start,
                'time': DateFormat('HH:mm:ss').parse(start),
              });
            }
          });
        }
      });

      allLogs.sort((a, b) => a['time'].compareTo(b['time']));

      startEndData.clear();
      for (int i = 0; i < allLogs.length; i++) {
        final current = allLogs[i];
        final next = i + 1 < allLogs.length ? allLogs[i + 1] : null;

        final start = DateFormat('hh:mm:ss a').format(current['time']);
        final end =
            next != null
                ? DateFormat('hh:mm:ss a').format(next['time'])
                : DateFormat('hh:mm:ss a').format(DateTime.now());

        final activityName = current['activity'];

        if (!startEndData.containsKey(activityName)) {
          startEndData[activityName] = {'start': start, 'end': end};
        } else {
          startEndData[activityName]!['end'] = end;
        }
      }
    }
  }

  void showDesk(int index) async {
    setState(() {
      currentIndex = index;
      selectedActivity = null;
      isLoading = true;
    });

    await loadStartEndTimes(deskKeys[currentIndex]);

    setState(() {
      isLoading = false;
    });
  }

  void listenToDeskTimes() {
    final ref = FirebaseDatabase.instance.ref().child('desk_times');

    ref.onValue.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      data.forEach((deskName, activityMap) {
        final activities = Map<String, dynamic>.from(activityMap);

        final currentActivity = getMostActive(activities);
        final now = DateTime.now();

        if (!deskStates.containsKey(deskName)) {
          deskStates[deskName] = {'activity': currentActivity, 'start': now};
          saveToHistory(deskName, currentActivity, now, null);
        } else {
          final previous = deskStates[deskName]!;

          if (previous['activity'] != currentActivity) {
            saveToHistory(
              deskName,
              previous['activity'],
              previous['start'],
              now,
            );

            deskStates[deskName] = {'activity': currentActivity, 'start': now};

            saveToHistory(deskName, currentActivity, now, null);
          }
        }
      });
    });
  }

  String getMostActive(Map<String, dynamic> activities) {
    String maxKey = '';
    int maxValue = -1;

    activities.forEach((key, value) {
      final val = int.tryParse(value.toString()) ?? 0;
      if (val > maxValue) {
        maxValue = val;
        maxKey = key;
      }
    });

    return maxKey;
  }

  void saveToHistory(
    String desk,
    String activity,
    DateTime start,
    DateTime? end,
  ) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final ref =
        FirebaseDatabase.instance
            .ref()
            .child('desk_times_history')
            .child(today)
            .child(desk)
            .push();

    final entry = {
      'activity': activity,
      'start': DateFormat('HH:mm:ss').format(start),
      'end': end != null ? DateFormat('HH:mm:ss').format(end) : "",
    };

    ref.set(entry);
  }

  String formatDuration(int seconds) {
    if (seconds < 60) {
      return "$seconds sec";
    } else if (seconds < 3600) {
      int minutes = seconds ~/ 60;
      return "$minutes min${minutes > 1 ? 's' : ''}";
    } else {
      int hours = seconds ~/ 3600;
      int minutes = (seconds % 3600) ~/ 60;
      return "$hours h ${minutes > 0 ? '$minutes min' : ''}";
    }
  }

  double calculateWorkPerformance(Map<String, dynamic> activityValues) {
    final working = activityValues['Working'] ?? 0;
    final eating = activityValues['Eating'] ?? 0;
    final sleeping = activityValues['Sleeping'] ?? 0;
    final phone = activityValues['Speaking on phone'] ?? 0;

    final total = working + eating + sleeping + phone;
    if (total == 0) return 0;

    final ratio = working / total;

    return (ratio * 5).clamp(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    final gradientBackground = const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.fromARGB(223, 20, 38, 82),
          Color.fromARGB(255, 247, 247, 247),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Search for all"),
        backgroundColor: const Color.fromARGB(224, 23, 40, 79),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: gradientBackground,
        padding: const EdgeInsets.all(20),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : deskKeys.isEmpty
                ? const Center(
                  child: Text(
                    "No desk data available",
                    style: TextStyle(color: Colors.white),
                  ),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Desk: ${deskKeys[currentIndex]}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...buildDeskEntries(
                      Map<String, dynamic>.from(
                        allDesks[deskKeys[currentIndex]],
                      ),
                    ),
                    buildOverallRatingCard(
                      Map<String, dynamic>.from(
                        allDesks[deskKeys[currentIndex]],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed:
                              currentIndex > 0
                                  ? () => showDesk(currentIndex - 1)
                                  : null,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text("Previous"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              195,
                              24,
                              49,
                              79,
                            ),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 30),
                        ElevatedButton.icon(
                          onPressed:
                              currentIndex < deskKeys.length - 1
                                  ? () => showDesk(currentIndex + 1)
                                  : null,
                          label: const Text("Next"),
                          icon: const Icon(Icons.arrow_forward),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              195,
                              24,
                              49,
                              79,
                            ),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        lastUpdated.isNotEmpty
                            ? "Last Update $lastUpdated"
                            : "",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  List<Widget> buildDeskEntries(Map<dynamic, dynamic> data) {
    return data.entries
        .where(
          (entry) => entry.key.toString().toLowerCase() != 'starts',
        ) // تجاهل starts
        .map((entry) {
          final activityKey = entry.key.toString();
          final activityValue = entry.value.toString();
          final isSelected = selectedActivity == activityKey;

          final String startTime =
              startEndData[activityKey]?['start'] ?? "Not Available";
          final String endTime =
              startEndData[activityKey]?['end'] ?? "Not Available";

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 5, 58, 96),
                    Color.fromARGB(255, 247, 247, 247),
                  ],
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.label_important,
                      size: 16,
                      color: Color.fromARGB(255, 91, 147, 225),
                    ),
                    title: Text(
                      "$activityKey: ${formatDuration(int.tryParse(activityValue.toString()) ?? 0)}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.expand_more,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                    tileColor: Colors.transparent,
                    onTap:
                        () => setState(() {
                          selectedActivity =
                              selectedActivity == activityKey
                                  ? null
                                  : activityKey;
                        }),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Start: $startTime",
                            style: const TextStyle(
                              color: Color.fromARGB(255, 10, 39, 78),
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "End: $endTime",
                            style: const TextStyle(
                              color: Color.fromARGB(255, 10, 39, 78),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        })
        .toList();
  }

  Widget buildOverallRatingCard(Map<String, dynamic> data) {
    final rating = calculateWorkPerformance(data);

    return Card(
      margin: const EdgeInsets.only(top: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 5, 58, 96),
              Color.fromARGB(255, 247, 247, 247),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Performance evaluation",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating.round() ? Icons.star : Icons.star_border,
                    color: const Color.fromARGB(206, 255, 193, 7),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
