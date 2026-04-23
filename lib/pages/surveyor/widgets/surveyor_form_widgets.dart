import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    bool required = false,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
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
          inputFormatters: inputFormatters,
          maxLength: maxLength ?? (keyboardType == TextInputType.phone ? 13 : null),
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          style: TextStyle(
            fontSize: 14,
            color: readOnly ? AppColors.textSecondary : AppColors.textMain,
          ),
          decoration: InputDecoration(
            labelText: label + (required ? ' *' : ''),
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
    List<TextInputFormatter>? inputFormatters,
  }) {
    if (suggestions.isEmpty) {
      return _buildTextFormField(ctrl, label, required, icon, keyboard, inputFormatters: inputFormatters);
    }

    return LayoutBuilder(
      builder: (context, constraints) => _SuggestionField(
        ctrl: ctrl,
        label: label,
        required: required,
        icon: icon,
        keyboard: keyboard,
        suggestions: suggestions,
        constraints: constraints,
        inputFormatters: inputFormatters,
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
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return ValueListenableBuilder(
      valueListenable: ctrl,
      builder: (context, value, child) {
        return TextFormField(
          controller: ctrl,
          focusNode: focusNode,
          keyboardType: keyboard,
          onFieldSubmitted: onFieldSubmitted,
          inputFormatters: inputFormatters,
          maxLength: maxLength ?? (keyboard == TextInputType.phone ? 13 : null),
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
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

class _SuggestionField extends StatefulWidget {
  final TextEditingController ctrl;
  final String label;
  final bool required;
  final IconData? icon;
  final TextInputType keyboard;
  final List<String> suggestions;
  final BoxConstraints constraints;
  final List<TextInputFormatter>? inputFormatters;

  const _SuggestionField({
    required this.ctrl,
    required this.label,
    required this.required,
    this.icon,
    required this.keyboard,
    required this.suggestions,
    required this.constraints,
    this.inputFormatters,
  });

  @override
  State<_SuggestionField> createState() => _SuggestionFieldState();
}

class _SuggestionFieldState extends State<_SuggestionField> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.ctrl,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        final q = textEditingValue.text.toLowerCase();
        final matches = widget.suggestions.where((s) => s.toLowerCase().startsWith(q));

        if (matches.length == 1 && matches.first.toLowerCase() == q) {
          return const Iterable<String>.empty();
        }

        return matches;
      },
      optionsViewBuilder: (context, onSelected, options) {
        return CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          followerAnchor: Alignment.topLeft,
          targetAnchor: Alignment.bottomLeft,
          offset: const Offset(0, 4),
          child: Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8.0,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Container(
                width: widget.constraints.maxWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 200,
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF5F6F8)),
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return InkWell(
                        onTap: () {
                          onSelected(option);
                          FocusScope.of(context).unfocus();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14.0, vertical: 12.0),
                          child: Text(option,
                              style: const TextStyle(fontSize: 14)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return CompositedTransformTarget(
          link: _layerLink,
          child: SurveyorFormWidgets._buildTextFormField(
            textEditingController,
            widget.label,
            widget.required,
            widget.icon,
            widget.keyboard,
            focusNode: focusNode,
            onFieldSubmitted: (v) => onFieldSubmitted(),
            inputFormatters: widget.inputFormatters,
          ),
        );
      },
    );
  }
}
