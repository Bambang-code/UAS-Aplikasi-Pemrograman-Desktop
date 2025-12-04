// models/menu.dart
class Menu {
  final int? id;
  final String nama;
  final String kategori;
  final double harga;
  final int stok;
  final String? foto;

  Menu({
    this.id,
    required this.nama,
    required this.kategori,
    required this.harga,
    required this.stok,
    this.foto,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'kategori': kategori,
      'harga': harga,
      'stok': stok,
      'foto': foto,
    };
  }

  factory Menu.fromMap(Map<String, dynamic> map) {
    return Menu(
      id: map['id'],
      nama: map['nama'],
      kategori: map['kategori'],
      harga: map['harga'].toDouble(),
      stok: map['stok'],
      foto: map['foto'],
    );
  }
}
