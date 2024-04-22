import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:easy_scaffold/easy_scaffold.dart';
import 'package:flutter/services.dart';

class WeightPage extends StatefulWidget {
  const WeightPage({super.key});

  @override
  _WeightPageState createState() => _WeightPageState();
}

class _WeightPageState extends State<WeightPage> {
  final bool _isLoading = false;
  String _input = '0';
  String _lastButtonPressed = '';
  bool _isExpressionValid = false;
  String? convertedAmount;
  String _selectedFromUnit = 'Gram(g)';
  String _selectedToUnit = 'Gram(g)';

  final List<String> _lengthUnits = [
    'Nanogram(ng)',
    'Microgram(μg)',
    'Milligram(mg)',
    'Gram(g)',
    'Kilogram(kg)',
    'Metric Ton(ton)',
    'Ounce(oz)',
    'Pound(lb)',
    'Stone(st)',
    'Tola(tola)',
    'Carat(ct)',
  ];

  TextEditingController amountController1 = TextEditingController();
  TextEditingController amountController2 = TextEditingController();

  bool _isConnected = true;
// Function untuk menangani input tombol
  void _convertLength() {
    if (_isNumeric(_input)) {
      double inputValue = double.parse(_input);
      double result =
          convertWeight(inputValue, _selectedFromUnit, _selectedToUnit);
      setState(() {
        convertedAmount = result.toString();
      });
    }
  }

