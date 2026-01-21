import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  Future<bool> login(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user != null;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> adminLogin(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final userData = await client
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();
        return userData['role'] == 'admin';
      }
      return false;
    } catch (e) {
      print('Admin login error: $e');
      return false;
    }
  }

  String? getCurrentUserId() => client.auth.currentUser?.id;
  bool isLoggedIn() => client.auth.currentUser != null;

  Future<List<Map<String, dynamic>>> getProducts({String? category}) async {
    try {
      var query = client.from('products').select();
      if (category != null && category != 'All') {
        query = query.eq('category', category);
      }
      final data = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  Future<bool> saveOrder({
    required double totalAmount,
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    try {
      // Generate order number
      final orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch}';

      // 1. Create order - WITHOUT user_id (guest order)
      final orderResponse = await client.from('orders').insert({
        'total_amount': totalAmount,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'delivery_address': deliveryAddress,
        'status': 'pending',
      }).select();

      if (orderResponse.isEmpty) return false;

      final orderId = orderResponse[0]['id'] as String;

      // 2. Create order items
      for (final item in cartItems) {
        await client.from('order_items').insert({
          'order_id': orderId,
          'product_id': item['id'],
          'quantity': item['quantity'],
          'price': double.tryParse(item['price'].toString()) ?? 0.0,
        });

        // 3. Update product stock
        final currentStock = int.tryParse(item['stock'].toString()) ?? 0;
        final quantity = item['quantity'] as int? ?? 1;
        if (currentStock >= quantity) {
          await client
              .from('products')
              .update({'stock': currentStock - quantity}).eq('id', item['id']);
        }
      }

      return true;
    } catch (e) {
      print('Error saving order: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final data = await client
          .from('orders')
          .select('*, order_items(*, products(*))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error getting user orders: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final data = await client
          .from('orders')
          .select('*')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error getting all orders: $e');
      return [];
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await client.from('orders').update({'status': status}).eq('id', orderId);
      return true;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  Future<bool> addProduct(Map<String, dynamic> product) async {
    try {
      await client.from('products').insert(product);
      return true;
    } catch (e) {
      print('Error adding product: $e');
      return false;
    }
  }

  Future<bool> updateProduct(
      String productId, Map<String, dynamic> updates) async {
    try {
      await client.from('products').update(updates).eq('id', productId);
      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await client.from('products').delete().eq('id', productId);
      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    try {
      final data = await client
          .from('orders')
          .select('*, order_items(*, products(*))')
          .eq('id', orderId)
          .single();
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Error getting order details: $e');
      return null;
    }
  }

  Future<int> getTodayOrdersCount() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final data = await client
          .from('orders')
          .select()
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      return (data as List).length;
    } catch (e) {
      print('Error getting today orders count: $e');
      return 0;
    }
  }

  Future<double> getTotalRevenue() async {
    try {
      final data = await client
          .from('orders')
          .select('total_amount')
          .eq('status', 'delivered');

      double total = 0.0;
      for (final order in data) {
        total += (order['total_amount'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      print('Error getting total revenue: $e');
      return 0.0;
    }
  }
}
