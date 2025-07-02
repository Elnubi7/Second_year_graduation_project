import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: IdSearch());
  }
}

class IdSearch extends StatefulWidget {
  const IdSearch({super.key});

  @override
  State<IdSearch> createState() => _IdSearchState();
}

class _IdSearchState extends State<IdSearch> {
  final TextEditingController _idController = TextEditingController();
  Map<String, dynamic>? deskData;
  bool isLoading = false;

  void fetchDeskDataById(String enteredId) async {
    setState(() {
      isLoading = true;
      deskData = null;
    });

    String deskKey = "Desk$enteredId";

    final ref = FirebaseDatabase.instance.ref().child('desk_times/$deskKey');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        deskData = data;
        isLoading = false;
      });
    } else {
      setState(() {
        deskData = null;
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Desk Not Found')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search by ID"),
        backgroundColor: const Color.fromARGB(224, 23, 40, 79),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(223, 20, 38, 82),
              Color.fromARGB(255, 247, 247, 247),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _idController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Search By ID',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.person, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_idController.text.isNotEmpty) {
                  fetchDeskDataById(_idController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(195, 24, 49, 79),
                foregroundColor: Colors.white,
              ),
              child: const Text("Search"),
            ),
            const SizedBox(height: 30),
            if (isLoading)
              const CircularProgressIndicator()
            else if (deskData != null)
              buildDeskCard(deskData!),
          ],
        ),
      ),
    );
  }

  Widget buildDeskCard(Map<String, dynamic> data) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
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
          children:
              data.entries
                  .where(
                    (entry) => [
                      'Speaking on phone',
                      'Sleeping',
                      'Working',
                      'Eating',
                    ].contains(entry.key.toString()),
                  )
                  .map((entry) {
                    return infoRow(
                      entry.key.toString(),
                      entry.value.toString(),
                    );
                  })
                  .toList(),
        ),
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.label_important,
            size: 15,
            color: Color.fromARGB(255, 41, 138, 212),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
