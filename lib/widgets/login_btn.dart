import 'package:flutter/material.dart';
import 'package:login/widgets/colors.dart';
import 'package:login/widgets/loader.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const CustomButton({
    Key? key,
    required this.onPressed,
    this.text = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ButtonColor, // Coffee brown color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12)), // Rounded corners
        ),
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        elevation: 10,
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 10),
          Icon(Icons.arrow_circle_right_sharp, color: Colors.white),
        ],
      ),
    );
  }
}

class CustomTextField extends StatefulWidget {
  final String hintText;
  final String label;
  final bool obscureText;
  final IconData? prefixIcon;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? errorText;

  const CustomTextField({
    Key? key,
    required this.hintText,
    this.label = "",
    required this.controller,
    this.obscureText = false,
    this.prefixIcon,
    this.validator,
    this.errorText,
  }) : super(key: key);

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          validator: widget.validator,
          focusNode: _focusNode,
          style: TextStyle(
            color: _focusNode.hasFocus
                ? Colors.white
                : Colors
                    .white, // Text color white when focused, black when unfocused
          ),
          decoration: InputDecoration(
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon,
                    color: _focusNode.hasFocus
                        ? Colors.white
                        : Colors
                            .grey) // Prefix icon white when focused, grey when unfocused
                : null,
            labelText: widget.label,
            labelStyle: TextStyle(
              color: _focusNode.hasFocus
                  ? Colors.white
                  : Colors.white, // Label color changes when focused
            ),
            hintText: widget.hintText,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.white), // White border on focus
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey), // Default grey border
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            errorText: widget.errorText,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: EdgeInsets.only(left: 12, top: 5),
            child: Text(
              widget.errorText!,
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
      ],
    );
  }
}

class CustomNextButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const CustomNextButton({
    Key? key,
    required this.onPressed,
    this.text = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.backgroundColor, // Coffee brown color
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30) // Rounded corners
              ),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 130),
          elevation: 8,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward_rounded, color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }
}

class CustomLoginButton extends StatefulWidget {
  final String text;
  final Widget nextScreen; // Accept the next screen as a parameter
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const CustomLoginButton({
    super.key,
    required this.text,
    required this.nextScreen,
    this.backgroundColor = AppColors.main,
    this.textColor = AppColors.black,
    this.width,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    required Null Function() onPressed,
  });

  @override
  _CustomLoginButtonState createState() => _CustomLoginButtonState();
}

class _CustomLoginButtonState extends State<CustomLoginButton> {
  bool _isLoading = false;

  void _handlePress() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 0), () {
      setState(() {
        _isLoading = false;
      });

      // Navigate with animation
      Navigator.push(context, SlideRightRoute(page: widget.nextScreen));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handlePress,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.textColor,
          padding: widget.padding,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : Text(widget.text),
      ),
    );
  }
}

class CustomSkipButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const CustomSkipButton({Key? key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.main),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text(
        'Skip',
        style: TextStyle(color: AppColors.white),
      ),
    );
  }
}

class SlideRightRoute extends PageRouteBuilder {
  final Widget page;

  SlideRightRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = const Offset(1.0, 0.0); // Start from right
            var end = Offset.zero;
            var curve = Curves.easeInOut;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

class CustomMainButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading; // Add isLoading
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const CustomMainButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false, // Default to false
    this.backgroundColor = AppColors.main,
    this.textColor = AppColors.black,
    this.width,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  }) : super(key: key);

  @override
  _CustomMainButtonState createState() => _CustomMainButtonState();
}

class _CustomMainButtonState extends State<CustomMainButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.textColor,
          padding: widget.padding,
        ),
        child: widget.isLoading
            ? Custom_Lottie(
            assetPath: 'assets/Animation/loader.json', scale: 0.5)
            : Text(widget.text),
      ),
    );
  }
}


class CustomCancelButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading; // Add isLoading
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const CustomCancelButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false, // Default to false
    this.backgroundColor = AppColors.black,
    this.textColor = AppColors.black,
    this.width,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  }) : super(key: key);

  @override
  _CustomCancelButtonState createState() => _CustomCancelButtonState();
}

class _CustomCancelButtonState extends State<CustomCancelButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor,
          side: const BorderSide(color: AppColors.main),
          foregroundColor: widget.textColor,
          padding: widget.padding,
        ),
        child: widget.isLoading
            ? Custom_Lottie(
            assetPath: 'assets/Animation/loader.json', scale: 0.5)
            : Text(widget.text, style: TextStyle(color: AppColors.white)),
      ),
    );
  }
}



class CustomTextFieldNew extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final Function(String)? onChanged;

  CustomTextFieldNew({required this.label, this.controller,this.onChanged,});

  InputDecoration customInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white), // Label color white
      floatingLabelStyle: TextStyle(color: Colors.grey),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey), // Underline color white
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white, width: 2.0), // Underline color white when focused
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 10.0), // Padding inside the TextField
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0), // Outer padding
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: customInputDecoration(label),
        onChanged: onChanged,
      ),
    );
  }
}





class CustomDropdown1 extends StatelessWidget {
  final List<String> items;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const CustomDropdown1({
    Key? key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(color: Colors.grey, style: BorderStyle.solid, width: 0.80),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue, // Uses external state
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items.map((String item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue); // Calls the function passed by the parent
            }
          },
        ),
      ),
    );
  }
}

class AppTypography {
  // Base text style that includes the font family
  static TextStyle _baseStyle(BuildContext context) {
    return const TextStyle(
      fontFamily: 'LexendDeca',
      color: AppColors.white,
    );
  }

  // Headings
  static TextStyle h1(BuildContext context) {
    return _baseStyle(context).copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      height: 1.3,
    );
  }

  static TextStyle h2(BuildContext context) {
    return _baseStyle(context).copyWith(
      fontSize:24,
      fontWeight: FontWeight.w400,
      height: 1.3,
    );
  }

  static TextStyle h3(BuildContext context) {
    return _baseStyle(context).copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 1.3,
    );
  }

  static TextStyle h4(BuildContext context) {
    return _baseStyle(context).copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.3,
    );
  }

  static TextStyle captionText(BuildContext context) {
    return _baseStyle(context).copyWith(
      fontSize: 12,
      color: AppColors.gray,
      fontWeight: FontWeight.w400,
      height: 1.4,
    );
  }


  static TextStyle inputPlaceholder(BuildContext context) {
    return _baseStyle(context).copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.white);
  }
}