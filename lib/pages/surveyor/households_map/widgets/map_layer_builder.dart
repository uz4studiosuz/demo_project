import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../models/household_model.dart';
import '../../../../models/user_role.dart';
import '../../../../providers/app_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../widgets/household_info_sheet.dart';
import '../../add_family_page.dart';
import '../households_map_view_model.dart';
import 'map_cluster_badge.dart';
import '../../widgets/surveyor_household_actions.dart';
import '../../widgets/building_bottom_sheet.dart';

List<Marker> buildMapMarkers({
  required BuildContext context,
  required HouseholdsMapViewModel viewModel,
  required List<HouseholdModel> households,
  required double currentZoom,
  required MapController mapController,
  HouseholdModel? focusHousehold,
  void Function(HouseholdModel)? onGetDirections,
}) {
  final isDriver =
      Provider.of<AppProvider>(context, listen: false).currentUser?.role ==
      UserRole.driver;

  if (currentZoom < 11) {
    return viewModel.byDistrict(households).entries.map((e) {
      final c = viewModel.getCenter(e.value);
      return Marker(
        point: c,
        width: 140,
        height: 44,
        child: GestureDetector(
          onTap: () => mapController.move(c, 12),
          child: MapClusterBadge(title: e.key, count: e.value.length),
        ),
      );
    }).toList();
  }

  if (currentZoom >= 11 && currentZoom < 12.5) {
    return viewModel.byMFY(households).entries.map((e) {
      final c = viewModel.getCenter(e.value);
      return Marker(
        point: c,
        width: 160,
        height: 44,
        child: GestureDetector(
          onTap: () => mapController.move(c, 14),
          child: MapClusterBadge(
            title: e.key,
            count: e.value.length,
            color: Colors.blueGrey.shade800,
          ),
        ),
      );
    }).toList();
  }

  if (currentZoom >= 12.5 && currentZoom < 15) {
    return viewModel.byStreet(households).entries.map((e) {
      final c = viewModel.getCenter(e.value);
      return Marker(
        point: c,
        width: 180,
        height: 44,
        child: GestureDetector(
          onTap: () => mapController.move(c, 16),
          child: MapClusterBadge(
            title: e.key,
            count: e.value.length,
            color: Colors.teal.shade700,
          ),
        ),
      );
    }).toList();
  }

  // currentZoom >= 15
  final markers = <Marker>[];

  // Faqat koordinatasi bor xonadonlarni olamiz
  final validHouseholds = households
      .where((h) => h.latitude != 0 && h.longitude != 0)
      .toList();

  if (validHouseholds.isEmpty && households.isNotEmpty) {
    debugPrint(
      '⚠️ [buildMapMarkers] DIQQAT: ${households.length} ta xonadon bor, lekin barchasining koordinatasi 0!',
    );
  }

  // HOUSE
  for (final h in validHouseholds.where((h) => h.propertyType == kHouse)) {
    final isFocused = focusHousehold?.id == h.id;
    markers.add(
      Marker(
        point: LatLng(h.latitude, h.longitude),
        width: 33,
        height: 33,
        child: GestureDetector(
          onTap: () {
            showHouseholdInfoSheet(
              context,
              h,
              onGetDirections: isDriver && onGetDirections != null
                  ? () => onGetDirections(h)
                  : null,
              onEdit: isDriver
                  ? null
                  : () async {
                      Navigator.pop(context);
                      final provider = Provider.of<AppProvider>(
                        context,
                        listen: false,
                      );
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddFamilyPage(existing: h),
                        ),
                      );
                      if (res == true) provider.fetchHouseholds();
                    },
              onDelete: isDriver
                  ? null
                  : () async {
                      Navigator.pop(context);
                      final provider = Provider.of<AppProvider>(
                        context,
                        listen: false,
                      );
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Xonadonni o\'chirish'),
                          content: const Text(
                            'Rostdan ham bu xonadonni o\'chirmoqchimisiz?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Bekor qilish'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'O\'chirish',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await provider.deleteHousehold(h.id);
                        provider.fetchHouseholds();
                      }
                    },
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: isFocused ? Colors.red : Colors.blue.shade700,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              h.houseNumber ?? "?",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // APARTMENT
  for (final entry in viewModel.buildingGroups(validHouseholds).entries) {
    final apartments = entry.value;
    final first = apartments.first;
    final point = LatLng(first.latitude, first.longitude);
    final isFocused = apartments.any((a) => a.id == focusHousehold?.id);
    final buildingNum = first.buildingNumber ?? '?';

    markers.add(
      Marker(
        point: point,
        width: 48,
        height: 48,
        child: GestureDetector(
          onTap: () {
            BuildingBottomSheet.show(
              context,
              apartments,
              onTapApartment: (apt) {
                if (isDriver) {
                  showHouseholdInfoSheet(
                    context,
                    apt,
                    onGetDirections: onGetDirections != null
                        ? () => onGetDirections(apt)
                        : null,
                  );
                } else {
                  showSurveyorHouseholdDetails(context, apt);
                }
              },
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: isFocused ? Colors.purple : Colors.red.shade700,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              buildingNum,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  return markers;
}
