// widgets/report_table.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/helpers.dart';

class ReportTable extends StatelessWidget {
  final List<Map<String, dynamic>> pesanan;
  final Function(int)? onDelete; // TAMBAH parameter ini

  const ReportTable({
    super.key,
    required this.pesanan,
    this.onDelete, // TAMBAH ini
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.brown[100]),
          columns: _buildColumns(), // UBAH jadi method
          rows: pesanan.map((p) {
            final date = DateTime.parse(p['tanggal']);
            final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

            return DataRow(
              cells: _buildCells(p, dateFormat, date), // UBAH jadi method
            );
          }).toList(),
        ),
      ),
    );
  }

  // METHOD BARU untuk build columns
  List<DataColumn> _buildColumns() {
    final columns = <DataColumn>[
      const DataColumn(
        label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const DataColumn(
        label: Text(
          'Tanggal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      const DataColumn(
        label: Text(
          'Meja',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      const DataColumn(
        label: Text(
          'Pelanggan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      const DataColumn(
        label: Text(
          'Metode Pembayaran',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      const DataColumn(
        label: Text(
          'Diskon',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      const DataColumn(
        label: Text(
          'Total',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      const DataColumn(
        label: Text(
          'Status Pembayaran',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      const DataColumn(
        label: Text(
          'Status Pesanan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ];

    // Tambah column Aksi jika onDelete tidak null
    if (onDelete != null) {
      columns.add(
        const DataColumn(
          label: Text(
            'Aksi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return columns;
  }

  // METHOD BARU untuk build cells
  List<DataCell> _buildCells(
    Map<String, dynamic> p,
    DateFormat dateFormat,
    DateTime date,
  ) {
    final cells = <DataCell>[
      DataCell(Text('#${p['id']}')),
      DataCell(Text(dateFormat.format(date))),
      DataCell(Text(p['nomor_meja'] ?? '-')),
      DataCell(Text(p['pelanggan_nama'] ?? '-')),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: _getPaymentMethodColor(
              p['metode_pembayaran'],
            ).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            p['metode_pembayaran'] ?? '-',
            style: TextStyle(
              color: _getPaymentMethodColor(p['metode_pembayaran']),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
      DataCell(
        Text(
          p['diskon'] != null && p['diskon'] > 0
              ? 'Rp ${Helpers.formatCurrency(p['diskon'])}'
              : '-',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      DataCell(
        Text(
          'Rp ${Helpers.formatCurrency(p['total'])}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: _getStatusPembayaranColor(p['status_pembayaran'])
                .withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            p['status_pembayaran'] ?? '-',
            style: TextStyle(
              color: _getStatusPembayaranColor(p['status_pembayaran']),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: _getStatusPesananColor(p['status_pesanan']).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            p['status_pesanan'] ?? '-',
            style: TextStyle(
              color: _getStatusPesananColor(p['status_pesanan']),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    ];

    // Tambah cell Aksi jika onDelete tidak null
    if (onDelete != null) {
      cells.add(
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () => onDelete!(p['id']),
            tooltip: 'Hapus pesanan',
          ),
        ),
      );
    }

    return cells;
  }

  Color _getPaymentMethodColor(String? method) {
    switch (method) {
      case 'Cash':
        return Colors.green;
      case 'QRIS':
        return Colors.blue;
      case 'Transfer':
        return Colors.purple;
      case 'Kartu':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusPembayaranColor(String? status) {
    switch (status) {
      case 'Lunas':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Gagal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusPesananColor(String? status) {
    switch (status) {
      case 'Selesai':
        return Colors.green;
      case 'Menunggu':
        return Colors.grey;
      case 'Diproses':
        return Colors.blue;
      case 'Dikirim':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
