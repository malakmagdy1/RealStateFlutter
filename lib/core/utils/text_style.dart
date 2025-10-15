import 'package:flutter/material.dart';
import 'colors.dart';

class CustomText16 extends StatelessWidget {
  final String text;
  final bool bold;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow? overflow;

  const CustomText16(
      this.text, {
        super.key,
        this.bold = false,
        this.color,
        this.align,
        this.maxLines,
        this.overflow,
      });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: color ?? AppColors.black,
      ),
    );
  }
}

class CustomText20 extends StatelessWidget {
  final String text;
  final bool bold;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow? overflow;

  const CustomText20(
      this.text, {
        super.key,
        this.bold = false,
        this.color,
        this.align,
        this.maxLines,
        this.overflow,
      });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: color ?? AppColors.black,
      ),
    );
  }
}

class CustomText18 extends StatelessWidget {
  final String text;
  final bool bold;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow? overflow;

  const CustomText18(
      this.text, {
        super.key,
        this.bold = false,
        this.color,
        this.align,
        this.maxLines,
        this.overflow,
      });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: color ?? AppColors.black,
      ),
    );
  }
}

class CustomText24 extends StatelessWidget {
  final String text;
  final bool bold;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow? overflow;

  const CustomText24(
      this.text, {
        super.key,
        this.bold = false,
        this.color,
        this.align,
        this.maxLines,
        this.overflow,
      });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 24,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: color ?? AppColors.black,
      ),
    );
  }
}
