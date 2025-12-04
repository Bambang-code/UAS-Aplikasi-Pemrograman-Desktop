// screens/pelanggan_menu_screen.dart - UPDATED WITH TABLE
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import '../models/user.dart';
import '../models/menu.dart';
import '../models/meja.dart';
import '../models/cart_item.dart';
import '../services/menu_service.dart';
import 'pelanggan_checkout_screen.dart';

class PelangganMenuWithTableScreen extends StatefulWidget {
  final User user;
  final Meja selectedMeja;

  const PelangganMenuWithTableScreen({
    super.key,
    required this.user,
    required this.selectedMeja,
  });

  @override
  State<PelangganMenuWithTableScreen> createState() =>
      _PelangganMenuWithTableScreenState();
}

class _PelangganMenuWithTableScreenState
    extends State<PelangganMenuWithTableScreen> {
  final MenuService _menuService = MenuService();
  List<Menu> _menus = [];
  List<CartItem> _cart = []; // TAMBAH INI - Variable yang hilang
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    setState(() => _isLoading = true);
    try {
      final menus = await _menuService.getAllMenu();
      setState(() {
        _menus = menus.where((m) => m.stok > 0).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addToCart(Menu menu) {
    setState(() {
      final existingItem = _cart.firstWhere(
        (item) => item.menu.id == menu.id,
        orElse: () => CartItem(menu: menu, quantity: 0),
      );

      if (existingItem.quantity == 0) {
        _cart.add(CartItem(menu: menu, quantity: 1));
      } else {
        existingItem.quantity++;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${menu.nama} ditambahkan ke keranjang'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _updateQuantity(CartItem item, int delta) {
    setState(() {
      item.quantity += delta;
      if (item.quantity <= 0) {
        _cart.remove(item);
      }
    });
  }

  double get _total => _cart.fold(0, (sum, item) => sum + item.subtotal);

  List<Menu> get _filteredMenus {
    return _menus.where((menu) {
      final matchCategory =
          _selectedCategory == 'Semua' || menu.kategori == _selectedCategory;
      final matchSearch = menu.nama.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      return matchCategory && matchSearch;
    }).toList();
  }

  void _checkout() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang masih kosong')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PelangganCheckoutWithTableScreen(
          cart: _cart,
          user: widget.user,
          selectedMeja: widget.selectedMeja,
        ),
      ),
    ).then((success) {
      if (success == true) {
        setState(() => _cart.clear());
        Navigator.pop(context); // Kembali ke table selection
      }
    });
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Menu Pelanggan'),
            Text(
              widget.selectedMeja.nomorMeja,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Row(
        children: [
          // Menu List
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari menu...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCategoryChip('Semua'),
                            _buildCategoryChip('Minuman'),
                            _buildCategoryChip('Makanan'),
                            _buildCategoryChip('Snack'),
                            _buildCategoryChip('Dessert'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredMenus.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.restaurant_menu,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak ada menu',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 200,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _filteredMenus.length,
                              itemBuilder: (context, index) {
                                final menu = _filteredMenus[index];
                                return _buildMenuCard(menu);
                              },
                            ),
                ),
              ],
            ),
          ),
          // Cart Sidebar
          Container(
            width: 350,
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.brown[700]),
                  child: const Row(
                    children: [
                      Icon(Icons.shopping_cart, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Keranjang Anda',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _cart.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Keranjang Kosong',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final item = _cart[index];
                            return _buildCartItem(item);
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Rp ${_formatNumber(_total)}',
                            style: const TextStyle(
                              fontSize: 18,
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
                          onPressed: _cart.isEmpty ? null : _checkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown[700],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Pesan Sekarang',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(Menu menu) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _addToCart(menu),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 120, child: _buildMenuImage(menu)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.nama,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    menu.kategori,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_formatNumber(menu.harga)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.menu.nama,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rp ${_formatNumber(item.menu.harga)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _updateQuantity(item, -1),
                  iconSize: 18,
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _updateQuantity(item, 1),
                  iconSize: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuImage(Menu menu) {
    if (menu.foto != null && menu.foto!.isNotEmpty) {
      if (menu.foto!.startsWith('data:image') || menu.foto!.length > 500) {
        try {
          final base64String = menu.foto!.contains(',')
              ? menu.foto!.split(',').last
              : menu.foto!;
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) =>
                _buildPlaceholder(menu),
          );
        } catch (e) {
          return _buildPlaceholder(menu);
        }
      } else {
        final file = File(menu.foto!);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) =>
                _buildPlaceholder(menu),
          );
        }
      }
    }
    return _buildPlaceholder(menu);
  }

  Widget _buildPlaceholder(Menu menu) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.brown[200]!, Colors.brown[100]!],
        ),
      ),
      child: Center(
        child: Icon(Icons.restaurant_menu, size: 48, color: Colors.brown[400]),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategory = category);
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.brown[700],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
