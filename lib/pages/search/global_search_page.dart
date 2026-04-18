import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/household_model.dart';
import '../../models/resident_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/colors.dart';
import 'global_search_view_model.dart';

class GlobalSearchPage extends StatelessWidget {
  final List<HouseholdModel>? households;
  final String title;
  final String hintText;
  final IconData actionIcon;
  final Function(HouseholdModel, ResidentModel?) onActionTap;
  final Function(HouseholdModel) onResultTap;

  const GlobalSearchPage({
    super.key,
    this.households,
    this.title = 'Qidiruv',
    this.hintText = 'Ism, familiya, manzil, telefon...',
    required this.actionIcon,
    required this.onActionTap,
    required this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProxyProvider<AppProvider, GlobalSearchViewModel>(
      create: (ctx) => GlobalSearchViewModel()
        ..init(households ?? ctx.read<AppProvider>().households),
      update: (ctx, prov, viewMod) =>
          viewMod!..updateHouseholds(prov.households),
      child: _GlobalSearchView(
        title: title,
        hintText: hintText,
        actionIcon: actionIcon,
        onActionTap: onActionTap,
        onResultTap: onResultTap,
      ),
    );
  }
}

class _GlobalSearchView extends StatefulWidget {
  final String title;
  final String hintText;
  final IconData actionIcon;
  final Function(HouseholdModel, ResidentModel?) onActionTap;
  final Function(HouseholdModel) onResultTap;

  const _GlobalSearchView({
    required this.title,
    required this.hintText,
    required this.actionIcon,
    required this.onActionTap,
    required this.onResultTap,
  });

