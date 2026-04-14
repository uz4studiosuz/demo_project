import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class SurveyorFormWidgets {
  static Widget card({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.govNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.govNavy, size: 18),
              ),
              const SizedBox(width: 10),
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
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  static Widget field({
    required String label,
    required IconData icon,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
    bool readOnly = false,
  }) {
    final ctrl = controller ?? TextEditingController();
    return ValueListenableBuilder(
      valueListenable: ctrl,
      builder: (context, value, child) {
        return TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          onChanged: onChanged,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: 14,
            color: readOnly ? AppColors.textSecondary : AppColors.textMain,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            prefixIcon: Icon(icon, size: 18, color: AppColors.govNavy),
            suffixIcon: !readOnly && value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.cancel, size: 16, color: AppColors.textSecondary),
                    onPressed: () => ctrl.clear(),
                  )
                : null,
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : const Color(0xFFF5F6F8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: readOnly ? BorderSide(color: Colors.grey.shade200) : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.govNavy, width: 1.5),
            ),
          ),
        );
      },
    );
  }

  static Widget formField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    IconData? icon,
    TextInputType keyboard = TextInputType.text,
    List<String> suggestions = const [],
  }) {
    if (suggestions.isEmpty) {
      return _buildTextFormField(ctrl, label, required, icon, keyboard);
    }

    return LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<String>(
        textEditingController: ctrl,
        focusNode: FocusNode(),
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          final q = textEditingValue.text.toLowerCase();
          final matches = suggestions.where((s) => s.toLowerCase().startsWith(q));
          
          // Agar kiritilgan matn birontasi bilan aynan mos kelsa va yagona bosa popupni yopamiz
          if (matches.length == 1 && matches.first.toLowerCase() == q) {
            return const Iterable<String>.empty();
          }
          
          return matches;
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 200,
                  maxWidth: constraints.maxWidth,
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF5F6F8)),
                  itemBuilder: (BuildContext context, int index) {
                    final String option = options.elementAt(index);
                    return InkWell(
                      onTap: () {
                        onSelected(option);
                        // Tanlangandan so'ng fokusni yo'qotish orqali popupni qayta ochilishini oldini olamiz
                        FocusScope.of(context).unfocus();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                        child: Text(option, style: const TextStyle(fontSize: 14)),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
          return _buildTextFormField(
            textEditingController,
            label,
            required,
            icon,
            keyboard,
            focusNode: focusNode,
            onFieldSubmitted: (v) => onFieldSubmitted(),
          );
        },
      ),
    );
  }

  static Widget _buildTextFormField(
    TextEditingController ctrl,
    String label,
    bool required,
    IconData? icon,
    TextInputType keyboard, {
    FocusNode? focusNode,
    void Function(String)? onFieldSubmitted,
  }) {
    return ValueListenableBuilder(
      valueListenable: ctrl,
      builder: (context, value, child) {
        return TextFormField(
          controller: ctrl,
          focusNode: focusNode,
          keyboardType: keyboard,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            labelText: label + (required ? ' *' : ''),
            labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.govNavy) : null,
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.cancel, size: 16, color: AppColors.textSecondary),
                    onPressed: () {
                      ctrl.clear();
                      if (focusNode != null) focusNode.requestFocus();
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF5F6F8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.govNavy, width: 1.5),
            ),
          ),
        );
      },
    );
  }

  static Widget datePicker(
      BuildContext context, {
      required DateTime? selectedDate,
      required void Function(DateTime?) onChanged,
      String label = 'Tug\'ilgan kun',
      bool isRequired = false,
  }) {
    String formatDate(DateTime d) {
      const months = [
        'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun',
        'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr',
      ];
      return '${d.day}-${months[d.month - 1]}, ${d.year}';
    }

    final bool hasVal = selectedDate != null;

    return GestureDetector(
      onTap: () async {
        final DateTime now = DateTime.now();
        final DateTime initial = selectedDate ?? DateTime(1990, 1, 1);
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(1900),
          lastDate: now,
          initialEntryMode: DatePickerEntryMode.calendar, // Defaults to calendar but allows text input
          helpText: 'TUG\'ILGAN KUNNI TANLANG',
          cancelText: 'BEKOR QILISH',
          confirmText: 'TASDIQLASH',
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.govNavy,
                  onPrimary: Colors.white,
                  onSurface: AppColors.textMain,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.govNavy,
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: hasVal ? AppColors.govNavy : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasVal ? formatDate(selectedDate) : label + (isRequired ? ' *' : ' (ixtiyoriy)'),
                style: TextStyle(
                  fontSize: 14,
                  color: hasVal ? AppColors.textMain : AppColors.textSecondary,
                  fontWeight: hasVal ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            if (hasVal)
              GestureDetector(
                onTap: () => onChanged(null),
                child: const Icon(Icons.cancel, size: 18, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
