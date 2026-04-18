import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/household_model.dart';
import '../../../providers/app_provider.dart';

enum DrillLevel { district, mfy, street, household }

class HouseOrBuilding {
  final bool isBuilding;
  final String title;
  final HouseholdModel? house;
  final List<HouseholdModel>? apartments;

  HouseOrBuilding.house(this.house)
      : isBuilding = false,
        title = (house!.houseNumber != null && house.houseNumber!.trim().isNotEmpty)
            ? '${house.houseNumber}-uy'
            : 'Raqamsiz uy',
        apartments = null;

  HouseOrBuilding.building(this.title, this.apartments)
      : isBuilding = true,
        house = null;
}

class PatientListViewModel extends ChangeNotifier {
  List<HouseholdModel> _all = [];
  List<HouseholdModel> get allHouseholds => _all;

  DrillLevel _level = DrillLevel.district;
  DrillLevel get level => _level;

  String? _selDistrict;
  String? get selDistrict => _selDistrict;

  String? _selMfy;
  String? get selMfy => _selMfy;

  String? _selStreet;
  String? get selStreet => _selStreet;

  Future<void> load(BuildContext context) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = Provider.of<AppProvider>(context, listen: false);
      if (p.households.isEmpty) {
        await p.fetchHouseholds();
      }
      _all = p.households;
      notifyListeners();
    });
  }

  Future<void> refresh(BuildContext context) async {
    await Provider.of<AppProvider>(context, listen: false).fetchHouseholds();
    await load(context);
  }

  void syncHouseholds(List<HouseholdModel> households) {
    if (_all != households) {
      _all = households;
      Future.microtask(() => notifyListeners());
    }
  }

  void setLevel(DrillLevel lvl) {
    _level = lvl;
    if (lvl == DrillLevel.district) {
      _selDistrict = null;
      _selMfy = null;
      _selStreet = null;
    } else if (lvl == DrillLevel.mfy) {
      _selMfy = null;
      _selStreet = null;
    } else if (lvl == DrillLevel.street) {
      _selStreet = null;
    }
    notifyListeners();
  }

  void selectDistrict(String district) {
    _selDistrict = district;
    _level = DrillLevel.mfy;
    notifyListeners();
  }

  void selectMfy(String mfy) {
    _selMfy = mfy;
    _level = DrillLevel.street;
    notifyListeners();
  }

  void selectStreet(String street) {
    _selStreet = street;
    _level = DrillLevel.household;
    notifyListeners();
  }

  void goBack() {
    switch (_level) {
      case DrillLevel.mfy:
        _selDistrict = null;
        _level = DrillLevel.district;
        break;
      case DrillLevel.street:
        _selMfy = null;
        _level = DrillLevel.mfy;
        break;
      case DrillLevel.household:
        _selStreet = null;
        _level = DrillLevel.street;
        break;
      default:
        break;
    }
    notifyListeners();
  }

  List<String> get districts {
    final s = <String>{};
    for (final h in _all) {
      if (h.tumanName != null && h.tumanName!.isNotEmpty) s.add(h.tumanName!);
    }
    return s.toList()..sort();
  }

  List<String> get mfys {
    final s = <String>{};
    for (final h in _all) {
      if (h.tumanName == _selDistrict && h.mfyName != null && h.mfyName!.isNotEmpty) {
        s.add(h.mfyName!);
      }
    }
    return s.toList()..sort();
  }

  List<String> get streets {
    final s = <String>{};
    for (final h in _all) {
      if (h.tumanName == _selDistrict && h.mfyName == _selMfy && h.streetName != null && h.streetName!.isNotEmpty) {
        s.add(h.streetName!);
      }
    }
    return s.toList()..sort();
  }

  List<HouseOrBuilding> get groupedObjectsInStreet {
    final list = _all.where((h) => h.tumanName == _selDistrict && h.mfyName == _selMfy && h.streetName == _selStreet).toList();
    final result = <HouseOrBuilding>[];
    final aptGroups = <String, List<HouseholdModel>>{};

    for (final h in list) {
      if (h.propertyType == 'APARTMENT') {
        final bNum = h.buildingNumber != null && h.buildingNumber!.isNotEmpty ? h.buildingNumber! : 'Noma\'lum';
        aptGroups.putIfAbsent(bNum, () => []).add(h);
      } else {
        result.add(HouseOrBuilding.house(h));
      }
    }

    aptGroups.forEach((bNum, apts) {
      result.add(HouseOrBuilding.building('$bNum-bino', apts));
    });

    return result;
  }

  int countFor(String label) {
    return _all.where((h) {
      if (_level == DrillLevel.district) return h.tumanName == label;
      if (_level == DrillLevel.mfy) return h.tumanName == _selDistrict && h.mfyName == label;
      if (_level == DrillLevel.street) return h.tumanName == _selDistrict && h.mfyName == _selMfy && h.streetName == label;
      return false;
    }).length;
  }
}
