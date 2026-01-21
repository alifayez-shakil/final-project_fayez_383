import 'package:flutter/material.dart';
import 'package:fayezmart/pages/placeorderpage.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  const CartPage({super.key, required this.cartItems});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late List<Map<String, dynamic>> _cartItems;

  @override
  void initState() {
    super.initState();
    _cartItems = List.from(widget.cartItems);
  }

  void _updateQuantity(int index, int change) {
    setState(() {
      final currentQuantity = _cartItems[index]['quantity'] as int? ?? 1;
      final newQuantity = currentQuantity + change;
      if (newQuantity < 1) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index]['quantity'] = newQuantity;
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item removed from cart'),
        backgroundColor: Colors.red,
      ),
    );
  }

  double _getTotal() {
    return _cartItems.fold(0.0, (double sum, item) {
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      final quantity = (item['quantity'] as int? ?? 1).toDouble();
      return sum + (price * quantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Cart"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Cart items
          Expanded(
            child: _cartItems.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Your cart is empty",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final price =
                          double.tryParse(item['price'].toString()) ?? 0.0;
                      final quantity = item['quantity'] as int? ?? 1;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.shopping_bag,
                                color: Colors.green),
                          ),
                          title: Text(
                            item['name'] ?? 'Product',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('৳${price.toStringAsFixed(2)} each'),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    iconSize: 20,
                                    onPressed: () => _updateQuantity(index, -1),
                                  ),
                                  Text(
                                    'Qty: $quantity',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    iconSize: 20,
                                    onPressed: () => _updateQuantity(index, 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeItem(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Checkout section
          if (_cartItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: const Border(top: BorderSide(color: Colors.grey)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Amount:",
                          style: TextStyle(fontSize: 18)),
                      Text(
                        "৳${_getTotal().toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlaceOrderPage(
                              cartItems: _cartItems,
                              totalAmount: _getTotal(),
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        "Proceed to Checkout",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
