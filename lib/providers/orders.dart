import 'package:flutter/cupertino.dart';
import 'package:flutter_complete_guide/providers/cart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({this.id, this.amount, this.products, this.dateTime});
}

class Orders with ChangeNotifier {
  static const firebaseDomain =
      'flutter-my-shop-app-d0449-default-rtdb.asia-southeast1.firebasedatabase.app';
  final String authToken;
  final String userId;

  List<OrderItem> _orders = [];

  Orders(this.authToken, this.userId, this._orders);

  List<OrderItem> get orders {
    return [..._orders];
  }

  //TO DO: Complete the Firebase functionality for orders
  Future<void> addOrders(List<CartItem> cart, double total) async {
    final url = Uri.https(firebaseDomain, '/orders/$userId.json', {'auth': authToken});
    final timestamp = DateTime.now();
    return http
        .post(url,
            body: json.encode({
              'amount': total,
              'products': cart
                  .map((cp) => {
                        'id': cp.id,
                        'title': cp.title,
                        'quantity': cp.quantity,
                        'price': cp.price,
                      })
                  .toList(),
              'dateTime': timestamp.toIso8601String(),
            }))
        .then((response) {
      _orders.insert(
        0,
        OrderItem(
            id: json.decode(response.body)['name'],
            amount: total,
            dateTime: DateTime.now(),
            products: cart),
      );
      notifyListeners();
    }).catchError((error) {
      print(error);
      throw (error);
    });
  }

  Future<void> getAllOrders() async {
    final url = Uri.https(firebaseDomain, '/orders/$userId.json', {'auth': authToken});
    final response = await http.get(url);
    final List<OrderItem> ordersList = [];
    final responseData = json.decode(response.body) as Map<String, dynamic>;
    if(responseData == null) {
      return;
    }
    responseData.forEach((orderId, data) {
      ordersList.add(
        OrderItem(
          id: orderId,
          amount: data['amount'],
          dateTime: DateTime.parse(data['dateTime']),
          products: (data['products'] as List<dynamic>)
              .map(
                (item) => CartItem(
                  id: item['id'],
                  title: item['title'],
                  quantity: item['quantity'],
                  price: item['price'],
                ),
              )
              .toList(),
        ),
      );
    });
    _orders = ordersList.reversed.toList();
    notifyListeners();
  }
}
