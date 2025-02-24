import 'package:flutter/material.dart';

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  final Color? quaternary;

  const CustomColors({this.quaternary});

  @override
  CustomColors copyWith({Color? quaternary}) {
    return CustomColors(quaternary: quaternary ?? this.quaternary);
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      quaternary: Color.lerp(quaternary, other.quaternary, t),
    );
  }
}
