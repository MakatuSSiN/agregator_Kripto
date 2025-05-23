import 'package:flutter/material.dart';

class CryptoDataRow extends StatelessWidget {  // Изменили имя на CryptoDataRow
  final String title;
  final String value;

  const CryptoDataRow({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 140, child: Text(title)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(value),
        ),
      ],
    );
  }
}