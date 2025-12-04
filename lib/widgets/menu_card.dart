import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import '../models/menu.dart';
import '../utils/helpers.dart';

class MenuCard extends StatelessWidget {
  final Menu menu;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MenuCard({
    super.key,
    required this.menu,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with improved design
            Container(
              height: 140,
              child: Stack(
                children: [
                  // Image or Placeholder with shimmer effect
                  _buildImageWidget(),

                  // Gradient Overlay for better text visibility
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Stock Badge with improved design
                  if (menu.stok <= 5)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: menu.stok == 0 ? Colors.red : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (menu.stok == 0 ? Colors.red : Colors.orange)
                                      .withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              menu.stok == 0
                                  ? Icons.block_rounded
                                  : Icons.warning_amber_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              menu.stok == 0 ? 'Habis' : 'Stok: ${menu.stok}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Action Menu with improved design
                  if (onEdit != null || onDelete != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: PopupMenuButton(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: Colors.grey[700],
                            size: 20,
                          ),
                          itemBuilder: (context) => [
                            if (onEdit != null)
                              PopupMenuItem(
                                onTap: onEdit,
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded,
                                        size: 20, color: Colors.blue[700]),
                                    const SizedBox(width: 12),
                                    const Text('Edit Menu'),
                                  ],
                                ),
                              ),
                            if (onDelete != null)
                              PopupMenuItem(
                                onTap: onDelete,
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_rounded,
                                        color: Colors.red[700], size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Hapus',
                                      style: TextStyle(color: Colors.red[700]),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info Section with improved spacing and design
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Menu name
                    Text(
                      menu.nama,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Category badge with icon
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCategoryColor().withOpacity(0.2),
                            _getCategoryColor().withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getCategoryColor().withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(),
                            size: 12,
                            color: _getCategoryColor(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            menu.kategori,
                            style: TextStyle(
                              fontSize: 10,
                              color: _getCategoryColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Price with improved design
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_money_rounded,
                            size: 16,
                            color: Colors.green[700],
                          ),
                          Text(
                            'Rp ${Helpers.formatCurrency(menu.harga)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
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
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          );
        } catch (e) {
          return _buildPlaceholder();
        }
      } else {
        final file = File(menu.foto!);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          );
        }
      }
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor().withOpacity(0.3),
            _getCategoryColor().withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(),
            size: 56,
            color: _getCategoryColor().withOpacity(0.6),
          ),
          const SizedBox(height: 8),
          Text(
            menu.kategori,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getCategoryColor().withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor() {
    switch (menu.kategori.toLowerCase()) {
      case 'minuman':
        return Colors.blue;
      case 'makanan':
        return Colors.orange;
      case 'snack':
        return Colors.green;
      case 'dessert':
        return Colors.purple;
      default:
        return Colors.brown;
    }
  }

  IconData _getCategoryIcon() {
    switch (menu.kategori.toLowerCase()) {
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
}
