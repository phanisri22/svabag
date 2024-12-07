import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class KidsScreen extends StatefulWidget {
  const KidsScreen({super.key});

  @override
  _KidsScreenState createState() => _KidsScreenState();
}

class _KidsScreenState extends State<KidsScreen> {
  // Controllers for form fields
  final _nameController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();

  // Function to pick an image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Function to upload the image to Firebase Storage
  Future<String> _uploadImage() async {
    if (_image == null) {
      return ''; // No image to upload
    }
    try {
      final storageRef = FirebaseStorage.instance.ref().child('kids_photos/${DateTime.now().toString()}.jpg');
      final uploadTask = storageRef.putFile(_image!);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }

  // Function to add a kid's information to Firestore
  Future<void> _addKid() async {
    final name = _nameController.text;
    if (name.isEmpty || _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter kid\'s name and select a photo')),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final photoURL = await _uploadImage();

    if (currentUser != null) {
      await FirebaseFirestore.instance.collection('kids').add({
        'name': name,
        'photoURL': photoURL,  // Use the image URL obtained from Firebase Storage
        'parentID': currentUser.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kid added successfully')),
      );

      // Clear the form fields
      _nameController.clear();
      setState(() {
        _image = null; // Clear the image
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Kid Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kid's Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Kid\'s Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the kid\'s name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Kid's Photo (select from gallery)
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: _image == null
                      ? const Text('Tap to select photo')
                      : Image.file(_image!, width: 100, height: 100),
                ),
              ),
              const SizedBox(height: 16),

              // Submit Button
              ElevatedButton(
                onPressed: _addKid,
                child: const Text('Add Kid'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
