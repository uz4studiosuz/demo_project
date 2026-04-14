import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/household_model.dart';
import '../../theme/colors.dart';
import '../../widgets/household_info_sheet.dart';
import 'surveyor_dashboard.dart';
import 'add_family_page.dart';
import 'surveyor_search_page.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  PATIENT LIST PAGE  — Xonadonlar ro'yxati
//  • Tuman, MFY filtrlari
//  • Xonadon / Kvartira farqi
//  • Pagination: 40 ta dan ko'rsatiladi
//  • Har bir kartochkada "Xaritada ko'rish" tugmasi
// ═══════════════════════════════════════════════════════════════════════════

class PatientListPage extends StatefulWidget {
  final bool isEmbedded;
  const PatientListPage({super.key, this.isEmbedded = false});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  String? _filterDistrict;
  String? _filterMfy;
  String? _filterType; // 'house', 'apartment', null
  bool _showFilters = false;

  int _pageSize = 40;
  int _currentPage = 1;

  @override
  void dispose() {
    super.dispose();
  }

  // ─── Filter helpers ───────────────────────────────────────────────
  List<String> _districts(List<HouseholdModel> all) {
    final s = <String>{};
    for (final h in all) {
      if (h.tumanName != null && h.tumanName!.isNotEmpty) s.add(h.tumanName!);
    }
    return s.toList()..sort();
  }

  List<String> _mfys(List<HouseholdModel> all) {
    final s = <String>{};
    for (final h in all) {
      if (_filterDistrict != null && h.tumanName != _filterDistrict) continue;
      if (h.mfyName != null && h.mfyName!.isNotEmpty) s.add(h.mfyName!);
    }
    return s.toList()..sort();
  }

  bool get _hasFilter =>
      _filterDistrict != null || _filterMfy != null || _filterType != null;

  void _applyFilter(void Function() fn) {
    setState(fn);
    _currentPage = 1;
  }

  void _clearAll() => setState(() {
    _filterDistrict = null;
    _filterMfy = null;
    _filterType = null;
    _currentPage = 1;
  });

  // ─── Filtered list ────────────────────────────────────────────────
  List<HouseholdModel> _getFiltered(List<HouseholdModel> all) {
    List<HouseholdModel> out = all.reversed.toList();
    if (_filterDistrict != null) {
      out = out.where((h) => h.tumanName == _filterDistrict).toList();
    }
    if (_filterMfy != null) {
      out = out.where((h) => h.mfyName == _filterMfy).toList();
    }
    if (_filterType == 'house') {
      out = out.where((h) => h.propertyType == kHouse).toList();
    } else if (_filterType == 'apartment') {
      out = out.where((h) => h.propertyType == kApartment).toList();
    }
    return out;
  }

  // ─────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final all = provider.households;
          final filtered = _getFiltered(all);
          final paginated = filtered.skip((_currentPage - 1) * _pageSize).take(_pageSize).toList();

