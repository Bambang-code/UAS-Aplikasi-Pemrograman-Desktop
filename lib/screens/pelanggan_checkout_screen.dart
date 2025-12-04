// screens/pelanggan_checkout_screen.dart - UPDATED WITH KARTU
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../models/user.dart';
import '../models/cart_item.dart';
import '../models/meja.dart';
import '../services/pesanan_service.dart';
import '../utils/constants.dart';

class PelangganCheckoutWithTableScreen extends StatefulWidget {
  final List<CartItem> cart;
  final User user;
  final Meja selectedMeja;

  const PelangganCheckoutWithTableScreen({
    super.key,
    required this.cart,
    required this.user,
    required this.selectedMeja,
  });

  @override
  State<PelangganCheckoutWithTableScreen> createState() =>
      _PelangganCheckoutWithTableScreenState();
}

class _PelangganCheckoutWithTableScreenState
    extends State<PelangganCheckoutWithTableScreen> {
  bool _isProcessing = false;
  final _promoController = TextEditingController();
  double _discount = 0;

  // Payment method
  String _paymentMethod = AppConstants.paymentCash;
  String? _buktiTransferPath;
  String? _buktiTransferBase64;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  double get _subtotal =>
      widget.cart.fold(0, (sum, item) => sum + item.subtotal);
  double get _total => _subtotal - _discount;

  void _applyPromo() {
    final promo = _promoController.text.toUpperCase();
    setState(() {
      if (promo == 'CAFE10') {
        _discount = _subtotal * 0.1;
        _showSnackBar('Diskon 10% berhasil diterapkan!', Colors.green);
      } else if (promo == 'CAFE20') {
        _discount = _subtotal * 0.2;
        _showSnackBar('Diskon 20% berhasil diterapkan!', Colors.green);
      } else if (promo.isNotEmpty) {
        _showSnackBar('Kode promo tidak valid', Colors.red);
      }
    });
  }

  Future<void> _pickTransferProof() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      setState(() {
        _buktiTransferPath = result.files.first.path;
        _buktiTransferBase64 = base64Image;
      });

      _showSnackBar('Bukti transfer berhasil dipilih', Colors.green);
    }
  }

  Future<void> _createPesanan() async {
    // Validasi bukti transfer untuk QRIS dan Transfer
    if ((_paymentMethod == AppConstants.paymentQRIS ||
            _paymentMethod == AppConstants.paymentTransfer) &&
        _buktiTransferBase64 == null) {
      _showSnackBar(
        'Silahkan upload bukti pembayaran terlebih dahulu',
        Colors.orange,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final pesananService = PesananService();
      final pesananId = await pesananService.createPesanan(
        pelangganId: widget.user.id!,
        cart: widget.cart,
        nomorMeja: widget.selectedMeja.nomorMeja,
        diskon: _discount,
        metodePembayaran: _paymentMethod,
        buktiTransfer: _buktiTransferBase64,
      );

      if (mounted) {
        await _showSuccessDialog(pesananId);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showSuccessDialog(int pesananId) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 8),
            Text('Pesanan Berhasil Dibuat'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ID Pesanan: #$pesananId'),
            const SizedBox(height: 16),
            Text('Total: Rp ${_formatNumber(_total)}'),
            const SizedBox(height: 8),
            Text('Meja: ${widget.selectedMeja.nomorMeja}'),
            Text('Metode: $_paymentMethod'),
            const SizedBox(height: 16),
            const Text('Pesanan Anda telah diterima kasir.'),
            if (_paymentMethod == AppConstants.paymentCash ||
                _paymentMethod == AppConstants.paymentKartu)
              const Text('Silahkan bayar di kasir.')
            else
              const Text('Menunggu konfirmasi pembayaran.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown[700]),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
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
      appBar: AppBar(title: const Text('Checkout Pesanan')),
      body: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // INFO MEJA TERPILIH
                  Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.table_restaurant,
                            color: Colors.green[700],
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Meja Terpilih',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                widget.selectedMeja.nomorMeja,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[900],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Metode Pembayaran',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentMethodCard(
                    AppConstants.paymentCash,
                    Icons.money,
                    Colors.green,
                    'Bayar di kasir',
                  ),
                  _buildPaymentMethodCard(
                    AppConstants.paymentQRIS,
                    Icons.qr_code,
                    Colors.blue,
                    'Upload bukti QRIS',
                  ),
                  _buildPaymentMethodCard(
                    AppConstants.paymentTransfer,
                    Icons.account_balance,
                    Colors.purple,
                    'Upload bukti transfer',
                  ),
                  _buildPaymentMethodCard(
                    AppConstants.paymentKartu,
                    Icons.credit_card,
                    Colors.orange,
                    'Gesek kartu di kasir',
                  ),
                  if (_paymentMethod == AppConstants.paymentQRIS ||
                      _paymentMethod == AppConstants.paymentTransfer) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                _paymentMethod == AppConstants.paymentQRIS
                                    ? 'Informasi QRIS'
                                    : 'Informasi Transfer',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_paymentMethod == AppConstants.paymentQRIS)
                            const Text(
                                'Scan QRIS di kasir atau minta ke pelayan')
                          else ...[
                            const Text('Bank: BCA'),
                            const Text('No. Rek: 1234567890'),
                            const Text('A.n: Cafe Management'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickTransferProof,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _buktiTransferPath != null
                                ? Colors.green
                                : Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: _buktiTransferPath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(_buktiTransferPath!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.upload_file,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Klik untuk upload bukti pembayaran',
                                    style: TextStyle(color: Colors.grey[600]),
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
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Kode Promo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoController,
                          decoration: InputDecoration(
                            hintText: 'Masukkan kode promo',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _applyPromo,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Text('Terapkan'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contoh: CAFE10 (10%), CAFE20 (20%)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 350,
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Pesanan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.cart.length,
                    itemBuilder: (context, index) {
                      final item = widget.cart[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.menu.nama,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity} x Rp ${_formatNumber(item.menu.harga)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Rp ${_formatNumber(item.subtotal)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text('Rp ${_formatNumber(_subtotal)}'),
                  ],
                ),
                if (_discount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Diskon:',
                        style: TextStyle(color: Colors.red),
                      ),
                      Text(
                        '- Rp ${_formatNumber(_discount)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rp ${_formatNumber(_total)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _createPesanan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'BUAT PESANAN',
                            style: TextStyle(
                              fontSize: 18,
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
    );
  }

  Widget _buildPaymentMethodCard(
    String method,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    final isSelected = _paymentMethod == method;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? color.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() {
          _paymentMethod = method;
          if (method == AppConstants.paymentCash ||
              method == AppConstants.paymentKartu) {
            _buktiTransferPath = null;
            _buktiTransferBase64 = null;
          }
        }),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
