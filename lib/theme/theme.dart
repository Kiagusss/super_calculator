import 'package:easy_scaffold/easy_scaffold.dart';
import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
        background: colorWhite,
        primary: colorLightTextPrimary,
        secondary: colorLightTextSecondary,
        onPrimaryContainer: colorLightButtonPrimary,
        onPrimary: colorLightButtonSecondary,
        onSecondary: colorLightTextGrey,
        onSecondaryContainer: colorBgGrey,
        surfaceTint: Colors.white));

ThemeData darkMode = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
        background: colorBlack,
        primary: colorDarkTextPrimary,
        secondary: colorDarkTextSecondary,
        onPrimaryContainer: colorDarkButtonPrimary,
        onPrimary: colorDarkButtonSecondary,
        onSecondary: colorDarkTextGrey,
        onSecondaryContainer: const Color(0xff222831),
        surfaceTint: const Color(0xff181818)));
