import 'package:flutter/material.dart';
import 'colors.dart';

class CustomText12 extends StatelessWidget {
  final String text;
  final bool bold;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDecoration? decoration;

  const CustomText12(
      this.text, {
        super.key,
        this.bold = false,
        this.color,
        this.align,
        this.maxLines,
        this.overflow,
        this.decoration,
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
        fontSize: 12,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: color ?? AppColors.black,
        decoration: decoration,
      ),
    );
  }
}

class CustomText14 extends StatelessWidget {
  final String text;
  final bool bold;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDecoration? decoration;

  CustomText14(
      this.text, {
        super.key,
        this.bold = false,
        this.color,
        this.align,
        this.maxLines,
        this.overflow,
        this.decoration,
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
        fontSize: 14,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: color ?? AppColors.black,
        decoration: decoration,
      ),
    );
  }
}

class CustomText16 extends StatelessWidget {
  final String text;
  final bool bold;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDecoration? decoration;

  CustomText16(
      this.text, {
        super.key,
        this.bold = false,
        this.color,
        this.align,
        this.maxLines,
        this.overflow,
        this.decoration,
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
        decoration: decoration,
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

  CustomText20(
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

  CustomText18(
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

  CustomText24(
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

class CustomText32 extends StatelessWidget {
  final String text;
  final bool bold;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow? overflow;

  CustomText32(
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
        fontSize: 32,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: color ?? AppColors.black,
      ),
    );
  }
}
