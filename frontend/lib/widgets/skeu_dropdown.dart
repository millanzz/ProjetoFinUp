import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Dropdown skeuomórfico no mesmo estilo do SkeuInput.
class SkeuDropdown<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;

  const SkeuDropdown({
    super.key,
    required this.label,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xfff8fafc),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.silverMist.withOpacity(0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.silverMist.withOpacity(0.35),
                offset: const Offset(0, 2),
                blurRadius: 3,
                spreadRadius: -1,
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text(
                hint ?? '',
                style: const TextStyle(
                  color: AppTheme.coolGray,
                  fontSize: 15,
                ),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTheme.coolGray,
              ),
              borderRadius: BorderRadius.circular(14),
              dropdownColor: Colors.white,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkText,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
