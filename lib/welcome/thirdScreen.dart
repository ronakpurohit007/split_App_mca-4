import 'package:flutter/material.dart';
import 'package:login/welcome/firstScreen.dart';

import '../Login/Screen/login_screen.dart';
import '../widgets/colors.dart';
import '../widgets/login_btn.dart';

class ThirdWelcomeScreen extends StatelessWidget {
  const ThirdWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.amber.shade700,
                Colors.amber.shade700.withOpacity(1), // Transition color
                Colors.black,
              ],
              stops: const [0.2, 0, 1.0], // Middle point at 0.5 (center)
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Header with menu and logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [],
                ),

                // Centered Demo Text
                const Expanded(
                  child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(height: 120,),
                          Image(
                            image: AssetImage('assets/logo.png'),
                            color: AppColors.black,
                            height: 200,
                            width: 200,
                          ),
                          SizedBox(height: 60),

                          Text(
                            "Effortless \nSharing on Mobile",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            "Easy bill creation, receipt \nscanning, and group invites via \nmobile.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70,
                              fontSize: 17,),
                          ),
                          SizedBox(
                            height: 50,
                          ),
                        ]
                    ),
                  ),
                ),

                // Bottom Section
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Navigation dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(3, (index) =>
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == 2 ? AppColors.white : AppColors.gray,
                              ),
                            ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Bottom buttons
                    Divider(color: AppColors.gray,thickness: 0.4,),
                    const SizedBox(height: 20,),
                    Row(
                      children: [
                        Expanded(
                            child:CustomLoginButton(
                              text: "Get Started",
                             onPressed: (){},
                             nextScreen: LoginScreen(),
                            )
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

