import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class NameSearch extends StatefulWidget {
  const NameSearch({super.key});

  @override
  State<NameSearch> createState() => _NameSearchState();
}

class _NameSearchState extends State<NameSearch> {
  final TextEditingController _NameController = TextEditingController();
  Map<String, dynamic> allDesks = {};
  Map<String, dynamic>? selectedDesk;
  bool isLoading = false;

  void searchDeskByName(String name) async {
    setState(() {
      isLoading = true;
    });

    final ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child('desk_times').get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final matchedKey = data.keys.firstWhere(
        (key) => key.toLowerCase() == name.toLowerCase(),
        orElse: () => '',
      );

      if (matchedKey.isNotEmpty) {
        setState(() {
          selectedDesk = Map<String, dynamic>.from(data[matchedKey]);
          isLoading = false;
        });
      } else {
        setState(() {
          selectedDesk = null;
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Desk not found')));
      }
    } else {
      setState(() {
        selectedDesk = null;
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No desk data found')));
    }
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
        title: const Text("Search By Name"),
        backgroundColor: const Color.fromARGB(224, 23, 40, 79),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: gradientBackground,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _NameController,
              keyboardType: TextInputType.text,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Search By Name',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.person_search_sharp,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_NameController.text.isNotEmpty) {
                  searchDeskByName(_NameController.text.trim());
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
            else if (selectedDesk != null)
              buildDeskCard(selectedDesk!),
          ],
        ),
      ),
    );
  }

  Widget buildDeskCard(Map<dynamic, dynamic> data) {
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
