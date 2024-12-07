import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  _ActivitiesScreenState createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final _activityController = TextEditingController();
  String? selectedKidID;
  List<Map<String, dynamic>> kidsList = [];

  // Function to fetch kids from Firestore
  Future<void> fetchKids() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final kidsSnapshot = await FirebaseFirestore.instance
          .collection('kids')
          .where('parentID', isEqualTo: currentUser.uid)
          .get();

      setState(() {
        kidsList = kidsSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
          };
        }).toList();
      });
    }
  }

  // Function to add an activity to Firestore
  Future<void> addActivity(String kidID, String activityName) async {
    if (kidID.isEmpty || activityName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a kid and enter an activity name')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('activities').add({
        'name': activityName,
        'kidID': kidID,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity added successfully')),
      );
      _activityController.clear(); // Clear the activity input field
    } catch (e) {
      print('Error adding activity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding activity')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchKids(); // Fetch the list of kids when the screen is loaded
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Activities'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Kid Dropdown
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
            const SizedBox(height: 16),

            // Activity Name Input Field
            TextFormField(
              controller: _activityController,
              decoration: const InputDecoration(
                labelText: 'Activity Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.star),
              ),
            ),
            const SizedBox(height: 16),

            // Add Activity Button
            ElevatedButton(
              onPressed: () async {
                if (selectedKidID != null && _activityController.text.isNotEmpty) {
                  await addActivity(selectedKidID!, _activityController.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a kid and enter an activity name')),
                  );
                }
              },
              child: const Text('Add Activity'),
            ),
          ],
        ),
      ),
    );
  }
}
