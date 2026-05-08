import 'package:flutter/material.dart';

class ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String>? onChanged;

  const ModernTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(), 
          style: TextStyle(
            color: isDark ? Colors.white24 : Colors.black26, 
            fontSize: 9, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1.5,
          ),
        ),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87, 
            fontSize: 16, 
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white12 : Colors.black12, 
              fontSize: 16,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}
