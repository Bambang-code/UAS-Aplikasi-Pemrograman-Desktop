// models/meja.dart - UPDATED
class Meja {
  final int? id;
  final String nomorMeja;
  final String status;
  final String? qrCode; // Token unik untuk QR code

  Meja({
    this.id,
    required this.nomorMeja,
    required this.status,
    this.qrCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nomor_meja': nomorMeja,
      'status': status,
      'qr_code': qrCode,
    };
  }

  factory Meja.fromMap(Map<String, dynamic> map) {
    return Meja(
      id: map['id'],
      nomorMeja: map['nomor_meja'],
      status: map['status'],
      qrCode: map['qr_code'],
    );
  }

  // Generate URL untuk pelanggan
  String getOrderUrl() {
    return 'cafe://order?table=${qrCode ?? id}';
  }
}
