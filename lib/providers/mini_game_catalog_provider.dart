import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/mini_games/mini_game_catalog.dart';
import 'package:focusNexus/mini_games/mini_game_definition.dart';

/// Overridable catalog for hub / lobby.
final miniGameCatalogProvider = Provider<List<MiniGameDefinition>>(
  (ref) => MiniGameCatalog.production,
);
