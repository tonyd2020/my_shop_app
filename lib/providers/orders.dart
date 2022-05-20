import 'package:flutter/cupertino.dart';
import 'package:flutter_complete_guide/providers/cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({this.id, this.amount, this.products, this.dateTime});
}

class Orders with ChangeNotifier {
  List<OrderItem> _orders =[];


  List<OrderItem> get orders {
    return [..._orders];
  }

  void addOrders(List<CartItem> cart, double total) {
    _orders.insert(0, OrderItem(id: DateTime.now().toString(), amount: total, dateTime: DateTime.now(), products: cart),);
    notifyListeners();
  }
}
