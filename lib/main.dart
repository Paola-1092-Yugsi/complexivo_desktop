import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Productos Divertidos',
    home: ProductListScreen(),
  ));
}

// Modelo Producto
class Producto {
  final int id;
  final String description;
  final String price;

  Producto({
    required this.id,
    required this.description,
    required this.price,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'],
      description: json['description'],
      price: json['price'],
    );
  }
}

// Servicio API
class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/products';

  static Future<List<Producto>> obtenerProductos() async {
    final Map<String, dynamic> requestBody = {
      "search": {
        "scopes": [],
        "filters": [],
        "sorts": [
          {"field": "id", "direction": "desc"}
        ],
        "selects": [
          {"field": "id"},
          {"field": "description"},
          {"field": "price"}
        ],
        "includes": [],
        "aggregates": [],
        "page": 1,
        "limit": 10
      }
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/search'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          List<dynamic> productos = jsonResponse['data'];
          return productos.map((data) => Producto.fromJson(data)).toList();
        } else {
          throw Exception('Error en la estructura de respuesta.');
        }
      } else {
        print('Error en la respuesta del servidor: ${response.body}');
        throw Exception('Error al obtener los productos.');
      }
    } catch (e) {
      print('Excepción: $e');
      rethrow;
    }
  }
}

// Pantalla Principal
class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Producto> _productos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProductos();
  }

  Future<void> _fetchProductos() async {
    try {
      List<Producto> productos = await ApiService.obtenerProductos();
      setState(() {
        _productos = productos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error al cargar productos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Productos Divertidos 🧸', style: TextStyle(fontSize: 24)),
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchProductos,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _productos.length,
                itemBuilder: (context, index) {
                  return _buildProductItem(_productos[index]);
                },
              ),
            ),
    );
  }

  Widget _buildProductItem(Producto producto) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightGreen[100],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.orange, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  producto.description,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Text(
                "ID: ${producto.id}",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(width: 20),
              Text(
                "Precio: \$${producto.price}",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
