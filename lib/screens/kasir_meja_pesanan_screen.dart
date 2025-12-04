// screens/kasir_meja_pesanan_screen.dart - UPDATED (Tambah tombol hapus untuk admin)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/meja.dart';
import '../services/db_helper.dart';
import '../services/pesanan_service.dart'; // TAMBAH INI

class KasirMejaPesananScreen extends StatefulWidget {
  final Meja meja;
  final User user;

  const KasirMejaPesananScreen({
    super.key,
    required this.meja,
    required this.user,
  });

  @override
  State<KasirMejaPesananScreen> createState() => _KasirMejaPesananScreenState();
}

class _KasirMejaPesananScreenState extends State<KasirMejaPesananScreen> {
  List<Map<String, dynamic>> _pesanan = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto refresh setiap 3 detik
    Future.delayed(const Duration(seconds: 3), _autoRefresh);
  }

  void _autoRefresh() {
    if (mounted) {
      _loadData();
      Future.delayed(const Duration(seconds: 3), _autoRefresh);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dbHelper = DBHelper();

      // Load pesanan untuk meja ini DENGAN nama pelanggan
      final pesananData = await dbHelper.rawQuery('''
      SELECT p.*, u.username as pelanggan_nama
      FROM pesanan p
      LEFT JOIN users u ON p.pelanggan_id = u.id
      WHERE p.nomor_meja = ?
      ORDER BY p.tanggal DESC
    ''', [widget.meja.nomorMeja]);

      setState(() {
        _pesanan = pesananData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error: $e', Colors.red);
    }
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

  // TAMBAH METHOD INI - Hapus pesanan gagal
  Future<void> _deletePesanan(Map<String, dynamic> pesanan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 32),
            const SizedBox(width: 8),
            const Text('Hapus Pesanan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yakin ingin menghapus pesanan #${pesanan['id']}?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stok menu akan dikembalikan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete),
            label: const Text('Ya, Hapus'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PesananService().deletePesanan(pesanan['id']);
        _loadData();
        _showSnackBar('Pesanan berhasil dihapus', Colors.green);
      } catch (e) {
        _showSnackBar('Error: $e', Colors.red);
      }
    }
  }

  Future<void> _showPesananDetail(Map<String, dynamic> pesanan) async {
    try {
      final dbHelper = DBHelper();
      final details = await dbHelper.rawQuery('''
        SELECT dp.*, m.nama as nama_menu, m.harga as harga_satuan
        FROM detail_pesanan dp
        JOIN menu m ON dp.menu_id = m.id
        WHERE dp.pesanan_id = ?
      ''', [pesanan['id']]);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Detail Pesanan #${pesanan['id']}'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Pelanggan', pesanan['pelanggan_nama'] ?? '-'),
                  _buildInfoRow('Meja', pesanan['nomor_meja']),
                  _buildInfoRow(
                    'Tanggal',
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(DateTime.parse(pesanan['tanggal'])),
                  ),
                  _buildInfoRow(
                    'Metode Pembayaran',
                    pesanan['metode_pembayaran'] ?? 'Belum dipilih',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status Pembayaran:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildStatusChip(
                              pesanan['status_pembayaran'],
                              _getStatusPembayaranColor(
                                pesanan['status_pembayaran'],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status Pesanan:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildStatusChip(
                              pesanan['status_pesanan'],
                              _getStatusPesananColor(pesanan['status_pesanan']),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Item Pesanan:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...details.map(
                    (d) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('${d['nama_menu']} x${d['jumlah']}'),
                          ),
                          Text('Rp ${_formatNumber(d['subtotal'])}'),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  if (pesanan['diskon'] > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text('Rp ${_formatNumber(pesanan['subtotal'])}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Diskon:',
                          style: TextStyle(color: Colors.red),
                        ),
                        Text(
                          '- Rp ${_formatNumber(pesanan['diskon'])}',
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
                        'Total:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Rp ${_formatNumber(pesanan['total'])}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
            // TAMBAH TOMBOL HAPUS INI - Hanya untuk admin dan status Gagal
            if (widget.user.role == 'admin' &&
                pesanan['status_pembayaran'] == 'Gagal') ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _deletePesanan(pesanan);
                },
                icon: const Icon(Icons.delete),
                label: const Text('Hapus Pesanan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ],
          ],
        ),
      );
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPesanan = _pesanan.length;
    final totalPesananLunas =
        _pesanan.where((p) => p['status_pembayaran'] == 'Lunas').length;
    final totalRevenue = _pesanan
        .where((p) => p['status_pembayaran'] == 'Lunas')
        .fold<double>(0, (sum, p) => sum + (p['total'] as num).toDouble());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pesanan ${widget.meja.nomorMeja}'),
            Text(
              widget.meja.status,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.brown[700]!, Colors.brown[500]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
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
                          Icons.table_restaurant,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.meja.nomorMeja,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: widget.meja.status == 'Kosong'
                                    ? Colors.green
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.meja.status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$totalPesanan',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Total Pesanan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Pesanan Lunas',
                        totalPesananLunas.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Revenue',
                        'Rp ${_formatNumber(totalRevenue)}',
                        Icons.attach_money,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 20, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Daftar pesanan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
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
                : _buildPesananList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPesananList() {
    if (_pesanan.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada pesanan',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Pesanan dari ${widget.meja.nomorMeja} akan muncul di sini',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pesanan.length,
      itemBuilder: (context, index) {
        final pesanan = _pesanan[index];
        final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showPesananDetail(pesanan),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusPesananColor(pesanan['status_pesanan'])
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusPesananIcon(pesanan['status_pesanan']),
                      color: _getStatusPesananColor(pesanan['status_pesanan']),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pesanan #${pesanan['id']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rp ${_formatNumber(pesanan['total'])}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pelanggan: ${pesanan['pelanggan_nama'] ?? '-'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dateFormat.format(DateTime.parse(pesanan['tanggal'])),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _buildStatusChip(
                              pesanan['status_pembayaran'],
                              _getStatusPembayaranColor(
                                pesanan['status_pembayaran'],
                              ),
                            ),
                            _buildStatusChip(
                              pesanan['status_pesanan'],
                              _getStatusPesananColor(pesanan['status_pesanan']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
