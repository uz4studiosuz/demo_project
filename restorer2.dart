import 'dart:io';

void main() {
  final file = File('lib/pages/driver/driver_dashboard.dart');
  var content = file.readAsStringSync();

  content = content.replaceFirst(
    '''      case _DrillLevel.household:
        final households = _householdsInStreet;
        if (households.isEmpty) return _buildResidentList([]);
        return _buildHouseholdGrid(
          title: '\${_selStreet} — Xonadonlar',
          items: households,
          // ✅ Tap → Bottom Sheet (list emas)
          onTap: (h) => _openDetails(h),
        );''',
    '''      case _DrillLevel.household:
        final grouped = _groupedObjectsInStreet;
        if (grouped.isEmpty) return _buildResidentList([]);
        return _buildHouseholdGrid(
          title: '\${_selStreet} — Binolar/Xonadonlar',
          items: grouped,
          onTap: (item) {
            if (item.isBuilding) {
              _showBuildingSheet(context, item.apartments!);
            } else {
              _openDetails(item.house!);
            }
          },
        );'''
  );

  file.writeAsStringSync(content);
}
