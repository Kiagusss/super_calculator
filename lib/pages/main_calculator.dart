import 'dart:io';
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_scaffold/easy_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_calculator/pages/currency_page.dart';
import 'package:super_calculator/pages/hidde_page.dart';
import 'package:super_calculator/pages/unit_page/unit_page.dart';
import 'package:super_calculator/theme/theme_provider.dart';
import 'package:local_auth/local_auth.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  bool _isAuthenticating = false;
  String _input = '0';
  String _lastButtonPressed = '';
  final List<String> _history = [];
  bool _isExpressionValid = false;
  bool _historyPage = false;
  void _addToHistory(String expression) {
    String timestamp = DateTime.now().toString(); // Get current timestamp
    setState(() {
      _history
          .add('$expression, $timestamp'); // Append expression and timestamp
      _saveHistoryToPrefs(_history);
    });
  }

  void _saveHistoryToPrefs(List<String> history) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('history', history);
  }

  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  Future<void> saveToCSV(List<List<dynamic>> rows) async {
    List<List<dynamic>> rowsWithTimestamp = [];
    for (var row in rows) {
      String expression = row[0];
      String timestamp = row.length > 1 ? row[1] : '';
      rowsWithTimestamp
          .add([expression, timestamp]); // Include timestamp in each row
    }

    // Prepare CSV data
    List<List<dynamic>> rowsWithHeaders = [
      ['Hasil Perhitungan', 'Waktu Perhitungan']
    ];
    rowsWithHeaders.addAll(rows);
    String csv = const ListToCsvConverter().convert(rowsWithHeaders);

    // Obtain the directory path
    Directory? directory = await getExternalStorageDirectory();
    if (directory != null) {
      String downloadPath = "${directory.path}/Download";
      final dir = Directory(downloadPath);
      if (!(await dir.exists())) {
        await dir.create(recursive: true);
      }

      // Get CSV file path
      final path = '$downloadPath/calculator_history.csv';
      File file = File(path);

      // Write data to the CSV file
      await file.writeAsString(csv);

      // Show a snackbar to indicate successful export
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data successfully exported to CSV: $path'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      print('Failed to access external storage directory.');
    }
  }

  // Function untuk menangani input tombol
  Future<void> _authenticateUser() async {
    if (_isAuthenticating) {
      try {
        await _localAuthentication.authenticate(
          localizedReason: 'Use biometric to turn off your biometric',
          options: const AuthenticationOptions(
            stickyAuth: true,
          ),
        );

        setState(() {
          _isAuthenticating = false;
        });
      } on PlatformException catch (e) {
        if (e.message != "Authentication canceled.") {}

        return;
      }
    } else {
      await _localAuthentication
          .authenticate(
        localizedReason: 'Authorize your biometric',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      )
          .then((value) async {
        if (value) {
          setState(() {
            _isAuthenticating = true;
          });
          openPage(const HiddenPage(), context);
          setState(() {
            _isAuthenticating = false;
          });
        }
      });
    }
  }

  void _onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'C') {
        _input = '0';
        _isExpressionValid =
            false; // Set kevalidan ekspresi ke false saat tombol 'C' ditekan
      } else if (buttonText == '=') {
        if (_isExpressionValid) {
          // Cek kevalidan ekspresi sebelum menghitung hasil
          String expression = _input;
          _input = _evaluateExpression(_input);
          _input = _removeTrailingZero(_input);
          if (_lastButtonPressed != '=') {
            _addToHistory('$expression = $_input');
          }
          if (_input == '911') {
            // Lakukan verifikasi biometrik
            _authenticateUser();
          }
        }
      } else if (buttonText == '⌫') {
        _input =
            _input.length > 1 ? _input.substring(0, _input.length - 1) : '0';
      } else if (buttonText == '×' ||
          buttonText == '÷' ||
          buttonText == '+' ||
          buttonText == 'sqrt(' ||
          buttonText == '-' ||
          buttonText == '.' ||
          buttonText == '^') {
        if (_input.isNotEmpty &&
            (_input.endsWith('×') ||
                _input.endsWith('÷') ||
                _input.endsWith('+') ||
                _input.endsWith('-') ||
                _input.endsWith('.') ||
                _input.endsWith('sqrt(') ||
                _input.endsWith('^'))) {
          _input = _input.substring(0, _input.length - 1) + buttonText;
        } else {
          _input += buttonText;
        }
        _isExpressionValid =
            false; // Set kevalidan ekspresi ke false setelah menambah operator
      } else if (buttonText == '%') {
        if (_isNumeric(_lastButtonPressed)) {
          double currentValue = double.parse(_input);
          double percentage =
              currentValue * double.parse(_lastButtonPressed) / 100;
          _input = percentage.toString();
        } else {
          _input += buttonText;
        }
        _isExpressionValid =
            false; // Set kevalidan ekspresi ke false setelah menambah operator
      } else if (buttonText == '^') {
        _input += buttonText;
        _isExpressionValid =
            false; // Set kevalidan ekspresi ke false setelah menambah operator
      } else if (buttonText == '.') {
        _input += buttonText;

        _isExpressionValid =
            false; // Set kevalidan ekspresi ke false setelah menambah desimal
      } else if (_input == '0' && _isNumeric(buttonText)) {
        _input = buttonText;
      } else {
        _input += buttonText;
        _isExpressionValid =
            true; // Set kevalidan ekspresi ke true setelah menambah angka
      }
      _input = _input.replaceAll('√', 'sqrt(');
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
            double percentage = num1 % num2;
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
    _loadHistoryFromPrefs();
    requestStoragePermission();
  }

  Future<bool> _requestPermission(Permission permission) async {
    AndroidDeviceInfo build = await DeviceInfoPlugin().androidInfo;
    if (build.version.sdkInt >= 30) {
      var re = await Permission.manageExternalStorage.request();
      if (re.isGranted) {
        return true;
      } else {
        return false;
      }
    } else {
      if (await permission.isGranted) {
        return true;
      } else {
        var result = await permission.request();
        if (result.isGranted) {
          return true;
        } else {
          return false;
        }
      }
    }
  }

  void _requestStoragePermission() async {
    // Memeriksa status izin penyimpanan
    var status = await Permission.storage.status;
    // Jika izin belum diberikan, meminta izin
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  void _loadHistoryFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? history = prefs.getStringList('history');
    if (history != null) {
      setState(() {
        _history.addAll(history);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _historyPage = !_historyPage;
                    });
                  },
                  child: Icon(
                    Icons.history,
                    size: 30,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CurrencyPage()),
                    );
                  },
                  child: Icon(
                    Icons.currency_exchange,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                InkWell(
                  onTap: () {
                    openPage(const UnitPage(), context);
                  },
                  child: Icon(
                    Icons.straighten,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                InkWell(
                    onTap: () {
                      Provider.of<ThemeProvider>(context, listen: false)
                          .toggleTheme();
                    },
                    child: Icon(
                      Icons.dark_mode,
                      color: Theme.of(context).colorScheme.primary,
                    )),
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
          Stack(
            children: [
              Container(
                color: Theme.of(context).colorScheme.background,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(width: 120, child: _buildButtonIcon3('C')),
                          SizedBox(width: 120, child: _buildButtonIcon3('⌫')),
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
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: _historyPage ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: _historyPage
                      ? Container(
                          color: Theme.of(context).colorScheme.background,
                          height: 400,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15.0, vertical: 20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      InkWell(
                                          onTap: () {
                                            setState(() {
                                              _historyPage = false;
                                            });
                                          },
                                          child: Icon(
                                            Icons.arrow_back_ios,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondaryContainer,
                                          )),
                                      CustomText(
                                        text: "History",
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ],
                                  ),
                                  ButtonWidget(
                                    backGroundColor: Theme.of(context)
                                        .colorScheme
                                        .background,
                                    borderColor: Theme.of(context)
                                        .colorScheme
                                        .background,
                                    borderRadius: 10,
                                    padding: const EdgeInsets.all(10),
                                    onPressed: () async {
                                      List<List<dynamic>> rows = [];
                                      for (String expression in _history) {
                                        rows.add([expression]);
                                      }
                                      // Menyimpan data ke file CSV
                                      await saveToCSV(_history
                                          .map((entry) => entry.split(','))
                                          .toList());
                                    },
                                    child: Row(
                                      children: [
                                        CustomText(
                                          text: "Download Excel",
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        const Icon(
                                          Icons.file_copy_outlined,
                                          size: 16,
                                        )
                                      ],
                                    ),
                                  ),
                                  ButtonWidget(
                                    backGroundColor: Theme.of(context)
                                        .colorScheme
                                        .background,
                                    borderColor: Theme.of(context)
                                        .colorScheme
                                        .background,
                                    borderRadius: 10,
                                    padding: const EdgeInsets.all(10),
                                    onPressed: () {
                                      setState(() {
                                        _history
                                            .clear(); // Menghapus semua riwayat perhitungan
                                        _saveHistoryToPrefs(
                                            _history); // Simpan perubahan ke SharedPreferences
                                      });
                                    },
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          size: 25,
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    CustomText(
                                      text: "Hasil Perhitungan",
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 15,
                                    ),
                                    CustomText(
                                      text: "Waktu Perhitungan",
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 15,
                                    ),
                                  ],
                                ),
                              ),
                              RawScrollbar(
                                thumbColor: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                thickness: 3,
                                child: SizedBox(
                                  height: 337,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    reverse: false,
                                    itemCount: _history.length,
                                    itemBuilder: (context, index) {
                                      List<String> historyEntry =
                                          _history[index].split(', ');
                                      String expression = historyEntry[0];
                                      String timestamp = historyEntry[1];
                                      DateTime dateTime =
                                          DateTime.parse(timestamp);
                                      String formattedTime =
                                          '${dateTime.year}-${dateTime.month}-${dateTime.day}, ${dateTime.hour}:${dateTime.minute}:${dateTime.second}';

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: CustomText(
                                                fontSize: 23,
                                                text: expression,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ),
                                            CustomText(
                                              fontSize: 15,
                                              text: formattedTime,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(),
                ),
              ),
            ],
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

  // Widget untuk membuat tombol kalkulator
  Widget _buildButtonIcon(String buttonText) {
    return ButtonWidget(
      borderRadius: 15,
      backGroundColor: Theme.of(context).colorScheme.primary,
      borderColor: Theme.of(context).colorScheme.background,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      onPressed: () {
        _onButtonPressed(buttonText);
        HapticFeedback.heavyImpact();
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

  void requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Memeriksa versi SDK perangkat
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 30) {
        // Meminta izin manajemen penyimpanan (Android 11+)
        var status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          // Handle jika izin tidak diberikan
          print('Permission denied for manage external storage.');
          return;
        }
      } else {
        // Memeriksa status izin penyimpanan
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          // Jika izin belum diberikan, minta izin penyimpanan
          status = await Permission.storage.request();
          if (!status.isGranted) {
            // Handle jika izin tidak diberikan
            print('Permission denied for storage.');
          }
        }
      }
    }
  }
}
