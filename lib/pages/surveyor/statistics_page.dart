import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/app_provider.dart';
import '../../theme/colors.dart';
import '../../models/household_model.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Statistika va Tahlil',
          style: TextStyle(color: AppColors.govNavy, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.govNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final households = provider.households;
          if (households.isEmpty && !provider.isLoading) {
            return _buildEmptyState();
          }
          if (provider.isLoading && households.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.govNavy));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryGrid(households),
                const SizedBox(height: 24),
                _buildSectionTitle('Mulk turi bo\'yicha'),
                _buildPropertyPieChart(households),
                const SizedBox(height: 24),
                _buildSectionTitle('Aholi jinsi bo\'yicha'),
                _buildGenderPieChart(households),
                const SizedBox(height: 24),
                _buildSectionTitle('Hududlar kesimida (TOP 5)'),
                _buildRegionBarChart(households),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.govNavy,
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(List<HouseholdModel> households) {
    int totalResidents = 0;
    for (var h in households) {
      totalResidents += h.residents.length;
    }

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Xonadonlar',
            households.length.toString(),
            Icons.home_work_rounded,
            AppColors.govNavy,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Aholi soni',
            totalResidents.toString(),
            Icons.people_alt_rounded,
            const Color(0xFF2E7D32),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyPieChart(List<HouseholdModel> households) {
    final houseCount = households.where((h) => h.propertyType == kHouse).length;
    final aptCount = households.where((h) => h.propertyType == kApartment).length;
    final total = households.length;

    if (total == 0) return const SizedBox();

    return _buildChartCard(
      height: 240,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: houseCount.toDouble(),
                    title: '${((houseCount / total) * 100).toStringAsFixed(0)}%',
                    color: AppColors.govNavy,
                    radius: 50,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  PieChartSectionData(
                    value: aptCount.toDouble(),
                    title: '${((aptCount / total) * 100).toStringAsFixed(0)}%',
                    color: Colors.orangeAccent,
                    radius: 50,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem('Hovli', houseCount, AppColors.govNavy),
                const SizedBox(height: 12),
                _buildLegendItem('Kvartira', aptCount, Colors.orangeAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderPieChart(List<HouseholdModel> households) {
    int male = 0;
    int female = 0;
    for (var h in households) {
      for (var r in h.residents) {
        if (r.gender == 'MALE') male++;
        if (r.gender == 'FEMALE') female++;
      }
    }
    final total = male + female;
    if (total == 0) return const SizedBox();

    return _buildChartCard(
      height: 240,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: male.toDouble(),
                    title: '${((male / total) * 100).toStringAsFixed(0)}%',
                    color: const Color(0xFF1976D2),
                    radius: 50,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  PieChartSectionData(
                    value: female.toDouble(),
                    title: '${((female / total) * 100).toStringAsFixed(0)}%',
                    color: const Color(0xFFE91E63),
                    radius: 50,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem('Erkak', male, const Color(0xFF1976D2)),
                const SizedBox(height: 12),
                _buildLegendItem('Ayol', female, const Color(0xFFE91E63)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionBarChart(List<HouseholdModel> households) {
    final Map<String, int> distribution = {};
    for (var h in households) {
      final key = h.mfyName ?? 'Noma\'lum';
      distribution[key] = (distribution[key] ?? 0) + 1;
    }

    final sortedEntries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final top5 = sortedEntries.take(5).toList();

    if (top5.isEmpty) return const SizedBox();

    return _buildChartCard(
      height: 300,
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: top5.isEmpty ? 10 : (top5.first.value * 1.2).toDouble(),
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index < 0 || index >= top5.length) return const SizedBox();
                    String label = top5[index].key;
                    if (label.length > 10) label = label.substring(0, 8) + '..';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: top5.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.value.toDouble(),
                    color: AppColors.govNavy,
                    width: 24,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: top5.first.value * 1.2,
                      color: const Color(0xFFF5F6F8),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String title, int count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 2),
          child: Text(
            '$count ta',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard({required Widget child, double height = 200}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Hali ma\'lumotlar mavjud emas',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
