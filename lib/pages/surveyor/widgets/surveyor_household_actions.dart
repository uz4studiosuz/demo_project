import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/household_model.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/household_info_sheet.dart';
import '../add_family_page.dart';

/// Surveyor dashboard, list va xarita uchun umumiy xonadon ma'lumotlari oynasi.
/// Tahrirlash va o'chirish logikasi bir joyga jamlangan.
void showSurveyorHouseholdDetails(BuildContext context, HouseholdModel household) {
  final provider = Provider.of<AppProvider>(context, listen: false);

  showHouseholdInfoSheet(
    context,
    household,
    onEdit: () async {
      Navigator.pop(context); // Sheetni yopish
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddFamilyPage(existing: household)),
      );
      if (result == true) {
        provider.fetchHouseholds();
      }
    },
    onDelete: () async {
      Navigator.pop(context); // Sheetni yopish
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xonadonni o\'chirish'),
          content: const Text('Rostdan ham bu xonadonni o\'chirmoqchimisiz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bekor qilish'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('O\'chirish', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await provider.deleteHousehold(household.id);
        provider.fetchHouseholds();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xonadon muvaffaqiyatli o\'chirildi')),
          );
        }
      }
    },
  );
}
