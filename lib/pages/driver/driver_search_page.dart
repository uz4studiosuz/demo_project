import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/household_model.dart';
import '../../models/resident_model.dart';
import '../../theme/colors.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  DRIVER SEARCH PAGE  — Smart qidiruv sahifasi
//  • Bo'sh qatorga hammasini ko'rsatmaydi
//  • Kamida 2 belgi: izlash boshlanadi
//  • 300ms debounce — har harfda qayta hisoblashdan saqlanadi
//  • Natijalar maksimal 50 ta (tezlik uchun)
//  • Filtr tanlanganida natijalar chiqadi (matn bo'lmasa ham)
// ═══════════════════════════════════════════════════════════════════════════

const int _kMinQueryLength = 2;   // kamida shu uzunlikdagi so'rov bo'lishi kerak
const int _kMaxResults     = 50;  // ko'p natija UI lagiga sabab bo'ladi

class DriverSearchPage extends StatefulWidget {
  final List<HouseholdModel> households;
  final void Function(HouseholdModel h, ResidentModel? r) onNavigate;
  final void Function(HouseholdModel h) onOpenDetail;

  const DriverSearchPage({
    super.key,
    required this.households,
    required this.onNavigate,
    required this.onOpenDetail,
  });

  @override
  State<DriverSearchPage> createState() => _DriverSearchPageState();
}

