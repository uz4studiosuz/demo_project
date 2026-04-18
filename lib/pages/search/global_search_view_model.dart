import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/household_model.dart';
import '../../models/resident_model.dart';
import '../../services/supabase_service.dart';
import '../../utils/uz_converter.dart';
import '../../theme/colors.dart';

const int kMinSearchLength = 2;
const int kMaxSearchResults = 60;

class SearchResult {
  final HouseholdModel household;
  final ResidentModel? resident; // null means matched by address/house number
  SearchResult({required this.household, this.resident});
}

class GlobalSearchViewModel extends ChangeNotifier {
  List<HouseholdModel> _households = [];
  Timer? _debounce;
  
  String _rawQuery = '';
  String get rawQuery => _rawQuery;

  String _activeQuery = '';
  String get activeQuery => _activeQuery;

  String? _filterDistrict;
  String? get filterDistrict => _filterDistrict;

  String? _filterMfy;
  String? get filterMfy => _filterMfy;

  String? _filterType; // 'house' | 'apartment' | null
  String? get filterType => _filterType;

  String? _filterGender; // Added for driver compatibility if needed
  String? get filterGender => _filterGender;

  bool _showFilters = false;
  bool get showFilters => _showFilters;

  List<SearchResult> _results = [];
  List<SearchResult> get results => _results;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  void init(List<HouseholdModel> households) {
    _households = households;
  }

  void updateHouseholds(List<HouseholdModel> households) {
    _households = households;
    if (_rawQuery.isNotEmpty || hasFilter) {
      _runSearch(_rawQuery.trim());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void toggleFilters() {
    _showFilters = !_showFilters;
    notifyListeners();
  }

  void onChanged(String raw) {
    _rawQuery = raw;
    notifyListeners();

    _debounce?.cancel();
    final trimmed = raw.trim();

    if (trimmed.length < kMinSearchLength && !hasFilter) {
      _activeQuery = '';
      _results = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    if (trimmed.length < kMinSearchLength && hasFilter) {
      _debounce = Timer(const Duration(milliseconds: 150), () => _runSearch(''));
      return;
    }

    _isSearching = true;
    notifyListeners();
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(trimmed));
  }

  void _runSearch(String query) async {
    final lower = query.toLowerCase();
    final alternativeQuery = UzConverter.convert(query).toLowerCase();
    
    // 1. Local search first
    final out = <SearchResult>[];

    for (final h in _households) {
      if (out.length >= kMaxSearchResults) break;
      if (_filterDistrict != null && h.tumanName != _filterDistrict) continue;
      if (_filterMfy != null && h.mfyName != _filterMfy) continue;
      if (_filterType == 'house' && h.propertyType != 'house') continue;
      if (_filterType == 'apartment' && h.propertyType != 'apartment') continue;

      if (lower.isEmpty) {
        // Only filtered
        for (final r in h.residents) {
          if (out.length >= kMaxSearchResults) break;
          if (_filterGender != null && r.gender != _filterGender) continue;
          out.add(SearchResult(household: h, resident: r));
        }
        if (h.residents.isEmpty && _filterGender == null) {
          out.add(SearchResult(household: h));
        }
        continue;
      }

      final hData = (h.officialAddress + (h.tumanName ?? "") + (h.mfyName ?? "") + (h.streetName ?? "") + (h.houseNumber ?? "")).toLowerCase();
      final addrMatch = hData.contains(lower) || (alternativeQuery.isNotEmpty && hData.contains(alternativeQuery));

      bool anyResidentAdded = false;
      for (final r in h.residents) {
        if (out.length >= kMaxSearchResults) break;
        if (_filterGender != null && r.gender != _filterGender) continue;

        final rData = (r.displayFullName + (r.phonePrimary ?? "")).toLowerCase();
        final resMatch = rData.contains(lower) || (alternativeQuery.isNotEmpty && rData.contains(alternativeQuery));
        
        if (resMatch || addrMatch) {
          out.add(SearchResult(household: h, resident: r));
          anyResidentAdded = true;
        }
      }
      
      if (!anyResidentAdded && addrMatch && _filterGender == null) {
        out.add(SearchResult(household: h));
      }
    }

    // 2. REMOTE SEARCH
    if (query.length >= 3 && out.length < 5) {
      _isSearching = true;
      notifyListeners();

      final remoteResults = await SupabaseService.searchHouseholdsRemote(query);
      
      for (final h in remoteResults) {
        if (out.any((e) => e.household.id == h.id)) continue;
        if (out.length >= kMaxSearchResults) break;
        if (_filterDistrict != null && h.tumanName != _filterDistrict) continue;
        if (_filterMfy != null && h.mfyName != _filterMfy) continue;

        if (h.residents.isEmpty) {
          out.add(SearchResult(household: h));
        } else {
          for (final r in h.residents) {
             if (_filterGender != null && r.gender != _filterGender) continue;
             out.add(SearchResult(household: h, resident: r));
          }
        }
      }
    }

    _activeQuery = query;
    _results = out;
    _isSearching = false;
    notifyListeners();
  }

  // Filter properties
  List<String> get districts {
    final s = <String>{};
    for (final h in _households) {
      if (h.tumanName != null && h.tumanName!.isNotEmpty) s.add(h.tumanName!);
    }
    return s.toList()..sort();
  }

  List<String> get mfys {
    final s = <String>{};
    for (final h in _households) {
      if (_filterDistrict != null && h.tumanName != _filterDistrict) continue;
      if (h.mfyName != null && h.mfyName!.isNotEmpty) s.add(h.mfyName!);
    }
    return s.toList()..sort();
  }

  bool get hasFilter => _filterDistrict != null || _filterMfy != null || _filterType != null || _filterGender != null;
  bool get isIdle => _rawQuery.trim().length < kMinSearchLength && !hasFilter;

  int get totalHouseholds => _households.length;
  int get totalResidents => _households.fold<int>(0, (s, h) => s + h.residents.length);

  void setFilterDistrict(String? district) {
    _filterDistrict = district == _filterDistrict ? null : district;
    _filterMfy = null;
    onChanged(_rawQuery);
  }

  void setFilterMfy(String? mfy) {
    _filterMfy = mfy == _filterMfy ? null : mfy;
    onChanged(_rawQuery);
  }

  void setFilterType(String? type) {
    _filterType = _filterType == type ? null : type;
    onChanged(_rawQuery);
  }

  void setFilterGender(String? gender) {
    _filterGender = _filterGender == gender ? null : gender;
    onChanged(_rawQuery);
  }

  void clearFilters() {
    _filterDistrict = null;
    _filterMfy = null;
    _filterType = null;
    _filterGender = null;
    onChanged(_rawQuery);
  }
}
