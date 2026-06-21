import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/providers/zen_garden_shop_provider.dart';
import 'package:focusNexus/progressive_visuals/decor_catalog.dart';
import 'package:focusNexus/progressive_visuals/garden_engine.dart';
import 'package:focusNexus/progressive_visuals/garden_op_result.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';

class ZenGardenShopSheet extends ConsumerStatefulWidget {
  const ZenGardenShopSheet({
    super.key,
    required this.textStyle,
    required this.primary,
    required this.garden,
    required this.engine,
    required this.onPurchased,
    this.onUserMessage,
  });

  final TextStyle textStyle;
  final Color primary;
  final GardenState garden;
  final ProgressiveGardenEngine engine;
  final void Function(GardenOpResult r) onPurchased;
  final void Function(String message)? onUserMessage;

  @override
  ConsumerState<ZenGardenShopSheet> createState() => _ZenGardenShopSheetState();
}

class _ZenGardenShopSheetState extends ConsumerState<ZenGardenShopSheet> {
  late final Map<String, TextEditingController> _qtyControllers;
  final ValueNotifier<int> _qtyRevision = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _qtyControllers = {
      for (final e in decorCatalogFor(VisualThemeId.zenGarden))
        e.id: TextEditingController(text: '1'),
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncCartWallet());
  }

  void _syncCartWallet() {
    final wallet = ref.read(pointsBalanceProvider).valueOrNull;
    if (wallet == null) return;
    final cart = ref.read(zenGardenShopCartProvider(widget.garden));
    if (cart.pointsBalance == wallet) return;
    ref.read(zenGardenShopCartProvider(widget.garden).notifier).setGarden(
          cart.copyWith(pointsBalance: wallet),
        );
  }

  @override
  void dispose() {
    _qtyRevision.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int _parsedQty(String kind) {
    final raw = _qtyControllers[kind]?.text ?? '';
    final v = int.tryParse(raw.trim());
    if (v == null || v < 1) return 1;
    return v.clamp(1, 999);
  }

  void _bumpQty(String kind, int delta) {
    final q = (_parsedQty(kind) + delta).clamp(1, 999);
    _qtyControllers[kind]!.text = '$q';
    _qtyRevision.value++;
  }

  void _buy(DecorCatalogEntry entry) {
    final q = _parsedQty(entry.id);
    final wallet = ref.read(pointsBalanceProvider).valueOrNull;
    final cart = ref.read(zenGardenShopCartProvider(widget.garden));
    final working = wallet != null
        ? cart.copyWith(pointsBalance: wallet)
        : cart;
    final r = widget.engine.purchaseDecor(working, entry.id, quantity: q);
    if (r.isSuccess && r.state != null) {
      ref.read(zenGardenShopCartProvider(widget.garden).notifier).setGarden(
            r.state!,
          );
    }
    widget.onPurchased(r);
    if (r.isSuccess) {
      widget.onUserMessage?.call('Bought $q× ${entry.label}.');
    } else {
      widget.onUserMessage?.call(r.error ?? 'Could not buy');
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = decorCatalogFor(VisualThemeId.zenGarden);
    ref.watch(pointsBalanceProvider);
    final cartGarden = ref.watch(zenGardenShopCartProvider(widget.garden));
    final balance =
        ref.watch(pointsBalanceProvider).valueOrNull ?? cartGarden.pointsBalance;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return ValueListenableBuilder<int>(
      valueListenable: _qtyRevision,
      builder: (context, _, __) => Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) {
          return Material(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'Decoration shop',
                    style: widget.textStyle.copyWith(fontSize: 18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Balance: $balance pts',
                    style: widget.textStyle.copyWith(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                    itemCount: entries.length,
                    itemBuilder: (ctx, i) {
                      final e = entries[i];
                      final q = _parsedQty(e.id);
                      final total = e.pointCost * q;
                      final canBuy = balance >= total;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(e.icon, color: widget.primary, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(e.label, style: widget.textStyle),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${e.pointCost} pts each · Total: $total pts',
                                          style: widget.textStyle.copyWith(
                                            fontWeight: FontWeight.normal,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Fewer',
                                    onPressed: q > 1 ? () => _bumpQty(e.id, -1) : null,
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _qtyControllers[e.id],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        labelText: 'Qty',
                                      ),
                                      onChanged: (_) => _qtyRevision.value++,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'More',
                                    onPressed: q < 999 ? () => _bumpQty(e.id, 1) : null,
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: canBuy ? () => _buy(e) : null,
                                    child: const Text('Buy'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
    );
  }
}
