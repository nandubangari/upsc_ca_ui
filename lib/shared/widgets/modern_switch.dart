import 'package:flutter/material.dart';

class ModernSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ModernSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isDark ? (value ? Colors.white : Colors.white38) : (value ? Colors.black87 : Colors.black26),
                  fontSize: 15,
                  fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 38,
              height: 20,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: value ? Theme.of(context).colorScheme.primary : (isDark ? Colors.white10 : Colors.black12),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
