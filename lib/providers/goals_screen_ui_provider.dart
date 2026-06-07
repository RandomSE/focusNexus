import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'goals_screen_ui_provider.g.dart';

/// Ephemeral goals screen UI: filters, form dropdowns, template maps.
class GoalsScreenUiState {
  const GoalsScreenUiState({
    this.selectedCategoryFilter = 'All',
    this.selectedComplexityFilter = 'All',
    this.selectedStatusFilter = 'Active',
    this.sortBy = 'None',
    this.category = 'Productivity',
    this.complexity = 'Low',
    this.effort = 'Low',
    this.motivation = 'Low',
    this.goalsCompletedToday = 0,
    this.userTemplates = const {},
    this.templateGroups = const {},
    this.templateDialogCategory = 'Productivity',
    this.templateDialogComplexity = 'Low',
    this.templateDialogEffort = 'Low',
    this.templateDialogMotivation = 'Low',
    this.templateDialogDeadlineHours = 0,
    this.templateDialogSteps = '1',
    this.templateDialogTime = '',
    this.templateDialogName = '',
    this.showTemplateSaveDialog = false,
    this.editingTemplateKey,
  });

  final String selectedCategoryFilter;
  final String selectedComplexityFilter;
  final String selectedStatusFilter;
  final String sortBy;
  final String category;
  final String complexity;
  final String effort;
  final String motivation;
  final int goalsCompletedToday;
  final Map<String, Map<String, dynamic>> userTemplates;
  final Map<String, List<String>> templateGroups;

  final String templateDialogCategory;
  final String templateDialogComplexity;
  final String templateDialogEffort;
  final String templateDialogMotivation;
  final int templateDialogDeadlineHours;
  final String templateDialogSteps;
  final String templateDialogTime;
  final String templateDialogName;
  final bool showTemplateSaveDialog;
  final String? editingTemplateKey;

  GoalsScreenUiState copyWith({
    String? selectedCategoryFilter,
    String? selectedComplexityFilter,
    String? selectedStatusFilter,
    String? sortBy,
    String? category,
    String? complexity,
    String? effort,
    String? motivation,
    int? goalsCompletedToday,
    Map<String, Map<String, dynamic>>? userTemplates,
    Map<String, List<String>>? templateGroups,
    String? templateDialogCategory,
    String? templateDialogComplexity,
    String? templateDialogEffort,
    String? templateDialogMotivation,
    int? templateDialogDeadlineHours,
    String? templateDialogSteps,
    String? templateDialogTime,
    String? templateDialogName,
    bool? showTemplateSaveDialog,
    String? editingTemplateKey,
    bool clearEditingTemplateKey = false,
  }) {
    return GoalsScreenUiState(
      selectedCategoryFilter:
          selectedCategoryFilter ?? this.selectedCategoryFilter,
      selectedComplexityFilter:
          selectedComplexityFilter ?? this.selectedComplexityFilter,
      selectedStatusFilter: selectedStatusFilter ?? this.selectedStatusFilter,
      sortBy: sortBy ?? this.sortBy,
      category: category ?? this.category,
      complexity: complexity ?? this.complexity,
      effort: effort ?? this.effort,
      motivation: motivation ?? this.motivation,
      goalsCompletedToday: goalsCompletedToday ?? this.goalsCompletedToday,
      userTemplates: userTemplates ?? this.userTemplates,
      templateGroups: templateGroups ?? this.templateGroups,
      templateDialogCategory:
          templateDialogCategory ?? this.templateDialogCategory,
      templateDialogComplexity:
          templateDialogComplexity ?? this.templateDialogComplexity,
      templateDialogEffort: templateDialogEffort ?? this.templateDialogEffort,
      templateDialogMotivation:
          templateDialogMotivation ?? this.templateDialogMotivation,
      templateDialogDeadlineHours:
          templateDialogDeadlineHours ?? this.templateDialogDeadlineHours,
      templateDialogSteps: templateDialogSteps ?? this.templateDialogSteps,
      templateDialogTime: templateDialogTime ?? this.templateDialogTime,
      templateDialogName: templateDialogName ?? this.templateDialogName,
      showTemplateSaveDialog:
          showTemplateSaveDialog ?? this.showTemplateSaveDialog,
      editingTemplateKey: clearEditingTemplateKey
          ? null
          : (editingTemplateKey ?? this.editingTemplateKey),
    );
  }
}

@Riverpod(keepAlive: true)
class GoalsScreenUi extends _$GoalsScreenUi {
  @override
  GoalsScreenUiState build() => const GoalsScreenUiState();

  void update(GoalsScreenUiState Function(GoalsScreenUiState current) fn) {
    state = fn(state);
  }
}

/// Back-compat type name for the goals screen UI notifier.
typedef GoalsScreenUiNotifier = GoalsScreenUi;
