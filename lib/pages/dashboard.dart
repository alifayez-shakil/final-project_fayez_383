import 'package:flutter/material.dart';
import 'package:fayezmart/pages/orderspage.dart';
import 'package:fayezmart/pages/addproductpage.dart';
import 'package:fayezmart/services/supabase_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _productCount = 0;
  int _todayOrders = 0;
  double _totalRevenue = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final products = await SupabaseService().getProducts();
      final todayOrders = await SupabaseService().getTodayOrdersCount();
      final totalRevenue = await SupabaseService().getTotalRevenue();

      setState(() {
        _productCount = products.length;
        _todayOrders = todayOrders;
        _totalRevenue = totalRevenue;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddProductPage(),
            ),
          );
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add Product"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistics Section
                    const Text(
                      "Statistics",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        StatCard(
                          title: "Total Products",
                          value: _productCount.toString(),
                          icon: Icons.inventory,
                          color: Colors.blue,
                        ),
                        StatCard(
                          title: "Orders Today",
                          value: _todayOrders.toString(),
                          icon: Icons.shopping_cart,
                          color: Colors.orange,
                        ),
                        StatCard(
                          title: "Total Revenue",
                          value: "৳${_totalRevenue.toStringAsFixed(2)}",
                          icon: Icons.attach_money,
                          color: Colors.green,
                        ),
                        StatCard(
                          title: "Available Stock",
                          value: "High", // You can calculate this
                          icon: Icons.warehouse,
                          color: Colors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Quick Actions Section
                    const Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        ActionCard(
                          title: "Manage Orders",
                          icon: Icons.shopping_bag,
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OrdersPage(),
                              ),
                            );
                          },
                        ),
                        // This is the existing "Add Product" card in the grid
                        ActionCard(
                          title: "Add Product",
                          icon: Icons.add_circle,
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddProductPage(),
                              ),
                            );
                          },
                        ),
                        ActionCard(
                          title: "View Products",
                          icon: Icons.list,
                          color: Colors.orange,
                          onTap: () {
                            _showProductsDialog(context);
                          },
                        ),
                        ActionCard(
                          title: "Reports",
                          icon: Icons.analytics,
                          color: Colors.purple,
                          onTap: () {
                            _showReportsDialog(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showProductsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("All Products"),
        content: FutureBuilder<List<Map<String, dynamic>>>(
          future: SupabaseService().getProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError ||
                snapshot.data == null ||
                snapshot.data!.isEmpty) {
              return const Text("No products available");
            }

            final products = snapshot.data!;
            return SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ListTile(
                    leading: const Icon(Icons.shopping_bag),
                    title: Text(product['name']),
                    subtitle: Text(
                        "৳${product['price']} | Stock: ${product['stock']}"),
                    trailing: Text(product['category']),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showReportsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sales Report"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Today's Summary:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text("• Total Orders: $_todayOrders"),
            Text("• Total Revenue: ৳$_totalRevenue"),
            const SizedBox(height: 16),
            const Text("Product Status:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text("• Available Products: $_productCount"),
            Text("• Low Stock Items: ${_getLowStockCount()}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  int _getLowStockCount() {
    return 0; // Placeholder
  }
}

class StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
