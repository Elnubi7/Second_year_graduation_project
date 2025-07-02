import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> activityLog = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    listenToDeskChanges();
  }

  void listenToDeskChanges() {
    final ref = FirebaseDatabase.instance.ref().child('desk_times');
    ref.onValue.listen((event) {
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(now);
      final formattedTime = DateFormat('hh:mm:ss a').format(now);

      if (!event.snapshot.exists) return;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      data.forEach((desk, activityMap) {
        final activities = Map<String, dynamic>.from(activityMap);
        final mostActive = getMostActive(activities);

        if (activityLog.isEmpty ||
            activityLog.last['desk'] != desk ||
            activityLog.last['activity'] != mostActive) {
          setState(() {
            activityLog.add({
              'desk': desk,
              'date': formattedDate,
              'activity': mostActive,
              'start': formattedTime,
              'end': '',
            });
          });
        } else {
          setState(() {
            activityLog.last['end'] = formattedTime;
          });
        }
      });

      setState(() {
        loading = false;
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
        title: const Text("History"),
        backgroundColor: const Color.fromARGB(224, 23, 40, 79),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: gradientBackground,
        padding: const EdgeInsets.all(16.0),
        child:
            loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                  itemCount: activityLog.length,
                  itemBuilder: (context, index) {
                    final log = activityLog[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Desk: ${log['desk']}  |  Date: ${log['date']}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Activity: ${log['activity']}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "Start: ${log['start']}   End: ${getNextStartTime(index)}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  String getNextStartTime(int index) {
    final currentLog = activityLog[index];

    for (int i = index + 1; i < activityLog.length; i++) {
      final nextLog = activityLog[i];

      if (nextLog['desk'] == currentLog['desk']) {
        return nextLog['start'];
      }
    }

    return "Not Available";
  }
}