  void _onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'AC') {
        _input = '0';
        amountController1.text = _input; // Reset nilai input
        _isExpressionValid = false;
      } else if (buttonText == 'Convert') {
        _convertLength();

        if (_isExpressionValid) {
          String expression = _input;
          _input = _evaluateExpression(_input);
          _input = _removeTrailingZero(_input);
        }
      } else if (buttonText == '⌫') {
        _input =
            _input.length > 1 ? _input.substring(0, _input.length - 1) : '0';
        amountController1.text = _input; // Update nilai input
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
        amountController1.text = _input; // Update nilai input
        _isExpressionValid = false;
      } else if (buttonText == '%') {
        if (_isNumeric(_lastButtonPressed)) {
          double currentValue = double.parse(_input);
          double percentage =
              currentValue * double.parse(_lastButtonPressed) / 100;
          _input = percentage.toString();
        } else {
          _input += buttonText;
        }
        amountController1.text = _input; // Update nilai input
        _isExpressionValid = false;
      } else if (buttonText == '^') {
        _input += buttonText;
        amountController1.text = _input; // Update nilai input
        _isExpressionValid = false;
      } else if (buttonText == '.') {
        if (!_input.contains('.')) {
          _input += buttonText;
        }
        amountController1.text = _input; // Update nilai input
        _isExpressionValid = false;
      } else if (_input == '0' && _isNumeric(buttonText)) {
        _input = buttonText;
        amountController1.text = _input; // Update nilai input
      } else {
        _input += buttonText;
        amountController1.text = _input; // Update nilai input
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
  void initState() {
    super.initState();

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isConnected = result != ConnectivityResult.none;
      });
    });
  }

  @override
  void dispose() {
    amountController1.dispose();
    amountController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    borderRadius:
                        BorderRadius.circular(10), // Ubah sesuai kebutuhan
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2), // Warna bayangan
                        spreadRadius: 5, // Radius penyebaran bayangan
                        blurRadius: 3, // Radius blur bayangan
                        offset: const Offset(
                            0, 3), // Offset bayangan dari container
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 200,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: CustomText(
                                        text: "From",
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    _buildDropdownButton(
                                        'Select unit', _selectedFromUnit,
                                        (value) {
                                      setState(() {
                                        _selectedFromUnit = value!;
                                      });
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      TextFormField(
                        controller: amountController1,
                        onChanged: (value) {
                          _input = value;
                        },
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 35,
                        ),
                        decoration: InputDecoration(
                          enabled: false,
                          hintText: "0",
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 35,
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                        ),
                      ),
                      // CustomText(
                      //   fontFamily: 'Poppins',
                      //   text: _input,
                      //   color: Theme.of(context).colorScheme.primary,
                      //   fontSize: 35,
                      // ),

                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: 200,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: "To",
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      fontSize: 12,
                                    ),
                                    _buildDropdownButton(
                                        'Select unit', _selectedToUnit,
                                        (value) {
                                      setState(() {
                                        _selectedToUnit = value!;
                                      });
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : CustomText(
                                fontFamily: 'Poppins',
                                text: convertedAmount ?? '0',
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 35,
                              ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.175,
                    left: MediaQuery.of(context).size.width * 0.7,
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        String temp = _selectedFromUnit;
                        _selectedFromUnit = _selectedToUnit;
                        _selectedToUnit = temp;
                      });
                    },
                    child: const Icon(
                      Icons.swap_vert_circle,
                      size: 49,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              color: Theme.of(context).colorScheme.background,
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildButton('7'),
                        _buildButton('8'),
                        _buildButton('9'),
                        _buildButtonIcon2('AC'),
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
                        _buildButtonIcon2('⌫'),
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
                        _buildButton('0'),
                      ],
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildButton('00'),
                        _buildButton('.'),
                        SizedBox(child: _buildButtonIcon('Convert', 20)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        HapticFeedback.lightImpact();
      },
      child: CustomText(
        text: buttonText,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildDropdownButton(
      String labelText, String selectedValue, ValueChanged<String?> onChanged) {
    return DropdownButton<String>(
      value: selectedValue,
      onChanged: onChanged,
      items: _lengthUnits.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget _buildButtonIcon(String buttonText, double? fontSize) {
    return ButtonWidget(
      borderRadius: 15,
      backGroundColor: Theme.of(context).colorScheme.primary,
      borderColor: Theme.of(context).colorScheme.background,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      onPressed: () {
        _onButtonPressed(buttonText);
        HapticFeedback.heavyImpact();
      },
      child: CustomText(
        fontFamily: 'Poppins',
        text: buttonText,
        fontSize: fontSize ?? 32,
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
        HapticFeedback.lightImpact();
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
        HapticFeedback.mediumImpact();
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

  double convertWeight(double value, String fromUnit, String toUnit) {
    double gramValue = 0.0;

    switch (fromUnit) {
      case 'Nanogram(ng)':
        gramValue = value / 1e9;
        break;
      case 'Microgram(μg)':
        gramValue = value / 1e6;
        break;
      case 'Milligram(mg)':
        gramValue = value / 1000;
        break;
      case 'Gram(g)':
        gramValue = value;
        break;
      case 'Kilogram(kg)':
        gramValue = value * 1000;
        break;
      case 'Metric Ton(ton)':
        gramValue = value * 1e6;
        break;
      case 'Ounce(oz)':
        gramValue = value * 28.3495;
        break;
      case 'Pound(lb)':
        gramValue = value * 453.592;
        break;
      case 'Stone(st)':
        gramValue = value * 6350.29;
        break;
      case 'Tola(tola)':
        gramValue = value * 11.66;
        break;
      case 'Carat(ct)':
        gramValue = value / 5;
        break;
    }

    double result = 0.0;

    switch (toUnit) {
      case 'Nanogram(ng)':
        result = gramValue * 1e9;
        break;
      case 'Microgram(μg)':
        result = gramValue * 1e6;
        break;
      case 'Milligram(mg)':
        result = gramValue * 1000;
        break;
      case 'Gram(g)':
        result = gramValue;
        break;
      case 'Kilogram(kg)':
        result = gramValue / 1000;
        break;
      case 'Metric Ton(ton)':
        result = gramValue / 1e6;
        break;
      case 'Ounce(oz)':
        result = gramValue / 28.3495;
        break;
      case 'Pound(lb)':
        result = gramValue / 453.592;
        break;
      case 'Stone(st)':
        result = gramValue / 6350.29;
        break;
      case 'Tola(tola)':
        result = gramValue / 11.66;
        break;
      case 'Carat(ct)':
        result = gramValue * 5;
        break;
    }

    return result;
  }
}
