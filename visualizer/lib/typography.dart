import 'package:flutter/material.dart';

import 'app_colors.dart';

TextStyle interText(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.textPrimary,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: 0.1,
  );
}

TextStyle monoText(
  double size, {
  FontWeight weight = FontWeight.w500,
  Color color = AppColors.textPrimary,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    fontFamily: 'Menlo',
    letterSpacing: 0.2,
  );
}
