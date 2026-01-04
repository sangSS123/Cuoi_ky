import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String image;

  CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.image,
  });

  factory CartItem.fromMap(String id, Map<String, dynamic> data) {
    return CartItem(
      id: id,
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: (data['price'] as num).toDouble(),
      image: data['image'] ?? '',
    );
  }
}

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  Future<void> fetchAndSetCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .get();

      final Map<String, CartItem> loadedItems = {};
      for (var doc in snapshot.docs) {
        loadedItems[doc.id] = CartItem.fromMap(doc.id, doc.data());
      }
      _items = loadedItems;
      notifyListeners();
    } catch (error) {
      debugPrint("Lỗi tải giỏ hàng: $error");
    }
  }

  Future<void> addItem(
    String productId,
    double price,
    String name,
    String image,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(productId);

    final doc = await cartRef.get();
    if (doc.exists) {
      await cartRef.update({'quantity': FieldValue.increment(1)});
    } else {
      await cartRef.set({
        'id': productId,
        'name': name,
        'price': price,
        'image': image,
        'quantity': 1,
      });
    }
    await fetchAndSetCart();
  }

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  Future<void> removeSingleItem(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !_items.containsKey(productId)) return;

    final cartRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(productId);
    if (_items[productId]!.quantity > 1) {
      await cartRef.update({'quantity': FieldValue.increment(-1)});
    } else {
      await cartRef.delete();
    }
    await fetchAndSetCart();
  }

  Future<void> removeItem(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(productId)
        .delete();
    await fetchAndSetCart();
  }

  Future<void> clearCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      _items = {};
      notifyListeners();
    } catch (e) {
      debugPrint("Lỗi khi xóa sạch giỏ hàng: $e");
    }
  }
}
