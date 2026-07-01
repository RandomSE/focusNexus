/// Progressive visual theme identifiers.
enum VisualThemeId {
  zenGarden,
}

String visualThemeLabel(VisualThemeId id) {
  if (id == VisualThemeId.zenGarden) {
    return 'Zen garden';
  }
  return 'Progressive visual';
}
