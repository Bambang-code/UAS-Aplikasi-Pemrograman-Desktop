// screens/pelanggan_order_tracking_screen.dart - COMPLETE WITH STRUK
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/pesanan.dart';
import '../models/detail_pesanan.dart';
import '../services/pesanan_service.dart';

class PelangganOrderTrackingScreen extends StatefulWidget {
  final int pesananId;
  final User user;

  const PelangganOrderTrackingScreen({
    super.key,
    required this.pesananId,
    required this.user,
  });

  @override
  State<PelangganOrderTrackingScreen> createState() =>
      _PelangganOrderTrackingScreenState();
}

class _PelangganOrderTrackingScreenState
    extends State<PelangganOrderTrackingScreen> {
  final PesananService _pesananService = PesananService();
  Pesanan? _pesanan;
  List<DetailPesanan> _details = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPesanan();
    // Auto refresh setiap 5 detik
    Future.delayed(const Duration(seconds: 5), _autoRefresh);
  }

  void _autoRefresh() {
    if (mounted) {
      _loadPesanan();
      Future.delayed(const Duration(seconds: 5), _autoRefresh);
    }
  }

  Future<void> _loadPesanan() async {
    try {
      final pesanan = await _pesananService.getPesananById(widget.pesananId);
      final details = await _pesananService.getDetailPesanan(widget.pesananId);

      if (mounted) {
        setState(() {
          _pesanan = pesanan;
          _details = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  Color _getStatusPembayaranColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Lunas':
        return Colors.green;
      case 'Gagal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusPesananColor(String status) {
    switch (status) {
      case 'Menunggu':
        return Colors.grey;
      case 'Diproses':
        return Colors.blue;
      case 'Dikirim':
        return Colors.purple;
      case 'Selesai':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusPesananIcon(String status) {
    switch (status) {
      case 'Menunggu':
        return Icons.hourglass_empty;
      case 'Diproses':
        return Icons.outdoor_grill;
      case 'Dikirim':
        return Icons.room_service;
      case 'Selesai':
        return Icons.check_circle;
      default:
        return Icons.circle;
    }
  }

  Widget _buildStatusTimeline() {
    if (_pesanan == null) return const SizedBox();

    final statuses = ['Menunggu', 'Diproses', 'Dikirim', 'Selesai'];
    final currentIndex = statuses.indexOf(_pesanan!.statusPesanan);

    return Column(
      children: List.generate(statuses.length, (index) {
        final status = statuses[index];
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? _getStatusPesananColor(status)
                        : Colors.grey[300],
                    border: Border.all(
                      color: isCurrent
                          ? _getStatusPesananColor(status)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    _getStatusPesananIcon(status),
                    color: isCompleted ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                ),
                if (index < statuses.length - 1)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? Colors.black : Colors.grey,
                    ),
                  ),
                  if (isCurrent)
                    Text(
                      'Status saat ini',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _showStrukDialog() async {
    if (_pesanan == null || _details.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.brown[700],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Struk Pembayaran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo / Header
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.coffee,
                                size: 48, color: Colors.brown[700]),
                            const SizedBox(height: 8),
                            const Text(
                              'CAFE MANAGEMENT',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Jl. Contoh No. 123',
                              style: TextStyle(fontSize: 12),
                            ),
                            const Text(
                              'Telp: 0812-3456-7890',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 32),
                      // Info Transaksi
                      _buildStrukRow('Pesanan', '#${_pesanan!.id}'),
                      _buildStrukRow(
                        'Tanggal',
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(_pesanan!.tanggal),
                      ),
                      _buildStrukRow('Meja', _pesanan!.nomorMeja),
                      _buildStrukRow(
                        'Pembayaran',
                        _pesanan!.metodePembayaran ?? '-',
                      ),
                      const Divider(height: 24),
                      // Items
                      const Text(
                        'Item Pesanan:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._details.map((detail) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${detail.namaMenu} x${detail.jumlah}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  'Rp ${_formatNumber(detail.subtotal)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          )),
                      const Divider(height: 24),
                      // Total
                      if (_pesanan!.diskon > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:'),
                            Text('Rp ${_formatNumber(_pesanan!.subtotal)}'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Diskon:',
                              style: TextStyle(color: Colors.red),
                            ),
                            Text(
                              '- Rp ${_formatNumber(_pesanan!.diskon)}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Rp ${_formatNumber(_pesanan!.total)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      // Status Pembayaran
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getStatusPembayaranColor(
                                  _pesanan!.statusPembayaran)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getStatusPembayaranColor(
                                _pesanan!.statusPembayaran),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _pesanan!.statusPembayaran == 'Lunas'
                                  ? Icons.check_circle
                                  : Icons.pending,
                              color: _getStatusPembayaranColor(
                                  _pesanan!.statusPembayaran),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _pesanan!.statusPembayaran == 'Lunas'
                                    ? 'PEMBAYARAN LUNAS'
                                    : 'MENUNGGU PEMBAYARAN',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusPembayaranColor(
                                      _pesanan!.statusPembayaran),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Column(
                          children: [
                            Text(
                              'Terima Kasih',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Pesanan Tidak Dapat Dibatalkan',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Tutup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[700],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrukRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status Pesanan'),
            Text(
              'Pesanan #${widget.pesananId}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPesanan,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pesanan == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      const Text(
                        'Pesanan tidak ditemukan',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Kembali'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[700],
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Card
                      Card(
                        color: Colors.brown[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.person,
                                  size: 40, color: Colors.brown[700]),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Halo, ${widget.user.username}!',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.brown[900],
                                      ),
                                    ),
                                    Text(
                                      'Terima kasih atas pesanan Anda',
                                      style: TextStyle(
                                        color: Colors.brown[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Status Pembayaran
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Status Pembayaran',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _getStatusPembayaranColor(
                                          _pesanan!.statusPembayaran)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getStatusPembayaranColor(
                                        _pesanan!.statusPembayaran),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _pesanan!.statusPembayaran == 'Lunas'
                                          ? Icons.check_circle
                                          : _pesanan!.statusPembayaran ==
                                                  'Gagal'
                                              ? Icons.cancel
                                              : Icons.pending,
                                      color: _getStatusPembayaranColor(
                                          _pesanan!.statusPembayaran),
                                      size: 32,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _pesanan!.statusPembayaran,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: _getStatusPembayaranColor(
                                                  _pesanan!.statusPembayaran),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _pesanan!.statusPembayaran ==
                                                    'Pending'
                                                ? 'Menunggu konfirmasi kasir'
                                                : _pesanan!.statusPembayaran ==
                                                        'Lunas'
                                                    ? 'Pembayaran telah dikonfirmasi'
                                                    : 'Pembayaran ditolak',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_pesanan!.statusPembayaran == 'Pending') ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: Colors.orange[700], size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _pesanan!.metodePembayaran == 'Cash'
                                              ? 'Silahkan bayar di kasir'
                                              : 'Kasir sedang memverifikasi pembayaran Anda',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange[900],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status Pesanan Timeline
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Status Pesanan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildStatusTimeline(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Detail Pesanan
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Detail Pesanan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(
                                'Meja',
                                _pesanan!.nomorMeja,
                                Icons.table_restaurant,
                              ),
                              _buildInfoRow(
                                'Tanggal',
                                DateFormat('dd MMM yyyy HH:mm')
                                    .format(_pesanan!.tanggal),
                                Icons.calendar_today,
                              ),
                              _buildInfoRow(
                                'Metode Pembayaran',
                                _pesanan!.metodePembayaran ?? '-',
                                Icons.payment,
                              ),
                              const Divider(height: 24),
                              const Text(
                                'Item Pesanan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._details.map((detail) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${detail.namaMenu} x${detail.jumlah}',
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        Text(
                                          'Rp ${_formatNumber(detail.subtotal)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              const Divider(height: 24),
                              if (_pesanan!.diskon > 0) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Subtotal:'),
                                    Text(
                                        'Rp ${_formatNumber(_pesanan!.subtotal)}'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Diskon:',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    Text(
                                      '- Rp ${_formatNumber(_pesanan!.diskon)}',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'TOTAL',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Rp ${_formatNumber(_pesanan!.total)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tombol Lihat Struk
                      if (_pesanan!.statusPembayaran == 'Lunas') ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showStrukDialog,
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('Lihat Struk'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Tombol Kembali
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Kembali'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
