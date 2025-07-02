import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class EvaluationPage extends StatefulWidget {
  const EvaluationPage({super.key});

  @override
  State<EvaluationPage> createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<EvaluationPage> {
  Map<String, Map<String, double>> allDesksData = {};
  List<String> deskKeys = [];
  int currentIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEvaluationData();
  }

  void fetchEvaluationData() async {
    final ref = FirebaseDatabase.instance.ref().child('desk_times');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final result = <String, Map<String, double>>{};

      data.forEach((deskKey, activityMap) {
        final activities = Map<String, dynamic>.from(activityMap);
        result[deskKey] = Map.fromEntries(
          activities.entries
              .where((entry) => entry.value is num)
              .map(
                (entry) => MapEntry(entry.key, (entry.value as num).toDouble()),
              ),
        );
      });

      setState(() {
        allDesksData = result;
        deskKeys = result.keys.toList();
        isLoading = false;
      });
    }
  }

  double getRating(double seconds) {
    if (seconds >= 300) return 5;
    if (seconds >= 200) return 4;
    if (seconds >= 100) return 3;
    if (seconds >= 50) return 2;
    if (seconds > 0) return 1;
    return 0;
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

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (deskKeys.isEmpty) {
      return const Scaffold(body: Center(child: Text("No Data Available")));
    }

    final currentDeskKey = deskKeys[currentIndex];
    final activityDurations = allDesksData[currentDeskKey]!;
    final total = activityDurations.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Evaluation"),
        backgroundColor: const Color.fromARGB(224, 23, 40, 79),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: gradientBackground,
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Desk: $currentDeskKey',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections:
                      activityDurations.entries.map((entry) {
                        final percent =
                            total == 0 ? 0 : (entry.value / total) * 100;
                        return PieChartSectionData(
                          color: _getColorForActivity(entry.key),
                          value: entry.value,
                          title: '${entry.key}\n${percent.toStringAsFixed(1)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Star Ratings per Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            ...activityDurations.entries.map((entry) {
              final rating = getRating(entry.value);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(entry.key),
                  subtitle: Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      );
                    }),
                  ),
                  trailing: Text("${entry.value.toStringAsFixed(0)}s"),
                ),
              );
            }),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed:
                      currentIndex > 0
                          ? () => setState(() => currentIndex--)
                          : null,
                  child: const Text("Previous"),
                ),
                ElevatedButton(
                  onPressed:
                      currentIndex < deskKeys.length - 1
                          ? () => setState(() => currentIndex++)
                          : null,
                  child: const Text("Next"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForActivity(String activity) {
    switch (activity) {
      case 'Working':
        return const Color.fromARGB(255, 71, 103, 179);
      case 'Eating':
        return const Color.fromARGB(255, 113, 164, 184);
      case 'Sleeping':
        return const Color.fromARGB(255, 4, 42, 55);
      case 'Speaking on phone':
        return const Color.fromARGB(255, 118, 132, 255);
      default:
        return const Color.fromARGB(255, 212, 202, 202);
    }
  }
}
