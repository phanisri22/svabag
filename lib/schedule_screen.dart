import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String? selectedKidID;
  String? selectedDay;
  String? selectedTimeSlot;
  String? selectedActivityID;
  List<Map<String, dynamic>> kidsList = [];
  List<Map<String, dynamic>> activitiesList = [];

  final List<String> daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  
  final List<String> timeSlots = [
    'Morning', 'Afternoon', 'Evening'
  ];

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

  // Function to fetch activities from Firestore
  Future<void> fetchActivities() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final activitiesSnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .where('parentID', isEqualTo: currentUser.uid)
          .get();

      setState(() {
        activitiesList = activitiesSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
          };
        }).toList();
      });
    }
  }

  // Function to create a schedule for a kid
  Future<void> createSchedule(String kidID, String day, String timeSlot, String activityID) async {
    if (kidID.isEmpty || day.isEmpty || timeSlot.isEmpty || activityID.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all fields')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('schedules').add({
        'kidID': kidID,
        'day': day,
        'timeSlot': timeSlot,
        'activityID': activityID,
        'status': "Not Done",
        'points': 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule added successfully')),
      );
    } catch (e) {
      print('Error creating schedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error creating schedule')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchKids();      // Fetch the list of kids when the screen is loaded
    fetchActivities(); // Fetch the list of activities when the screen is loaded
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Weekly Schedule'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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

            // Day Dropdown
            DropdownButton<String>(
              hint: const Text('Select a Day'),
              value: selectedDay,
              onChanged: (String? newDay) {
                setState(() {
                  selectedDay = newDay;
                });
              },
              items: daysOfWeek.map((day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Time Slot Dropdown
            DropdownButton<String>(
              hint: const Text('Select a Time Slot'),
              value: selectedTimeSlot,
              onChanged: (String? newTimeSlot) {
                setState(() {
                  selectedTimeSlot = newTimeSlot;
                });
              },
              items: timeSlots.map((timeSlot) {
                return DropdownMenuItem<String>(
                  value: timeSlot,
                  child: Text(timeSlot),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Activity Dropdown
            DropdownButton<String>(
              hint: const Text('Select an Activity'),
              value: selectedActivityID,
              onChanged: (String? newActivityID) {
                setState(() {
                  selectedActivityID = newActivityID;
                });
              },
              items: activitiesList.map((activity) {
                return DropdownMenuItem<String>(
                  value: activity['id'],
                  child: Text(activity['name']),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Add to Schedule Button
            ElevatedButton(
              onPressed: () async {
                if (selectedKidID != null && selectedDay != null && selectedTimeSlot != null && selectedActivityID != null) {
                  await createSchedule(selectedKidID!, selectedDay!, selectedTimeSlot!, selectedActivityID!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select all fields')),
                  );
                }
              },
              child: const Text('Add to Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
