import 'package:flutter/material.dart';

class DemoTest extends StatelessWidget {
  const DemoTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Demo Test"),
        ),
        body: Center(
          child: Text("This is a demo test"),
        ),
        floatingActionButton: FloatingActionButton(onPressed: () {}));
  }
}
