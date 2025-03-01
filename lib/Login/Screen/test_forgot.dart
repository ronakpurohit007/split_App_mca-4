import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login/Services/authentication.dart';

import 'package:login/widgets/login_btn.dart';

import '../../widgets/snackbar_utils.dart';


class ForgotPasswordScreenTestTest extends StatefulWidget {
  const ForgotPasswordScreenTestTest({super.key});

  @override
  State<ForgotPasswordScreenTestTest> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<ForgotPasswordScreenTestTest> {
  final _auth =AuthServices();
  final TextEditingController _emailTextController = TextEditingController();

  @override
  void dispose() {
    _emailTextController.dispose();
    super.dispose();
  }

  // Future passwordReset() async {
  //   print("Password reset inside");
  //   try{
  //     showDialog(
  //         context: context,
  //         builder: (context) => const Center(
  //           child: CircularProgressIndicator(),
  //         ));
  //     print("Inside try block------------>>");
  //     await FirebaseAuth.instance
  //         .sendPasswordResetEmail(
  //         email: _emailTextController.text.trim());
  //     Navigator.pop(context);
  //     showDialog(context: context, builder: (context) {
  //       return AlertDialog(
  //         content: Text("Password reset email send to the mentioned email address."),
  //         actions: [
  //           TextButton(
  //               onPressed: () {
  //                 Navigator.pop(context);
  //               },
  //               child: const Text("OK")),
  //         ],
  //       );
  //     });
  //   } on FirebaseAuthException catch(e){
  //     print("Error-------------->>>");
  //     print(e);
  //     showDialog(context: context, builder: (context) {
  //       return AlertDialog(
  //         content: Text(e.message.toString()),
  //       );
  //     });
  //     Navigator.pop(context);
  //   }
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white10,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white,
                Colors.black38,
                Colors.black54,
              ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  (20), MediaQuery.of(context).size.height * 0.1, 20, 0),
              child: Column(
                children: <Widget>[
                  // logoWidget("assets/images/img_2.png"),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text("FORGOT PASSWORD",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      )),
                  const SizedBox(
                    height: 30,
                  ),
                  const Center(
                    child: Text(
                      "To change the password please enter the provided email address.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  CustomTextField(hintText: '', controller: _emailTextController),
                  const SizedBox(
                    height: 10,
                  ),
                  ForgotPassworSubmitdButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Container ForgotPassworSubmitdButton() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.6,
      height: 50,
      margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
      ),
      child: ElevatedButton(
          onPressed: () async{
            // passwordReset();
           await _auth.sendEmailForgot(_emailTextController.text);
           SnackbarUtils.showSuccessSnackbar(context, "Password reset email sent!");
          },
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.pressed)) {
                  return Colors.black26;
                }
                return Colors.white;
              }),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              )),
          child: const Text(
            "Submit",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          )),
    );
  }
}