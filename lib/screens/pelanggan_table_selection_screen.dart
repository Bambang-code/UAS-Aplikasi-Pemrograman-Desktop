// screens/pelanggan_table_selection_screen.dart - UPDATED WITH TAKEAWAY
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/user.dart';
import '../models/meja.dart';
import '../services/db_helper.dart';
import 'pelanggan_menu_screen.dart';

class PelangganTableSelectionScreen extends StatefulWidget {
  final User user;

  const PelangganTableSelectionScreen({super.key, required this.user});

  @override
  State<PelangganTableSelectionScreen> createState() =>
      _PelangganTableSelectionScreenState();
}

class _PelangganTableSelectionScreenState
    extends State<PelangganTableSelectionScreen> {
  List<Meja> _mejas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMejas();
    // Auto refresh setiap 5 detik
    Future.delayed(const Duration(seconds: 5), _autoRefresh);
  }

  void _autoRefresh() {
    if (mounted) {
      _loadMejas();
      Future.delayed(const Duration(seconds: 5), _autoRefresh);
    }
  }

  Future<void> _loadMejas() async {
    setState(() => _isLoading = true);
    try {
      final data = await DBHelper().query('meja');
      setState(() {
        _mejas = data.map((m) => Meja.fromMap(m)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // TAMBAH METHOD INI - Untuk Takeaway
  void _goToTakeaway() {
    // Buat meja dummy untuk takeaway
    final takeawayMeja = Meja(
      id: -1,
      nomorMeja: 'Takeaway',
      status: 'Kosong',
      qrCode: 'TAKEAWAY',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PelangganMenuWithTableScreen(
          user: widget.user,
          selectedMeja: takeawayMeja,
        ),
      ),
    ).then((_) => _loadMejas());
  }

  void _showQRCodeDialog(Meja meja) {
    final qrData = meja.qrCode ?? 'TABLE_${meja.id}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.qr_code_2, color: Colors.brown[700]),
            const SizedBox(width: 8),
            Text('QR Code ${meja.nomorMeja}'),
          ],
        ),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${meja.nomorMeja} tersedia',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kode: $qrData',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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
                    Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Meja ini akan otomatis terisi setelah Anda melakukan pesanan',
                        style: TextStyle(
                          fontSize: 11,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PelangganMenuWithTableScreen(
                    user: widget.user,
                    selectedMeja: meja,
                  ),
                ),
              ).then((_) => _loadMejas());
            },
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Lanjut ke Menu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[700],
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kosong = _mejas.where((m) => m.status == 'Kosong').length;
    final terisi = _mejas.where((m) => m.status == 'Terisi').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Opsi Pesanan'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMejas,
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
                      Icon(Icons.person, color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat Datang, ${widget.user.username}!',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Pilih dine-in atau takeaway',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // TAMBAH TOMBOL TAKEAWAY INI
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _goToTakeaway,
                    icon: const Icon(Icons.shopping_bag, size: 32),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Text(
                            'TAKEAWAY',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pesan untuk dibawa pulang',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Atau pilih meja untuk Dine-in:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Meja Tersedia',
                        kosong,
                        Colors.green,
                        Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Meja Terisi',
                        terisi,
                        Colors.orange,
                        Icons.event_seat,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Total Meja',
                        _mejas.length,
                        Colors.blue,
                        Icons.table_restaurant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      
          // Meja Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _mejas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.table_restaurant,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada meja tersedia',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gunakan opsi Takeaway di atas',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          childAspectRatio: 1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _mejas.length,
                        itemBuilder: (context, index) {
                          final meja = _mejas[index];
                          return _buildMejaCard(meja);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
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

  Widget _buildMejaCard(Meja meja) {
    final isKosong = meja.status == 'Kosong';
    final color = isKosong ? Colors.green : Colors.grey;

    return Card(
      elevation: isKosong ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isKosong ? color : Colors.grey[400]!,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: isKosong ? () => _showQRCodeDialog(meja) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isKosong ? Colors.green[50] : Colors.grey[200],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.table_restaurant,
                size: 64,
                color: isKosong ? color : Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                meja.nomorMeja,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isKosong ? Colors.black87 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  meja.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (isKosong) ...[
                const SizedBox(height: 8),
                Text(
                  'Tap untuk pilih',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
