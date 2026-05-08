import 'package:flutter/material.dart';

class ModernDatePicker extends StatelessWidget {
  final String label;
  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateSelected;

  const ModernDatePicker({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: firstDate,
          lastDate: lastDate,
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark 
                ? ColorScheme.dark(
                    primary: primaryColor,
                    surface: const Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                  )
                : ColorScheme.light(
                    primary: primaryColor,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onDateSelected(picked);
      },
      child: Column(
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${selectedDate.day} ${_getMonth(selectedDate.month)} ${selectedDate.year}',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87, 
                  fontSize: 16, 
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.calendar_today_rounded, size: 16, color: isDark ? Colors.white24 : Colors.black26),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
        ],
      ),
    );
  }

  String _getMonth(int m) {
    return ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'][m - 1];
  }
}
