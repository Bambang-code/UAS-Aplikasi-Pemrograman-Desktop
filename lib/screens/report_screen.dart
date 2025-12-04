import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/user.dart';
import '../services/pesanan_service.dart'; // UPDATED
import '../widgets/report_table.dart';
import '../utils/helpers.dart';

class ReportScreen extends StatefulWidget {
  final User user;

  const ReportScreen({super.key, required this.user});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final PesananService _pesananService = PesananService(); // UPDATED
  String _selectedPeriod = 'Hari Ini';
  String? _selectedPaymentMethod;
  List<Map<String, dynamic>> _pesanan = []; // UPDATED
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      DateTime start, end;
      final now = DateTime.now();

      switch (_selectedPeriod) {
        case 'Hari Ini':
          start = DateTime(now.year, now.month, now.day);
          end = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'Minggu Ini':
          start = now.subtract(Duration(days: now.weekday - 1));
          start = DateTime(start.year, start.month, start.day, 0, 0,
              0);
          end = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'Bulan Ini':
          start = DateTime(
              now.year, now.month, 1, 0, 0, 0);
          end = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'Custom':
          if (_startDate == null || _endDate == null) {
            setState(() => _isLoading = false);
            return;
          }
          start = DateTime(
              _startDate!.year, _startDate!.month, _startDate!.day, 0, 0, 0);
          end = DateTime(
              _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
          break;
        default:
          start = DateTime(now.year, now.month, now.day);
          end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      }

      final data = await _pesananService.getPesananByDateRange(
        start,
        end,
        paymentMethod: _selectedPaymentMethod,
      );

      final summary = await _pesananService.getSummary(
        start,
        end,
        paymentMethod: _selectedPaymentMethod,
      );

      setState(() {
        _pesanan = data;
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deletePesanan(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pesanan'),
        content: const Text(
          'Yakin ingin menghapus pesanan ini dari laporan? '
          'Stok akan dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _pesananService.deletePesanan(id);
        _loadReport();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dihapus'),
            backgroundColor: Colors.green,
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
  }


  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'Custom';
      });
      _loadReport();
    }
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'LAPORAN PENJUALAN',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Periode: $_selectedPeriod'),
          if (_selectedPaymentMethod != null)
            pw.Text('Metode Pembayaran: $_selectedPaymentMethod'),
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildPDFStat(
                'Total Pesanan', // UPDATED
                '${_summary?['total_transactions'] ?? 0}',
              ),
              _buildPDFStat(
                'Total Pendapatan',
                'Rp ${Helpers.formatCurrency(_summary?['total_revenue'] ?? 0)}',
              ),
              _buildPDFStat(
                'Rata-rata',
                'Rp ${Helpers.formatCurrency(_summary?['average'] ?? 0)}',
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: [
              'ID',
              'Tanggal',
              'Meja',
              'Pelanggan',
              'Metode',
              'Total',
              'Status'
            ], // UPDATED
            data: _pesanan.map((p) {
              return [
                '#${p['id']}',
                dateFormat.format(DateTime.parse(p['tanggal'])),
                p['nomor_meja'] ?? '-',
                p['pelanggan_nama'] ?? '-', // ADDED
                p['metode_pembayaran'] ?? '-',
                'Rp ${Helpers.formatCurrency(p['total'])}',
                '${p['status_pembayaran']} / ${p['status_pesanan']}', // UPDATED
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  pw.Widget _buildPDFStat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
      ],
    );
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
                    'Laporan Penjualan',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _exportPDF,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _loadReport,
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
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPeriod,
                      decoration: const InputDecoration(
                        labelText: 'Periode',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Custom']
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedPeriod = value!);
                        if (value != 'Custom') {
                          _loadReport();
                        } else {
                          _selectDateRange();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPaymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Metode Pembayaran',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Semua'),
                        ),
                        ...['Cash', 'QRIS', 'Transfer', 'E-Wallet'].map(
                          (m) => DropdownMenuItem(value: m, child: Text(m)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedPaymentMethod = value);
                        _loadReport();
                      },
                    ),
                  ),
                  if (_selectedPeriod == 'Custom') ...[
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _selectDateRange,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _startDate != null && _endDate != null
                            ? '${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM').format(_endDate!)}'
                            : 'Pilih Tanggal',
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              if (_summary != null)
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Pesanan', // UPDATED
                        '${_summary!['total_transactions']}',
                        Icons.receipt_long, // UPDATED
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Pendapatan',
                        'Rp ${Helpers.formatCurrency(_summary!['total_revenue'])}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Rata-rata Pesanan', // UPDATED
                        'Rp ${Helpers.formatCurrency(_summary!['average'])}',
                        Icons.trending_up,
                        Colors.orange,
                      ),
                    ),
                  ],
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
                            'Tidak ada pesanan', // UPDATED
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                        :  ReportTable(
                            pesanan: _pesanan,
                            onDelete: widget.user.role == 'admin' ? _deletePesanan : null, // TAMBAH INI
                          ),
                          ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
