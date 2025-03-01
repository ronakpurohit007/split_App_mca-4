import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login/widgets/colors.dart';
import 'package:login/widgets/snackbar_utils.dart';
import 'package:login/widgets/login_btn.dart';

import '../../widgets/AppBar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final auth = FirebaseAuth.instance;
  bool _isLoading = false;

// // Future<void> _resetPassword() async {
// //   setState(() {
// //     _isLoading = true;
// //   });
// //
// //   try {
// //     await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
// //
// //     // Show success message (e.g., using a Snackbar)
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text("Password reset email sent! Check your inbox."))
// //     );
// //
// //   } on FirebaseAuthException catch (e) {
// //     // Show error message if something goes wrong
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text(e.message ?? "Something went wrong!"))
// //     );
// //   }
//
//   setState(() {
//     _isLoading = false;
//   });
// }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: CustomAppBar(title: "Forgot Password"),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child:SingleChildScrollView(child:
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  colors: [AppColors.main, AppColors.white], // Gradient colors
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ).createShader(bounds);
              },
              blendMode: BlendMode
                  .srcIn, // Ensures the gradient is applied only to the image
              child: Image.asset(
                'assets/logo.png',
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              "Enter your email and we'll send a password reset link.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.white, fontSize: 16),
            ),
            SizedBox(height: 30),
            CustomTextField(
              controller: _emailController,
              hintText: "Email",
              label: "Email",
              prefixIcon: Icons.email_rounded,
            ),
            SizedBox(height: 20),
            CustomMainButton(
              text: _isLoading ? "" : "Reset Password",
              width: double.infinity,
              onPressed: () {
                auth
                    .sendPasswordResetEmail(
                        email: _emailController.text.toString())
                    .then((value) {
                  SnackbarUtils.showSuccessSnackbar(
                      context, "Sent to your email");
                }).catchError((error) {
                  SnackbarUtils.showSuccessSnackbar(
                      context, "Please enter a valid email");
                });
              },
              isLoading: _isLoading,
            ),
          ],
        ),
      ),)
    );
  }
}
