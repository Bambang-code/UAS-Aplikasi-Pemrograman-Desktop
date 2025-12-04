// screens/kasir_payment_screen.dart - UPDATED
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../models/pesanan.dart';
import '../models/detail_pesanan.dart';
import '../services/pesanan_service.dart';

class KasirPaymentScreen extends StatefulWidget {
  final Pesanan pesanan;
  final List<DetailPesanan> details;
  final User user;

  const KasirPaymentScreen({
    super.key,
    required this.pesanan,
    required this.details,
    required this.user,
  });

  @override
  State<KasirPaymentScreen> createState() => _KasirPaymentScreenState();
}

class _KasirPaymentScreenState extends State<KasirPaymentScreen> {
  String _paymentMethod = 'Cash';
  final _cashController = TextEditingController();
  bool _isProcessing = false;

  double get _total => widget.pesanan.total;
  double get _change {
    final cash = double.tryParse(_cashController.text) ?? 0;
    return cash - _total;
  }

  Future<void> _completePesanan() async {
    if (_paymentMethod == 'Cash') {
      final cash = double.tryParse(_cashController.text) ?? 0;
      if (cash < _total) {
        _showSnackBar('Uang tidak cukup', Colors.red);
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      // Update status pesanan ke Selesai
      await PesananService().completePesanan(widget.pesanan.id!);

      if (mounted) {
        await _showSuccessDialog();
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 8),
            Text('Pembayaran Berhasil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pesanan #${widget.pesanan.id} telah diselesaikan'),
            const SizedBox(height: 16),
            Text('Total: Rp ${_formatNumber(_total)}'),
            if (_paymentMethod == 'Cash') ...[
              const SizedBox(height: 8),
              Text(
                'Bayar: Rp ${_formatNumber(double.parse(_cashController.text))}',
              ),
              Text('Kembalian: Rp ${_formatNumber(_change)}'),
            ],
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
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
      appBar: AppBar(title: const Text('Pembayaran Pesanan')),
      body: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Metode Pembayaran',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentMethodCard('Cash', Icons.money, Colors.green),
                  _buildPaymentMethodCard('QRIS', Icons.qr_code, Colors.blue),
                  _buildPaymentMethodCard(
                    'E-Wallet',
                    Icons.account_balance_wallet,
                    Colors.orange,
                  ),
                  if (_paymentMethod == 'Cash') ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Jumlah Uang',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _cashController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'Masukkan jumlah uang',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_cashController.text.isNotEmpty && _change >= 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Kembalian:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rp ${_formatNumber(_change)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
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
                Text(
                  'Meja: ${widget.pesanan.nomorMeja}',
                  style: const TextStyle(fontSize: 16),
                ),
                const Divider(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.details.length,
                    itemBuilder: (context, index) {
                      final detail = widget.details[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    detail.namaMenu ?? 'Item',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${detail.jumlah} x Rp ${_formatNumber(detail.hargaSatuan ?? 0)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Rp ${_formatNumber(detail.subtotal)}',
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
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rp ${_formatNumber(_total)}',
                      style: const TextStyle(
                        fontSize: 24,
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
                    onPressed: _isProcessing ? null : _completePesanan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'SELESAIKAN PEMBAYARAN',
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
    );
  }

  Widget _buildPaymentMethodCard(String method, IconData icon, Color color) {
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
        onTap: () => setState(() => _paymentMethod = method),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 16),
              Text(
                method,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isSelected) Icon(Icons.check_circle, color: color),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }
}
