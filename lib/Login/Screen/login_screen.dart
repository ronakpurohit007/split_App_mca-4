import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:login/Home/home.dart';
import 'package:login/Login/Screen/forgot_password.dart';
import 'package:login/Login/Screen/signup_screen.dart';
import 'package:login/widgets/colors.dart';
import 'package:login/widgets/login_btn.dart';
import 'package:login/widgets/snackbar_utils.dart';

import '../../Services/authentication.dart';
import '../../widgets/bottom_navbar.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailCon = TextEditingController();
  final TextEditingController _passwordCon = TextEditingController();
  bool isLoading = false;
  DateTime? currentBackPressTime;

  void loginUser() async {
    setState(() {
      isLoading = true;
    });
    await Future.delayed(Duration(seconds: 1));

    String res = await AuthServices().loginUser(
      email: _emailCon.text,
      password: _passwordCon.text,
    );

    print("Login Response: $res");

    setState(() {
      isLoading = false;
    });

    if (res == "success") {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } else {
      SnackbarUtils.showErrorSnackbar(context, res);
    }
  }

  @override
  void dispose() {
    _emailCon.dispose();
    _passwordCon.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > Duration(seconds: 2)) {
      currentBackPressTime = now;
        SnackbarUtils.showExitSnackbar(context, "Press back again to exit the app");

      return false; // Do not close the app yet
    }
    SystemNavigator.pop();
    return true; // Close the app
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 70, horizontal: 20),
              child: Column(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                      const Text(
                        'Let\'s Get Started',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 50),
                      CustomTextField(
                        controller: _emailCon,
                        hintText: "Enter your email",
                        label: "Email",
                        prefixIcon: Icons.email_rounded,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _passwordCon,
                        hintText: "Enter your password",
                        label: "Password",
                        prefixIcon: Icons.lock,
                        obscureText: true,
                      ),
                      const SizedBox(height: 80),
                      CustomMainButton(
                        onPressed: loginUser,
                        text: isLoading ? "Logging in..." : "Login",
                        textColor: isLoading ? AppColors.white : AppColors.black,
                        backgroundColor:
                        isLoading ? AppColors.ButtonColor : AppColors.main,
                        width: 400,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Don\'t have an account ?",
                            style: TextStyle(color: AppColors.gray),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) => SignUpScreen()),
                              );
                            },
                            child: Text(
                              "Sign up here",
                              style: TextStyle(color: AppColors.white),
                            ),
                          )
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => ForgotPasswordScreen()),
                            );
                          },
                          child: Text(
                            "Forgot Password ?",
                            style: TextStyle(
                                color: AppColors.white, fontSize: 17),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
