// widgets/dashboard_charts.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/pesanan_service.dart';
import '../utils/helpers.dart';

class DashboardCharts extends StatefulWidget {
  const DashboardCharts({super.key});

  @override
  State<DashboardCharts> createState() => _DashboardChartsState();
}

class _DashboardChartsState extends State<DashboardCharts> {
  final PesananService _pesananService = PesananService();
  bool _isLoading = true;

  List<Map<String, dynamic>> _dailySales = [];
  List<Map<String, dynamic>> _categoryData = [];
  List<Map<String, dynamic>> _topMenu = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  Map<String, dynamic>? _weeklyComparison;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() => _isLoading = true);
    try {
      final dailySales = await _pesananService.getDailySalesChart();
      final categoryData = await _pesananService.getSalesByCategory();
      final topMenu = await _pesananService.getTopSellingMenu(limit: 10);
      final paymentMethods = await _pesananService.getSalesByPaymentMethod();
      final weeklyComparison = await _pesananService.getWeeklyComparison();

      setState(() {
        _dailySales = dailySales;
        _categoryData = categoryData;
        _topMenu = topMenu;
        _paymentMethods = paymentMethods;
        _weeklyComparison = weeklyComparison;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading chart data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan Weekly Comparison
          _buildWeeklyComparisonCard(),
          const SizedBox(height: 24),

          // Row 1: Daily Sales & Category Pie Chart
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildDailySalesChart(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCategoryPieChart(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Row 2: Top Selling Menu & Payment Methods
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTopSellingMenu(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPaymentMethodsChart(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WEEKLY COMPARISON CARD
  // ==========================================
  Widget _buildWeeklyComparisonCard() {
    if (_weeklyComparison == null) return const SizedBox();

    final thisWeek = _weeklyComparison!['this_week'] as Map<String, dynamic>;
    final lastWeek = _weeklyComparison!['last_week'] as Map<String, dynamic>;
    final growth = _weeklyComparison!['growth_percentage'] as double;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.brown[700]!, Colors.brown[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performa Minggu Ini',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildWeeklyMetric(
                        'Pendapatan',
                        'Rp ${Helpers.formatCurrency(thisWeek['revenue'])}',
                        'Minggu lalu: Rp ${Helpers.formatCurrency(lastWeek['revenue'])}',
                      ),
                      const SizedBox(width: 32),
                      _buildWeeklyMetric(
                        'Pesanan',
                        '${thisWeek['total_orders']}',
                        'Minggu lalu: ${lastWeek['total_orders']}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    growth >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 48,
                    color: growth >= 0 ? Colors.greenAccent : Colors.redAccent,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color:
                          growth >= 0 ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                  const Text(
                    'Growth',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyMetric(String label, String value, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 10, color: Colors.white60),
        ),
      ],
    );
  }

  // ==========================================
  // DAILY SALES LINE CHART
  // ==========================================
  Widget _buildDailySalesChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Penjualan 7 Hari Terakhir',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: _dailySales.isEmpty
                  ? const Center(child: Text('Tidak ada data'))
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 &&
                                    value.toInt() < _dailySales.length) {
                                  final date = DateTime.parse(
                                    _dailySales[value.toInt()]['date'],
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      DateFormat('E').format(date),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  Helpers.formatCurrency(value),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _dailySales
                                .asMap()
                                .entries
                                .map((e) => FlSpot(
                                      e.key.toDouble(),
                                      (e.value['revenue'] as num).toDouble(),
                                    ))
                                .toList(),
                            isCurved: true,
                            color: Colors.brown[700],
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.brown[700]!.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CATEGORY PIE CHART
  // ==========================================
  Widget _buildCategoryPieChart() {
    final total = _categoryData.fold<double>(
      0,
      (sum, item) => sum + (item['revenue'] as num).toDouble(),
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Penjualan per Kategori',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: _categoryData.isEmpty
                  ? const Center(child: Text('Tidak ada data'))
                  : PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
                        sections: _categoryData.map((item) {
                          final revenue = (item['revenue'] as num).toDouble();
                          final percentage = (revenue / total) * 100;
                          return PieChartSectionData(
                            value: revenue,
                            title: '${percentage.toStringAsFixed(1)}%',
                            color: _getCategoryColor(item['kategori']),
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            ..._categoryData.map((item) {
              final revenue = (item['revenue'] as num).toDouble();
              final percentage = (revenue / total) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(item['kategori']),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['kategori'],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      'Rp ${Helpers.formatCurrency(revenue)} (${percentage.toStringAsFixed(0)}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'minuman':
        return Colors.blue;
      case 'makanan':
        return Colors.orange;
      case 'snack':
        return Colors.green;
      case 'dessert':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // ==========================================
  // TOP SELLING MENU BAR CHART
  // ==========================================
  Widget _buildTopSellingMenu() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 10 Menu Terlaris',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: _topMenu.isEmpty
                  ? const Center(child: Text('Tidak ada data'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: _topMenu.asMap().entries.map((e) {
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: (e.value['total_quantity'] as num)
                                    .toDouble(),
                                color: Colors.brown[700],
                                width: 16,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 &&
                                    value.toInt() < _topMenu.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      _topMenu[value.toInt()]['nama']
                                          .toString()
                                          .substring(
                                              0,
                                              _topMenu[value.toInt()]['nama']
                                                          .toString()
                                                          .length >
                                                      8
                                                  ? 8
                                                  : _topMenu[value.toInt()]
                                                          ['nama']
                                                      .toString()
                                                      .length),
                                      style: const TextStyle(fontSize: 9),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PAYMENT METHODS PIE CHART
  // ==========================================
  Widget _buildPaymentMethodsChart() {
    final totalOrders = _paymentMethods.fold<int>(
      0,
      (sum, item) => sum + (item['total_orders'] as int),
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metode Pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: _paymentMethods.isEmpty
                  ? const Center(child: Text('Tidak ada data'))
                  : PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 50,
                        sections: _paymentMethods.map((item) {
                          final orders = (item['total_orders'] as int);
                          final percentage = (orders / totalOrders) * 100;
                          return PieChartSectionData(
                            value: orders.toDouble(),
                            title: '${percentage.toStringAsFixed(0)}%',
                            color: _getPaymentColor(item['metode_pembayaran']),
                            radius: 45,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            ..._paymentMethods.map((item) {
              final orders = item['total_orders'] as int;
              final revenue = (item['revenue'] as num).toDouble();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getPaymentColor(item['metode_pembayaran']),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['metode_pembayaran'],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '$orders order',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getPaymentColor(String method) {
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
}
