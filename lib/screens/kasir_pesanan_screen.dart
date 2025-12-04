import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/user.dart';
import '../models/pesanan.dart';
import '../models/detail_pesanan.dart';
import '../services/pesanan_service.dart';
import '../utils/constants.dart';
import 'kasir_payment_screen.dart';

class KasirPesananScreen extends StatefulWidget {
  final User user;

  const KasirPesananScreen({super.key, required this.user});

  @override
  State<KasirPesananScreen> createState() => _KasirPesananScreenState();
}

class _KasirPesananScreenState extends State<KasirPesananScreen> {
  final PesananService _pesananService = PesananService();
  List<Pesanan> _pesanan = [];
  String _selectedFilter = 'Semua';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPesanan();
    Future.delayed(const Duration(seconds: 3), _autoRefresh);
  }

  void _autoRefresh() {
    if (mounted) {
      _loadPesanan();
      Future.delayed(const Duration(seconds: 3), _autoRefresh);
    }
  }

  Future<void> _loadPesanan() async {
    setState(() => _isLoading = true);
    try {
      List<Pesanan> pesanan;
      if (_selectedFilter == 'Semua') {
        pesanan = await _pesananService.getAllPesanan();
      } else if (AppConstants.statusPembayaran.contains(_selectedFilter)) {
        pesanan = await _pesananService.getPesananByStatusPembayaran(
          _selectedFilter,
        );
      } else {
        pesanan = await _pesananService.getPesananByStatusPesanan(
          _selectedFilter,
        );
      }

      setState(() {
        _pesanan = pesanan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _viewDetails(Pesanan pesanan) async {
    try {
      final details = await _pesananService.getDetailPesanan(pesanan.id!);
      if (mounted) {
        _showDetailDialog(pesanan, details);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _showDeleteConfirmDialog(Pesanan pesanan) async {
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
            Text('Yakin ingin menghapus pesanan #${pesanan.id}?'),
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
                      'Stok menu akan dikembalikan dan meja akan dikosongkan',
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
        await _pesananService.deletePesanan(pesanan.id!);
        _loadPesanan();
        _showSnackBar('Pesanan berhasil dihapus', Colors.green);
      } catch (e) {
        _showSnackBar('Error: $e', Colors.red);
      }
    }
  }

  void _showDetailDialog(Pesanan pesanan, List<DetailPesanan> details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Pesanan #${pesanan.id}'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Meja', pesanan.nomorMeja),
                _buildInfoRow(
                  'Pelanggan',
                  pesanan.pelangganNama ?? '-',
                ),
                _buildInfoRow(
                  'Metode',
                  pesanan.metodePembayaran ?? 'Belum dipilih',
                ),
                _buildInfoRow(
                  'Tanggal',
                  DateFormat('dd/MM/yyyy HH:mm').format(pesanan.tanggal),
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
                            pesanan.statusPembayaran,
                            _getStatusPembayaranColor(
                              pesanan.statusPembayaran,
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
                            pesanan.statusPesanan,
                            _getStatusPesananColor(pesanan.statusPesanan),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Bukti transfer
                if (pesanan.buktiTransfer != null &&
                    pesanan.buktiTransfer!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    'Bukti Pembayaran:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showFullImageDialog(pesanan.buktiTransfer!),
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(pesanan.buktiTransfer!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Text('Error loading image')),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Klik untuk memperbesar',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(),
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
                        Expanded(child: Text('${d.namaMenu} x${d.jumlah}')),
                        Text('Rp ${_formatNumber(d.subtotal)}'),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                if (pesanan.diskon > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text('Rp ${_formatNumber(pesanan.subtotal)}'),
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
                      'Total:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Rp ${_formatNumber(pesanan.total)}',
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
          // TOMBOL LIHAT STRUK - TAMBAH INI
          if (pesanan.statusPembayaran == 'Lunas') ...[
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showStrukDialog(pesanan, details);
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('Lihat Struk'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green[700],
                side: BorderSide(color: Colors.green[700]!),
              ),
            ),
          ],
          // Tombol HAPUS untuk Admin
          if (widget.user.role == 'admin') ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showDeleteConfirmDialog(pesanan);
              },
              icon: const Icon(Icons.delete),
              label: const Text('Hapus Pesanan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
          // Tombol untuk status pembayaran Pending
          if (pesanan.statusPembayaran == 'Pending') ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showConfirmDialog(
                  'Tolak Pembayaran',
                  'Yakin ingin menolak pembayaran pesanan ini?',
                  () => _updateStatusPembayaran(pesanan, 'Gagal'),
                );
              },
              icon: const Icon(Icons.close),
              label: const Text('Tolak'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showConfirmDialog(
                  'Konfirmasi Pembayaran',
                  'Yakin pembayaran sudah diterima?',
                  () => _updateStatusPembayaran(pesanan, 'Lunas'),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Konfirmasi Bayar'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
          // Tombol untuk update status pesanan (jika sudah lunas)
          if (pesanan.statusPembayaran == 'Lunas' &&
              pesanan.statusPesanan != 'Selesai')
            PopupMenuButton<String>(
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.update),
                label: const Text('Update Status Pesanan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
              itemBuilder: (context) =>
                  AppConstants.statusPesanan.map((status) {
                return PopupMenuItem<String>(
                  value: status,
                  child: Row(
                    children: [
                      Icon(
                        _getStatusPesananIcon(status),
                        color: _getStatusPesananColor(status),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(status),
                    ],
                  ),
                );
              }).toList(),
              onSelected: (status) {
                Navigator.pop(context);
                _updateStatusPesanan(pesanan, status);
              },
            ),
        ],
      ),
    );
  }

  void _showFullImageDialog(String base64Image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Bukti Pembayaran'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.memory(
                  base64Decode(base64Image),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showConfirmDialog(
    String title,
    String message,
    VoidCallback onConfirm,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[700],
            ),
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      onConfirm();
    }
  }

  Future<void> _updateStatusPembayaran(Pesanan pesanan, String status) async {
    try {
      await _pesananService.updateStatusPembayaran(pesanan.id!, status);

      // Jika disetujui, set status pesanan ke Diproses
      if (status == 'Lunas') {
        await _pesananService.updateStatusPesanan(pesanan.id!, 'Diproses');

        // Load details dan show struk
        final details = await _pesananService.getDetailPesanan(pesanan.id!);
        if (mounted) {
          await _showStrukDialog(pesanan, details);
        }
      }

      _loadPesanan();
      _showSnackBar(
        'Status pembayaran diupdate: $status',
        status == 'Lunas' ? Colors.green : Colors.red,
      );
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _updateStatusPesanan(Pesanan pesanan, String status) async {
    try {
      await _pesananService.updateStatusPesanan(pesanan.id!, status);
      _loadPesanan();
      _showSnackBar('Status pesanan diupdate: $status', Colors.green);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _showStrukDialog(
      Pesanan pesanan, List<DetailPesanan> details) async {
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
                        DateFormat('dd/MM/yyyy HH:mm').format(pesanan.tanggal),
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
                      // Status
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'PEMBAYARAN LUNAS',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
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
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Tutup'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _printStruk(pesanan, details),
                        icon: const Icon(Icons.print),
                        label: const Text('Cetak'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[700],
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
  }

  Future<void> _printStruk(Pesanan pesanan, List<DetailPesanan> details) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'CAFE MANAGEMENT',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Jl. Contoh No. 123'),
                      pw.Text('Telp: 0812-3456-7890'),
                    ],
                  ),
                ),
                pw.Divider(),

                // Info Pesanan
                pw.Text('Pesanan: #${pesanan.id}'),
                pw.Text('Tanggal: ${dateFormat.format(pesanan.tanggal)}'),
                pw.Text('Kasir: ${widget.user.username}'),
                pw.Text('Meja: ${pesanan.nomorMeja}'),
                pw.Text('Pelanggan: ${pesanan.pelangganNama ?? '-'}'),
                pw.Divider(),

                // Items
                ...details.map(
                  (item) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text('${item.namaMenu} x${item.jumlah}'),
                      ),
                      pw.Text('Rp ${_formatNumber(item.subtotal)}'),
                    ],
                  ),
                ),
                pw.Divider(),

                // Totals
                if (pesanan.diskon > 0) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Subtotal:'),
                      pw.Text('Rp ${_formatNumber(pesanan.subtotal)}'),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Diskon:'),
                      pw.Text('- Rp ${_formatNumber(pesanan.diskon)}'),
                    ],
                  ),
                ],
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Rp ${_formatNumber(pesanan.total)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Payment Info
                pw.Text('Pembayaran: ${pesanan.metodePembayaran ?? '-'}'),
                pw.Divider(),

                // Status
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'PEMBAYARAN LUNAS',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'STATUS: DIPROSES',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                // Footer
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('Terima Kasih'),
                      pw.Text(
                        'Pesanan Tidak Dapat Dibatalkan',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // PRINT PDF
      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
      );

      if (mounted) {
        _showSnackBar('Struk berhasil dicetak', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error cetak: $e', Colors.red);
      }
    }
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).cardColor,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pesanan Pelanggan',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Total: ${_pesanan.length} pesanan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _loadPesanan,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Semua', Icons.all_inclusive),
                    const SizedBox(width: 16),
                    const VerticalDivider(width: 1),
                    const SizedBox(width: 16),
                    const Text(
                      'Pembayaran:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...AppConstants.statusPembayaran.map((s) {
                      IconData icon;
                      switch (s) {
                        case 'Pending':
                          icon = Icons.pending;
                          break;
                        case 'Lunas':
                          icon = Icons.check_circle;
                          break;
                        case 'Gagal':
                          icon = Icons.cancel;
                          break;
                        default:
                          icon = Icons.circle;
                      }
                      return _buildFilterChip(s, icon);
                    }),
                    const SizedBox(width: 16),
                    const VerticalDivider(width: 1),
                    const SizedBox(width: 16),
                    const Text(
                      'Pesanan:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...AppConstants.statusPesanan.map((s) {
                      return _buildFilterChip(s, _getStatusPesananIcon(s));
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                            'Tidak ada pesanan',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedFilter == 'Semua'
                                ? 'Belum ada pesanan masuk'
                                : 'Tidak ada pesanan dengan filter "$_selectedFilter"',
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
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewDetails(pesanan), // PERBAIKI INI
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusPesananColor(pesanan.statusPesanan)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusPesananIcon(pesanan.statusPesanan),
                  color: _getStatusPesananColor(pesanan.statusPesanan),
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
                          'Pesanan #${pesanan.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                    const SizedBox(height: 4),
                    Text(
                      'Pelanggan: ${pesanan.pelangganNama ?? '-'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Meja: ${pesanan.nomorMeja}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateFormat.format(pesanan.tanggal),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _getPaymentIcon(pesanan.metodePembayaran),
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          pesanan.metodePembayaran ?? 'Belum dipilih',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (pesanan.buktiTransfer != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Ada bukti',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildStatusChip(
                          pesanan.statusPembayaran,
                          _getStatusPembayaranColor(
                            pesanan.statusPembayaran,
                          ),
                        ),
                        _buildStatusChip(
                          pesanan.statusPesanan,
                          _getStatusPesananColor(pesanan.statusPesanan),
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
  }

  IconData _getPaymentIcon(String? method) {
    switch (method) {
      case 'Cash':
        return Icons.money;
      case 'QRIS':
        return Icons.qr_code;
      case 'Transfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }
}
