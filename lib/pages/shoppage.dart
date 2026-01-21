import 'package:flutter/material.dart';
import 'package:fayezmart/services/supabase_service.dart';
import 'package:fayezmart/pages/cartpage.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _cart = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    _products = await SupabaseService().getProducts();
    setState(() => _isLoading = false);
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final existingIndex = _cart.indexWhere(
        (item) => item['id'] == product['id'],
      );

      if (existingIndex >= 0) {
        _cart[existingIndex]['quantity'] =
            (_cart[existingIndex]['quantity'] ?? 1) + 1;
      } else {
        _cart.add({
          ...product,
          'quantity': 1,
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${product['name']} to cart'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  int _getCartItemCount() {
    return _cart.fold(
        0, (int sum, item) => sum + (item['quantity'] as int? ?? 0));
  }

  double _getCartTotal() {
    return _cart.fold(0.0, (double sum, item) {
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      final quantity = (item['quantity'] as int? ?? 0).toDouble();
      return sum + (price * quantity);
    });
  }

  void _navigateToCart() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your cart is empty"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(cartItems: _cart),
      ),
    );
  }

  void _viewProductDetails(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['name'] ?? 'Product Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (product['image_url'] != null)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                  ),
                  child:
                      Icon(Icons.image, size: 50, color: Colors.grey.shade400),
                ),
              const SizedBox(height: 16),
              Text(
                "Category: ${product['category'] ?? 'N/A'}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Price: ৳${(double.tryParse(product['price'].toString()) ?? 0.0).toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Stock: ${product['stock'] ?? 0} available",
                style: TextStyle(
                  color: (product['stock'] as int? ?? 0) > 0
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (product['description'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Description:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(product['description']),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          if ((product['stock'] as int? ?? 0) > 0)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                Navigator.pop(context);
                _addToCart(product);
              },
              child: const Text("Add to Cart"),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FayezMart Store"),
        backgroundColor: Colors.green,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _navigateToCart,
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _getCartItemCount().toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Cart Summary Bar
                if (_cart.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.blue.shade50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getCartItemCount()} items in cart',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Total: ৳${_getCartTotal().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: _navigateToCart,
                          child: const Text('View Cart'),
                        ),
                      ],
                    ),
                  ),

                // Product List Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "All Products",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "(${_products.length} items)",
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Product List
                Expanded(
                  child: _products.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_bag_outlined,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                "No products available",
                                style:
                                    TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            final price =
                                double.tryParse(product['price'].toString()) ??
                                    0.0;
                            final stock = product['stock'] as int? ?? 0;
                            final isOutOfStock = stock <= 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: () => _viewProductDetails(product),
                                contentPadding: const EdgeInsets.all(12),
                                leading: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.shopping_bag,
                                      color: Colors.green),
                                ),
                                title: Text(
                                  product['name'] ?? 'Product',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product['category'] ?? 'Category'),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '৳${price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          stock > 0
                                              ? 'In Stock'
                                              : 'Out of Stock',
                                          style: TextStyle(
                                            color: stock > 0
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: isOutOfStock
                                    ? const Text(
                                        "Sold Out",
                                        style: TextStyle(color: Colors.red),
                                      )
                                    : IconButton(
                                        icon:
                                            const Icon(Icons.add_shopping_cart),
                                        color: Colors.green,
                                        onPressed: () => _addToCart(product),
                                      ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
