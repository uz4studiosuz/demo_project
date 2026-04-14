import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class Step3PreviewStep extends StatelessWidget {
  final Map<String, dynamic> data;

  const Step3PreviewStep({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAlert(),
          const SizedBox(height: 16),
          _buildCard(
            'Manzil ma\'lumotlari',
            Icons.location_on_outlined,
            [
              _buildRow('Mulk turi', data['propertyType'] == 'HOVLI' ? 'Hovli joy' : 'Kvartira'),
              _buildRow('Tuman / Shahar', data['tuman'] ?? '-'),
              _buildRow('MFY', data['mfy'] ?? '-'),
              _buildRow('Ko\'cha', data['street'] ?? '-'),
              if (data['propertyType'] == 'HOVLI')
                _buildRow('Uy raqami', data['houseNumber'] ?? '-'),
              if (data['propertyType'] == 'KVARTIRA') ...[
                _buildRow('Bino raqami', data['buildingNumber'] ?? '-'),
                _buildRow('Kvartira', data['apartment'] ?? '-'),
                _buildRow('Qavat', data['floor']?.toString() ?? '-'),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            'Oila boshlig\'i',
            Icons.person_outline,
            [
              _buildRow('F.I.Sh', '${data['headLast']} ${data['headFirst']} ${data['headMiddle']}'),
              _buildRow('Jinsi', data['headGender'] == 'MALE' ? 'Erkak' : 'Ayol'),
              _buildRow('Telefon', data['headPhone'] ?? '-'),
            ],
          ),
          if (data['members'] != null && (data['members'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCard(
              'Boshqa oila a\'zolari (${(data['members'] as List).length} nafar)',
              Icons.group_outlined,
              (data['members'] as List).map((m) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${m['last']} ${m['first']} ${m['middle']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textMain)),
                      Text('${m['role']} • ${m['gender'] == 'MALE' ? 'Erkak' : 'Ayol'}${m['phone'] != null && (m['phone'] as String).isNotEmpty && (m['phone'] as String) != '+998 ' ? ' • ${m['phone']}' : ''}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlert() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.govNavy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.govNavy, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Iltimos, kiritilgan yozuvlarni yana bir bor vizual tekshirib chiqing. Barchasi to\'gri bo\'lsa «Bazaga yuklash» tugmasini bosing.',
              style: TextStyle(fontSize: 12, color: AppColors.govNavy, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.govNavy),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.govNavy,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppColors.textMain, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
