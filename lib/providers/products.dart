import 'package:flutter/material.dart';
import 'package:flutter_complete_guide/models/http_exception.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'product.dart';

class Products with ChangeNotifier {
  static const firebaseDomain =
      'flutter-my-shop-app-d0449-default-rtdb.asia-southeast1.firebasedatabase.app';
  List<Product> _items = [];

  // List<Product> _items = [
  //   Product(
  //     id: 'p1',
  //     title: 'Red Shirt',
  //     description: 'A red shirt - it is pretty red!',
  //     price: 29.99,
  //     imageUrl:
  //         'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
  //   ),
  //   Product(
  //     id: 'p2',
  //     title: 'Trousers',
  //     description: 'A nice pair of trousers.',
  //     price: 59.99,
  //     imageUrl:
  //         'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Trousers%2C_dress_%28AM_1960.022-8%29.jpg/512px-Trousers%2C_dress_%28AM_1960.022-8%29.jpg',
  //   ),
  //   Product(
  //     id: 'p3',
  //     title: 'Yellow Scarf',
  //     description: 'Warm and cozy - exactly what you need for the winter.',
  //     price: 19.99,
  //     imageUrl:
  //         'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
  //   ),
  //   Product(
  //     id: 'p4',
  //     title: 'A Pan',
  //     description: 'Prepare any meal you want.',
  //     price: 49.99,
  //     imageUrl:
  //         'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Cast-Iron-Pan.jpg/1024px-Cast-Iron-Pan.jpg',
  //   ),
  // ];
  //
  // var _showFavoritesOnly = false;
  String authToken;
  String userId;

  Products(this.authToken, this.userId, this._items);

  void update(String token) {
    authToken = token;
  }

  List<Product> get items {
    // if (_showFavoritesOnly) {
    //   return _items.where((item) => item.isFavorite);
    // } else{
    //   return [..._items];
    // }
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((item) => item.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  // void showFavoritesOnly(){
  //   _showFavoritesOnly = true;
  //   notifyListeners();
  // }
  //
  // void showAll(){
  //   _showFavoritesOnly = false;
  //   notifyListeners();
  // }

  Future<void> getAllProducts([bool filterByUser=false]) async {
    final filterString = filterByUser ? {'orderBy': '"creatorId"', 'equalTo': '"$userId"', 'auth': authToken} : {'auth': authToken};
    final List<Product> dataList = [];
    final url = Uri.https(firebaseDomain, '/products.json', filterString);
    // print(url);
    try {
      final response = await http.get(url);
      print('${response.statusCode} : ${response.reasonPhrase}');
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      }
      final favUrl = Uri.https(firebaseDomain, '/userFavorites/$userId.json', {'auth': authToken});
      final favResponse = await http.get(favUrl);
      final favData = json.decode(favResponse.body);
      final List<Product> loadedProducts = [];
      extractedData.forEach((prodId, prodData) {
        loadedProducts.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          price: prodData['price'],
          isFavorite: favData == null ? false : favData[prodId] ?? false,
          imageUrl: prodData['imageUrl'],
        ));
      });
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      print(error);
      throw (error);
    }
  }

  Future<void> addProduct(Product product) {
    final url = Uri.https(firebaseDomain, '/products.json', {'auth': authToken});
    return http
        .post(url,
            body: json.encode({
              'title': product.title,
              'description': product.description,
              'imageUrl': product.imageUrl,
              'price': product.price,
              'creatorId': userId,
            }))
        .then((response) {
      print('${response.statusCode} : ${response.reasonPhrase}');
      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: json.decode(response.body)['name'],
      );
      _items.add(newProduct);
      notifyListeners();
    }).catchError((error) {
      print(error);
      throw (error);
    });
  }

  Future<void> updateProduct(String id, Product product) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final url =
          Uri.https(firebaseDomain, '/products/$id.json', {'auth': authToken});
      try {
         final response = await http.patch(url,
            body: json.encode({
              'title': product.title,
              'description': product.description,
              'price': product.price,
              'imageUrl': product.imageUrl,
            }));
         print('${response.statusCode} : ${response.reasonPhrase}');
      } catch (e) {
        print(e);
      }

      _items[index] = product;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    final url = Uri.https(firebaseDomain, '/products/$id.json', {'auth': authToken});
    final currentIndex = _items.indexWhere((prod) => prod.id == id);
    var currentProd = _items[currentIndex];
    _items.removeAt(currentIndex);
    await http.delete(url).then((response) {
      if (response.statusCode >= 400) {
        _items.insert(currentIndex, currentProd);
        throw HttpException('Could not delete the item');
      } else {
        currentProd = null;
        notifyListeners();
      }
    });
  }

  Future<void> toggleFavorite(String id, String userId) async {
    final url = Uri.https(firebaseDomain, '/userFavorites/$userId/$id.json', {'auth': authToken});
    final currentIndex = _items.indexWhere((prod) => prod.id == id);
    var currentProd = _items[currentIndex];
    currentProd.toggleFavoriteStatus();
    try {
      await http
          .put(url,
              body: json.encode(currentProd.isFavorite))
          .then((response) {
        if (response.statusCode >= 400) {
          currentProd.toggleFavoriteStatus();
          throw HttpException('Could not update the database');
        } else {
          notifyListeners();
        }
      });
    } catch (e) {
      print(e);
    }
  }
}
