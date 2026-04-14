// ═══════════════════════════════════════════════════════════════════════════
//  NAVIGATION OPTIONS SHEET
// ═══════════════════════════════════════════════════════════════════════════

import 'package:beemor/models/household_model.dart';
import 'package:beemor/models/resident_model.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/colors.dart';
import '../driver_map_page.dart';

class NavOptionsSheet extends StatelessWidget {
  final HouseholdModel household;
  final ResidentModel? targetResident;
  const NavOptionsSheet({super.key, required this.household, this.targetResident});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Yo\'nalish usulini tanlang',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.govNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            household.officialAddress,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _option(
            context,
            icon: Icons.map_rounded,
            color: AppColors.govNavy,
            title: 'Ilova ichida navigatsiya',
            sub: 'Marshrut va yo\'nalish ko\'rsatmalar',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DriverMapPage(
                    destination: LatLng(
                      household.latitude,
                      household.longitude,
                    ),
                    addressTitle: household.officialAddress,
                    household: household,
                    targetResident: targetResident,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _option(
            context,
            icon: Icons.location_on_rounded,
            color: Colors.red,
            title: 'Google Maps',
            sub: 'Tashqi ilovada ochish',
            onTap: () async {
              Navigator.pop(context);
              final url = Uri.parse(
                'https://www.google.com/maps/dir/?api=1&destination=${household.latitude},${household.longitude}&travelmode=driving',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const Divider(height: 1),
          _option(
            context,
            icon: Icons.navigation_rounded,
            color: Colors.amber.shade700,
            title: 'Yandex Navigator',
            sub: 'Tashqi ilovada ochish',
            onTap: () async {
              Navigator.pop(context);
              final url = Uri.parse(
                'yandexnavi://build_route_on_map?lat_to=${household.latitude}&lon_to=${household.longitude}',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                final fb = Uri.parse(
                  'https://yandex.com/maps/?rtext=~${household.latitude},${household.longitude}',
                );
                if (await canLaunchUrl(fb)) {
                  await launchUrl(fb, mode: LaunchMode.externalApplication);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        sub,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
