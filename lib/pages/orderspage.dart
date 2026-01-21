import 'package:flutter/material.dart';
import 'package:fayezmart/services/supabase_service.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    _orders = await SupabaseService().getAllOrders();
    setState(() => _isLoading = false);
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    final success =
        await SupabaseService().updateOrderStatus(orderId, newStatus);
    if (success) {
      await _loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Orders"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text("No orders found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final user = order['users'] as Map<String, dynamic>? ?? {};
                    final orderId = order['id'] as String? ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: _getStatusIcon(order['status'] ?? 'pending'),
                        title: Text("Order #${orderId.substring(0, 8)}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Customer: ${user['name'] ?? user['email'] ?? 'N/A'}"),
                            Text(
                                "Total: ৳${(order['total_amount'] ?? 0).toString()}"),
                          ],
                        ),
                        trailing: DropdownButton<String>(
                          value: order['status'] ?? 'pending',
                          items:
                              ['pending', 'processing', 'shipped', 'delivered']
                                  .map((status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      ))
                                  .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _updateStatus(orderId, value);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return const Icon(Icons.pending, color: Colors.orange);
      case 'processing':
        return const Icon(Icons.sync, color: Colors.blue);
      case 'shipped':
        return const Icon(Icons.local_shipping, color: Colors.purple);
      case 'delivered':
        return const Icon(Icons.check_circle, color: Colors.green);
      default:
        return const Icon(Icons.question_mark, color: Colors.grey);
    }
  }
}
