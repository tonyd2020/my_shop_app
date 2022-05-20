import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [];

  List<Product> get items {
    return [..._items];
  }

  void addProduct() {

    notifyListeners();
  }
}
