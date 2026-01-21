import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fayezmart/services/supabase_service.dart';

class CustomerLoginPage extends StatefulWidget {
  final bool isRegister;
  const CustomerLoginPage({super.key, this.isRegister = false});

  @override
  State<CustomerLoginPage> createState() => _CustomerLoginPageState();
}

class _CustomerLoginPageState extends State<CustomerLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isRegister = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _isRegister = widget.isRegister;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final success = await SupabaseService().login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (success) {
        Fluttertoast.showToast(
          msg: "Login successful!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // Navigate to shop page
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/shop',
          (route) => false,
        );
      } else {
        setState(() {
          _error = 'Invalid email or password';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Login failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // First register in auth
      // FIXED: Access client as static
      final authResponse = await SupabaseService.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (authResponse.user != null) {
        // Create user record in users table
        // FIXED: Access client as static
        await SupabaseService.client.from('users').insert({
          'id': authResponse.user!.id,
          'email': emailController.text.trim(),
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'role': 'customer',
        });

        Fluttertoast.showToast(
          msg: "Registration successful! Please login.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // Switch to login mode
        setState(() {
          _isRegister = false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Registration failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Registration failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegister ? "Customer Registration" : "Customer Login"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: 350,
            child: Card(
              elevation: 8,
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          _isRegister ? "Create Account" : "Customer Login",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_error.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Name field for registration
                      if (_isRegister)
                        Column(
                          children: [
                            TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: "Full Name",
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: _isRegister
                                  ? (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your name';
                                      }
                                      return null;
                                    }
                                  : null,
                            ),
                            const SizedBox(height: 15),
                          ],
                        ),

                      // Phone field for registration
                      if (_isRegister)
                        Column(
                          children: [
                            TextFormField(
                              controller: phoneController,
                              decoration: const InputDecoration(
                                labelText: "Phone Number",
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: _isRegister
                                  ? (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter phone number';
                                      }
                                      if (value.length < 10) {
                                        return 'Enter valid phone number';
                                      }
                                      return null;
                                    }
                                  : null,
                            ),
                            const SizedBox(height: 15),
                          ],
                        ),

                      // Email field (for both)
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Password field (for both)
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: _isRegister ? _register : _login,
                                child: Text(
                                  _isRegister ? "Register" : "Login",
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                      ),

                      // Toggle between login/register
                      const SizedBox(height: 15),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isRegister = !_isRegister;
                              _error = '';
                            });
                          },
                          child: Text(
                            _isRegister
                                ? "Already have an account? Login"
                                : "Don't have an account? Register",
                            style: TextStyle(color: Colors.green.shade700),
                          ),
                        ),
                      ),

                      // Continue as guest option
                      if (!_isRegister)
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/shop',
                                (route) => false,
                              );
                            },
                            child: const Text(
                              "Continue as Guest",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
