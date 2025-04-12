// lib/screens/calculator_screen.dart
import 'package:flutter/material.dart';
import 'package:login/widgets/AppBar.dart';
import 'package:login/widgets/colors.dart';
import 'package:login/widgets/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final ConsoleAppLogger logger = ConsoleAppLogger();

class CalculatorScreen extends StatefulWidget {
  final String groupId;

  const CalculatorScreen({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String _result = '0';
  List<Map<String, dynamic>> _history = [];

  void _addToHistory(String expression, String result) {
    setState(() {
      _history.insert(0, {
        'expression': expression,
        'result': result,
        'timestamp': DateTime.now(),
      });
    });

    // Save calculation to Firestore
    FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('calculations')
        .add({
          'expression': expression,
          'result': result,
          'timestamp': Timestamp.now(),
        })
        .then((_) => logger.d("Calculation saved to history"))
        .catchError((e) => logger.e("Error saving calculation: $e"));
  }

  void _fetchHistory() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('calculations')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      List<Map<String, dynamic>> fetchedHistory = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        fetchedHistory.add({
          'expression': data['expression'],
          'result': data['result'],
          'timestamp': (data['timestamp'] as Timestamp).toDate(),
        });
      }

      setState(() {
        _history = fetchedHistory;
      });
    } catch (e) {
      logger.e("Error fetching calculation history: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  void _onDigitPress(String digit) {
    setState(() {
      if (_result != '0' && _expression.isEmpty) {
        // If we've just calculated a result, start a new expression
        _expression = digit;
        _result = '0';
      } else {
        _expression += digit;
      }
    });
  }

  void _onOperatorPress(String operator) {
    if (_expression.isEmpty) {
      if (_result != '0') {
        // Use previous result as starting point
        setState(() {
          _expression = _result + operator;
        });
      }
      return;
    }

    setState(() {
      // Check if last character is already an operator
      final lastChar = _expression[_expression.length - 1];
      if (['+', '-', '×', '÷'].contains(lastChar)) {
        // Replace operator
        _expression =
            _expression.substring(0, _expression.length - 1) + operator;
      } else {
        _expression += operator;
      }
    });
  }

  void _onClearPress() {
    setState(() {
      _expression = '';
      _result = '0';
    });
  }

  void _onBackspacePress() {
    if (_expression.isNotEmpty) {
      setState(() {
        _expression = _expression.substring(0, _expression.length - 1);
      });
    }
  }

  void _onEqualsPress() {
    if (_expression.isEmpty) return;

    try {
      // Replace operators with their numerical equivalents
      String evaluableExpression =
          _expression.replaceAll('×', '*').replaceAll('÷', '/');

      // Simple evaluation (this is not secure for production use,
      // but serves as a demo for a calculator app)
      try {
        // Evaluate using a parser (simplified here)
        final String expressionToEvaluate = evaluableExpression;
        final result = _evaluateExpression(expressionToEvaluate);

        setState(() {
          _result = result
              .toStringAsFixed(result.truncateToDouble() == result ? 0 : 2);
          _addToHistory(_expression, _result);
          _expression = '';
        });
      } catch (e) {
        setState(() {
          _result = 'Error';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error';
      });
    }
  }

  // Simple expression evaluator
  double _evaluateExpression(String expression) {
    // Parse the expression
    expression = expression.replaceAll(' ', '');

    // Handle parentheses (not implemented in this simple version)

    // Handle multiplication and division
    List<String> byMultDiv = _splitByOperators(expression, ['*', '/']);
    double result = _evaluateTerm(byMultDiv[0]);

    for (int i = 1; i < byMultDiv.length; i += 2) {
      String operator = byMultDiv[i];
      double operand = _evaluateTerm(byMultDiv[i + 1]);

      if (operator == '*') {
        result *= operand;
      } else if (operator == '/') {
        if (operand == 0) throw Exception("Division by zero");
        result /= operand;
      }
    }

    return result;
  }

  double _evaluateTerm(String term) {
    // Handle addition and subtraction
    List<String> byAddSub = _splitByOperators(term, ['+', '-']);
    double result = double.parse(byAddSub[0]);

    for (int i = 1; i < byAddSub.length; i += 2) {
      String operator = byAddSub[i];
      double operand = double.parse(byAddSub[i + 1]);

      if (operator == '+') {
        result += operand;
      } else if (operator == '-') {
        result -= operand;
      }
    }

    return result;
  }

  List<String> _splitByOperators(String expression, List<String> operators) {
    List<String> parts = [];
    String currentPart = '';

    for (int i = 0; i < expression.length; i++) {
      String char = expression[i];
      if (operators.contains(char)) {
        parts.add(currentPart);
        parts.add(char);
        currentPart = '';
      } else {
        currentPart += char;
      }
    }

    if (currentPart.isNotEmpty) {
      parts.add(currentPart);
    }

    return parts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Calculator"),
      body: Column(
        children: [
          // Display area
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.all(16),
              color: AppColors.black,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Expression
                  Text(
                    _expression,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Result
                  Text(
                    _result,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // History area
          Expanded(
            flex: 2,
            child: Container(
              color: AppColors.mainShadow,
              child: Column(
                children: [
                  // History header
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "History",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // History list
                  Expanded(
                    child: _history.isEmpty
                        ? Center(
                            child: Text(
                              "No calculations yet",
                              style: TextStyle(color: Colors.white60),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _history.length,
                            itemBuilder: (context, index) {
                              final item = _history[index];
                              return ListTile(
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 16),
                                title: Text(
                                  item['expression'],
                                  style: TextStyle(color: Colors.white70),
                                ),
                                trailing: Text(
                                  "= ${item['result']}",
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _expression = item['result'];
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Calculator buttons
          Container(
            padding: EdgeInsets.all(12),
            color: AppColors.black,
            child: Column(
              children: [
                // Row 1
                Row(
                  children: [
                    _buildButton("C", color: AppColors.ErrorColor),
                    _buildButton("("),
                    _buildButton(")"),
                    _buildButton("÷", isOperator: true),
                  ],
                ),
                // Row 2
                Row(
                  children: [
                    _buildButton("7"),
                    _buildButton("8"),
                    _buildButton("9"),
                    _buildButton("×", isOperator: true),
                  ],
                ),
                // Row 3
                Row(
                  children: [
                    _buildButton("4"),
                    _buildButton("5"),
                    _buildButton("6"),
                    _buildButton("-", isOperator: true),
                  ],
                ),
                // Row 4
                Row(
                  children: [
                    _buildButton("1"),
                    _buildButton("2"),
                    _buildButton("3"),
                    _buildButton("+", isOperator: true),
                  ],
                ),
                // Row 5
                Row(
                  children: [
                    _buildButton("0", flex: 2),
                    _buildButton("."),
                    _buildButton("=", color: AppColors.main, isEquals: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    String text, {
    Color? color,
    bool isOperator = false,
    bool isEquals = false,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        margin: EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: () {
            if (text == "C") {
              _onClearPress();
            } else if (text == "=") {
              _onEqualsPress();
            } else if (text == "⌫") {
              _onBackspacePress();
            } else if (["+", "-", "×", "÷"].contains(text)) {
              _onOperatorPress(text);
            } else {
              _onDigitPress(text);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                color ?? (isOperator ? AppColors.main : AppColors.mainShadow),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isEquals ? 8 : 40),
            ),
            padding: EdgeInsets.all(20),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
