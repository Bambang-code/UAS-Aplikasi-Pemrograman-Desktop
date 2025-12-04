// models/pesanan.dart 
import 'detail_pesanan.dart';

class Pesanan {
  final int? id;
  final int pelangganId;
  final String nomorMeja;
  final double subtotal;
  final double diskon;
  final double total;
  final String statusPembayaran; 
  final String statusPesanan; 
  final DateTime tanggal;
  final String? metodePembayaran;
  final String? buktiTransfer;
  final List<DetailPesanan>? details;
  final String? pelangganNama;


  Pesanan({
    this.id,
    required this.pelangganId,
    required this.nomorMeja,
    required this.subtotal,
    this.diskon = 0,
    required this.total,
    required this.statusPembayaran,
    required this.statusPesanan,
    required this.tanggal,
    this.metodePembayaran,
    this.buktiTransfer,
    this.details,
    this.pelangganNama,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pelanggan_id': pelangganId,
      'nomor_meja': nomorMeja,
      'subtotal': subtotal,
      'diskon': diskon,
      'total': total,
      'status_pembayaran': statusPembayaran,
      'status_pesanan': statusPesanan,
      'tanggal': tanggal.toIso8601String(),
      'metode_pembayaran': metodePembayaran,
      'bukti_transfer': buktiTransfer,
    };
  }

  factory Pesanan.fromMap(Map<String, dynamic> map) {
    return Pesanan(
      id: map['id'],
      pelangganId: map['pelanggan_id'],
      nomorMeja: map['nomor_meja'],
      subtotal: map['subtotal'],
      diskon: map['diskon'] ?? 0,
      total: map['total'],
      statusPembayaran: map['status_pembayaran'] ?? 'Pending',
      statusPesanan: map['status_pesanan'] ?? 'Menunggu',
      tanggal: DateTime.parse(map['tanggal']),
      metodePembayaran: map['metode_pembayaran'],
      buktiTransfer: map['bukti_transfer'],
      pelangganNama: map['pelanggan_nama'],
    );
  }
}
