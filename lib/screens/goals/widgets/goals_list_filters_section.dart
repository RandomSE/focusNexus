import 'package:flutter/material.dart';

import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/goals_screen_ui_provider.dart';
import 'package:focusNexus/utils/common_utils.dart';

/// Category, complexity, status, and sort filters for the goals list.
class GoalsListFiltersSection extends StatelessWidget {
  const GoalsListFiltersSection({
    super.key,
    required this.uiState,
    required this.bundle,
    required this.categories,
    required this.levels,
    required this.onCategoryFilterChanged,
    required this.onComplexityFilterChanged,
    required this.onStatusFilterChanged,
    required this.onSortByChanged,
  });

  final GoalsScreenUiState uiState;
  final ThemeBundle bundle;
  final List<String> categories;
  final List<String> levels;
  final ValueChanged<String?> onCategoryFilterChanged;
  final ValueChanged<String?> onComplexityFilterChanged;
  final ValueChanged<String?> onStatusFilterChanged;
  final ValueChanged<String?> onSortByChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        CommonUtils.buildDropdownButton(
          uiState.selectedCategoryFilter,
          ['All', ...categories],
          bundle.textStyle,
          bundle.secondaryColor,
          onCategoryFilterChanged,
          displayText: (v) => 'Category: $v',
        ),
        CommonUtils.buildDropdownButton(
          uiState.selectedComplexityFilter,
          ['All', ...levels],
          bundle.textStyle,
          bundle.secondaryColor,
          onComplexityFilterChanged,
          displayText: (v) => 'Complexity: $v',
        ),
        CommonUtils.buildDropdownButton(
          uiState.selectedStatusFilter,
          ['Active', 'Completed'],
          bundle.textStyle,
          bundle.secondaryColor,
          onStatusFilterChanged,
          displayText: (v) => 'Status: $v',
        ),
        CommonUtils.buildDropdownButton(
          uiState.sortBy,
          [
            'None',
            'Time-slot only',
            'In slot now',
            'Title A-Z',
            'Title Z-A',
            'Time ↑',
            'Time ↓',
            'Steps ↑',
            'Steps ↓',
            'Closest deadline',
          ],
          bundle.textStyle,
          bundle.secondaryColor,
          onSortByChanged,
          displayText: (v) => 'Sort: $v',
        ),
      ],
    );
  }
}