          return Scaffold(
            backgroundColor: const Color(0xFFF5F6F8),
            body: Column(
              children: [
                _buildTopBar(context, all),
                AnimatedCrossFade(
                  firstChild: _buildFilterPanel(all),
                  secondChild: const SizedBox(width: double.infinity),
                  crossFadeState: _showFilters ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 250),
                ),
                if (_hasFilter) _buildActiveBadges(),
                _buildPaginationControls(filtered.length),
                Expanded(
                  child: provider.isLoading && all.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: AppColors.govNavy))
                      : filtered.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              color: AppColors.govNavy,
                              onRefresh: () async {
                                await provider.fetchHouseholds();
                                setState(() => _currentPage = 1);
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                                itemCount: paginated.length,
                                itemBuilder: (_, i) => _buildCard(context, paginated[i], provider),
                              ),
                            ),
                ),
              ],
            ),
            floatingActionButton: widget.isEmbedded
                ? null
                : FloatingActionButton.extended(
                    onPressed: () => _openAdd(context, provider),
                    backgroundColor: AppColors.govNavy,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Yangi xatlov',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
          );
        },
      ),
    );
  }

  // ─── PAGINATION ───────────────────────────────────────────────────
  Widget _buildPaginationControls(int totalFiltered) {
    final totalPages = totalFiltered == 0 ? 1 : (totalFiltered / _pageSize).ceil();
    if (totalPages <= 1) {
      final end = totalFiltered;
      return _buildCountBox(totalFiltered > 0 ? 1 : 0, end, totalFiltered);
    }
    final start = ((_currentPage - 1) * _pageSize) + 1;
    final end = (_currentPage * _pageSize).clamp(0, totalFiltered);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildCountBox(start, end, totalFiltered),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pageBtn(icon: Icons.arrow_back_ios_new_rounded, enabled: _currentPage > 1,
                    onTap: () => setState(() => _currentPage--)),
                const SizedBox(width: 8),
                ...List.generate(totalPages, (index) {
                  final p = index + 1;
                  if (totalPages > 7) {
                    if (p != 1 && p != totalPages && (p - _currentPage).abs() > 1) {
                      if (p == 2 || p == totalPages - 1) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('...', style: TextStyle(color: AppColors.textSecondary)),
                        );
                      }
                      return const SizedBox.shrink();
                    }
                  }
                  return _pageLabel(p);
                }).where((w) => w is! SizedBox),
                const SizedBox(width: 8),
                _pageBtn(icon: Icons.arrow_forward_ios_rounded, enabled: _currentPage < totalPages,
                    onTap: () => setState(() => _currentPage++)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageBtn({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF0F2F5) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: enabled ? AppColors.govNavy : Colors.grey.shade300),
      ),
    );
  }

  Widget _pageLabel(int p) {
    final active = p == _currentPage;
    return GestureDetector(
      onTap: () => setState(() => _currentPage = p),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 32, height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.govNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? AppColors.govNavy : Colors.transparent),
        ),
        child: Text('$p', style: TextStyle(fontSize: 13,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.white : AppColors.textMain)),
      ),
    );
  }

  Widget _buildCountBox(int start, int end, int total) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppColors.govNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Text('$start-$end / $total',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.govNavy)),
      ),
      const SizedBox(width: 8),
      Text(_hasFilter ? 'natija' : 'xonadon ko\'rsatilmoqda',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]);
  }

  // ─── TOP BAR ─────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, List<HouseholdModel> all) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: topPad + 8, left: 16, right: 16, bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              if (!widget.isEmbedded) ...[
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.govNavy, size: 20),
                ),
                const SizedBox(width: 8),
              ],
              const Expanded(
                child: Text('Xonadonlar ro\'yxati',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.govNavy)),
              ),
              GestureDetector(
                onTap: () => setState(() => _showFilters = !_showFilters),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _showFilters || _hasFilter ? AppColors.govNavy : const Color(0xFFF5F6F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.tune_rounded,
                          color: _showFilters || _hasFilter ? Colors.white : AppColors.govNavy, size: 20),
                      if (_hasFilter && !_showFilters)
                        Positioned(
                          top: 8, right: 8,
                          child: Container(width: 8, height: 8,
                              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => SurveyorSearchPage(households: all))),
            child: Container(
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFFF5F6F8), borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.govNavy, size: 20),
                  const SizedBox(width: 8),
                  Text('Ism, manzil, telefon...',
                      style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── FILTER PANEL ────────────────────────────────────────────────
  Widget _buildFilterPanel(List<HouseholdModel> all) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          _filterLabel('Tuman / Shahar'),
          const SizedBox(height: 6),
          _chipRow(
            items: _districts(all),
            selected: _filterDistrict,
            onSelect: (v) => _applyFilter(() {
              _filterDistrict = v == _filterDistrict ? null : v;
              _filterMfy = null;
            }),
          ),
          const SizedBox(height: 12),
          if (_filterDistrict != null) ...[
            _filterLabel('MFY'),
            const SizedBox(height: 6),
            _chipRow(
              items: _mfys(all),
              selected: _filterMfy,
              onSelect: (v) => _applyFilter(() => _filterMfy = v == _filterMfy ? null : v),
            ),
            const SizedBox(height: 12),
          ],
          _filterLabel('Mulk turi'),
          const SizedBox(height: 6),
          Row(
            children: [
              _typeChip('house', Icons.home_outlined, 'Xonadon'),
              const SizedBox(width: 8),
              _typeChip('apartment', Icons.apartment, 'Kvartira'),
            ],
          ),
          if (_hasFilter) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.filter_alt_off, size: 16),
              label: const Text('Filtrlarni tozalash'),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: AppColors.textSecondary, letterSpacing: 0.5));

  Widget _chipRow({
    required List<String> items,
    required String? selected,
    required void Function(String) onSelect,
  }) {
    if (items.isEmpty) {
      return const Text('Ma\'lumot yo\'q', style: TextStyle(fontSize: 12, color: AppColors.textSecondary));
    }
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final v = items[i];
          final active = v == selected;
          return GestureDetector(
            onTap: () => onSelect(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.govNavy : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(v, style: TextStyle(fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? Colors.white : AppColors.textMain)),
            ),
          );
        },
      ),
    );
  }

  Widget _typeChip(String type, IconData icon, String label) {
    final active = _filterType == type;
    return GestureDetector(
      onTap: () => _applyFilter(() => _filterType = _filterType == type ? null : type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.govNavy : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: active ? Colors.white : AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? Colors.white : AppColors.textMain)),
        ]),
      ),
    );
  }

  // ─── ACTIVE BADGES ───────────────────────────────────────────────
  Widget _buildActiveBadges() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          if (_filterDistrict != null)
            _badge(_filterDistrict!, () => _applyFilter(() {
              _filterDistrict = null;
              _filterMfy = null;
            })),
          if (_filterMfy != null)
            _badge(_filterMfy!, () => _applyFilter(() => _filterMfy = null)),
          if (_filterType != null)
            _badge(
              _filterType == 'house' ? 'Xonadon' : 'Kvartira',
              () => _applyFilter(() => _filterType = null),
            ),
        ],
      ),
    );
  }

  Widget _badge(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.govNavy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.govNavy.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.govNavy, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        GestureDetector(onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.govNavy)),
      ]),
    );
  }

  // ─── CARD ────────────────────────────────────────────────────────
  Widget _buildCard(BuildContext context, HouseholdModel h, AppProvider provider) {
    final isApartment = h.propertyType == kApartment;
    final title = isApartment
        ? '${h.buildingNumber ?? "?"}-bino, ${h.apartment ?? "?"}-kv'
        : (h.houseNumber != null && h.houseNumber!.isNotEmpty
            ? '${h.houseNumber}-uy'
            : h.officialAddress);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showHouseholdInfoSheet(context, h),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Ikon
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isApartment
                      ? const Color(0xFF37474F).withValues(alpha: 0.08)
                      : AppColors.govNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isApartment ? Icons.apartment : Icons.home_work_outlined,
                  color: isApartment ? const Color(0xFF37474F) : AppColors.govNavy,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Ma'lumotlar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMain),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(
                      [h.streetName, h.mfyName, h.tumanName]
                          .where((e) => e != null && e.isNotEmpty).join(' • '),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    if (isApartment && h.floor != null)
                      Text('${h.floor}-qavat',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Tugmalar
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.govNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                    child: Text('${h.residents.length} nafar',
                        style: const TextStyle(fontSize: 11, color: AppColors.govNavy, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 4),
                  // Xaritada ko'rish
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => HouseholdsMapPage(focusHousehold: h))),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.map_outlined, size: 12, color: Color(0xFF1976D2)),
                        SizedBox(width: 4),
                        Text('Xarita', style: TextStyle(fontSize: 11, color: Color(0xFF1976D2), fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Tahrirlash
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => AddFamilyPage(existing: h)));
                      if (result == true && context.mounted) provider.fetchHouseholds();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.govNavy, borderRadius: BorderRadius.circular(8)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.edit_outlined, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Tahrir', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Empty ───────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color: AppColors.govNavy.withValues(alpha: 0.06), shape: BoxShape.circle),
            child: Icon(Icons.search_off_rounded, size: 36,
                color: AppColors.govNavy.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          const Text('Hech narsa topilmadi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain)),
        ],
      ),
    );
  }

  Future<void> _openAdd(BuildContext context, AppProvider provider) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFamilyPage()));
    if (result == true && context.mounted) provider.fetchHouseholds();
  }
}
