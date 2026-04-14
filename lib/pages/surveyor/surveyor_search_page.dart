import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/household_model.dart';
import '../../models/resident_model.dart';
import '../../theme/colors.dart';
import '../../widgets/household_info_sheet.dart';
import '../../providers/app_provider.dart';
import 'add_family_page.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  SURVEYOR SEARCH PAGE  — Smart qidiruv
//  • Resident darajasida qidiruv (isim, telefon)
//  • Manzil darajasida qidiruv (ko'cha, uy, MFY, tuman)
//  • 300ms debounce
//  • Highlight: qidiruv so'zi natijalarda belgilanadi
//  • Idle: statistika va maslahatlar
// ═══════════════════════════════════════════════════════════════════════════

const int _kMin = 2;
const int _kMax = 60;

/// Bitta qidiruv natijasi
class _SResult {
  final HouseholdModel household;
  final ResidentModel? resident; // null → uy raqami/manzil bo'yicha topildi
  _SResult({required this.household, this.resident});
}

class SurveyorSearchPage extends StatefulWidget {
  final List<HouseholdModel> households;
  const SurveyorSearchPage({super.key, required this.households});

  @override
  State<SurveyorSearchPage> createState() => _SurveyorSearchPageState();
}

class _SurveyorSearchPageState extends State<SurveyorSearchPage> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();

  Timer? _debounce;
  String _rawQuery = '';
  String _activeQuery = '';

  String? _filterDistrict;
  String? _filterMfy;
  String? _filterType; // 'house' | 'apartment' | null
  bool _showFilters = false;

  List<_SResult> _results = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ─── Search logic ─────────────────────────────────────────────────
  void _onChanged(String raw) {
    setState(() => _rawQuery = raw);
    _debounce?.cancel();
    final trimmed = raw.trim();

    if (trimmed.length < _kMin && !_hasFilter) {
      setState(() { _activeQuery = ''; _results = []; _isSearching = false; });
      return;
    }

    if (trimmed.length < _kMin && _hasFilter) {
      _debounce = Timer(const Duration(milliseconds: 150), () => _runSearch(''));
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(trimmed));
  }

  void _runSearch(String query) {
    final lower = query.toLowerCase();
    final out = <_SResult>[];

    for (final h in widget.households) {
      if (out.length >= _kMax) break;
      if (_filterDistrict != null && h.tumanName != _filterDistrict) continue;
      if (_filterMfy != null && h.mfyName != _filterMfy) continue;
      if (_filterType == 'house' && h.propertyType != kHouse) continue;
      if (_filterType == 'apartment' && h.propertyType != kApartment) continue;

      if (lower.isEmpty) {
        // Faqat filtr rejimi
        for (final r in h.residents) {
          if (out.length >= _kMax) break;
          out.add(_SResult(household: h, resident: r));
        }
        if (h.residents.isEmpty) out.add(_SResult(household: h));
        continue;
      }

      // Manzil bo'yicha moslik
      final addrMatch =
          h.officialAddress.toLowerCase().contains(lower) ||
          (h.tumanName  ?? '').toLowerCase().contains(lower) ||
          (h.mfyName    ?? '').toLowerCase().contains(lower) ||
          (h.streetName ?? '').toLowerCase().contains(lower) ||
          (h.houseNumber ?? '').contains(lower) ||
          (h.buildingNumber ?? '').contains(lower);

      // Resident bo'yicha moslik
      bool anyResidentAdded = false;
      for (final r in h.residents) {
        if (out.length >= _kMax) break;
        final resMatch =
            r.displayFullName.toLowerCase().contains(lower) ||
            (r.phonePrimary ?? '').contains(lower);
        if (resMatch || addrMatch) {
          out.add(_SResult(household: h, resident: r));
          anyResidentAdded = true;
        }
      }
      // Agar resident topilmasa lekin manzil mos bo'lsa — uy kartochkasi
      if (!anyResidentAdded && addrMatch) {
        out.add(_SResult(household: h));
      }
    }

    if (mounted) {
      setState(() {
        _activeQuery = query;
        _results = out;
        _isSearching = false;
      });
    }
  }

  // ─── Filter helpers ───────────────────────────────────────────────
  List<String> get _districts {
    final s = <String>{};
    for (final h in widget.households) {
      if (h.tumanName != null && h.tumanName!.isNotEmpty) s.add(h.tumanName!);
    }
    return s.toList()..sort();
  }

  List<String> get _mfys {
    final s = <String>{};
    for (final h in widget.households) {
      if (_filterDistrict != null && h.tumanName != _filterDistrict) continue;
      if (h.mfyName != null && h.mfyName!.isNotEmpty) s.add(h.mfyName!);
    }
    return s.toList()..sort();
  }

  bool get _hasFilter =>
      _filterDistrict != null || _filterMfy != null || _filterType != null;

  bool get _isIdle => _rawQuery.trim().length < _kMin && !_hasFilter;

  void _applyFilter(void Function() fn) {
    setState(fn);
    _onChanged(_rawQuery);
  }

  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Column(
        children: [
          _buildTopBar(context),
          AnimatedCrossFade(
            firstChild: _buildFilterPanel(),
            secondChild: const SizedBox(width: double.infinity),
            crossFadeState: _showFilters ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),
          if (_hasFilter) _buildActiveFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ─── Top bar ─────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8, right: 16, bottom: 12,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.govNavy, size: 20),
          ),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFFF5F6F8), borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                onChanged: _onChanged,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ism, familiya, manzil, telefon...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  prefixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.govNavy)))
                      : const Icon(Icons.search, color: AppColors.govNavy, size: 20),
                  suffixIcon: _rawQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                          onPressed: () { _ctrl.clear(); _onChanged(''); })
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _showFilters || _hasFilter ? AppColors.govNavy : const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(alignment: Alignment.center, children: [
                Icon(Icons.tune_rounded,
                    color: _showFilters || _hasFilter ? Colors.white : AppColors.govNavy, size: 20),
                if (_hasFilter && !_showFilters)
                  Positioned(top: 8, right: 8,
                      child: Container(width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle))),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter panel ─────────────────────────────────────────────────
  Widget _buildFilterPanel() {
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
          _chipRow(items: _districts, selected: _filterDistrict, onSelect: (v) => _applyFilter(() {
            _filterDistrict = v == _filterDistrict ? null : v;
            _filterMfy = null;
          })),
          if (_filterDistrict != null) ...[
            const SizedBox(height: 12),
            _fLabel('MFY'),
            const SizedBox(height: 6),
            _chipRow(items: _mfys, selected: _filterMfy,
                onSelect: (v) => _applyFilter(() => _filterMfy = v == _filterMfy ? null : v)),
          ],
          const SizedBox(height: 12),
          _fLabel('Mulk turi'),
          const SizedBox(height: 6),
          Row(children: [
            _typeChip('house', Icons.home_outlined, 'Xonadon'),
            const SizedBox(width: 8),
            _typeChip('apartment', Icons.apartment, 'Kvartira'),
          ]),
          if (_hasFilter) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _applyFilter(() {
                _filterDistrict = null; _filterMfy = null; _filterType = null;
              }),
              icon: const Icon(Icons.filter_alt_off, size: 16),
              label: const Text('Filtrlarni tozalash'),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fLabel(String t) => Text(t,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: AppColors.textSecondary, letterSpacing: 0.5));

  Widget _chipRow({required List<String> items, required String? selected, required void Function(String) onSelect}) {
    if (items.isEmpty) return const Text('—', style: TextStyle(color: AppColors.textSecondary, fontSize: 12));
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
          Icon(icon, size: 14, color: active ? Colors.white : AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? Colors.white : AppColors.textMain)),
        ]),
      ),
    );
  }

  // ─── Active badge row ──────────────────────────────────────────────
  Widget _buildActiveFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Wrap(spacing: 6, runSpacing: 4, children: [
        if (_filterDistrict != null) _badge(_filterDistrict!, () => _applyFilter(() { _filterDistrict = null; _filterMfy = null; })),
        if (_filterMfy != null) _badge(_filterMfy!, () => _applyFilter(() => _filterMfy = null)),
        if (_filterType != null) _badge(_filterType == 'house' ? 'Xonadon' : 'Kvartira', () => _applyFilter(() => _filterType = null)),
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
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.govNavy, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        GestureDetector(onTap: onRemove, child: const Icon(Icons.close, size: 14, color: AppColors.govNavy)),
      ]),
    );
  }

  // ─── Body ────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isIdle) return _buildIdleState();
    if (_rawQuery.trim().length == 1 && !_hasFilter) {
      return _emptyState(Icons.keyboard_outlined, 'Davom eting...', 'Kamida 2 belgi kiriting');
    }
    if (_isSearching && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.govNavy));
    }
    if (_results.isEmpty) {
      return _emptyState(Icons.search_off_rounded, 'Natija topilmadi', 'Boshqa kalit so\'z yoki filtr sinab ko\'ring');
    }

    final isCapped = _results.length >= _kMax;
    return Column(
      children: [
        // Natija soni
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppColors.govNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(
                isCapped ? '${_results.length}+ natija' : '${_results.length} natija',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.govNavy),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(
                isCapped ? '— aniqroq yozing' : '— topildi',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          ]),
        ),
        if (isCapped)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              Expanded(child: Text('To\'liq ism yoki tuman filtri bilan aniqroq natija',
                  style: TextStyle(fontSize: 11, color: Colors.amber.shade800))),
            ]),
          ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: _results.length,
            itemBuilder: (_, i) => _buildResultCard(_results[i]),
          ),
        ),
      ],
    );
  }

  // ─── Result card ──────────────────────────────────────────────────
  Widget _buildResultCard(_SResult sr) {
    final h = sr.household;
    final r = sr.resident;
    final q = _activeQuery.toLowerCase();
    final isApartment = h.propertyType == kApartment;

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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showHouseholdInfoSheet(context, h),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: r == null
                        ? [const Color(0xFF1A3A5C), const Color(0xFF0D2137)]
                        : r.gender == 'FEMALE'
                            ? [const Color(0xFF8E44AD), const Color(0xFFB65FC7)]
                            : [AppColors.govNavy, const Color(0xFF2D5A8E)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  r == null
                      ? (isApartment ? Icons.apartment : Icons.home_work_rounded)
                      : (r.gender == 'FEMALE' ? Icons.woman_rounded : Icons.man_rounded),
                  color: Colors.white, size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Ma'lumot
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _highlight(titleText, q, bold: true),
                    const SizedBox(height: 3),
                    // Resident bo'lsa — uyga havola
                    if (r != null)
                      Row(children: [
                        const Icon(Icons.home_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(child: _highlight(
                          h.officialAddress, q,
                          size: 11, color: AppColors.textSecondary,
                        )),
                      ]),
                    const SizedBox(height: 2),
                    Text(
                      [h.tumanName, h.mfyName].where((e) => e != null && e.isNotEmpty).join(' › '),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    if (r?.phonePrimary != null && r!.phonePrimary!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _highlight(r.phonePrimary!, q, color: AppColors.govNavy, size: 11),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Tahrirlash
              GestureDetector(
                onTap: () async {
                  final provider = Provider.of<AppProvider>(context, listen: false);
                  final nav = Navigator.of(context);
                  final result = await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AddFamilyPage(existing: h)));
                  if (result == true) {
                    provider.fetchHouseholds();
                    nav.pop();
                  }
                },
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: AppColors.govNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.govNavy),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Text highlight ───────────────────────────────────────────────
  Widget _highlight(String text, String query, {
    bool bold = false, double size = 13, Color color = AppColors.textMain,
  }) {
    if (query.isEmpty) {
      return Text(text,
          style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color),
          maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final lower = text.toLowerCase();
    final qLower = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int idx;

    while ((idx = lower.indexOf(qLower, start)) != -1) {
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx),
            style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: AppColors.govNavy,
          backgroundColor: AppColors.govNavy.withValues(alpha: 0.1),
        ),
      ));
      start = idx + query.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start),
          style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color)));
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }

  // ─── Idle state ───────────────────────────────────────────────────
  Widget _buildIdleState() {
    final totalH = widget.households.length;
    final totalR = widget.households.fold<int>(0, (s, h) => s + h.residents.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1A3A5C), Color(0xFF2D6A9F)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Ma\'lumotlar bazasi',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text('$totalH xonadon',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text('$totalR nafar aholi',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ])),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 28),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          const Text('Qidiruv bo\'yicha maslahatlar',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain)),
          const SizedBox(height: 12),
          _tip(Icons.person_outline_rounded, 'Ism yoki familiya', 'Misol: "Karimov" yoki "Aziza"'),
          _tip(Icons.phone_outlined, 'Telefon raqam', 'Misol: "998901234"'),
          _tip(Icons.home_outlined, 'Manzil yoki uy raqami', 'Misol: "Mustaqillik 45"'),
          _tip(Icons.apartment, 'Bino yoki kvartira', 'Misol: "3-bino" yoki "12-kv"'),
          _tip(Icons.tune_rounded, 'Tuman filtri', 'Aniqroq natija uchun'),
          const SizedBox(height: 24),
          const Text('Tezkor filtrlar',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _districts.take(6).map((d) => GestureDetector(
              onTap: () => setState(() { _filterDistrict = d; _filterMfy = null; _showFilters = false; _onChanged(_rawQuery); }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.govNavy),
                  const SizedBox(width: 6),
                  Text(d, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMain)),
                ]),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _tip(IconData icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              color: AppColors.govNavy.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: AppColors.govNavy),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain)),
          Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]),
      ]),
    );
  }

  Widget _emptyState(IconData icon, String msg, String sub) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 4),
        Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
    );
  }
}