  @override
  State<_GlobalSearchView> createState() => _GlobalSearchViewState();
}

class _GlobalSearchViewState extends State<_GlobalSearchView> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GlobalSearchViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Column(
        children: [
          _buildTopBar(viewModel),
          AnimatedCrossFade(
            firstChild: _buildFilterPanel(viewModel),
            secondChild: const SizedBox(width: double.infinity),
            crossFadeState: viewModel.showFilters
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),
          if (viewModel.hasFilter) _buildActiveFilters(viewModel),
          Expanded(child: _buildBody(viewModel)),
        ],
      ),
    );
  }

  Widget _buildTopBar(GlobalSearchViewModel viewModel) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.govNavy,
              size: 20,
            ),
          ),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                onChanged: viewModel.onChanged,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  prefixIcon: viewModel.isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.govNavy,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.search,
                          color: AppColors.govNavy,
                          size: 20,
                        ),
                  suffixIcon: viewModel.rawQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            _ctrl.clear();
                            viewModel.onChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: viewModel.toggleFilters,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: viewModel.showFilters || viewModel.hasFilter
                    ? AppColors.govNavy
                    : const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: viewModel.showFilters || viewModel.hasFilter
                        ? Colors.white
                        : AppColors.govNavy,
                    size: 20,
                  ),
                  if (viewModel.hasFilter && !viewModel.showFilters)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(GlobalSearchViewModel viewModel) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          _fLabel('Tuman / Shahar'),
          const SizedBox(height: 6),
          _chipRow(
            items: viewModel.districts,
            selected: viewModel.filterDistrict,
            onSelect: viewModel.setFilterDistrict,
          ),
          if (viewModel.filterDistrict != null) ...[
            const SizedBox(height: 12),
            _fLabel('MFY'),
            const SizedBox(height: 6),
            _chipRow(
              items: viewModel.mfys,
              selected: viewModel.filterMfy,
              onSelect: viewModel.setFilterMfy,
            ),
          ],
          const SizedBox(height: 12),
          _fLabel('Mulk turi'),
          const SizedBox(height: 6),
          Row(
            children: [
              _typeChip('house', Icons.home_outlined, 'Xonadon', viewModel),
              const SizedBox(width: 8),
              _typeChip('apartment', Icons.apartment, 'Kvartira', viewModel),
            ],
          ),
          const SizedBox(height: 12),
          _fLabel('Jinsi'),
          const SizedBox(height: 6),
          Row(
            children: [
              _genderChip('MALE', Icons.man_rounded, 'Erkak', viewModel),
              const SizedBox(width: 8),
              _genderChip('FEMALE', Icons.woman_rounded, 'Ayol', viewModel),
            ],
          ),
          if (viewModel.hasFilter) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: viewModel.clearFilters,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Filtrlarni tozalash'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.danger,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fLabel(String t) => Text(
        t,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      );

  Widget _chipRow({
    required List<String> items,
    required String? selected,
    required void Function(String) onSelect,
  }) {
    if (items.isEmpty) {
      return const Text(
        '—',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      );
    }
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final v = items[i];
          final active = v == selected;
          return GestureDetector(
            onTap: () => onSelect(v),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.govNavy : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                v,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? Colors.white : AppColors.textMain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _typeChip(
      String type, IconData icon, String label, GlobalSearchViewModel viewModel) {
    final active = viewModel.filterType == type;
    return GestureDetector(
      onTap: () => viewModel.setFilterType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.govNavy : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? Colors.white : AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderChip(String gender, IconData icon, String label,
      GlobalSearchViewModel viewModel) {
    final active = viewModel.filterGender == gender;
    return GestureDetector(
      onTap: () => viewModel.setFilterGender(gender),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.govNavy : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: active ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    color: active ? Colors.white : AppColors.textMain)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters(GlobalSearchViewModel viewModel) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          if (viewModel.filterDistrict != null)
            _badge(
              viewModel.filterDistrict!,
              () => viewModel.setFilterDistrict(viewModel.filterDistrict!),
            ),
          if (viewModel.filterMfy != null)
            _badge(
              viewModel.filterMfy!,
              () => viewModel.setFilterMfy(viewModel.filterMfy!),
            ),
          if (viewModel.filterType != null)
            _badge(
              viewModel.filterType == 'house' ? 'Xonadon' : 'Kvartira',
              () => viewModel.setFilterType(viewModel.filterType!),
            ),
          if (viewModel.filterGender != null)
            _badge(
              viewModel.filterGender == 'MALE' ? 'Erkak' : 'Ayol',
              () => viewModel.setFilterGender(viewModel.filterGender!),
            ),
        ],
      ),
    );
  }

  Widget _badge(String label, void Function() onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.govNavy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.govNavy.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.govNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.govNavy),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(GlobalSearchViewModel viewModel) {
    if (viewModel.isIdle) return _buildIdleState(viewModel);
    if (viewModel.rawQuery.trim().length == 1 && !viewModel.hasFilter) {
      return _emptyState(
        Icons.keyboard_outlined,
        'Davom eting...',
        'Kamida $kMinSearchLength belgi kiriting',
      );
    }
    if (viewModel.isSearching && viewModel.results.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.govNavy),
      );
    }
    if (viewModel.results.isEmpty) {
      return _emptyState(
        Icons.search_off_rounded,
        'Natija topilmadi',
        'Boshqa kalit so\'z yoki filtr sinab ko\'ring',
      );
    }

    final isCapped = viewModel.results.length >= kMaxSearchResults;
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.govNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCapped
                      ? '${viewModel.results.length}+ natija'
                      : '${viewModel.results.length} natija',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.govNavy,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCapped ? '— aniqroq yozing' : '— topildi',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isCapped)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'To\'liq ism yoki tuman filtri bilan aniqroq natija',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: viewModel.results.length,
            itemBuilder: (_, i) =>
                _buildResultCard(viewModel.results[i], viewModel),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(SearchResult res, GlobalSearchViewModel viewModel) {
    final h = res.household;
    final r = res.resident;
    final q = viewModel.activeQuery;
    final isApartment = h.propertyType == 'apartment';

    final titleText = r != null
        ? r.displayFullName
        : isApartment
            ? '${h.buildingNumber ?? "?"}-bino, ${h.apartment ?? "?"}-kv'
            : (h.houseNumber != null && h.houseNumber!.isNotEmpty
                ? '${h.houseNumber}-uy'
                : h.officialAddress);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onResultTap(h),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: r == null
                        ? [const Color(0xFF1A3A5C), const Color(0xFF0D2137)]
                        : r.gender == 'FEMALE'
                            ? [const Color(0xFF8E44AD), const Color(0xFFB65FC7)]
                            : [AppColors.govNavy, const Color(0xFF2D5A8E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  r == null
                      ? (isApartment ? Icons.apartment : Icons.home_work_rounded)
                      : (r.gender == 'FEMALE'
                          ? Icons.woman_rounded
                          : Icons.man_rounded),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _highlight(titleText, q, bold: true),
                    const SizedBox(height: 3),
                    if (r != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.home_outlined,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _highlight(
                              h.officialAddress,
                              q,
                              size: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        h.tumanName,
                        h.mfyName,
                      ].where((e) => e != null && e.isNotEmpty).join(' › '),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (r?.phonePrimary != null && r!.phonePrimary!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _highlight(
                        r.phonePrimary!,
                        q,
                        color: AppColors.govNavy,
                        size: 11,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => widget.onActionTap(h, r),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.govNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.actionIcon,
                    size: 18,
                    color: AppColors.govNavy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _highlight(
    String text,
    String query, {
    bool bold = false,
    double size = 13,
    Color color = AppColors.textMain,
  }) {
    if (query.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontSize: size,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lower = text.toLowerCase();
    final qLower = query.toLowerCase();
    final List<TextSpan> spans = [];
    int start = 0;
    int idx;

    while ((idx = lower.indexOf(qLower, start)) != -1) {
      if (idx > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, idx),
            style: TextStyle(
              fontSize: size,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.bold,
            color: AppColors.govNavy,
            backgroundColor: AppColors.govNavy.withValues(alpha: 0.1),
          ),
        ),
      );
      start = idx + query.length;
    }
    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: TextStyle(
            fontSize: size,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      );
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }

  Widget _buildIdleState(GlobalSearchViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3A5C), Color(0xFF2D6A9F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ma\'lumotlar bazasi',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${viewModel.totalHouseholds} xonadon',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${viewModel.totalResidents} nafar aholi',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Qidiruv bo\'yicha maslahatlar',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          _tip(
            Icons.person_outline_rounded,
            'Ism yoki familiya',
            'Misol: "Karimov" yoki "Aziza"',
          ),
          _tip(Icons.phone_outlined, 'Telefon raqam', 'Misol: "998901234"'),
          _tip(
            Icons.home_outlined,
            'Manzil yoki uy raqami',
            'Misol: "Mustaqillik 45"',
          ),
          _tip(
            Icons.apartment,
            'Bino yoki kvartira',
            'Misol: "3-bino" yoki "12-kv"',
          ),
          _tip(Icons.tune_rounded, 'Aniqroq natija', 'Filtrlardan foydalaning'),
          const SizedBox(height: 24),
          const Text(
            'Tezkor filtrlar',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: viewModel.districts
                .take(6)
                .map(
                  (d) => GestureDetector(
                    onTap: () => viewModel.setFilterDistrict(d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.govNavy,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            d,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _tip(IconData icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.govNavy.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.govNavy),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String msg, String sub) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            msg,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
