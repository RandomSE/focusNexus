/// Alternate metaphors; each maps the same [GrowthStage] to different art/audio copy.
enum VisualThemeId {
  zenGarden,
  bonsai,
  coralReef,
  constellation,
  sandGarden,
}

String visualThemeLabel(VisualThemeId id) => switch (id) {
      VisualThemeId.zenGarden => 'Zen garden',
      VisualThemeId.bonsai => 'Bonsai',
      VisualThemeId.coralReef => 'Coral reef',
      VisualThemeId.constellation => 'Constellation',
      VisualThemeId.sandGarden => 'Sand garden',
    };
