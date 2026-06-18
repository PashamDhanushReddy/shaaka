import 'package:flutter/foundation.dart';

class CartService {
  static final ValueNotifier<int> cartItemCountNotifier = ValueNotifier<int>(0);

  static void updateCount(int count) {
    cartItemCountNotifier.value = count;
  }
}
