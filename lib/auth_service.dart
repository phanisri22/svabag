import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign in with Google for Web
  static Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User canceled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create Firebase credentials
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credentials
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      // If the user is successfully logged in, map their email to user ID in Firestore
      if (user != null) {
        await _mapEmailWithUserId(user); // Save user info to Firestore
      }

      return user;
    } catch (e) {
      print('Error during Google Sign-In: $e');
      return null;
    }
  }

  // Sign out the user
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      print("User signed out successfully.");
    } catch (e) {
      print('Error during sign-out: $e');
    }
  }

  // Map email to user ID in Firestore
  static Future<void> _mapEmailWithUserId(User user) async {
    try {
      String email = user.email ?? '';
      String uid = user.uid;

      // Check if the user already exists in Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        // If the user doesn't exist, store the user's details
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': email,
          'uid': uid,
          'displayName': user.displayName ?? '',
          'photoURL': user.photoURL ?? '',
          'lastLogin': FieldValue.serverTimestamp(), // Optional: Save last login time
        });
        print("User data saved successfully to Firestore.");
      } else {
        print("User already exists in Firestore.");
      }
    } catch (e) {
      print('Error saving user to Firestore: $e');
    }
  }

  // Fetch user data from Firestore using user ID
  static Future<DocumentSnapshot> getUserData(String userId) async {
    try {
      return await FirebaseFirestore.instance.collection('users').doc(userId).get();
    } catch (e) {
      print('Error fetching user data: $e');
      rethrow; // rethrow error for further handling if needed
    }
  }

  // Check if the user is already signed in
  static Future<User?> getCurrentUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        print("Currently signed in as: ${user.displayName}");
        return user;
      } else {
        print("No user is signed in.");
        return null;
      }
    } catch (e) {
      print('Error fetching current user: $e');
      return null;
    }
  }
}