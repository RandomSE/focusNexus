import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/app/app_routes.dart';
import 'package:focusNexus/mini_games/firefly_jar/firefly_jar_constants.dart';
import 'package:focusNexus/mini_games/mini_game_definition.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/mini_game_catalog_provider.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/theme_styles.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';

/// Empty-state copy when the production catalog has no games.
const miniGamesHubEmptyMessage = 'No mini-games available yet.';

/// Portrait hub thumbnail aspect (width : height).
const miniGamesHubImageAspectRatio = 9 / 16;

/// Hub shortcut label for the most recently played game.
String miniGamesLastPlayedButtonLabel(String title) => 'Last played: $title';

class MiniGamesScreen extends ConsumerStatefulWidget {
  const MiniGamesScreen({super.key});

  @override
  ConsumerState<MiniGamesScreen> createState() => _MiniGamesScreenState();
}

class _MiniGamesScreenState extends ConsumerState<MiniGamesScreen> {
  final Map<String, bool> _unlockedById = <String, bool>{};
  bool _busy = false;
  String _lastPlayedGameId = FireflyJarConstants.gameId;
  String _lastPlayedTitle = FireflyJarConstants.title;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadHubState());
  }

  Future<void> _reloadHubState() async {
    final catalog = ref.read(miniGameCatalogProvider);
    final repos = ref.read(appRepositoriesProvider);
    final next = <String, bool>{};
    for (final game in catalog) {
      if (game.isFreeUnlock) {
        await repos.miniGames.ensureWelcomeUnlock(game);
        next[game.id] = true;
      } else {
        next[game.id] = await repos.miniGames.isUnlocked(game);
      }
    }
    final recentId = await repos.miniGames.mostRecentlyPlayedGameId();
    final resolvedId = recentId ?? FireflyJarConstants.gameId;
    var resolvedTitle = FireflyJarConstants.title;
    for (final game in catalog) {
      if (game.id == resolvedId) {
        resolvedTitle = game.title;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _unlockedById
        ..clear()
        ..addAll(next);
      _lastPlayedGameId = resolvedId;
      _lastPlayedTitle = resolvedTitle;
    });
  }

  bool _isUnlocked(MiniGameDefinition game) {
    return _unlockedById[game.id] ?? game.isFreeUnlock;
  }

  Future<void> _openLastPlayedLobby() async {
    if (_busy) return;
    await ref.pushRoute(context, MiniGameLobbyRoute(_lastPlayedGameId));
    await _reloadHubState();
  }

  Future<void> _onTileTap(
    MiniGameDefinition game,
    TextStyle textStyle,
    Color dialogBackground,
  ) async {
    if (_busy) return;
    if (_isUnlocked(game)) {
      await ref.pushRoute(context, MiniGameLobbyRoute(game.id));
      await _reloadHubState();
      return;
    }

    setState(() => _busy = true);
    try {
      final balance =
          ref.read(pointsBalanceProvider).valueOrNull ??
          await ref.read(appRepositoriesProvider).points.readBalance();
      if (!mounted) return;

      if (balance < game.unlockCost) {
        await CommonUtils.showInteractableAlertDialog(
          context,
          game.title,
          'This mini game costs ${game.unlockCost} points to unlock',
          textStyle,
          dialogBackground,
          barrierDismissible: true,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Okay', style: textStyle),
            ),
          ],
        );
        return;
      }

      final confirmed = await CommonUtils.showInteractableAlertDialog(
        context,
        'Unlock ${game.title}?',
        'Would you like to unlock this mini game for ${game.unlockCost} points?',
        textStyle,
        dialogBackground,
        barrierDismissible: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: textStyle),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Unlock', style: textStyle),
          ),
        ],
      );
      if (confirmed != true || !mounted) return;

      final points = ref.read(appRepositoriesProvider).points;
      final spent = await points.trySpend(game.unlockCost);
      if (!mounted) return;
      if (spent == null) {
        await CommonUtils.showInteractableAlertDialog(
          context,
          game.title,
          'This mini game costs ${game.unlockCost} points to unlock',
          textStyle,
          dialogBackground,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Okay', style: textStyle),
            ),
          ],
        );
        return;
      }
      await ref.read(appRepositoriesProvider).miniGames.unlock(game.id);
      ref.read(pointsBalanceProvider.notifier).adoptBalance(spent);
      await _reloadHubState();
      if (!mounted) return;
      await ref.pushRoute(context, MiniGameLobbyRoute(game.id));
      await _reloadHubState();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(miniGameCatalogProvider);

    return SettingsThemedBuilder(
      builder: (context, bundle) {
        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            backgroundColor: bundle.secondaryColor,
            appBar: AppBar(
              title: Text(
                'Mini-games',
                style: TextStyle(
                  backgroundColor: bundle.secondaryColor,
                  color: bundle.primaryColor,
                ),
              ),
              backgroundColor: bundle.secondaryColor,
              iconTheme: ThemeStyles.iconThemeFor(bundle.primaryColor),
            ),
            body: Container(
              color: bundle.secondaryColor,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: catalog.isEmpty
                  ? Center(
                      child: CommonUtils.buildText(
                        miniGamesHubEmptyMessage,
                        bundle.textStyle,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CommonUtils.buildTextButton(
                            _busy ? null : _openLastPlayedLobby,
                            miniGamesLastPlayedButtonLabel(_lastPlayedTitle),
                            bundle.textStyle,
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: catalog.length,
                            separatorBuilder: (_, __) => SizedBox(
                              height: 28,
                              child: Center(
                                child: Divider(
                                  height: 28,
                                  thickness: 1.5,
                                  color: bundle.primaryColor.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ),
                            ),
                            itemBuilder: (context, index) {
                              final game = catalog[index];
                              return _MiniGameHubTile(
                                game: game,
                                locked: !_isUnlocked(game),
                                textStyle: bundle.textStyle,
                                primaryColor: bundle.primaryColor,
                                secondaryColor: bundle.secondaryColor,
                                onTap: _busy
                                    ? null
                                    : () => _onTileTap(
                                        game,
                                        bundle.textStyle,
                                        bundle.secondaryColor,
                                      ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniGameHubTile extends StatelessWidget {
  const _MiniGameHubTile({
    required this.game,
    required this.locked,
    required this.textStyle,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onTap,
  });

  final MiniGameDefinition game;
  final bool locked;
  final TextStyle textStyle;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color.alphaBlend(
        primaryColor.withValues(alpha: 0.09),
        secondaryColor,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CommonUtils.buildText(game.title, textStyle),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: miniGamesHubImageAspectRatio,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _HubArt(
                        asset: game.hubImageAsset,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                      ),
                      if (locked)
                        const Positioned.fill(child: _HubLockChainsOverlay()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubArt extends StatelessWidget {
  const _HubArt({
    required this.asset,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String? asset;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    final path = asset;
    if (path == null || path.isEmpty) {
      return _placeholder();
    }
    return ColoredBox(
      color: Color.alphaBlend(
        primaryColor.withValues(alpha: 0.08),
        secondaryColor,
      ),
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: Color.alphaBlend(
        primaryColor.withValues(alpha: 0.16),
        secondaryColor,
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: primaryColor.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

/// Dimmed art with crossing chains and a centered padlock.
class _HubLockChainsOverlay extends StatelessWidget {
  const _HubLockChainsOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _LockChainsPainter(),
        child: const Center(
          child: Icon(
            Icons.lock_rounded,
            size: 56,
            color: Color(0xFFE8E0D0),
            shadows: [
              Shadow(
                color: Color(0xCC000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockChainsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = const Color(0x99000000);
    canvas.drawRect(Offset.zero & size, dim);

    final chain = Paint()
      ..color = const Color(0xFFC8B896)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3.0, size.shortestSide * 0.028)
      ..strokeCap = StrokeCap.round;

    final link = Paint()
      ..color = const Color(0xFFD4C4A0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.2, size.shortestSide * 0.02);

    void drawChain(Offset a, Offset b) {
      canvas.drawLine(a, b, chain);
      final dx = b.dx - a.dx;
      final dy = b.dy - a.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len < 1) return;
      final linkCount = math.max(5, (len / (size.shortestSide * 0.11)).round());
      final linkR = size.shortestSide * 0.035;
      for (var i = 1; i < linkCount; i++) {
        final t = i / linkCount;
        final c = Offset(a.dx + dx * t, a.dy + dy * t);
        final rect = Rect.fromCenter(
          center: c,
          width: linkR * 2.2,
          height: linkR * 1.4,
        );
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(math.atan2(dy, dx) + (i.isOdd ? 0.55 : -0.55));
        canvas.translate(-c.dx, -c.dy);
        canvas.drawOval(rect, link);
        canvas.restore();
      }
    }

    final inset = size.shortestSide * 0.08;
    drawChain(
      Offset(inset, inset),
      Offset(size.width - inset, size.height - inset),
    );
    drawChain(
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
