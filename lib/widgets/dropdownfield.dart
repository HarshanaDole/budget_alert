import 'package:flutter/material.dart';
import '../components/app_colors.dart';

class CustomDropdownField extends StatelessWidget {
  const CustomDropdownField(
      {super.key,
      required this.labelText,
      required this.value,
      required this.options,
      required this.onChanged});

  final String labelText;
  final String value;
  final List options;
  final ValueChanged onChanged;

  String? validateDropdown(value) {
    if (value == null || value.isEmpty) {
      return 'Please select an option';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField(
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option,
              child: Text(option),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validateDropdown,
      dropdownColor: AppColors.SubColor,
      decoration: InputDecoration(
        labelText: labelText,
      ),
    );
  }
}
