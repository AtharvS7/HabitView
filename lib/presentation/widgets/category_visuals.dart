import 'package:flutter/material.dart';

import '../../domain/models/habit.dart';

/// Icon, label and accent colour for each [HabitCategory]. Kept in one place so
/// the look is consistent across cards, forms and the dashboard.
class CategoryVisuals {
  const CategoryVisuals._();

  static IconData icon(HabitCategory category) => switch (category) {
        HabitCategory.productivity => Icons.bolt_outlined,
        HabitCategory.fitness => Icons.fitness_center_outlined,
        HabitCategory.mindfulness => Icons.self_improvement_outlined,
        HabitCategory.learning => Icons.menu_book_outlined,
        HabitCategory.other => Icons.star_outline,
      };

  static String label(HabitCategory category) => switch (category) {
        HabitCategory.productivity => 'Productivity',
        HabitCategory.fitness => 'Fitness',
        HabitCategory.mindfulness => 'Mindfulness',
        HabitCategory.learning => 'Learning',
        HabitCategory.other => 'Other',
      };

  static Color color(HabitCategory category) => switch (category) {
        HabitCategory.productivity => const Color(0xFF6750A4),
        HabitCategory.fitness => const Color(0xFFB3261E),
        HabitCategory.mindfulness => const Color(0xFF1E6E5C),
        HabitCategory.learning => const Color(0xFF7A5900),
        HabitCategory.other => const Color(0xFF555555),
      };
}
