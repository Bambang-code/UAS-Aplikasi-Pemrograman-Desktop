// screens/dashboard_screen.dart - IMPROVED UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/pesanan_service.dart';
import '../main.dart';
import '../widgets/dashboard_charts.dart';
import 'menu_screen.dart';
import 'order_screen.dart';
import 'report_screen.dart';
import 'meja_screen.dart';
import 'login_screen.dart';
import 'pelanggan_menu_screen.dart';
import 'pelanggan_history_screen.dart';
import 'pelanggan_table_selection_screen.dart';
import 'kasir_pesanan_screen.dart';
import 'user_screen.dart';

class DashboardScreen extends StatefulWidget {
  final User user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _loadStats();
    if (widget.user.role == 'admin') {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await PesananService().getDashboardStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Widget> get _pages {
    if (widget.user.role == 'pelanggan') {
      return [
        PelangganTableSelectionScreen(user: widget.user),
        PelangganHistoryScreen(user: widget.user),
      ];
    } else if (widget.user.role == 'kasir') {
      return [
        KasirPesananScreen(user: widget.user),
        OrderScreen(user: widget.user),
        MejaScreen(user: widget.user),
      ];
    } else {
      return [
        _buildAdminHome(),
        MenuScreen(user: widget.user),
        MejaScreen(user: widget.user),
        UserScreen(currentUser: widget.user),
        ReportScreen(user: widget.user),
      ];
    }
  }

  Widget _buildAdminHome() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.brown[700],
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.brown[700],
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.dashboard_outlined, size: 24),
                text: 'Overview',
              ),
              Tab(
                icon: Icon(Icons.bar_chart_rounded, size: 24),
                text: 'Grafik Analisis',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildHome(),
              const DashboardCharts(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHome() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card with Gradient
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.brown[700]!, Colors.brown[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown[300]!.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.waving_hand,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Datang, ${widget.user.username}!',
                        style: const TextStyle(
                          fontSize: 26,
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
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.user.role.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Stats Cards Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.4,
            children: [
              _buildModernStatCard(
                'Total Pesanan Hari Ini',
                '${_stats?['today_transactions'] ?? 0}',
                Icons.receipt_long_rounded,
                Colors.blue,
                [Colors.blue[400]!, Colors.blue[600]!],
              ),
              _buildModernStatCard(
                'Pendapatan Hari Ini',
                'Rp ${_formatNumber(_stats?['today_revenue'] ?? 0)}',
                Icons.attach_money_rounded,
                Colors.green,
                [Colors.green[400]!, Colors.green[600]!],
              ),
              _buildModernStatCard(
                'Total Menu',
                '${_stats?['total_menu'] ?? 0}',
                Icons.restaurant_menu_rounded,
                Colors.orange,
                [Colors.orange[400]!, Colors.orange[600]!],
              ),
              _buildModernStatCard(
                'Meja Terisi',
                '${_stats?['occupied_tables'] ?? 0} / ${_stats?['total_tables'] ?? 0}',
                Icons.table_restaurant_rounded,
                Colors.purple,
                [Colors.purple[400]!, Colors.purple[600]!],
              ),
            ],
          ),
          const SizedBox(height: 32),

          if (widget.user.role == 'admin') ...[
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildModernQuickActionCard(
                    'Kelola Menu',
                    'Tambah, edit, atau hapus menu',
                    Icons.restaurant_rounded,
                    [Colors.brown[400]!, Colors.brown[700]!],
                    () => setState(() => _selectedIndex = 1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildModernQuickActionCard(
                    'Laporan Penjualan',
                    'Lihat statistik dan laporan',
                    Icons.bar_chart_rounded,
                    [Colors.indigo[400]!, Colors.indigo[700]!],
                    () => setState(() => _selectedIndex = 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildModernQuickActionCard(
                    'Kelola Meja',
                    'Lihat status meja',
                    Icons.table_bar_rounded,
                    [Colors.deepOrange[400]!, Colors.deepOrange[700]!],
                    () => setState(() => _selectedIndex = 2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildModernQuickActionCard(
                    'Kelola User',
                    'Manajemen akun user',
                    Icons.people_rounded,
                    [Colors.purple[400]!, Colors.purple[700]!],
                    () => setState(() => _selectedIndex = 3),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    List<Color> gradientColors,
  ) {
    return Card(
      elevation: 8,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradientColors[0].withOpacity(0.1),
                gradientColors[1].withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[1].withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.brown[700],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.coffee, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Cafe Management System',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: themeProvider.toggleTheme,
            tooltip: 'Toggle Dark Mode',
          ),
          if (widget.user.role != 'pelanggan')
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadStats,
              tooltip: 'Refresh',
            ),
          const SizedBox(width: 8),
          PopupMenuButton<int>(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            offset: const Offset(0, 50),
            icon: CircleAvatar(
              backgroundColor: Colors.brown[700],
              child: Text(
                widget.user.username[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            itemBuilder: (context) => <PopupMenuEntry<int>>[
              PopupMenuItem<int>(
                value: 0,
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.brown[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.user.role.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.brown[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<int>(
                value: 1,
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          if (widget.user.role != 'pelanggan') _buildModernNavigationRail(),
          if (widget.user.role == 'pelanggan') _buildPelangganNavigationRail(),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildModernNavigationRail() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: NavigationRail(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        labelType: NavigationRailLabelType.all,
        backgroundColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: Colors.brown[700], size: 28),
        unselectedIconTheme: IconThemeData(color: Colors.grey[400], size: 24),
        selectedLabelTextStyle: TextStyle(
          color: Colors.brown[700],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
        destinations: widget.user.role == 'kasir'
            ? const [
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: Text('Pesanan'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.restaurant_menu_outlined),
                  selectedIcon: Icon(Icons.restaurant_menu_rounded),
                  label: Text('Menu'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.table_restaurant_outlined),
                  selectedIcon: Icon(Icons.table_restaurant_rounded),
                  label: Text('Meja'),
                ),
              ]
            : const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.restaurant_menu_outlined),
                  selectedIcon: Icon(Icons.restaurant_menu_rounded),
                  label: Text('Menu'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.table_restaurant_outlined),
                  selectedIcon: Icon(Icons.table_restaurant_rounded),
                  label: Text('Meja'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people_rounded),
                  label: Text('User'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart_rounded),
                  label: Text('Laporan'),
                ),
              ],
      ),
    );
  }

  Widget _buildPelangganNavigationRail() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.brown[50],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: NavigationRail(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        labelType: NavigationRailLabelType.all,
        backgroundColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: Colors.brown[700], size: 28),
        unselectedIconTheme: IconThemeData(color: Colors.grey[400], size: 24),
        selectedLabelTextStyle: TextStyle(
          color: Colors.brown[700],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.table_restaurant_outlined),
            selectedIcon: Icon(Icons.table_restaurant_rounded),
            label: Text('Pilih Meja'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: Text('Riwayat'),
          ),
        ],
      ),
    );
  }
}
