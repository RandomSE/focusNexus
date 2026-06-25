/// Progressive visual theme identifiers.
enum VisualThemeId {
  zenGarden,
}

String visualThemeLabel(VisualThemeId id) => switch (id) {
      VisualThemeId.zenGarden => 'Zen garden',
    };
