import 'package:easy_scaffold/easy_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:super_calculator/theme/theme_provider.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _input = '0';
  String _lastButtonPressed = '';

  // Function untuk menangani input tombol
  void _onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'C') {
        _input = '0';
      } else if (buttonText == '=') {
        _input = _evaluateExpression(_input);
        _input = _removeTrailingZero(_input);
      } else if (buttonText == '⌫') {
        _input =
            _input.length > 1 ? _input.substring(0, _input.length - 1) : '0';
      } else if (buttonText == '×' ||
          buttonText == '÷' ||
          buttonText == '+' ||
          buttonText == '-' ||
          buttonText == '^') {
        if (_input.isNotEmpty &&
            (_input.endsWith('×') ||
                _input.endsWith('÷') ||
                _input.endsWith('+') ||
                _input.endsWith('-') ||
                _input.endsWith('^'))) {
          _input = _input.substring(0, _input.length - 1) + buttonText;
        } else {
          _input += buttonText;
        }
      } else if (buttonText == '%') {
        // Jika operator sebelumnya adalah angka, maka hitung persentase
        if (_isNumeric(_lastButtonPressed)) {
          double currentValue = double.parse(_input);
          double percentage =
              currentValue * double.parse(_lastButtonPressed) / 100;
          _input = percentage.toString();
        } else {
          // Jika tidak, tandai sebagai operator '%'
          _input += buttonText;
        }
      } else if (buttonText == '^') {
        _input += buttonText;
      } else if (buttonText == '.') {
        if (!_input.contains('.')) {
          _input += buttonText;
        }
      } else if (_input == '0' && _isNumeric(buttonText)) {
        _input = buttonText;
      } else {
        _input += buttonText;
      }

      // Update last button pressed
      _lastButtonPressed = buttonText;
    });
  }

  // Function untuk mengevaluasi ekspresi matematika
  String _evaluateExpression(String expression) {
    try {
      double result = _parseExpression(expression);
      return result.toString();
    } catch (e) {
      return 'Error';
    }
  }

  // Function untuk parsing ekspresi matematika
  double _parseExpression(String expression) {
    List<String> tokens = _tokenizeExpression(expression);
    return _evaluateTokens(tokens);
  }

  // Function untuk menghapus trailing zero pada angka desimal
  String _removeTrailingZero(String value) {
    if (value.contains('.')) {
      while (value.endsWith('0')) {
        value = value.substring(0, value.length - 1);
      }
      if (value.endsWith('.')) {
        value = value.substring(0, value.length - 1);
      }
    }
    return value;
  }

  // Function untuk memisahkan token pada ekspresi matematika
  List<String> _tokenizeExpression(String expression) {
    List<String> tokens = [];
    String currentToken = '';

    for (int i = 0; i < expression.length; i++) {
      if (_isOperator(expression[i])) {
        if (currentToken.isNotEmpty) {
          tokens.add(currentToken);
          currentToken = '';
        }
        tokens.add(expression[i]);
      } else {
        currentToken += expression[i];
      }
    }

    if (currentToken.isNotEmpty) {
      tokens.add(currentToken);
    }

    return tokens;
  }

  // Function untuk mengevaluasi token pada ekspresi matematika
  double _evaluateTokens(List<String> tokens) {
    double result = double.parse(tokens[0]);
    List<String> output = [];
    List<String> operators = [];

    for (int i = 0; i < tokens.length; i++) {
      String token = tokens[i];
      if (_isNumeric(token)) {
        output.add(token);
      } else if (_isOperator(token)) {
        while (operators.isNotEmpty &&
            _hasHigherPrecedence(operators.last, token)) {
          output.add(operators.removeLast());
        }
        operators.add(token);
      }
    }
    while (operators.isNotEmpty) {
      output.add(operators.removeLast());
    }

    for (int i = 0; i < output.length; i++) {
      String token = output[i];
      if (_isNumeric(token)) {
        operators.add(token);
      } else {
        double num2 = double.parse(operators.removeLast());
        double num1 = double.parse(operators.removeLast());
        switch (token) {
          case '+':
            operators.add((num1 + num2).toString());
            break;
          case '-':
            operators.add((num1 - num2).toString());
            break;
          case '×':
            operators.add((num1 * num2).toString());
            break;
          case '÷':
            operators.add((num1 / num2).toString());
            break;
          case '^':
            operators.add((_power(num1, num2)).toString());
            break;
          case '%':
            double percentage = num1 / 100 * num2 / 100;
            operators.add(percentage.toString());
            break;
          default:
            throw FormatException('Invalid operator: $token');
        }
      }
    }

    return double.parse(operators.first);
  }

  // Function untuk menghitung pangkat
  double _power(double base, double exponent) {
    return exponent == 0 ? 1 : base * _power(base, exponent - 1);
  }

  // Function untuk mengecek apakah sebuah string adalah operator
  bool _isOperator(String value) {
    return value == '+' ||
        value == '-' ||
        value == '×' ||
        value == '÷' ||
        value == '%' ||
        value == '^';
  }

  // Function untuk mengecek apakah sebuah operator memiliki prioritas lebih tinggi
  bool _hasHigherPrecedence(String op1, String op2) {
    if (op1 == '^') {
      return true; // Operator pangkat memiliki prioritas tertinggi
    } else if ((op1 == '×' || op1 == '÷') && (op2 == '+' || op2 == '-')) {
      return true;
    }
    return false;
  }

  // Function untuk mengecek apakah sebuah string adalah angka
  bool _isNumeric(String str) {
    try {
      double.parse(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.history,
                  color: colorLightButtonPrimary,
                ),
                const SizedBox(
                  width: 20,
                ),
                const Icon(Icons.currency_exchange),
                const SizedBox(
                  width: 20,
                ),
                const Icon(Icons.straighten),
                const SizedBox(
                  width: 20,
                ),
                InkWell(
                    onTap: () {
                      Provider.of<ThemeProvider>(context, listen: false)
                          .toggleTheme();
                    },
                    child: const Icon(Icons.dark_mode)),
              ],
            )
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              alignment: Alignment.bottomRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: CustomText(
                  fontFamily: 'Poppins',
                  text: _input,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 48,
                ),
              ),
            ),
          ),
          // Tombol-tombol kalkulator
          Container(
            color: Theme.of(context).colorScheme.background,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildButtonIcon3('C'),
                      _buildButtonIcon2('%'),
                      _buildButtonIcon3('⌫'),
                      _buildButtonIcon2('÷'),
                    ],
                  ),
                  const SizedBox(
                    height: 22,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildButton('7'),
                      _buildButton('8'),
                      _buildButton('9'),
                      _buildButtonIcon2('×'),
                    ],
                  ),
                  const SizedBox(
                    height: 22,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildButton('4'),
                      _buildButton('5'),
                      _buildButton('6'),
                      _buildButtonIcon2('-'),
                    ],
                  ),
                  const SizedBox(
                    height: 22,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildButton('1'),
                      _buildButton('2'),
                      _buildButton('3'),
                      _buildButtonIcon2('+'),
                    ],
                  ),
                  const SizedBox(
                    height: 22,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildButtonIcon2('^'),
                      _buildButton('0'),
                      _buildButton('.'),
                      _buildButtonIcon('='),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk membuat tombol kalkulator
  Widget _buildButton(String buttonText) {
    return ButtonWidget(
      borderRadius: 20,
      backGroundColor: Theme.of(context).colorScheme.background,
      borderColor: Theme.of(context).colorScheme.background,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      onPressed: () async {
        _onButtonPressed(buttonText);
      },
      child: CustomText(
        text: buttonText,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // Widget untuk membuat tombol kalkulator
  Widget _buildButtonIcon(String buttonText) {
    return ButtonWidget(
      borderRadius: 15,
      backGroundColor: Theme.of(context).colorScheme.primary,
      borderColor: Theme.of(context).colorScheme.background,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      onPressed: () {
        _onButtonPressed(buttonText);
      },
      child: CustomText(
        fontFamily: 'Poppins',
        text: buttonText,
        fontSize: 32,
        color: colorWhite,
      ),
    );
  }

  Widget _buildButtonIcon2(String buttonText) {
    return ButtonWidget(
      borderRadius: 15,
      backGroundColor: Theme.of(context).colorScheme.onPrimary,
      borderColor: Theme.of(context).colorScheme.background,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      onPressed: () {
        _onButtonPressed(buttonText);
      },
      child: CustomText(
        fontFamily: 'Poppins',
        text: buttonText,
        fontSize: 32,
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _buildButtonIcon3(String buttonText) {
    return ButtonWidget(
      borderRadius: 15,
      backGroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
      borderColor: Theme.of(context).colorScheme.background,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      onPressed: () {
        _onButtonPressed(buttonText);
      },
      child: CustomText(
        fontFamily: 'Poppins',
        text: buttonText,
        fontSize: 32,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSecondary,
      ),
    );
  }
}
