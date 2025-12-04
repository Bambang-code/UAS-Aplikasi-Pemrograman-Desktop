// models/detail_pesanan.dart - NEW
class DetailPesanan {
  final int? id;
  final int pesananId;
  final int menuId;
  final int jumlah;
  final double subtotal;
  final String? namaMenu;
  final double? hargaSatuan;

  DetailPesanan({
    this.id,
    required this.pesananId,
    required this.menuId,
    required this.jumlah,
    required this.subtotal,
    this.namaMenu,
    this.hargaSatuan,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pesanan_id': pesananId,
      'menu_id': menuId,
      'jumlah': jumlah,
      'subtotal': subtotal,
    };
  }

  factory DetailPesanan.fromMap(Map<String, dynamic> map) {
    return DetailPesanan(
      id: map['id'],
      pesananId: map['pesanan_id'],
      menuId: map['menu_id'],
      jumlah: map['jumlah'],
      subtotal: map['subtotal'],
      namaMenu: map['nama_menu'],
      hargaSatuan: map['harga_satuan'],
    );
  }
}
