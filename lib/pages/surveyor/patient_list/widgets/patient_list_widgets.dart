import 'package:beemor/pages/surveyor/add_family_page.dart';
import 'package:flutter/material.dart';
import '../../../../models/household_model.dart';
import '../../../../theme/colors.dart';
import '../../../../widgets/household_info_sheet.dart';
import '../../../../providers/app_provider.dart';
import '../../../search/global_search_page.dart';
import '../patient_list_view_model.dart';
import 'package:provider/provider.dart';

class PatientListAppBar extends StatelessWidget {
  final PatientListViewModel viewModel;

  const PatientListAppBar({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFFF5F6F8),
      elevation: 0,
      pinned: true,
      title: const Text(
        'Xonadonlar',
        style: TextStyle(
          color: AppColors.govNavy,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              if (viewModel.level != DrillLevel.district)
                IconButton(
                  onPressed: viewModel.goBack,
                  icon: const Icon(Icons.arrow_back, color: AppColors.govNavy),
                ),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildBreadcrumbItem(
                      'Hududlar',
                      DrillLevel.district,
                      viewModel.level == DrillLevel.district,
                      viewModel,
                    ),
                    if (viewModel.level.index >= DrillLevel.mfy.index &&
                        viewModel.selDistrict != null)
                      _buildBreadcrumbItem(
                        viewModel.selDistrict!,
                        DrillLevel.mfy,
                        viewModel.level == DrillLevel.mfy,
                        viewModel,
                      ),
                    if (viewModel.level.index >= DrillLevel.street.index &&
                        viewModel.selMfy != null)
                      _buildBreadcrumbItem(
                        viewModel.selMfy!,
                        DrillLevel.street,
                        viewModel.level == DrillLevel.street,
                        viewModel,
                      ),
                    if (viewModel.level.index >= DrillLevel.household.index &&
                        viewModel.selStreet != null)
                      _buildBreadcrumbItem(
                        viewModel.selStreet!,
                        DrillLevel.household,
                        viewModel.level == DrillLevel.household,
                        viewModel,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbItem(
    String label,
    DrillLevel lvl,
    bool isActive,
    PatientListViewModel viewModel,
  ) {
    return GestureDetector(
      onTap: () => viewModel.setLevel(lvl),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.govNavy
                  : AppColors.govNavy.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.govNavy,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          if (lvl != DrillLevel.household && isActive == false)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class PatientListSearchTrigger extends StatelessWidget {
  final PatientListViewModel viewModel;

  const PatientListSearchTrigger({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GlobalSearchPage(
              households: viewModel.allHouseholds,
              actionIcon: Icons.edit_outlined,
              onActionTap: (h, r) async {
                final provider = Provider.of<AppProvider>(
                  context,
                  listen: false,
                );
                final nav = Navigator.of(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddFamilyPage(existing: h)),
                );
                if (result == true) {
                  provider.fetchHouseholds();
                  nav.pop();
                }
              },
              onResultTap: (h) => showHouseholdInfoSheet(context, h),
            ),
          ),
        ),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.govNavy, size: 20),
              const SizedBox(width: 12),
              Text(
                'Ism, familiya, manzil orqali...',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PatientListDrillContent extends StatelessWidget {
  final PatientListViewModel viewModel;
  final void Function(BuildContext, HouseholdModel) onOpenDetails;
  final void Function(BuildContext, List<HouseholdModel>) onShowBuildingSheet;

  const PatientListDrillContent({
    super.key,
    required this.viewModel,
    required this.onOpenDetails,
    required this.onShowBuildingSheet,
  });

  @override
  Widget build(BuildContext context) {
    switch (viewModel.level) {
      case DrillLevel.district:
        return _buildGrid(
          title: 'Tumanlar va shaharlar',
          items: viewModel.districts,
          icon: Icons.location_city_rounded,
          onTap: viewModel.selectDistrict,
          viewModel: viewModel,
        );
      case DrillLevel.mfy:
        final mfys = viewModel.mfys;
        if (mfys.isEmpty) return _buildEmpty();
        return _buildGrid(
          title: '${viewModel.selDistrict} — MFYlar',
          items: mfys,
          icon: Icons.maps_home_work_rounded,
          onTap: viewModel.selectMfy,
          viewModel: viewModel,
        );
      case DrillLevel.street:
        final streets = viewModel.streets;
        if (streets.isEmpty) return _buildEmpty();
        return _buildGrid(
          title: '${viewModel.selMfy} — Ko\'chalar',
          items: streets,
          icon: Icons.signpost_rounded,
          onTap: viewModel.selectStreet,
          viewModel: viewModel,
        );
      case DrillLevel.household:
        final grouped = viewModel.groupedObjectsInStreet;
        if (grouped.isEmpty) return _buildEmpty();
        return _buildHouseholdGrid(
          title: '${viewModel.selStreet} — Binolar',
          items: grouped,
          onTap: (item) {
            if (item.isBuilding) {
              onShowBuildingSheet(context, item.apartments!);
            } else {
              onOpenDetails(context, item.house!);
            }
          },
        );
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.govNavy.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 36,
              color: AppColors.govNavy.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Hech narsa topilmadi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid({
    required String title,
    required List<String> items,
    required IconData icon,
    required void Function(String) onTap,
    required PatientListViewModel viewModel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.govNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${items.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.govNavy,
                  ),
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) =>
              _buildGridItem(items[i], icon, onTap, viewModel),
        ),
      ],
    );
  }

  Widget _buildGridItem(
    String label,
    IconData icon,
    void Function(String) onTap,
    PatientListViewModel viewModel,
  ) {
    int count = viewModel.countFor(label);

    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.govNavy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.govNavy, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  count > 0 ? '$count ta xonadon' : 'Ochish →',
                  style: TextStyle(
                    fontSize: 10,
                    color: count > 0
                        ? AppColors.textSecondary
                        : AppColors.govNavy,
                    fontWeight: count > 0 ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseholdGrid({
    required String title,
    required List<HouseOrBuilding> items,
    required void Function(HouseOrBuilding) onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.govNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${items.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.govNavy,
                  ),
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _buildHouseholdItem(items[i], onTap),
        ),
      ],
    );
  }

  Widget _buildHouseholdItem(
    HouseOrBuilding item,
    void Function(HouseOrBuilding) onTap,
  ) {
    return GestureDetector(
      onTap: () => onTap(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.govNavy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.isBuilding ? Icons.apartment : Icons.home_work_outlined,
                color: AppColors.govNavy,
                size: 20,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.isBuilding
                      ? '${item.apartments!.length} ta kvartira'
                      : 'ID: ${item.house!.id}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
