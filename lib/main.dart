// lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

// Product model class
class Product {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String price;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Get the first image URL if available
    String imageUrl = '';
    if (json['images'] != null && json['images'].length > 0) {
      imageUrl = json['images'][0]['src'];
    }
    // Get price from first variant if available
    String price = '';
    if (json['variants'] != null && json['variants'].length > 0) {
      price = json['variants'][0]['price'];
    }
    return Product(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['body_html'] ?? '',
      imageUrl: imageUrl,
      price: price,
    );
  }
}

// Function to fetch products using Shopify Admin API
Future<List<Product>> fetchProducts() async {
  // Replace YOUR_STORE_NAME and YOUR_TOKEN_HERE with your actual Shopify details.
  final url =
      "https://YOUR_STORE_NAME.myshopify.com/admin/api/2023-10/products.json?limit=10";
  final response = await http.get(Uri.parse(url), headers: {
    "X-Shopify-Access-Token": "YOUR_TOKEN_HERE",
    "Content-Type": "application/json"
  });
  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    final List<dynamic> productsJson = data['products'];
    return productsJson.map((json) => Product.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load products');
  }
}

// Global cart list (for simplicity)
List<Product> cart = [];

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Language toggle: true for English, false for Arabic.
  bool languageEnglish = true;

  void toggleLanguage() {
    setState(() {
      languageEnglish = !languageEnglish;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bassant Jewellery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(
        languageEnglish: languageEnglish,
        toggleLanguage: toggleLanguage,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final bool languageEnglish;
  final VoidCallback toggleLanguage;

  const HomeScreen({Key? key, required this.languageEnglish, required this.toggleLanguage})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String titleText = languageEnglish ? "Products" : "المنتجات";
    return Scaffold(
      appBar: AppBar(
        title: Text("Bassant Jewellery - $titleText"),
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            onPressed: toggleLanguage,
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CartScreen(languageEnglish: languageEnglish)));
            },
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
                child: Text("Menu", style: TextStyle(fontSize: 24))),
            ListTile(
              title: Text(languageEnglish ? "Admin Panel" : "لوحة الإدارة"),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AdminPanelScreen(languageEnglish: languageEnglish)));
              },
            )
          ],
        ),
      ),
      body: FutureBuilder<List<Product>>(
        future: fetchProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Product> products = snapshot.data!;
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                Product product = products[index];
                return ListTile(
                  leading: product.imageUrl != ''
                      ? Image.network(product.imageUrl,
                          width: 50, height: 50, fit: BoxFit.cover)
                      : Container(width: 50, height: 50, color: Colors.grey),
                  title: Text(product.title),
                  subtitle: Text(
                      "${languageEnglish ? "Price" : "السعر"}: ${product.price}"),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                                product: product,
                                languageEnglish: languageEnglish)));
                  },
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(
                child: Text(languageEnglish
                    ? "Error loading products"
                    : "خطأ في تحميل المنتجات"));
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final bool languageEnglish;

  const ProductDetailScreen({Key? key, required this.product, required this.languageEnglish})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String addToCartText = languageEnglish ? "Add to Cart" : "أضف إلى السلة";
    return Scaffold(
      appBar: AppBar(
        title: Text(product.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            product.imageUrl != ''
                ? Image.network(product.imageUrl)
                : Container(height: 200, color: Colors.grey),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(product.title,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("${languageEnglish ? "Price" : "السعر"}: ${product.price}",
                  style: TextStyle(fontSize: 18)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                product.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                cart.add(product);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(languageEnglish
                      ? "Added to cart"
                      : "تم الإضافة إلى السلة"),
                ));
              },
              child: Text(addToCartText),
            )
          ],
        ),
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  final bool languageEnglish;
  const CartScreen({Key? key, required this.languageEnglish}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String checkoutText = languageEnglish ? "Checkout" : "الدفع";
    return Scaffold(
      appBar: AppBar(
        title: Text(languageEnglish ? "Your Cart" : "سلة المشتريات"),
      ),
      body: cart.isEmpty
          ? Center(
              child: Text(languageEnglish ? "Cart is empty" : "السلة فارغة"))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      Product product = cart[index];
                      return ListTile(
                        leading: product.imageUrl != ''
                            ? Image.network(product.imageUrl,
                                width: 50, height: 50, fit: BoxFit.cover)
                            : Container(width: 50, height: 50, color: Colors.grey),
                        title: Text(product.title),
                        subtitle: Text("${languageEnglish ? "Price" : "السعر"}: ${product.price}"),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    cart.clear();
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(languageEnglish ? "Order Placed" : "تم الطلب"),
                          content: Text(languageEnglish
                              ? "Your order has been placed with Cash on Delivery."
                              : "تم طلب الشراء بنظام الدفع عند الاستلام."),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                              },
                              child: Text("OK"),
                            )
                          ],
                        );
                      },
                    );
                  },
                  child: Text(checkoutText),
                ),
              ],
            ),
    );
  }
}

class AdminPanelScreen extends StatelessWidget {
  final bool languageEnglish;
  const AdminPanelScreen({Key? key, required this.languageEnglish}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy admin panel screen.
    return Scaffold(
      appBar: AppBar(
        title: Text(languageEnglish ? "Admin Panel" : "لوحة الإدارة"),
      ),
      body: Center(
        child: Text(
          languageEnglish
              ? "Admin Panel - Under Construction"
              : "لوحة الإدارة - قيد الإنشاء",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
