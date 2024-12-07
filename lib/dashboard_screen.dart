import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? selectedKidID;
  List<Map<String, dynamic>> kidsList = [];

  // Function to fetch the kids list from Firestore
  Future<void> fetchKids() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final kidSnapshot = await FirebaseFirestore.instance
          .collection('kids')
          .where('parentID', isEqualTo: currentUser.uid)
          .get();

      setState(() {
        kidsList = kidSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
            'photoURL': doc['photoURL'],
          };
        }).toList();
      });
    }
  }

// Function to calculate monthly points for a selected kid
Future<int> calculateMonthlyPoints(String kidID) async {
  final result = await FirebaseFirestore.instance
      .collection('schedules')
      .where('kidID', isEqualTo: kidID)
      .where('status', isEqualTo: "Done")
      .get();

  // Safely summing the points, ensuring points is treated as an integer
  int totalPoints = 0;

  // Loop over the documents to sum points
  for (var doc in result.docs) {
    // Make sure doc['points'] is an integer
    int points = (doc['points'] is int) ? doc['points'] : 0;
    totalPoints += points;
  }

  return totalPoints;
}


  @override
  void initState() {
    super.initState();
    fetchKids(); // Fetch the kids list when the screen loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Points Summary'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown to select a kid
            DropdownButton<String>(
              hint: const Text('Select a Kid'),
              value: selectedKidID,
              onChanged: (String? newKidID) {
                setState(() {
                  selectedKidID = newKidID;
                });
              },
              items: kidsList.map((kid) {
                return DropdownMenuItem<String>(
                  value: kid['id'],
                  child: Text(kid['name']),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Display the points for the selected kid
            selectedKidID == null
                ? const Center(child: Text('Please select a kid.'))
                : FutureBuilder<int>(
                    future: calculateMonthlyPoints(selectedKidID!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (snapshot.hasData) {
                        return Text(
                          'Points this month: ${snapshot.data}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        );
                      } else {
                        return const Text('No points for this month.');
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
