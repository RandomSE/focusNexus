import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:focusNexus/providers/zen_garden_session_provider.dart';

import 'package:focusNexus/providers/zen_garden_session_state.dart';

import 'package:focusNexus/progressive_visuals/decor_catalog.dart';

import 'package:focusNexus/progressive_visuals/garden_engine.dart';

import 'package:focusNexus/progressive_visuals/garden_op_result.dart';

import 'package:focusNexus/progressive_visuals/garden_valuation.dart';



import 'zen_garden_stage_labels.dart';

import 'zen_inventory_stacks.dart';



typedef ZenGardenInventoryPatch = void Function(

  ZenGardenSessionState Function(ZenGardenSessionState) transform,

);



typedef ZenGardenInventoryOpApply = void Function(

  GardenOpResult result, {

  String? announce,

  int? pointsEarned,

});



void showZenGardenInventorySheet({

  required BuildContext context,

  required TextStyle textStyle,

  required ProgressiveGardenEngine engine,

  required ZenGardenInventoryOpApply onApplyInventoryOp,

  required VoidCallback onExitSelectionForPlacement,

  required ZenGardenInventoryPatch onPatch,

  required VoidCallback onRefresh,

  required VoidCallback onClearPlacementPrompts,

}) {

  showModalBottomSheet<void>(

    context: context,

    showDragHandle: true,

    isScrollControlled: true,

    builder: (sheetCtx) {

      return Consumer(

        builder: (sheetCtx, ref, _) {

          final ui = ref.watch(zenGardenSessionProvider);

          final garden = ui.garden;

          final placingDecorInventoryId = ui.placingDecorInventoryId;

          final placingPlantInventoryId = ui.placingPlantInventoryId;

          void refreshSheet() => onRefresh();



          final plantStacks = groupPlantInventory(garden.plantInventory);

          final decorStacks = groupDecorInventory(garden.decorInventory);

          final isEmpty = plantStacks.isEmpty && decorStacks.isEmpty;

          final subtitleStyle = textStyle.copyWith(

            fontWeight: FontWeight.normal,

            fontSize: (textStyle.fontSize ?? 14) * 0.92,

          );



          return SafeArea(

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                Padding(

                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),

                  child: Row(

                    children: [

                      Expanded(

                        child: Text(

                          'Inventory',

                          style: textStyle.copyWith(fontSize: 18),

                        ),

                      ),

                      IconButton(

                        tooltip: 'Close',

                        onPressed: () => Navigator.pop(sheetCtx),

                        icon: const Icon(Icons.close),

                      ),

                    ],

                  ),

                ),

                if (isEmpty)

                  Padding(

                    padding: const EdgeInsets.all(24),

                    child: Text(

                      'Inventory is empty. Buy decorations from the shop or move items here from the garden.',

                      style: textStyle.copyWith(fontWeight: FontWeight.normal),

                      textAlign: TextAlign.center,

                    ),

                  )

                else

                  Flexible(

                    child: ListView(

                      shrinkWrap: true,

                      padding: const EdgeInsets.all(16),

                      children: [

                        if (plantStacks.isNotEmpty) ...[

                          Text('Plants', style: textStyle.copyWith(fontSize: 15)),

                          const SizedBox(height: 8),

                          ...plantStacks.map((stack) {

                            final p = stack.representative;

                            final sell = plantSellValue(p);

                            final countLabel =

                                stack.count > 1 ? ' ×${stack.count}' : '';

                            return _ZenGardenInventoryEntry(

                              leading: Badge(

                                isLabelVisible: stack.count > 1,

                                label: Text('${stack.count}'),

                                child: const Icon(Icons.grass_outlined),

                              ),

                              title:

                                  'Plant · ${zenGardenStageLabel(p.stageIndex)}$countLabel',

                              subtitle: 'Sell: $sell pts each',

                              titleStyle: textStyle,

                              subtitleStyle: subtitleStyle,

                              actions: [

                                FilledButton.tonal(

                                  onPressed: () {

                                    Navigator.pop(sheetCtx);

                                    onExitSelectionForPlacement();

                                    onPatch(

                                      (s) => s.copyWith(

                                        placingPlant: true,

                                        placingPlantInventoryId:

                                            stack.placeOrSellItemId,

                                        clearPlacingDecorInventoryId: true,

                                      ),

                                    );

                                  },

                                  child: const Text('Place'),

                                ),

                                OutlinedButton(

                                  onPressed: () {

                                    final itemId = stack.placeOrSellItemId;

                                    onApplyInventoryOp(

                                      engine.sellPlantInventoryItem(

                                        garden,

                                        itemId,

                                      ),

                                      announce: 'Sold plant for $sell points.',

                                      pointsEarned: sell,

                                    );

                                    if (placingPlantInventoryId == itemId) {

                                      final stackKey =

                                          plantInventoryStackKey(p);

                                      final nextId =

                                          nextPlantInventoryIdInStack(

                                        garden.plantInventory,

                                        stackKey,

                                      );

                                      onPatch(

                                        (s) => s.copyWith(

                                          placingPlantInventoryId: nextId,

                                          placingPlant: nextId != null,

                                          clearPlacingPlantInventoryId:

                                              nextId == null,

                                        ),

                                      );

                                    }

                                    refreshSheet();

                                    if (garden.plantInventory.isEmpty &&

                                        garden.decorInventory.isEmpty) {

                                      Navigator.pop(sheetCtx);

                                    }

                                  },

                                  child: const Text('Sell 1'),

                                ),

                              ],

                            );

                          }),

                          const SizedBox(height: 16),

                        ],

                        if (decorStacks.isNotEmpty) ...[

                          Text('Decorations', style: textStyle.copyWith(fontSize: 15)),

                          const SizedBox(height: 8),

                          ...decorStacks.map((stack) {

                            final d = stack.representative;

                            final meta = decorEntryByKind(d.kind);

                            final sell = decorSellValue(d);

                            final stackKey = decorInventoryStackKey(d);

                            final placingThis =

                                placingDecorInventoryId != null &&

                                stack.itemIds.contains(placingDecorInventoryId);

                            final countLabel =

                                stack.count > 1 ? ' ×${stack.count}' : '';

                            return _ZenGardenInventoryEntry(

                              leading: Badge(

                                isLabelVisible: stack.count > 1,

                                label: Text('${stack.count}'),

                                child: Icon(

                                  meta?.icon ?? Icons.inventory_2_outlined,

                                ),

                              ),

                              title: '${meta?.label ?? d.kind}$countLabel',

                              subtitle:

                                  'Stage ${d.stageIndex + 1} · Sell: $sell pts each'

                                  '${d.mutation != null ? ' · variant' : ''}',

                              titleStyle: textStyle,

                              subtitleStyle: subtitleStyle,

                              actions: [

                                FilledButton.tonal(

                                  onPressed: () {

                                    Navigator.pop(sheetCtx);

                                    onExitSelectionForPlacement();

                                    onPatch(

                                      (s) => s.copyWith(

                                        placingDecorInventoryId:

                                            stack.sellItemId,

                                        placingPlant: false,

                                        clearPlacingPlantInventoryId: true,

                                      ),

                                    );

                                  },

                                  child: Text(placingThis ? 'Placing…' : 'Place'),

                                ),

                                if (placingThis)

                                  TextButton(

                                    onPressed: () {

                                      onPatch(

                                        (s) => s.copyWith(

                                          clearPlacingDecorInventoryId: true,

                                        ),

                                      );

                                      onClearPlacementPrompts();

                                      refreshSheet();

                                    },

                                    child: const Text('Deselect'),

                                  ),

                                OutlinedButton(

                                  onPressed: () {

                                    final itemId = stack.sellItemId;

                                    onApplyInventoryOp(

                                      engine.sellDecorInventoryItem(

                                        garden,

                                        itemId,

                                      ),

                                      announce:

                                          'Sold decoration for $sell points.',

                                      pointsEarned: sell,

                                    );

                                    if (placingDecorInventoryId != null &&

                                        stack.itemIds.contains(

                                          placingDecorInventoryId,

                                        )) {

                                      final nextId =

                                          nextDecorInventoryIdInStack(

                                        garden.decorInventory,

                                        stackKey,

                                      );

                                      onPatch(

                                        (s) => s.copyWith(

                                          placingDecorInventoryId: nextId,

                                          clearPlacingDecorInventoryId:

                                              nextId == null,

                                        ),

                                      );

                                    }

                                    refreshSheet();

                                    if (garden.plantInventory.isEmpty &&

                                        garden.decorInventory.isEmpty) {

                                      Navigator.pop(sheetCtx);

                                    }

                                  },

                                  child: const Text('Sell 1'),

                                ),

                              ],

                            );

                          }),

                        ],

                      ],

                    ),

                  ),

              ],

            ),

          );

        },

      );

    },

  );

}



/// Avoids [ListTile] trailing overflow when action buttons need more width.

class _ZenGardenInventoryEntry extends StatelessWidget {

  const _ZenGardenInventoryEntry({

    required this.leading,

    required this.title,

    required this.subtitle,

    required this.titleStyle,

    required this.subtitleStyle,

    required this.actions,

  });



  final Widget leading;

  final String title;

  final String subtitle;

  final TextStyle titleStyle;

  final TextStyle subtitleStyle;

  final List<Widget> actions;



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 12),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          Row(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              leading,

              const SizedBox(width: 16),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(title, style: titleStyle),

                    const SizedBox(height: 2),

                    Text(subtitle, style: subtitleStyle),

                  ],

                ),

              ),

            ],

          ),

          const SizedBox(height: 8),

          Wrap(

            spacing: 8,

            runSpacing: 8,

            alignment: WrapAlignment.end,

            children: actions,

          ),

        ],

      ),

    );

  }

}


