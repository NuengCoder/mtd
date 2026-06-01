import 'package:flutter/material.dart';

/// Wraps Navigator.pop in try-catch as per project spec.
void savePopNav(BuildContext context, [dynamic result]) {
  try {
    Navigator.of(context).pop(result);
  } catch (_) {}
}