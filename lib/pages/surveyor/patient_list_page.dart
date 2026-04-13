import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/household_model.dart';
import '../../theme/colors.dart';
import 'widgets/household_card.dart';

class PatientListPage extends StatefulWidget {
  final bool isEmbedded;
  const PatientListPage({super.key, this.isEmbedded = false});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  final _searchController = TextEditingController();
  String _filterType = 'all'; // all, multi_resident
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    // Filtering logic
    List<HouseholdModel> households = provider.households.reversed.toList();

    if (_searchQuery.isNotEmpty) {
      households = households.where((h) {
        final addressMatch = h.officialAddress.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
        final residentMatch = h.residents.any(
          (r) => r.displayFullName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        );
        return addressMatch || residentMatch;
      }).toList();
    }

    if (_filterType == 'multi_resident') {
      households = households.where((h) => h.residents.length > 2).toList();
    }

    // Clear grouped data as we're switching back to a flat list
    // Map<String, Map<String, List<HouseholdModel>>> groupedData = {};
    // if (_searchQuery.isEmpty) {
    //   ...
    // }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('Barcha Xonadonlar'),
              backgroundColor: AppColors.surface,
            ),
      body: SafeArea(
        child: Column(
          children: [
            // iOS Style Search and Filter
            Container(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Minimalist Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CupertinoSearchTextField(
                      controller: _searchController,
                      placeholder: 'Qidirish...',
                      backgroundColor: Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Professional Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        _buildFilterChip('Hammasi', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Ko\'p a\'zoli', 'multi_resident'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: provider.isLoading && households.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : households.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => provider.fetchHouseholds(),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          top: 12,
                          left: 20,
                          right: 20,
                          bottom: 120,
                        ),
                        itemCount: households.length,
                        itemBuilder: (context, index) {
                          return HouseholdCard(
                            household: households[index],
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.grey.withValues(alpha: 0.1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMain,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Hech narsa topilmadi',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
