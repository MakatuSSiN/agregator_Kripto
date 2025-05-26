import 'package:intl/intl.dart';

String formatCryptoPrice(double price) {
  if (price >= 10) {
    return NumberFormat("0.0#").format(price); // 2 знака
  } else if (price >= 1) {
    return NumberFormat("0.00#").format(price); // 3 знака
  } else {
    return NumberFormat("0.0000#").format(price); // 5 знака
  }
}