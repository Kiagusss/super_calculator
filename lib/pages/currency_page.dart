import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity/connectivity.dart';
import 'package:easy_scaffold/easy_scaffold.dart';

import 'package:flutter/material.dart';
import 'package:currency_converter/currency.dart';
import 'package:currency_converter/currency_converter.dart';
import 'package:flutter/services.dart';

import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class CurrencyPage extends StatefulWidget {
  const CurrencyPage({super.key});

  @override
  _CurrencyPageState createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<CurrencyPage> {
  bool _isLoading = false;
  String _input = '0';
  String _lastButtonPressed = '';
  bool _isExpressionValid = false;
  String? convertedAmount;
  Country? selectedCountry1;
  Country? selectedCountry2;
  Currency? selectedCurrency;
  TextEditingController amountController1 = TextEditingController();
  TextEditingController amountController2 = TextEditingController();

  bool _isConnected = true; // Status koneksi awal

  // Function untuk menangani input tombol
  void _onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'AC') {
        _input = '0';
        amountController1.text = _input; // Reset nilai input
        _isExpressionValid = false;
      } else if (buttonText == 'Convert') {
        convert();
        if (_isExpressionValid) {
          String expression = _input;
          _input = _evaluateExpression(_input);
          _input = _removeTrailingZero(_input);
          convert();
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
    selectedCountry1 = countries[0];
    selectedCountry2 = countries[1];
    convert(); // Perform initial conversion
    // Langganan perubahan status koneksi
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

  void convert() async {
    if (selectedCountry1 != null && selectedCountry2 != null) {
      setState(() {
        _isLoading = true; // Tunjukkan loading
      });

      double amount = double.tryParse(amountController1.text) ?? 1;
      var converted = await CurrencyConverter.convert(
        from: selectedCountry1!.currency,
        to: selectedCountry2!.currency,
        amount: amount,
        withoutRounding: true,
      );

      setState(() {
        convertedAmount = converted!.toStringAsFixed(2);
        selectedCurrency =
            selectedCountry2!.currency;
        _isLoading = false;
      });
    }
  }

  void _showCountryList(int selector) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        List<Country> filteredCountries = countries;
        TextEditingController searchController = TextEditingController();

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                children: [
                  Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 200,
                      child: const Divider(
                        thickness: 5,
                      )),
                  Container(
                    width: 300,
                    height: 60,
                    margin: const EdgeInsets.only(top: 20, bottom: 10),
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      keyboardType: TextInputType.text,
                      controller: searchController,
                      decoration: InputDecoration(
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          hintText: 'Search Country',
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                          labelStyle: const TextStyle(color: colorDarkTextGrey),
                          border: const OutlineInputBorder(),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      searchController.clear();
                                      filteredCountries = countries;
                                    });
                                  },
                                )
                              : null,
                          prefixIcon: const Icon(Icons.search)),
                      onChanged: (value) {
                        setState(() {
                          filteredCountries = countries
                              .where((country) => country.name
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredCountries.length,
                      itemBuilder: (BuildContext context, int index) {
                        final country = filteredCountries[index];
                        return ListTile(
                          title: Row(
                            children: [
                              SizedBox(
                                width: 45,
                                height: 50,
                                child: CachedNetworkImage(
                                  imageUrl:
                                      "https://flagcdn.com/48x36/${country.code.toLowerCase()}.png",
                                  placeholder: (context, url) => Center(
                                    child: SizedBox(
                                      width: 55,
                                      height: 50,
                                      child: Shimmer.fromColors(
                                        baseColor: Colors.grey.shade300,
                                        highlightColor: Colors.grey.shade200,
                                        child: Container(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Center(
                                    child: Icon(Icons.error),
                                  ),
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Text(country.name),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              if (selector == 1) {
                                selectedCountry1 = country;
                              } else {
                                selectedCountry2 = country;
                              }
                              convert(); // Trigger conversion
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(
              height: 39,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Currency Formatter",
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    backPage(context);
                  },
                  child: const Icon(
                    Icons.calculate_outlined,
                    size: 50,
                    color: Color(0xfff5c123),
                  ),
                )
              ],
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                borderRadius:
                    BorderRadius.circular(10), // Ubah sesuai kebutuhan
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2), // Warna bayangan
                    spreadRadius: 5, // Radius penyebaran bayangan
                    blurRadius: 3, // Radius blur bayangan
                    offset:
                        const Offset(0, 3), // Offset bayangan dari container
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
                        width: 45,
                        height: 50,
                        child: selectedCountry1 != null
                            ? CachedNetworkImage(
                                imageUrl:
                                    "https://flagcdn.com/48x36/${selectedCountry1!.code.toLowerCase()}.png",
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Center(
                                  child: Icon(Icons.error),
                                ),
                                fit: BoxFit.contain,
                              )
                            : const CircleAvatar(
                                radius: 20,
                              ),
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 150,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: "From",
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontSize: 12,
                                ),
                                SizedBox(
                                  child: CustomText(
                                    text: selectedCountry1 != null
                                        ? selectedCountry1!.name
                                        : "Select Country",
                                    color: Colors.white,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          _showCountryList(1);
                        },
                        child: CustomText(
                          text: "Change",
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      )
                    ],
                  ),

                  TextFormField(
                    controller: amountController1,
                    onChanged: (value) {
                      _input = value;
                      convert(); // Trigger conversion
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
                        width: 45,
                        height: 50,
                        child: selectedCountry2 != null
                            ? CachedNetworkImage(
                                imageUrl:
                                    "https://flagcdn.com/48x36/${selectedCountry2!.code.toLowerCase()}.png",
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Center(
                                  child: Icon(Icons.error),
                                ),
                                fit: BoxFit.contain,
                              )
                            : const CircleAvatar(
                                radius: 20,
                              ),
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      SizedBox(
                        width: 150,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: "To",
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontSize: 12,
                                ),
                                CustomText(
                                  text: selectedCountry2 != null
                                      ? selectedCountry2!.name
                                      : "Select Country",
                                  color: Colors.white,
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _showCountryList(2);
                        },
                        child: CustomText(
                          text: "Change",
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      )
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
                            text: convertedAmount != null
                                ? '${NumberFormat.currency(
                                    symbol:
                                        '${selectedCurrency?.name.toUpperCase()} ',
                                    locale: selectedCountry2!.locale,
                                  ).format(double.parse(convertedAmount!))} '
                                : '0',
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 35,
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              color: Theme.of(context).colorScheme.background,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1),
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

// Widget untuk membuat tombol kalkulator
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

  Widget _buildFlagWidget(Country? country) {
    if (country == null) {
      return Container(); // Widget kosong jika negara tidak dipilih
    }

    return SizedBox(
      width: 45,
      height: 50,
      child: CachedNetworkImage(
        imageUrl: "https://flagcdn.com/48x36/${country.code.toLowerCase()}.png",
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error),
        ),
        fit: BoxFit.contain,
      ),
    );
  }
}

class Country {
  final String code;
  final String name;
  final Currency currency;
  final String locale;

  Country(
      {required this.code,
      required this.name,
      required this.currency,
      required this.locale});
}

// Daftar negara dan mata uang
List<Country> countries = [
  Country(code: 'ID', name: 'Indonesia', currency: Currency.idr, locale: 'ID'),
  Country(
      code: 'US',
      name: 'United States',
      currency: Currency.usd,
      locale: 'en_us'),
  Country(
      code: 'GB',
      name: 'United Kingdom',
      currency: Currency.gbp,
      locale: 'en_gb'),
  Country(code: 'CA', name: 'Canada', currency: Currency.usd, locale: 'en_ca'),
  Country(code: 'FR', name: 'France', currency: Currency.eur, locale: 'fr_fr'),
  Country(code: 'DE', name: 'Germany', currency: Currency.eur, locale: 'de_de'),
  Country(
      code: 'AU', name: 'Australia', currency: Currency.aud, locale: 'en_au'),
  Country(code: 'JP', name: 'Japan', currency: Currency.jpy, locale: 'ja_jp'),
  Country(code: 'CN', name: 'China', currency: Currency.cny, locale: 'zh_cn'),
  Country(code: 'BR', name: 'Brazil', currency: Currency.brl, locale: 'pt_br'),
  Country(code: 'MX', name: 'Mexico', currency: Currency.mxn, locale: 'es_mx'),
  Country(code: 'RU', name: 'Russia', currency: Currency.rub, locale: 'ru_ru'),
  Country(code: 'IN', name: 'India', currency: Currency.inr, locale: 'hi_in'),
  Country(code: 'NG', name: 'Nigeria', currency: Currency.ngn, locale: 'en_ng'),
  Country(
      code: 'SA',
      name: 'Saudi Arabia',
      currency: Currency.sar,
      locale: 'ar_sa'),
  Country(
      code: 'ZA',
      name: 'South Africa',
      currency: Currency.zar,
      locale: 'en_za'),
  Country(
      code: 'KR', name: 'South Korea', currency: Currency.krw, locale: 'ko_kr'),
  Country(code: 'ES', name: 'Spain', currency: Currency.eur, locale: 'es_es'),
  Country(code: 'IT', name: 'Italy', currency: Currency.eur, locale: 'it_it'),
  Country(
      code: 'AR', name: 'Argentina', currency: Currency.ars, locale: 'es_ar'),
  Country(code: 'EG', name: 'Egypt', currency: Currency.egp, locale: 'ar_eg'),
  Country(
      code: 'TR', name: 'Turkey', currency: Currency.turkisL, locale: 'tr_tr'),
  Country(
      code: 'PK', name: 'Pakistan', currency: Currency.pkr, locale: 'ur_pk'),
  Country(
      code: 'BD', name: 'Bangladesh', currency: Currency.bdt, locale: 'bn_bd'),
  Country(code: 'IR', name: 'Iran', currency: Currency.irr, locale: 'fa_ir'),
  Country(code: 'PL', name: 'Poland', currency: Currency.pln, locale: 'pl_pl'),
  Country(
      code: 'NL', name: 'Netherlands', currency: Currency.eur, locale: 'nl_nl'),
  Country(code: 'BE', name: 'Belgium', currency: Currency.eur, locale: 'nl_be'),
  Country(
      code: 'CH', name: 'Switzerland', currency: Currency.chf, locale: 'de_ch'),
  Country(code: 'SE', name: 'Sweden', currency: Currency.sek, locale: 'sv_se'),
  Country(code: 'NO', name: 'Norway', currency: Currency.nok, locale: 'no_no'),
  Country(code: 'FI', name: 'Finland', currency: Currency.eur, locale: 'fi_fi'),
  Country(code: 'DK', name: 'Denmark', currency: Currency.dkk, locale: 'da_dk'),
  Country(
      code: 'MY', name: 'Malaysia', currency: Currency.myr, locale: 'ms_my'),
  Country(
      code: 'SG', name: 'Singapore', currency: Currency.sgd, locale: 'en_sg'),
  Country(
      code: 'TH', name: 'Thailand', currency: Currency.thb, locale: 'th_th'),
  Country(
      code: 'PH', name: 'Philippines', currency: Currency.php, locale: 'en_ph'),
  Country(code: 'CL', name: 'Chile', currency: Currency.clp, locale: 'es_cl'),
  Country(
      code: 'CO', name: 'Colombia', currency: Currency.cop, locale: 'es_co'),
  Country(code: 'PE', name: 'Peru', currency: Currency.pen, locale: 'es_pe'),
  Country(code: 'UA', name: 'Ukraine', currency: Currency.uah, locale: 'uk_ua'),
  Country(
      code: 'CZ',
      name: 'Czech Republic',
      currency: Currency.czk,
      locale: 'cs_cz'),
  Country(code: 'AT', name: 'Austria', currency: Currency.eur, locale: 'de_at'),
  Country(code: 'HU', name: 'Hungary', currency: Currency.huf, locale: 'hu_hu'),
  Country(code: 'GR', name: 'Greece', currency: Currency.eur, locale: 'el_gr')
];

class ShimmerComponent extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerComponent.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
  }) : shapeBorder = const RoundedRectangleBorder();

  const ShimmerComponent.circular({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade200,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          shape: shapeBorder,
          color: Colors.grey,
        ),
      ),
    );
  }
}
