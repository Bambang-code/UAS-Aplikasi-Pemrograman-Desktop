// models/cart_item.dart
import 'menu.dart';
class CartItem {
  final Menu menu;
  int quantity;

  CartItem({
    required this.menu,
    this.quantity = 1,
  });

  double get subtotal => menu.harga * quantity;
}