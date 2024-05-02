import 'package:flutter/material.dart';

class DeleteButton extends StatelessWidget {
  const DeleteButton({super.key, required this.onPress});

  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPress,
        child: Text(
          'Delete Account'.toUpperCase(),
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
      ),
    );
  }
}
