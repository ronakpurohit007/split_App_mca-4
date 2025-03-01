import 'package:flutter/material.dart';
import 'package:login/Login/Screen/ValidationUtils.dart';
import 'package:login/Services/authentication.dart';
import 'package:login/widgets/colors.dart';
import 'package:login/widgets/login_btn.dart';
import 'package:login/widgets/snackbar_utils.dart';

import '../../Home/home.dart';
import '../../widgets/AppBar.dart';
import '../../widgets/bottom_navbar.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailCon = TextEditingController();
  final TextEditingController passwordCon = TextEditingController();
  final TextEditingController comfirmpasswordCon = TextEditingController();
  final TextEditingController nameCon = TextEditingController();

  final _auth = AuthServices();
  bool isLoading = false;

  void signUpUser() async {
    setState(() => isLoading = true);
    String res = await AuthServices().signUpUser(
      email: emailCon.text,
      password: passwordCon.text,
      name: nameCon.text
    );
    if (res == "success") {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => MainScreen(),
      ));
    } else {
      setState(() => isLoading = false);
      SnackbarUtils.showErrorSnackbar(context, "Please enter valid details");
    }
  }

  @override
  void dispose() {
    emailCon.dispose();
    passwordCon.dispose();
    comfirmpasswordCon.dispose();
    nameCon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: CustomAppBar(title: "Sign up"),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 50, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      colors: [AppColors.main, AppColors.white], // Gradient colors
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcIn, // Ensures the gradient is applied only to the image
                  child: Image.asset(
                    'assets/logo.png',
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 40),
                // const Text(
                //   'Signup',
                //   style: TextStyle(
                //     fontSize: 32,
                //     fontWeight: FontWeight.bold,
                //     color: AppColors.white,
                //   ),
                // ),
                // SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: nameCon,
                        hintText: "Enter your name",
                        label: 'Name',
                        prefixIcon: Icons.person,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'First Name is required' : null,
                      ),
                      SizedBox(height: 20),
                      CustomTextField(
                        controller: emailCon,
                        hintText: "Enter your email",
                        label: 'Email',
                        prefixIcon: Icons.email_sharp,
                        validator: (value) => ValidationUtils.validateEmail(value),
                      ),
                      SizedBox(height: 20),
                      CustomTextField(
                        controller: passwordCon,
                        hintText: "Enter your password",
                        label: 'Password',
                        prefixIcon: Icons.lock,
                        obscureText: true,
                        validator: (value) => ValidationUtils.validatePassword(value),
                      ),
                      SizedBox(height: 20),
                      CustomTextField(
                        controller: comfirmpasswordCon,
                        hintText: "Enter confirm your password",
                        label: 'Confirm Password',
                        prefixIcon: Icons.lock,
                        obscureText: true,
                        validator: (value) =>
                            ValidationUtils.validateConfirmPassword(passwordCon.text, value),
                      ),
                      SizedBox(height: 30),
                      CustomMainButton(
                        onPressed: signUpUser,
                        text: isLoading ? "Registering..." : "Register",
                        textColor:  isLoading ? AppColors.white : AppColors.black,
                        backgroundColor: isLoading ? AppColors.ButtonColor : AppColors.main,
                        width: double.infinity,
                      ),
                      // CustomMainButton(text: "Google", onPressed: () async{
                      //   await _auth.loginWithGoogle();
                      // })

                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text("Already have an account?", style: TextStyle(color: AppColors.gray)),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text("Sign in", style: TextStyle(color: AppColors.white)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
