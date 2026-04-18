import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_provider.dart';
import '../../../theme/colors.dart';
import '../widgets/surveyor_household_actions.dart';
import '../add_family_page.dart';
import 'patient_list_view_model.dart';
import 'widgets/patient_list_widgets.dart';
import '../../../models/household_model.dart';

class PatientListPage extends StatelessWidget {
  final bool isEmbedded;
  const PatientListPage({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProxyProvider<AppProvider, PatientListViewModel>(
      create: (ctx) => PatientListViewModel()..load(ctx),
      update: (ctx, provider, viewModel) =>
          viewModel!..syncHouseholds(provider.households),
      child: _PatientListView(isEmbedded: isEmbedded),
    );
  }
}

class _PatientListView extends StatelessWidget {
  final bool isEmbedded;
  const _PatientListView({required this.isEmbedded});

  void _openDetails(BuildContext context, HouseholdModel h) {
    showSurveyorHouseholdDetails(context, h);
  }

  void _openAdd(BuildContext context, PatientListViewModel viewModel) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddFamilyPage()),
    );
    if (res == true && context.mounted) {
      viewModel.load(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PatientListViewModel>();
    final isLoading = context.watch<AppProvider>().isLoading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        body: RefreshIndicator(
          color: AppColors.govNavy,
          onRefresh: () => viewModel.refresh(context),
          child: CustomScrollView(
            slivers: [
              _buildAppBar(viewModel),
              SliverToBoxAdapter(
                child: _buildSearchTrigger(context, viewModel),
              ),
              SliverToBoxAdapter(
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.govNavy,
                          ),
                        ),
                      )
                    : _buildDrillContent(context, viewModel),
              ),
            ],
          ),
        ),
        floatingActionButton: isEmbedded
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _openAdd(context, viewModel),
                backgroundColor: AppColors.govNavy,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Yangi xatlov',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }

  // ─── APP BAR & BREADCRUMBS ───────────────────────────────────────────────
  Widget _buildAppBar(PatientListViewModel viewModel) {
    return PatientListAppBar(viewModel: viewModel);
  }

  // ─── SEARCH TRIGGER ──────────────────────────────────────────────────────
  Widget _buildSearchTrigger(
    BuildContext context,
    PatientListViewModel viewModel,
  ) {
    return PatientListSearchTrigger(viewModel: viewModel);
  }

  // ─── DRILL CONTENT ───────────────────────────────────────────────────────
  Widget _buildDrillContent(
    BuildContext context,
    PatientListViewModel viewModel,
  ) {
    return PatientListDrillContent(
      viewModel: viewModel,
      onOpenDetails: _openDetails,
      onShowBuildingSheet: _showBuildingSheet,
    );
  }

  // ─── BUILDING BOTTOM SHEET ────────────────────────────────────────
  void _showBuildingSheet(
    BuildContext context,
    List<HouseholdModel> apartments,
  ) {
    final floorsMap = <int, List<HouseholdModel>>{};
    for (final apt in apartments) {
      final f = apt.floor ?? 0;
      floorsMap.putIfAbsent(f, () => []).add(apt);
    }
    final sortedFloors = floorsMap.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF37474F), Color(0xFF263238)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.apartment,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${apartments.first.buildingNumber ?? "?"}–bino',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Jami ${apartments.length} ta xonadon ro\'yxatdan o\'tgan',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: sortedFloors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (ctx, i) {
                  final f = sortedFloors[i];
                  final apts = floorsMap[f]!
                    ..sort(
                      (a, b) => (int.tryParse(a.apartment ?? '0') ?? 0)
                          .compareTo(int.tryParse(b.apartment ?? '0') ?? 0),
                    );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          '$f–qavat',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.6,
                            ),
                        itemCount: apts.length,
                        itemBuilder: (_, j) {
                          final h = apts[j];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              showSurveyorHouseholdDetails(context, h);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${h.apartment}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.govNavy,
                                      ),
                                    ),
                                    const Text(
                                      'kvartira',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
