import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityStatusScreen extends StatefulWidget {
  const ActivityStatusScreen({super.key});

  @override
  _ActivityStatusScreenState createState() => _ActivityStatusScreenState();
}

class _ActivityStatusScreenState extends State<ActivityStatusScreen> {
  String? selectedKidID;
  List<Map<String, dynamic>> scheduleList = [];

  // Function to fetch the scheduled activities for a kid
  Future<void> fetchSchedules() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final scheduleSnapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .where('kidID', isEqualTo: selectedKidID)
          .get();

      setState(() {
        scheduleList = scheduleSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'day': doc['day'],
            'timeSlot': doc['timeSlot'],
            'activityID': doc['activityID'],
            'status': doc['status'],
            'points': doc['points'],
          };
        }).toList();
      });
    }
  }

  // Function to update the activity status and assign points
  Future<void> updateActivityStatus(String scheduleID, String status, int points) async {
    try {
      await FirebaseFirestore.instance.collection('schedules').doc(scheduleID).update({
        'status': status,
        'points': points,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Activity marked as $status with $points points')),
      );
    } catch (e) {
      print('Error updating activity status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating status')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSchedules(); // Fetch schedules when screen loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Activities as Done and Assign Points'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kid Dropdown (to select a kid for marking activities)
            DropdownButton<String>(
              hint: const Text('Select a Kid'),
              value: selectedKidID,
              onChanged: (String? newKidID) {
                setState(() {
                  selectedKidID = newKidID;
                  fetchSchedules(); // Fetch new schedules after kid selection
                });
              },
              items: const [
                // Example kids dropdown, in real use fetch from Firestore
                DropdownMenuItem<String>(
                  value: 'kid1',
                  child: Text('Kid 1'),
                ),
                DropdownMenuItem<String>(
                  value: 'kid2',
                  child: Text('Kid 2'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Displaying the scheduled activities
            Expanded(
              child: ListView.builder(
                itemCount: scheduleList.length,
                itemBuilder: (context, index) {
                  final schedule = scheduleList[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text('${schedule['day']} - ${schedule['timeSlot']}'),
                      subtitle: Text('Activity ID: ${schedule['activityID']}'),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Status Button
                          ElevatedButton(
                            onPressed: () async {
                              await updateActivityStatus(schedule['id'], "Done", 10);
                            },
                            child: const Text("Mark as Done"),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () async {
                              await updateActivityStatus(schedule['id'], "Not Done", 0);
                            },
                            child: const Text("Mark as Not Done"),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
