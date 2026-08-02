import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_prestige_path.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_state.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/services/music_unlock.dart';
import 'package:focusNexus/services/sound_channel.dart';

void main() {
  test('cherryBlossomMusicForTree maps stages to tracks', () {
    expect(
      cherryBlossomMusicForTree(const CherryBlossomTreeState()),
      SoundChannel.cherryStage1Music,
    );
    expect(
      cherryBlossomMusicForTree(
        const CherryBlossomTreeState(stageIndex: 3).normalized(),
      ),
      SoundChannel.cherryStage1Music,
    );
    expect(
      cherryBlossomMusicForTree(
        const CherryBlossomTreeState(stageIndex: 4).normalized(),
      ),
      SoundChannel.cherryStage2Music,
    );
    expect(
      cherryBlossomMusicForTree(
        const CherryBlossomTreeState(
          stageIndex: CherryBlossomStageCatalog.maxPlayableStage,
        ).normalized(),
      ),
      SoundChannel.cherryBalanceMusic,
    );
    expect(
      cherryBlossomMusicForTree(
        const CherryBlossomTreeState(
          stageIndex: CherryBlossomStageCatalog.finaleStage,
          prestigePath: CherryBlossomPrestigePath.peace,
        ).normalized(),
      ),
      SoundChannel.cherryPeaceMusic,
    );
    expect(
      cherryBlossomMusicForTree(
        const CherryBlossomTreeState(
          stageIndex: CherryBlossomStageCatalog.finaleStage,
          prestigePath: CherryBlossomPrestigePath.power,
        ).normalized(),
      ),
      SoundChannel.cherryPowerMusic,
    );
  });

  test('music unlock gates cherry tracks by progress', () {
    const lockedGarden = GardenState(pointsBalance: 0);
    expect(
      isMusicChannelUnlocked(
        channel: SoundChannel.cherryStage1Music,
        garden: lockedGarden,
        progressiveVisualsEnabled: true,
        miniGamesEnabled: false,
      ),
      isFalse,
    );

    final garden = GardenState(
      pointsBalance: 0,
      cherryBlossomTreeUnlocked: true,
      cherryBlossomTree: const CherryBlossomTreeState(
        stageIndex: 5,
        highestStageUnlocked: 5,
      ).normalized(),
    );

    expect(
      isMusicChannelUnlocked(
        channel: SoundChannel.cherryStage1Music,
        garden: garden,
        progressiveVisualsEnabled: true,
        miniGamesEnabled: false,
      ),
      isTrue,
    );
    expect(
      isMusicChannelUnlocked(
        channel: SoundChannel.cherryStage2Music,
        garden: garden,
        progressiveVisualsEnabled: true,
        miniGamesEnabled: false,
      ),
      isTrue,
    );
    expect(
      isMusicChannelUnlocked(
        channel: SoundChannel.cherryBalanceMusic,
        garden: garden,
        progressiveVisualsEnabled: true,
        miniGamesEnabled: false,
      ),
      isFalse,
    );
    expect(
      isMusicChannelUnlocked(
        channel: SoundChannel.breathBackground,
        garden: garden,
        progressiveVisualsEnabled: true,
        miniGamesEnabled: false,
      ),
      isFalse,
    );
    expect(
      isMusicChannelUnlocked(
        channel: SoundChannel.breathBackground,
        garden: garden,
        progressiveVisualsEnabled: true,
        miniGamesEnabled: true,
      ),
      isTrue,
    );
  });
}
