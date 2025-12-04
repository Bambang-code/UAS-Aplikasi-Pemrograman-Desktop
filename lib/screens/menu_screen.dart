// screens/menu_screen.dart - IMPROVED UI
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../models/user.dart';
import '../models/menu.dart';
import '../services/menu_service.dart';
import '../widgets/menu_card.dart';
import '../utils/constants.dart';

class MenuScreen extends StatefulWidget {
  final User user;

  const MenuScreen({super.key, required this.user});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final MenuService _menuService = MenuService();
  List<Menu> _menus = [];
  List<Menu> _filteredMenus = [];
  String _selectedCategory = 'Semua';
  final _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMenus() async {
    setState(() => _isLoading = true);
    try {
      final menus = await _menuService.getAllMenu();
      setState(() {
        _menus = menus;
        _filterMenus();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _filterMenus() {
    setState(() {
      _filteredMenus = _menus.where((menu) {
        final matchCategory =
            _selectedCategory == 'Semua' || menu.kategori == _selectedCategory;
        final matchSearch = menu.nama.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );
        return matchCategory && matchSearch;
      }).toList();
    });
  }

  void _showMenuDialog([Menu? menu]) {
    final isEdit = menu != null;
    final namaController = TextEditingController(text: menu?.nama);
    final hargaController = TextEditingController(text: menu?.harga.toString());
    final stokController = TextEditingController(text: menu?.stok.toString());
    String selectedKategori =
        menu?.kategori ?? AppConstants.menuCategories.first;
    String? selectedImagePath = menu?.foto;
    String? selectedImageBase64;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.brown[700]!, Colors.brown[500]!],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isEdit ? Icons.edit_rounded : Icons.add_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            isEdit ? 'Edit Menu' : 'Tambah Menu',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image Preview
                          Center(
                            child: GestureDetector(
                              onTap: () async {
                                final result =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  allowMultiple: false,
                                );

                                if (result != null && result.files.isNotEmpty) {
                                  final file = File(result.files.first.path!);
                                  final bytes = await file.readAsBytes();
                                  final base64Image = base64Encode(bytes);

                                  setDialogState(() {
                                    selectedImagePath = result.files.first.path;
                                    selectedImageBase64 = base64Image;
                                  });
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                height: 220,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.brown[200]!,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: selectedImagePath != null &&
                                        selectedImagePath!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: _buildImageWidget(
                                            selectedImagePath!),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_rounded,
                                            size: 64,
                                            color: Colors.brown[300],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Klik untuk upload foto',
                                            style: TextStyle(
                                              color: Colors.brown[700],
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'JPG, PNG (Max 5MB)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Nama Menu
                          TextField(
                            controller: namaController,
                            decoration: InputDecoration(
                              labelText: 'Nama Menu',
                              hintText: 'Contoh: Kopi Susu',
                              prefixIcon: Icon(Icons.restaurant_rounded,
                                  color: Colors.brown[700]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.brown[700]!, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Kategori
                          DropdownButtonFormField<String>(
                            value: selectedKategori,
                            decoration: InputDecoration(
                              labelText: 'Kategori',
                              prefixIcon: Icon(Icons.category_rounded,
                                  color: Colors.brown[700]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.brown[700]!, width: 2),
                              ),
                            ),
                            items: AppConstants.menuCategories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Row(
                                  children: [
                                    Icon(_getCategoryIcon(cat), size: 20),
                                    const SizedBox(width: 8),
                                    Text(cat),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setDialogState(() => selectedKategori = value!),
                          ),
                          const SizedBox(height: 16),

                          // Harga & Stok
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: hargaController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Harga',
                                    hintText: '15000',
                                    prefixText: 'Rp ',
                                    prefixIcon: Icon(Icons.attach_money_rounded,
                                        color: Colors.brown[700]),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors.brown[700]!, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: stokController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Stok',
                                    hintText: '100',
                                    prefixIcon: Icon(Icons.inventory_rounded,
                                        color: Colors.brown[700]),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors.brown[700]!, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Actions
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.grey[400]!),
                              ),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (namaController.text.isEmpty ||
                                    hargaController.text.isEmpty) {
                                  _showSnackBar('Nama dan harga harus diisi',
                                      Colors.orange);
                                  return;
                                }

                                final newMenu = Menu(
                                  id: menu?.id,
                                  nama: namaController.text,
                                  kategori: selectedKategori,
                                  harga: double.parse(hargaController.text),
                                  stok: int.parse(
                                    stokController.text.isEmpty
                                        ? '0'
                                        : stokController.text,
                                  ),
                                  foto:
                                      selectedImageBase64 ?? selectedImagePath,
                                );

                                try {
                                  if (isEdit) {
                                    await _menuService.updateMenu(newMenu);
                                    _showSnackBar(
                                        'Menu berhasil diupdate', Colors.green);
                                  } else {
                                    await _menuService.addMenu(newMenu);
                                    _showSnackBar('Menu berhasil ditambahkan',
                                        Colors.green);
                                  }
                                  Navigator.pop(context);
                                  _loadMenus();
                                } catch (e) {
                                  _showSnackBar('Error: $e', Colors.red);
                                }
                              },
                              icon: Icon(isEdit
                                  ? Icons.save_rounded
                                  : Icons.add_rounded),
                              label: Text(isEdit ? 'Update' : 'Tambah'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown[700],
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageWidget(String imagePath) {
    if (imagePath.startsWith('data:image') || imagePath.length > 500) {
      try {
        final base64String =
            imagePath.contains(',') ? imagePath.split(',').last : imagePath;
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity);
      } catch (e) {
        return _buildPlaceholder();
      }
    } else {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover, width: double.infinity);
      }
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.brown[100],
      child: Center(
        child:
            Icon(Icons.restaurant_rounded, size: 64, color: Colors.brown[300]),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'minuman':
        return Icons.local_drink_rounded;
      case 'makanan':
        return Icons.restaurant_rounded;
      case 'snack':
        return Icons.fastfood_rounded;
      case 'dessert':
        return Icons.cake_rounded;
      default:
        return Icons.restaurant_menu_rounded;
    }
  }

  Future<void> _deleteMenu(Menu menu) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red[700], size: 28),
            const SizedBox(width: 12),
            const Text('Konfirmasi Hapus'),
          ],
        ),
        content: Text('Hapus menu "${menu.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _menuService.deleteMenu(menu.id!);
        _showSnackBar('Menu berhasil dihapus', Colors.green);
        _loadMenus();
      } catch (e) {
        _showSnackBar('Error: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green
                  ? Icons.check_circle_rounded
                  : Icons.error_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = widget.user.role == 'admin';

    return Column(
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari menu...',
                          prefixIcon: Icon(Icons.search_rounded,
                              color: Colors.grey[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (_) => _filterMenus(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (canEdit)
                    ElevatedButton.icon(
                      onPressed: () => _showMenuDialog(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tambah Menu'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        backgroundColor: Colors.brown[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('Semua', Icons.apps_rounded),
                    ...AppConstants.menuCategories.map(
                      (cat) => _buildCategoryChip(cat, _getCategoryIcon(cat)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredMenus.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu_rounded,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada menu',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'Coba kata kunci lain'
                                : 'Mulai tambahkan menu baru',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 250,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: _filteredMenus.length,
                      itemBuilder: (context, index) {
                        final menu = _filteredMenus[index];
                        return MenuCard(
                          menu: menu,
                          onEdit: canEdit ? () => _showMenuDialog(menu) : null,
                          onDelete: canEdit ? () => _deleteMenu(menu) : null,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String category, IconData icon) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
            _filterMenus();
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.brown[700],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: isSelected ? 4 : 0,
      ),
    );
  }
}
