import 'package:focusNexus/progressive_visuals/cherry_blossom_prestige_path.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_state.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/services/sound_channel.dart';

/// Which looping BGM track matches a cherry tree state.
SoundChannel cherryBlossomMusicForTree(CherryBlossomTreeState tree) {
  final t = tree.normalized();
  if (t.isFinale) {
    return t.prestigePath == CherryBlossomPrestigePath.power
        ? SoundChannel.cherryPowerMusic
        : SoundChannel.cherryPeaceMusic;
  }
  if (t.stageIndex >= CherryBlossomStageCatalog.maxPlayableStage) {
    return SoundChannel.cherryBalanceMusic;
  }
  // Deep Twilight (4) + Aurora Veil (5).
  if (t.stageIndex >= 4) {
    return SoundChannel.cherryStage2Music;
  }
  // Bare Beginning through Golden Afternoon (0-3).
  return SoundChannel.cherryStage1Music;
}

/// Whether a music channel should appear in Sound effects (unlock-gated).
bool isMusicChannelUnlocked({
  required SoundChannel channel,
  required GardenState? garden,
  required bool progressiveVisualsEnabled,
  required bool miniGamesEnabled,
  Set<String> ownedAmbientIds = const {},
}) {
  if (!channel.isMusic) return true;
  if (channel.musicSection == SoundMusicSection.ambient) {
    return ownedAmbientIds.contains(channel.id);
  }
  switch (channel) {
    case SoundChannel.breathBackground:
      return miniGamesEnabled;
    case SoundChannel.zenGardenMusic:
      return progressiveVisualsEnabled;
    case SoundChannel.cherryStage1Music:
      return progressiveVisualsEnabled &&
          (garden?.cherryBlossomTreeUnlocked ?? false);
    case SoundChannel.cherryStage2Music:
      return progressiveVisualsEnabled &&
          (garden?.cherryBlossomTree.highestStageUnlocked ?? 0) >= 4;
    case SoundChannel.cherryBalanceMusic:
      return progressiveVisualsEnabled &&
          (garden?.cherryBlossomTree.highestStageUnlocked ?? 0) >=
              CherryBlossomStageCatalog.maxPlayableStage;
    case SoundChannel.cherryPeaceMusic:
      return progressiveVisualsEnabled &&
          (garden?.cherryBlossomTree
                  .isFinalePathUnlocked(CherryBlossomPrestigePath.peace) ??
              false);
    case SoundChannel.cherryPowerMusic:
      return progressiveVisualsEnabled &&
          (garden?.cherryBlossomTree
                  .isFinalePathUnlocked(CherryBlossomPrestigePath.power) ??
              false);
    case SoundChannel.bonsaiMusic:
      return progressiveVisualsEnabled &&
          (garden?.cherryBlossomTreeUnlocked ?? false);
    default:
      return true;
  }
}
