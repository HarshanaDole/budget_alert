import 'package:flutter/material.dart';
import '../components/app_colors.dart';

class CustomDropdownField extends StatelessWidget {
  const CustomDropdownField({
    Key? key,
    required this.labelText,
    required this.value,
    required this.options,
    required this.onChanged,
  }) : super(key: key);

  final String labelText;
  final String value;
  final List options;
  final ValueChanged onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: options
          .map(
            (option) => DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select an option';
        }
        return null;
      },
      dropdownColor: AppColors.SubColor,
      decoration: InputDecoration(
        labelText: labelText,
      ),
    );
  }
}