class _DriverSearchPageState extends State<DriverSearchPage> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();

  // Debounce
  Timer? _debounce;
  String _debouncedQuery = ''; // so'nggi ishlatilgan query
  String _rawQuery = '';       // real-time input (hint uchun)

  // Filters
  String? _filterDistrict;
  String? _filterMfy;
  String? _filterGender; // 'MALE' | 'FEMALE' | null

  bool _showFilters = false;

  // Computed results cache (setState orqali yangilanadi)
  List<_Match> _results = [];
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

  // ─────────────────────────────────────────────────────────────────
  //  SEARCH LOGIC
  // ─────────────────────────────────────────────────────────────────

  void _onQueryChanged(String raw) {
    setState(() => _rawQuery = raw);

    _debounce?.cancel();

    // Filter only mode — matn bo'lmasa ham filtr bo'lsa darhol yangilash
    if (raw.trim().length < _kMinQueryLength) {
      if (_hasActiveFilter) {
        // Filtr bor — matn yo'q: filtered list ko'rsatish kerak, debounce oz
        _debounce = Timer(const Duration(milliseconds: 150), () {
          _runSearch('');
        });
      } else {
        // Hech narsa yo'q — idle
        setState(() {
          _debouncedQuery = '';
          _results = [];
          _isSearching = false;
        });
      }
      return;
    }

    // 2+ belgi: debounce 300ms
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(raw.trim());
    });
  }

  void _runSearch(String query) {
    final lower = query.toLowerCase();
    final List<_Match> out = [];

    for (final h in widget.households) {
      if (out.length >= _kMaxResults) break;

      // ─ Filtr chiplar ─
      if (_filterDistrict != null && h.tumanName != _filterDistrict) continue;
      if (_filterMfy      != null && h.mfyName    != _filterMfy)      continue;

      if (lower.isEmpty) {
        // Faqat filtr bilan ishlayapti — matn yo'q
        for (final r in h.residents) {
          if (out.length >= _kMaxResults) break;
          if (_filterGender != null && r.gender != _filterGender) continue;
          out.add(_Match(resident: r, household: h));
        }
        if (h.residents.isEmpty) {
          out.add(_Match(resident: null, household: h));
        }
        continue;
      }

      // ─ Matn qidiruv ─
      final addrMatch =
          h.officialAddress.toLowerCase().contains(lower) ||
          (h.tumanName  ?? '').toLowerCase().contains(lower) ||
          (h.mfyName    ?? '').toLowerCase().contains(lower) ||
          (h.streetName ?? '').toLowerCase().contains(lower) ||
          (h.houseNumber ?? '').contains(lower);

      bool hhAdded = false;
      for (final r in h.residents) {
        if (out.length >= _kMaxResults) break;
        if (_filterGender != null && r.gender != _filterGender) continue;

        final resMatch =
            r.displayFullName.toLowerCase().contains(lower) ||
            (r.phonePrimary ?? '').contains(lower)          ||
            (r.role         ?? '').toLowerCase().contains(lower);

        if (resMatch || addrMatch) {
          out.add(_Match(resident: r, household: h));
          hhAdded = true;
        }
      }
      if (!hhAdded && addrMatch && h.residents.isEmpty) {
        out.add(_Match(resident: null, household: h));
      }
    }

    if (mounted) {
      setState(() {
        _debouncedQuery = query;
        _results        = out;
        _isSearching    = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  FILTER HELPERS
  // ─────────────────────────────────────────────────────────────────

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

  bool get _hasActiveFilter =>
      _filterDistrict != null || _filterMfy != null || _filterGender != null;

  void _applyFilter(void Function() change) {
    setState(change);
    // Filtr o'zgarganda natijalarni qayta hisoblash
    _onQueryChanged(_rawQuery);
  }

  void _clearAll() => _applyFilter(() {
    _filterDistrict = null;
    _filterMfy      = null;
    _filterGender   = null;
  });

  // ─────────────────────────────────────────────────────────────────
  //  UI STATE ENUMS
  // ─────────────────────────────────────────────────────────────────

  /// Foydalanuvchi hali hech narsa urinmagan
  bool get _isIdle =>
      _rawQuery.trim().length < _kMinQueryLength && !_hasActiveFilter;

  /// Yetarli matn yo'q (1 belgi)
  bool get _needsMoreInput =>
      _rawQuery.trim().isNotEmpty &&
      _rawQuery.trim().length < _kMinQueryLength &&
      !_hasActiveFilter;

  // ─────────────────────────────────────────────────────────────────
  //  BUILD
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
            crossFadeState: _showFilters
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),

          if (_hasActiveFilter) _buildActiveFilters(),

          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ─── TOP BAR ─────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.govNavy, size: 20),
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
                onChanged: _onQueryChanged,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ism, ko\'cha, telefon...',
                  hintStyle: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                  prefixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.govNavy,
                            ),
                          ),
                        )
                      : const Icon(Icons.search, color: AppColors.govNavy, size: 20),
                  suffixIcon: _rawQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18,
                              color: AppColors.textSecondary),
                          onPressed: () {
                            _ctrl.clear();
                            _onQueryChanged('');
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
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: (_showFilters || _hasActiveFilter)
                    ? AppColors.govNavy
                    : const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.tune_rounded,
                      color: (_showFilters || _hasActiveFilter)
                          ? Colors.white
                          : AppColors.govNavy,
                      size: 20),
                  if (_hasActiveFilter && !_showFilters)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.danger, shape: BoxShape.circle),
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

  // ─── BODY ROUTER ─────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isIdle) {
      return _buildIdleState();
    }
    if (_needsMoreInput) {
      return _emptyState(
        icon: Icons.keyboard_rounded,
        message: 'Davom eting...',
        sub: 'Qidirish uchun kamida $_kMinQueryLength belgi kiriting',
      );
    }
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.govNavy),
      );
    }
    if (_results.isEmpty) {
      return _emptyState(
        icon: Icons.search_off_rounded,
        message: 'Natija topilmadi',
        sub: 'Boshqa kalit so\'z yoki filtr sinab ko\'ring',
      );
    }
    return _buildResultsList();
  }

  // ─── IDLE STATE ──────────────────────────────────────────────────
  Widget _buildIdleState() {
    final total = widget.households.fold<int>(
      0, (sum, h) => sum + h.residents.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats banner
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
                          color: Colors.white70, fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.households.length} xonadon',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$total nafar aholi',
                        style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.people_rounded,
                      color: Colors.white, size: 28),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Hint
          const Text(
            'Qidiruv bo\'yicha maslahatlar',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          _tip(Icons.person_outline_rounded, 'Ism yoki familiya bo\'yicha',
              'Misol: "Karimov" yoki "Jasur"'),
          _tip(Icons.phone_outlined, 'Telefon raqam bo\'yicha',
              'Misol: "998901234567" yoki "901234"'),
          _tip(Icons.signpost_outlined, 'Ko\'cha nomi bo\'yicha',
              'Misol: "Mustaqillik ko\'chasi"'),
          _tip(Icons.home_outlined, 'Uy raqami bo\'yicha',
              'Misol: "45" yoki "12A"'),
          _tip(Icons.tune_rounded, 'Filtr bilan biriktirib',
              'Tuman + ism → aniqroq natija'),

          const SizedBox(height: 24),

          // Quick filter shortcuts
          const Text(
            'Tezkor filtr',
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
            children: _districts.take(6).map((d) => GestureDetector(
              onTap: () => _applyFilter(() {
                _filterDistrict = d;
                _filterMfy = null;
                _showFilters = false;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.govNavy),
                    const SizedBox(width: 6),
                    Text(d,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        )),
                  ],
                ),
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
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.govNavy.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.govNavy),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain)),
              Text(sub,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── RESULTS LIST ─────────────────────────────────────────────────
  Widget _buildResultsList() {
    final total = widget.households.fold<int>(
      0, (sum, h) => sum + h.residents.length);
    final isCapped = _results.length >= _kMaxResults;

    return Column(
      children: [
        // Results count bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
                      ? '${_results.length}+ natija'
                      : '${_results.length} natija',
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
                  isCapped
                      ? '— aniqroq yozing (jami $total nafar)'
                      : '— topildi',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // "Too many results" hint
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
                Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ko\'proq aniq natija uchun to\'liq ism yoki tuman filtri tanlang',
                    style: TextStyle(
                        fontSize: 11, color: Colors.amber.shade800),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
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

  // ─── RESULT CARD ─────────────────────────────────────────────────
  Widget _buildResultCard(_Match m) {
    final r = m.resident;
    final h = m.household;
    final q = _debouncedQuery.toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onOpenDetail(h),
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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  r == null
                      ? Icons.home_work_rounded
                      : (r.gender == 'FEMALE'
                          ? Icons.woman_rounded
                          : Icons.man_rounded),
                  color: Colors.white, size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _highlightText(
                      r?.displayFullName ?? h.officialAddress,
                      q, bold: true,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (r?.role != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.govNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(r!.role!,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.govNavy,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: _highlightText(
                            '${h.houseNumber != null ? "${h.houseNumber}-uy • " : ""}${h.streetName ?? ""}',
                            q, size: 11, color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [h.tumanName, h.mfyName]
                          .where((e) => e != null && e.isNotEmpty)
                          .join(' › '),
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (r?.phonePrimary != null && r!.phonePrimary!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _highlightText(r.phonePrimary!, q,
                          color: AppColors.govNavy, size: 11),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Navigate
              GestureDetector(
                onTap: () => widget.onNavigate(h, r),
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.govNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_car_rounded,
                      color: AppColors.govNavy, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── FILTER PANEL ────────────────────────────────────────────────
  Widget _buildFilterPanel() {
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
            items: _districts,
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
              items: _mfys,
              selected: _filterMfy,
              onSelect: (v) =>
                  _applyFilter(() => _filterMfy = v == _filterMfy ? null : v),
            ),
            const SizedBox(height: 12),
          ],

          _filterLabel('Jinsi'),
          const SizedBox(height: 6),
          Row(
            children: [
              _genderChip('MALE',   Icons.man_rounded,   'Erkak'),
              const SizedBox(width: 8),
              _genderChip('FEMALE', Icons.woman_rounded, 'Ayol'),
            ],
          ),
          const SizedBox(height: 12),

          if (_hasActiveFilter)
            TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.filter_alt_off, size: 16),
              label: const Text('Filtrlarni tozalash'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.danger,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterLabel(String text) => Text(
        text,
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
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final v = items[i];
          final isActive = v == selected;
          return GestureDetector(
            onTap: () => onSelect(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.govNavy : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isActive ? AppColors.govNavy : Colors.transparent),
              ),
              child: Text(
                v,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.white : AppColors.textMain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _genderChip(String gender, IconData icon, String label) {
    final isActive = _filterGender == gender;
    return GestureDetector(
      onTap: () => _applyFilter(
          () => _filterGender = _filterGender == gender ? null : gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.govNavy : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16,
                color: isActive ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.white : AppColors.textMain,
                )),
          ],
        ),
      ),
    );
  }

  // ─── ACTIVE FILTERS SUMMARY ───────────────────────────────────────
  Widget _buildActiveFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Wrap(
        spacing: 6, runSpacing: 4,
        children: [
          if (_filterDistrict != null)
            _activeBadge(_filterDistrict!, () => _applyFilter(() {
              _filterDistrict = null;
              _filterMfy = null;
            })),
          if (_filterMfy != null)
            _activeBadge(_filterMfy!,
                () => _applyFilter(() => _filterMfy = null)),
          if (_filterGender != null)
            _activeBadge(
              _filterGender == 'MALE' ? 'Erkak' : 'Ayol',
              () => _applyFilter(() => _filterGender = null),
            ),
        ],
      ),
    );
  }

  Widget _activeBadge(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.govNavy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.govNavy.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
        ],
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────
  Widget _highlightText(
    String text,
    String query, {
    bool bold = false,
    Color color = AppColors.textMain,
    double size = 14,
  }) {
    final base = TextStyle(
      fontSize: size,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      color: color,
    );
    if (query.isEmpty) {
      return Text(text, style: base, maxLines: 1,
          overflow: TextOverflow.ellipsis);
    }
    final lower = text.toLowerCase();
    final idx   = lower.indexOf(query);
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
            fontWeight: FontWeight.w800,
          ),
        ),
        TextSpan(text: text.substring(idx + query.length)),
      ]),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String message,
    required String sub,
  }) {
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
            child: Icon(icon, size: 36,
                color: AppColors.govNavy.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain)),
          const SizedBox(height: 6),
          Text(sub,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Model ───────────────────────────────────────────────────────────────────
class _Match {
  final ResidentModel? resident;
  final HouseholdModel household;
  const _Match({required this.resident, required this.household});
}
