// import 'dart:math';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
//
// class AuthServices {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   Future<String> signUpUser(
//       {required String email,
//       required String password,
//       required String name}) async {
//     String res = "Some error Occurred";
//     try {
//       UserCredential credential = await _auth.createUserWithEmailAndPassword(
//           email: email, password: password);
//       await _firestore.collection("user").doc(credential.user!.uid).set({
//         'name': name,
//         'email': email,
//         'uid': credential.user!.uid,
//       });
//       res = "success";
//     } catch (e) {
//      return e.toString();
//     }
//     return res;
//   }
//
//   Future<String> loginUser({
//     required String email,
//     required String password,
//   }) async {
//     String res = "Some error occurred";
//     try {
//       if (email.isNotEmpty && password.isNotEmpty) {
//         await _auth.signInWithEmailAndPassword(email: email, password: password);
//         res = "success";
//       } else {
//         res = "Please enter a valid email and password";
//       }
//     } on FirebaseAuthException catch (e) {
//       res = e.message ?? "Authentication error";
//     } catch (e) {
//
//       res = e.toString();
//     }
//     return res;
//   }
//
//   // Future<UserCredential?>loginWithGoogle() async{
//   //   try{
//   //     final googleUser = await GoogleSignIn().signIn();
//   //
//   //     final googleAuth = await googleUser?.authentication;
//   //
//   //     final cred = GoogleAuthProvider.credential(idToken: googleAuth?.idToken,accessToken: googleAuth?.accessToken);
//   //     return await _auth.signInWithCredential(cred);
//   //   }catch(e){
//   //     print(e.toString());
//   //   }
//   // }
//
//   Future<void>sendEmailForgot( String email)async{
//     try{
//       await _auth.sendPasswordResetEmail(email: email);
//     }catch(e){
//   print(e.toString());
//     }
//   }
//
//   // Fetch the current user's name
//   Future<String?> getUserName() async {
//     try {
//       User? user = _auth.currentUser;
//       if (user != null) {
//         DocumentSnapshot doc = await _firestore.collection("user").doc(user.uid).get();
//         return doc["name"];
//       }
//     } catch (e) {
//       print("Error fetching user name: $e");
//     }
//     return null;
//   }
//
// }



import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔹 User Sign Up
  Future<String> signUpUser({
    required String email,
    required String password,
    required String name,
  }) async {
    String res = "Some error Occurred";
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;
      if (user != null) {
        await user.updateDisplayName(name); // Set Firebase Auth Display Name
        await user.reload(); // Reload user to apply updates

        // Store user data in Firestore
        await _firestore.collection("user").doc(user.uid).set({
          'name': name,
          'email': email,
          'uid': user.uid,
        });

        res = "success";
      }
    } catch (e) {
      return e.toString();
    }
    return res;
  }

  // 🔹 User Login
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        await credential.user?.reload(); // Reload user to get updated info

        res = "success";
      } else {
        res = "Please enter a valid email and password";
      }
    } on FirebaseAuthException catch (e) {
      res = e.message ?? "Authentication error";
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  // 🔹 Forgot Password
  Future<void> sendEmailForgot(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print(e.toString());
    }
  }

  // 🔹 Fetch Current User Name (From Firestore)
  Future<String?> getUserName() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Check Firestore for the name
        DocumentSnapshot doc = await _firestore.collection("user").doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          var data = doc.data() as Map<String, dynamic>;
          String? name = data["name"];
          String? email = user.email;
          return name?.isNotEmpty == true ? name : email; // Return name if available, else email
        }
        return user.email; // Return email if Firestore document doesn't exist
      }
    } catch (e) {
      print("Error fetching user name: $e");
    }
    return null;
  }

  Future<String?> getUserEmail() async {
    try {
      User? user = _auth.currentUser;
      return user?.email;
    } catch (e) {
      print("Error fetching user email: $e");
      return null;
    }
  }

}
