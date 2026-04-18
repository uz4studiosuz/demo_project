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
  final isDriver = Provider.of<AppProvider>(context, listen: false).currentUser?.role == UserRole.driver;
  
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
           child: MapClusterBadge(title: e.key, count: e.value.length, color: Colors.blueGrey.shade800),
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
           child: MapClusterBadge(title: e.key, count: e.value.length, color: Colors.teal.shade700),
         ),
       );
     }).toList();
  }

  // currentZoom >= 15
  final markers = <Marker>[];
  
  // Faqat koordinatasi bor xonadonlarni olamiz
  final validHouseholds = households.where((h) => h.latitude != 0 && h.longitude != 0).toList();
  
  if (validHouseholds.isEmpty && households.isNotEmpty) {
     debugPrint('⚠️ [buildMapMarkers] DIQQAT: ${households.length} ta xonadon bor, lekin barchasining koordinatasi 0!');
  }

  // HOUSE
  for (final h in validHouseholds.where((h) => h.propertyType == kHouse)) {
    final isFocused = focusHousehold?.id == h.id;
    markers.add(Marker(
      point: LatLng(h.latitude, h.longitude),
      width: isFocused ? 120 : 100,
      height: isFocused ? 66 : 54,
      child: GestureDetector(
        onTap: () {
          showHouseholdInfoSheet(
            context,
            h,
            onGetDirections: isDriver && onGetDirections != null 
                ? () => onGetDirections(h) 
                : null,
            onEdit: isDriver ? null : () async {
              Navigator.pop(context);
              final provider = Provider.of<AppProvider>(context, listen: false);
              final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddFamilyPage(existing: h)));
              if (res == true) provider.fetchHouseholds();
            },
            onDelete: isDriver ? null : () async {
              Navigator.pop(context);
              final provider = Provider.of<AppProvider>(context, listen: false);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xonadonni o\'chirish'),
                  content: const Text('Rostdan ham bu xonadonni o\'chirmoqchimisiz?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor qilish')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('O\'chirish', style: TextStyle(color: Colors.red))),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isFocused ? const Color(0xFFD32F2F) : AppColors.govNavy,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isFocused ? [BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 8)] : [],
              ),
              child: Text(
                h.houseNumber ?? "?",
                style: TextStyle(color: Colors.white, fontSize: isFocused ? 11 : 9, fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isFocused ? const Color(0xFFD32F2F) : AppColors.govNavy,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(Icons.home_rounded, color: Colors.white, size: isFocused ? 20 : 16),
            ),
          ],
        ),
      ),
    ));
  }

  // APARTMENT
  for (final entry in viewModel.buildingGroups(validHouseholds).entries) {
     final apartments = entry.value;
     final first = apartments.first;
     final point = LatLng(first.latitude, first.longitude);
     final isFocused = apartments.any((a) => a.id == focusHousehold?.id);
     final buildingNum = first.buildingNumber ?? '?';
     final aptCount = apartments.length;

     markers.add(Marker(
       point: point,
       width: 140,
       height: 70,
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
                   onGetDirections: onGetDirections != null ? () => onGetDirections(apt) : null,
                 );
               } else {
                 showSurveyorHouseholdDetails(context, apt);
               }
             },
           );
         },
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               decoration: BoxDecoration(
                 color: isFocused ? const Color(0xFF6A1B9A) : const Color(0xFF37474F),
                 borderRadius: BorderRadius.circular(8),
                 boxShadow: isFocused ? [BoxShadow(color: Colors.purple.withValues(alpha: 0.4), blurRadius: 10)] : [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
               ),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   const Icon(Icons.apartment, color: Colors.white, size: 12),
                   const SizedBox(width: 3),
                   Flexible(
                     child: Text(
                       '${first.streetName ?? ""}${first.streetName != null ? " " : ""}$buildingNum-b • $aptCount kv',
                       style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                       maxLines: 1, overflow: TextOverflow.ellipsis,
                     ),
                   ),
                 ],
               ),
             ),
             const SizedBox(height: 2),
             Container(
               padding: const EdgeInsets.all(4),
               decoration: BoxDecoration(
                 color: isFocused ? const Color(0xFF6A1B9A) : const Color(0xFF37474F),
                 shape: BoxShape.circle,
                 border: Border.all(color: Colors.white, width: 1.5),
               ),
               child: const Icon(Icons.location_city_rounded, color: Colors.white, size: 18),
             ),
           ],
         ),
       ),
     ));
  }

  return markers;
}
