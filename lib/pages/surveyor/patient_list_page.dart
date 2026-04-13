import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/household_model.dart';
import '../../theme/colors.dart';
import '../../widgets/household_info_sheet.dart';
import 'add_family_page.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  PATIENT LIST PAGE  — Driver stili bilan birxil professional ro'yxat
//  • Tuman, MFY, ko'cha filtrlari
//  • Debounce qidiruv
//  • Government UI
// ═══════════════════════════════════════════════════════════════════════════

class PatientListPage extends StatefulWidget {
  final bool isEmbedded;
  const PatientListPage({super.key, this.isEmbedded = false});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();

  // Debounce
  Timer? _debounce;
  String _rawQuery  = '';
  String _lastQuery = '';

  // Filters
  String? _filterDistrict;
  String? _filterMfy;
  String? _filterType; // 'multi', 'single', null

  bool _showFilters = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ─── Debounce input ──────────────────────────────────────────────
  void _onChanged(String v) {
    setState(() => _rawQuery = v);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (mounted) setState(() => _lastQuery = v.trim().toLowerCase());
    });
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
  }

  void _clearAll() => setState(() {
        _filterDistrict = null;
        _filterMfy = null;
        _filterType = null;
      });

  // ─── Filtered list ────────────────────────────────────────────────
  List<HouseholdModel> _filtered(List<HouseholdModel> all) {
    List<HouseholdModel> out = all.reversed.toList();

    if (_filterDistrict != null) {
      out = out.where((h) => h.tumanName == _filterDistrict).toList();
    }
    if (_filterMfy != null) {
      out = out.where((h) => h.mfyName == _filterMfy).toList();
    }
    if (_filterType == 'multi') {
      out = out.where((h) => h.residents.length > 1).toList();
    } else if (_filterType == 'single') {
      out = out.where((h) => h.residents.isEmpty).toList();
    }

    if (_lastQuery.isNotEmpty) {
      out = out.where((h) {
        final addressMatch = h.officialAddress
            .toLowerCase()
            .contains(_lastQuery);
        final streetMatch =
            (h.streetName ?? '').toLowerCase().contains(_lastQuery);
        final houseMatch =
            (h.houseNumber ?? '').toLowerCase().contains(_lastQuery);
        final residentMatch = h.residents.any((r) =>
            r.displayFullName.toLowerCase().contains(_lastQuery) ||
            (r.phonePrimary ?? '').contains(_lastQuery));
        return addressMatch || streetMatch || houseMatch || residentMatch;
      }).toList();
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
          final filtered = _filtered(all);

          return Scaffold(
            backgroundColor: const Color(0xFFF5F6F8),
            body: Column(
              children: [
                // ─── TOP BAR ────────────────────────────────────────
                _buildTopBar(context, all),

                // ─── FILTER PANEL ───────────────────────────────────
                AnimatedCrossFade(
                  firstChild: _buildFilterPanel(all),
                  secondChild: const SizedBox(width: double.infinity),
                  crossFadeState: _showFilters
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 250),
                ),

                // ─── ACTIVE FILTER BADGES ───────────────────────────
                if (_hasFilter) _buildActiveBadges(),

                // ─── RESULT COUNT ───────────────────────────────────
                _buildCountBar(filtered.length, all.length),

                // ─── LIST ───────────────────────────────────────────
                Expanded(
                  child: provider.isLoading && all.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.govNavy))
                      : filtered.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              color: AppColors.govNavy,
                              onRefresh: () => provider.fetchHouseholds(),
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 120),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) => _buildCard(
                                    context, filtered[i], provider),
                              ),
                            ),
                ),
              ],
            ),
            // ─── FAB ─────────────────────────────────────────────────
            floatingActionButton: widget.isEmbedded
                ? null
                : FloatingActionButton.extended(
                    onPressed: () => _openAdd(context, provider),
                    backgroundColor: AppColors.govNavy,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Yangi xatlov',
                        style:
                            TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
          );
        },
      ),
    );
  }

  // ─── TOP BAR ─────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, List<HouseholdModel> all) {
    final topPad = widget.isEmbedded
        ? MediaQuery.of(context).padding.top
        : MediaQuery.of(context).padding.top;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
          top: topPad + 8, left: 8, right: 16, bottom: 12),
      child: Row(
        children: [
          if (!widget.isEmbedded)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.govNavy, size: 20),
            ),
          if (widget.isEmbedded) const SizedBox(width: 16),

          // Title or search field
          Expanded(
            child: widget.isEmbedded && _rawQuery.isEmpty
                ? Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Xonadonlar ro\'yxati',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.govNavy),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {});
                          _focus.requestFocus();
                        },
                        child: Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6F8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.search,
                              color: AppColors.govNavy, size: 20),
                        ),
                      ),
                    ],
                  )
                : Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      onChanged: _onChanged,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ism, manzil, telefon...',
                        hintStyle: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.govNavy, size: 20),
                        suffixIcon: _rawQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close,
                                    size: 18,
                                    color: AppColors.textSecondary),
                                onPressed: () {
                                  _ctrl.clear();
                                  _onChanged('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
          ),

          const SizedBox(width: 8),

          // Filter toggle
          GestureDetector(
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: (_showFilters || _hasFilter)
                    ? AppColors.govNavy
                    : const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.tune_rounded,
                      color: (_showFilters || _hasFilter)
                          ? Colors.white
                          : AppColors.govNavy,
                      size: 20),
                  if (_hasFilter && !_showFilters)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Add (when not embedded)
          if (!widget.isEmbedded) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _openAdd(
                  context, Provider.of<AppProvider>(context, listen: false)),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.govNavy,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ],
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

          // Tumanlar
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

          // MFY (faqat tuman tanlanganda)
          if (_filterDistrict != null) ...[
            _filterLabel('MFY'),
            const SizedBox(height: 6),
            _chipRow(
              items: _mfys(all),
              selected: _filterMfy,
              onSelect: (v) => _applyFilter(
                  () => _filterMfy = v == _filterMfy ? null : v),
            ),
            const SizedBox(height: 12),
          ],

          // Xonadon turi
          _filterLabel('Xonadon turi'),
          const SizedBox(height: 6),
          Row(
            children: [
              _typeChip('multi',  Icons.group_rounded,    'Ko\'p a\'zoli'),
              const SizedBox(width: 8),
              _typeChip('single', Icons.home_outlined,    'Bo\'sh'),
            ],
          ),

          if (_hasFilter) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.filter_alt_off, size: 16),
              label: const Text('Filtrlarni tozalash'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.danger,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5));

  Widget _chipRow({
    required List<String> items,
    required String? selected,
    required void Function(String) onSelect,
  }) {
    if (items.isEmpty) {
      return const Text('Ma\'lumot yo\'q',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary));
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
                border: Border.all(
                    color: active ? AppColors.govNavy : Colors.transparent),
              ),
              child: Text(v,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
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
      onTap: () => _applyFilter(
          () => _filterType = _filterType == type ? null : type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.govNavy : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15,
                color: active ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500,
                    color:
                        active ? Colors.white : AppColors.textMain)),
          ],
        ),
      ),
    );
  }

  // ─── ACTIVE BADGES ───────────────────────────────────────────────
  Widget _buildActiveBadges() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Wrap(spacing: 6, runSpacing: 4, children: [
        if (_filterDistrict != null)
          _badge(_filterDistrict!, () => _applyFilter(() {
                _filterDistrict = null;
                _filterMfy = null;
              })),
        if (_filterMfy != null)
          _badge(_filterMfy!, () => _applyFilter(() => _filterMfy = null)),
        if (_filterType != null)
          _badge(
            _filterType == 'multi' ? 'Ko\'p a\'zoli' : 'Bo\'sh',
            () => _applyFilter(() => _filterType = null),
          ),
      ]),
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
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.govNavy,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close, size: 14, color: AppColors.govNavy),
        ),
      ]),
    );
  }

  // ─── COUNT BAR ───────────────────────────────────────────────────
  Widget _buildCountBar(int filtered, int total) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.govNavy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$filtered xonadon',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.govNavy),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _hasFilter || _lastQuery.isNotEmpty
              ? '/ jami $total'
              : 'ro\'yxatda',
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
      ]),
    );
  }

  // ─── CARD ────────────────────────────────────────────────────────
  Widget _buildCard(
      BuildContext context, HouseholdModel h, AppProvider provider) {
    final houseNum = h.houseNumber != null && h.houseNumber!.isNotEmpty
        ? '${h.houseNumber}-uy'
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showHouseholdInfoSheet(context, h),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.govNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.home_work_outlined,
                    color: AppColors.govNavy, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Highlight
                    _highlight(
                        houseNum ?? h.officialAddress, _lastQuery,
                        bold: true),
                    const SizedBox(height: 3),
                    _highlight(
                      [h.streetName, h.mfyName, h.tumanName]
                          .where((e) => e != null && e.isNotEmpty)
                          .join(' • '),
                      _lastQuery,
                      color: AppColors.textSecondary,
                      size: 11,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.govNavy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${h.residents.length} nafar',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.govNavy,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddFamilyPage()),
                      );
                      if (result == true && context.mounted) {
                        provider.fetchHouseholds();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.govNavy,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Tahrir',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
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

  // ─── Highlight ───────────────────────────────────────────────────
  Widget _highlight(
    String text,
    String query, {
    bool bold = false,
    Color color = AppColors.textMain,
    double size = 14,
  }) {
    final base = TextStyle(
        fontSize: size,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: color);

    if (query.isEmpty) {
      return Text(text, style: base, maxLines: 1,
          overflow: TextOverflow.ellipsis);
    }
    final lower = text.toLowerCase();
    final idx = lower.indexOf(query);
    if (idx == -1) {
      return Text(text, style: base, maxLines: 1,
          overflow: TextOverflow.ellipsis);
    }
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: base, children: [
        TextSpan(text: text.substring(0, idx)),
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: TextStyle(
              backgroundColor: AppColors.govNavy.withValues(alpha: 0.15),
              color: AppColors.govNavy,
              fontWeight: FontWeight.w800),
        ),
        TextSpan(text: text.substring(idx + query.length)),
      ]),
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
              color: AppColors.govNavy.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, size: 36,
                color: AppColors.govNavy.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          const Text('Hech narsa topilmadi',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain)),
          const SizedBox(height: 6),
          const Text('Filtr yoki qidiruv so\'zini o\'zgartiring',
              style:
                  TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ─── Add page ────────────────────────────────────────────────────
  Future<void> _openAdd(BuildContext context, AppProvider provider) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddFamilyPage()),
    );
    if (result == true && context.mounted) {
      provider.fetchHouseholds();
    }
  }
}
