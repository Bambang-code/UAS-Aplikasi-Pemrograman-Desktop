// screens/pelanggan_history_screen.dart - NEW
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/pesanan.dart';
import '../services/pesanan_service.dart';
import 'pelanggan_order_tracking_screen.dart';

class PelangganHistoryScreen extends StatefulWidget {
  final User user;

  const PelangganHistoryScreen({super.key, required this.user});

  @override
  State<PelangganHistoryScreen> createState() => _PelangganHistoryScreenState();
}

class _PelangganHistoryScreenState extends State<PelangganHistoryScreen> {
  final PesananService _pesananService = PesananService();
  List<Pesanan> _pesanan = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadPesanan();
  }

  Future<void> _loadPesanan() async {
    setState(() => _isLoading = true);
    try {
      final allPesanan = await _pesananService.getAllPesanan();

      // Filter hanya pesanan user ini
      final userPesanan =
          allPesanan.where((p) => p.pelangganId == widget.user.id).toList();

      setState(() {
        if (_selectedFilter == 'Semua') {
          _pesanan = userPesanan;
        } else {
          _pesanan = userPesanan
              .where((p) => p.statusPesanan == _selectedFilter)
              .toList();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showStrukDialog(Pesanan pesanan) async {
    try {
      final details = await _pesananService.getDetailPesanan(pesanan.id!);

      if (!mounted) return;

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
                        _buildStrukRow('Pesanan', '#${pesanan.id}'),
                        _buildStrukRow(
                          'Tanggal',
                          DateFormat('dd/MM/yyyy HH:mm')
                              .format(pesanan.tanggal),
                        ),
                        _buildStrukRow('Meja', pesanan.nomorMeja),
                        _buildStrukRow(
                          'Pembayaran',
                          pesanan.metodePembayaran ?? '-',
                        ),
                        const Divider(height: 24),
                        // Items
                        const Text(
                          'Item Pesanan:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...details.map((detail) => Padding(
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
                        if (pesanan.diskon > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:'),
                              Text('Rp ${_formatNumber(pesanan.subtotal)}'),
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
                                '- Rp ${_formatNumber(pesanan.diskon)}',
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
                              'Rp ${_formatNumber(pesanan.total)}',
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
                                    pesanan.statusPembayaran)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getStatusPembayaranColor(
                                  pesanan.statusPembayaran),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                pesanan.statusPembayaran == 'Lunas'
                                    ? Icons.check_circle
                                    : Icons.pending,
                                color: _getStatusPembayaranColor(
                                    pesanan.statusPembayaran),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pesanan.statusPembayaran == 'Lunas'
                                      ? 'PEMBAYARAN LUNAS'
                                      : 'MENUNGGU PEMBAYARAN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusPembayaranColor(
                                        pesanan.statusPembayaran),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPesanan,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'Filter: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip('Semua', Icons.all_inclusive),
                  _buildFilterChip('Menunggu', Icons.hourglass_empty),
                  _buildFilterChip('Diproses', Icons.outdoor_grill),
                  _buildFilterChip('Dikirim', Icons.room_service),
                  _buildFilterChip('Selesai', Icons.check_circle),
                ],
              ),
            ),
          ),
          // List Pesanan
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pesanan.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada pesanan',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedFilter == 'Semua'
                                  ? 'Mulai pesan sekarang!'
                                  : 'Tidak ada pesanan dengan status "$_selectedFilter"',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pesanan.length,
                        itemBuilder: (context, index) {
                          final pesanan = _pesanan[index];
                          return _buildPesananCard(pesanan);
                        },
                      ),
          ),
        ],
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

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : Colors.black87,
        ),
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = label);
          _loadPesanan();
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.brown[700],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPesananCard(Pesanan pesanan) {
    final dateFormat = DateFormat('dd MMM yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PelangganOrderTrackingScreen(
                pesananId: pesanan.id!,
                user: widget.user,
              ),
            ),
          ).then((_) => _loadPesanan());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getStatusPesananColor(pesanan.statusPesanan)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getStatusPesananIcon(pesanan.statusPesanan),
                          color: _getStatusPesananColor(pesanan.statusPesanan),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pesanan #${pesanan.id}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            dateFormat.format(pesanan.tanggal),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.table_restaurant,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    pesanan.nomorMeja,
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    pesanan.metodePembayaran ?? '-',
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildStatusChip(
                        pesanan.statusPembayaran,
                        _getStatusPembayaranColor(pesanan.statusPembayaran),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(
                        pesanan.statusPesanan,
                        _getStatusPesananColor(pesanan.statusPesanan),
                      ),
                    ],
                  ),
                  Text(
                    'Rp ${_formatNumber(pesanan.total)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              // Tombol Lihat Struk (hanya muncul jika Lunas)
              if (pesanan.statusPembayaran == 'Lunas') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showStrukDialog(pesanan),
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Lihat Struk'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.brown[700],
                      side: BorderSide(color: Colors.brown[700]!),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          fontSize: 10,
        ),
      ),
    );
  }
}
