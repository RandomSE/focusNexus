import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/repositories/custom_affirmation_pack_repository.dart';
import 'package:focusNexus/services/custom_affirmation_pack.dart';
import 'package:focusNexus/services/phrase_build_set_picks.dart';
import 'package:focusNexus/services/phrase_queue_positions.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/form_field_metrics.dart';
import 'package:focusNexus/utils/notifier.dart';
import 'package:focusNexus/widgets/ambient_section_chip.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';

/// Editor for one [PhrasePackKind] (queue, positions, sets, presets).
class PhrasePackScreen extends ConsumerStatefulWidget {
  const PhrasePackScreen({super.key, required this.kind});

  final PhrasePackKind kind;

  @override
  ConsumerState<PhrasePackScreen> createState() => _PhrasePackScreenState();
}

/// Back-compat entry; opens Daily Affirmations pack.
class CustomAffirmationPackScreen extends PhrasePackScreen {
  const CustomAffirmationPackScreen({super.key})
      : super(kind: PhrasePackKind.dailyAffirmation);
}

class _PhrasePackScreenState extends ConsumerState<PhrasePackScreen> {
  PhrasePackRepository get _repo =>
      ref.read(appRepositoriesProvider).phrasePacks;

  PhrasePackKind get _kind => widget.kind;

  PhrasePackData _pack = PhrasePackData.empty;
  bool _loading = true;
  final _addController = TextEditingController();
  final _addPositionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_load());
    });
  }

  @override
  void dispose() {
    _addController.dispose();
    _addPositionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final pack = await _repo.ensureSeeded(_kind);
    if (!mounted) return;
    setState(() {
      _pack = pack;
      _loading = false;
      _syncAddPositionDefault();
    });
  }

  void _syncAddPositionDefault() {
    final last = PhraseQueuePositions.maxInsertPosition(
      _pack.effectiveQueue.length,
    );
    _addPositionController.text = '$last';
  }

  Future<void> _refreshAffirmationsIfNeeded() async {
    if (_kind != PhrasePackKind.dailyAffirmation) return;
    final settings = ref.read(appSettingsProvider).snapshot;
    if (!settings.dailyAffirmations) return;
    await GoalNotifier.refreshDailyAffirmationSchedules(forceReschedule: true);
  }

  void _snack(String message, TextStyle textStyle) {
    CommonUtils.showSnackBar(context, message, textStyle, 3500, 16);
  }

  String _errorMessage(String? code) {
    switch (code) {
      case PhrasePackMutationResult.insufficientPoints:
        return 'Not enough points (need ${PhrasePackRules.pointCost}).';
      case PhrasePackMutationResult.emptyText:
        return 'Message cannot be empty.';
      case PhrasePackMutationResult.minOne:
        return 'Keep at least one message in the queue.';
      case PhrasePackMutationResult.notFound:
        return 'Message not found.';
      case PhrasePackMutationResult.emptyName:
        return 'Preset name cannot be empty.';
      default:
        return 'Could not update pack.';
    }
  }

  Future<void> _applyResult(
    PhrasePackMutationResult result,
    TextStyle textStyle, {
    String? successMessage,
  }) async {
    if (!result.ok) {
      _snack(_errorMessage(result.error), textStyle);
      return;
    }
    ref.invalidate(pointsBalanceProvider);
    setState(() {
      _pack = result.data ?? _pack;
      _syncAddPositionDefault();
    });
    if (successMessage != null && successMessage.isNotEmpty) {
      _snack(successMessage, textStyle);
    }
    await _refreshAffirmationsIfNeeded();
  }

  void _disposeControllerLater(TextEditingController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
  }

  Widget _outlinedAction({
    required String label,
    required VoidCallback onPressed,
    required TextStyle textStyle,
    required Color primary,
    required Color secondary,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        backgroundColor: secondary,
        side: BorderSide(color: primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      child: Text(label, style: textStyle.copyWith(color: primary)),
    );
  }

  int _parsePosition(String raw, int queueLength, {required bool forInsert}) {
    final max = forInsert
        ? PhraseQueuePositions.maxInsertPosition(queueLength)
        : PhraseQueuePositions.maxInsertPosition(queueLength - 1);
    final parsed = int.tryParse(raw.trim());
    if (parsed == null) return max;
    return PhraseQueuePositions.clampInsert(
      parsed,
      forInsert ? queueLength : queueLength - 1,
    );
  }

  Future<void> _addMessage(TextStyle textStyle) async {
    final queueLen = _pack.effectiveQueue.length;
    final pos = _parsePosition(
      _addPositionController.text,
      queueLen,
      forInsert: true,
    );
    final result = await _repo.tryAddMessage(
      _kind,
      _addController.text,
      position1Based: pos,
    );
    if (!mounted) return;
    if (result.ok) {
      _addController.clear();
    }
    await _applyResult(
      result,
      textStyle,
      successMessage: 'Message added to queue.',
    );
  }

  Future<void> _editSlot(
    int slotIndex,
    TextStyle textStyle,
    Color primary,
    Color secondary,
  ) async {
    final queue = _pack.effectiveQueue;
    if (slotIndex < 0 || slotIndex >= queue.length) return;
    final id = queue[slotIndex];
    final msg = _pack.messageById(id);
    if (msg == null) return;

    final textController = TextEditingController(text: msg.text);
    final positionController = TextEditingController(text: '${slotIndex + 1}');
    final maxMove = queue.length;
    final hint = PhraseQueuePositions.hintForSize(maxMove);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: secondary,
          title: Text('Edit message', style: textStyle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CommonUtils.buildTextFormField(
                  textController,
                  'Message (${PhrasePackRules.pointCost} pts if changed)',
                  textStyle,
                  secondary,
                  true,
                  null,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 12),
                _PositionField(
                  controller: positionController,
                  label: 'Position in queue',
                  hint: hint,
                  textStyle: textStyle,
                  fillColor: secondary,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: textStyle),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Save', style: textStyle.copyWith(color: primary)),
            ),
          ],
        );
      },
    );
    final nextText = textController.text;
    final posRaw = positionController.text;
    if (saved != true) {
      _disposeControllerLater(textController);
      _disposeControllerLater(positionController);
      return;
    }
    _disposeControllerLater(textController);
    _disposeControllerLater(positionController);
    if (!mounted) return;

    final pos = _parsePosition(posRaw, queue.length, forInsert: false);
    final result = await _repo.tryUpdateQueueSlot(
      _kind,
      slotIndex: slotIndex,
      rawText: nextText,
      position1Based: pos,
    );
    if (!mounted) return;
    await _applyResult(
      result,
      textStyle,
      successMessage: 'Message updated.',
    );
  }

  Future<void> _setMode(PhrasePlaybackMode mode, TextStyle textStyle) async {
    await _repo.writeMode(_kind, mode);
    final pack = await _repo.read(_kind);
    if (!mounted) return;
    setState(() => _pack = pack);
    await _refreshAffirmationsIfNeeded();
  }

  Future<void> _reorderQueue(int oldIndex, int newIndex) async {
    await _repo.reorderQueue(_kind, oldIndex, newIndex);
    final pack = await _repo.read(_kind);
    if (!mounted) return;
    setState(() {
      _pack = pack;
      _syncAddPositionDefault();
    });
    await _refreshAffirmationsIfNeeded();
  }

  Future<void> _moveQueueSlot(
    int slotIndex,
    int position1Based,
    TextStyle textStyle,
  ) async {
    final result = await _repo.tryUpdateQueueSlot(
      _kind,
      slotIndex: slotIndex,
      position1Based: position1Based,
    );
    if (!mounted) return;
    await _applyResult(result, textStyle);
  }

  Future<void> _openBuildSet(
    TextStyle textStyle,
    Color primary,
    Color secondary,
  ) async {
    final originOptions = <PhraseOrigin>[];
    if (_pack.hasBaselineMessages) originOptions.add(PhraseOrigin.baseline);
    if (_pack.hasCustomMessages) originOptions.add(PhraseOrigin.custom);
    if (originOptions.isEmpty) {
      _snack('No messages available to build a set.', textStyle);
      return;
    }

    var selectedOrigin = originOptions.first;
    var picks = <({String id, int position1Based})>[];
    final nameController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final pool = _pack.messagesOf(selectedOrigin);
            final buildingSize = picks.length;
            final maxPos = PhraseQueuePositions.maxInsertPosition(buildingSize);
            return AlertDialog(
              backgroundColor: secondary,
              title: Text('Build set', style: textStyle),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CommonUtils.buildText(
                        'Add Base and/or Custom messages. The same message can '
                        'be added more than once (each Add to set appends to the '
                        'end by default). Set a position per instance here, or '
                        'reorder later in Active queue. Save replaces the active '
                        'queue. Optionally name a preset.',
                        textStyle.copyWith(
                          fontWeight: FontWeight.normal,
                          fontSize: (textStyle.fontSize ?? 14) - 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<PhraseOrigin>(
                        key: ValueKey(selectedOrigin),
                        initialValue: selectedOrigin,
                        dropdownColor: secondary,
                        decoration: formInputDecoration(
                          label: 'Source',
                          textStyle: textStyle,
                          filled: true,
                          fillColor: secondary,
                        ),
                        items: [
                          for (final o in originOptions)
                            DropdownMenuItem(
                              value: o,
                              child: Text(
                                o.isBaseline ? 'Base' : 'Custom',
                                style: textStyle,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setLocal(() => selectedOrigin = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      CommonUtils.buildText(
                        'Building set size: $buildingSize. '
                        'Positions 1-$maxPos (last = $maxPos).',
                        textStyle.copyWith(
                          fontWeight: FontWeight.normal,
                          fontSize: (textStyle.fontSize ?? 14) - 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final msg in pool)
                        _BuildSetRow(
                          key: ValueKey(msg.id),
                          message: msg,
                          textStyle: textStyle,
                          primary: primary,
                          secondary: secondary,
                          instances: [
                            for (final i
                                in PhraseBuildSetPicks.indexesOf(picks, msg.id))
                              (
                                pickIndex: i,
                                position: picks[i].position1Based,
                              ),
                          ],
                          maxPosition: maxPos,
                          onAdd: () {
                            setLocal(() {
                              picks = PhraseBuildSetPicks.append(
                                picks: picks,
                                id: msg.id,
                              );
                            });
                          },
                          onRemove: (pickIndex) {
                            setLocal(() {
                              picks = PhraseBuildSetPicks.removeAt(
                                picks,
                                pickIndex,
                              );
                            });
                          },
                          onPosition: (pickIndex, pos) {
                            setLocal(() {
                              picks = PhraseBuildSetPicks.setPosition(
                                picks,
                                pickIndex,
                                pos,
                              );
                            });
                          },
                        ),
                      const SizedBox(height: 12),
                      CommonUtils.buildTextFormField(
                        nameController,
                        'Preset name (optional)',
                        textStyle,
                        secondary,
                        true,
                        null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancel', style: textStyle),
                ),
                TextButton(
                  onPressed:
                      picks.isEmpty ? null : () => Navigator.pop(ctx, true),
                  child: Text(
                    'Save set',
                    style: textStyle.copyWith(
                      color: picks.isEmpty
                          ? textStyle.color?.withValues(alpha: 0.4)
                          : primary,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    final presetName = nameController.text;
    _disposeControllerLater(nameController);
    if (saved != true || !mounted) return;

    final result = await _repo.tryBuildQueueFromPicks(_kind, picks);
    if (!mounted) return;
    await _applyResult(
      result,
      textStyle,
      successMessage: 'Active queue updated.',
    );
    if (!result.ok) return;
    final trimmed = presetName.trim();
    if (trimmed.isNotEmpty) {
      final presetResult = await _repo.trySavePreset(
        _kind,
        trimmed,
        queueOverride: result.data?.effectiveQueue,
      );
      if (!mounted) return;
      await _applyResult(
        presetResult,
        textStyle,
        successMessage: 'Preset "$trimmed" saved.',
      );
    }
  }

  Future<void> _saveCurrentAsPreset(
    TextStyle textStyle,
    Color primary,
    Color secondary,
  ) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: secondary,
        title: Text('Save preset', style: textStyle),
        content: CommonUtils.buildTextFormField(
          controller,
          'Preset name',
          textStyle,
          secondary,
          true,
          null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: textStyle),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Save', style: textStyle.copyWith(color: primary)),
          ),
        ],
      ),
    );
    final name = controller.text;
    _disposeControllerLater(controller);
    if (ok != true || !mounted) return;
    final result = await _repo.trySavePreset(_kind, name);
    if (!mounted) return;
    await _applyResult(
      result,
      textStyle,
      successMessage: 'Preset saved.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final pointsAsync = ref.watch(pointsBalanceProvider);

    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final textStyle = bundle.textStyle;
        final primary = bundle.primaryColor;
        final secondary = bundle.secondaryColor;
        final pointsLabel = pointsAsync.when(
          data: (p) => 'Points: $p',
          loading: () => 'Points: ...',
          error: (_, __) => 'Points: ?',
        );
        final queue = _pack.effectiveQueue;
        final insertMax = PhraseQueuePositions.maxInsertPosition(queue.length);

        return Scaffold(
          backgroundColor: secondary,
          appBar: AppBar(
            backgroundColor: secondary,
            foregroundColor: primary,
            title: Text(_kind.label, style: textStyle),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(child: Text(pointsLabel, style: textStyle)),
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    CommonUtils.buildText(
                      'Add or edit costs ${PhrasePackRules.pointCost} points. '
                      'Delete and reorder are free. Queue needs at least one '
                      'message. Max ${PhrasePackRules.maxTextLength} characters. '
                      'Off on Customization restores pristine built-ins; edits stay saved.',
                      textStyle.copyWith(
                        fontWeight: FontWeight.normal,
                        fontSize: (textStyle.fontSize ?? 14) - 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CommonUtils.buildText('Playback', textStyle),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AmbientSectionChip(
                          label: 'Sequence',
                          selected: _pack.mode == PhrasePlaybackMode.sequence,
                          onTap: () => unawaited(
                            _setMode(PhrasePlaybackMode.sequence, textStyle),
                          ),
                          primary: primary,
                          secondary: secondary,
                          textStyle: textStyle,
                        ),
                        AmbientSectionChip(
                          label: 'Random',
                          selected: _pack.mode == PhrasePlaybackMode.random,
                          onTap: () => unawaited(
                            _setMode(PhrasePlaybackMode.random, textStyle),
                          ),
                          primary: primary,
                          secondary: secondary,
                          textStyle: textStyle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CommonUtils.buildText('Add message', textStyle),
                    const SizedBox(height: 8),
                    CommonUtils.buildText(
                      'Queue has ${queue.length} message'
                      '${queue.length == 1 ? '' : 's'}. '
                      'Positions 1-$insertMax (default last = $insertMax).',
                      textStyle.copyWith(
                        fontWeight: FontWeight.normal,
                        fontSize: (textStyle.fontSize ?? 14) - 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CommonUtils.buildTextFormField(
                      _addController,
                      'New message',
                      textStyle,
                      secondary,
                      true,
                      null,
                      keyboardType: TextInputType.multiline,
                    ),
                    const SizedBox(height: 8),
                    _PositionField(
                      controller: _addPositionController,
                      label: 'Position',
                      hint: PhraseQueuePositions.hintForSize(insertMax),
                      textStyle: textStyle,
                      fillColor: secondary,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _outlinedAction(
                        label: 'Add (${PhrasePackRules.pointCost} pts)',
                        onPressed: () => unawaited(_addMessage(textStyle)),
                        textStyle: textStyle,
                        primary: primary,
                        secondary: secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _outlinedAction(
                          label: 'Build set',
                          onPressed: () => unawaited(
                            _openBuildSet(textStyle, primary, secondary),
                          ),
                          textStyle: textStyle,
                          primary: primary,
                          secondary: secondary,
                        ),
                        _outlinedAction(
                          label: 'Save preset',
                          onPressed: () => unawaited(
                            _saveCurrentAsPreset(
                              textStyle,
                              primary,
                              secondary,
                            ),
                          ),
                          textStyle: textStyle,
                          primary: primary,
                          secondary: secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CommonUtils.buildText('Active queue', textStyle),
                    const SizedBox(height: 8),
                    CommonUtils.buildText(
                      'Drag to reorder, or set a 1-based position on each '
                      'instance. Edit also lets you change the message text.',
                      textStyle.copyWith(
                        fontWeight: FontWeight.normal,
                        fontSize: (textStyle.fontSize ?? 14) - 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (queue.isEmpty)
                      CommonUtils.buildText(
                        'Queue is empty. Add a message or build a set.',
                        textStyle.copyWith(fontWeight: FontWeight.normal),
                      )
                    else
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        onReorderItem: (oldIndex, newIndex) {
                          unawaited(_reorderQueue(oldIndex, newIndex));
                        },
                        children: [
                          for (var i = 0; i < queue.length; i++)
                            _QueueTile(
                              key: ValueKey('queue-slot-$i-${queue[i]}'),
                              index: i,
                              queueLength: queue.length,
                              message: _pack.messageById(queue[i]),
                              textStyle: textStyle,
                              primary: primary,
                              secondary: secondary,
                              onEdit: () => unawaited(
                                _editSlot(i, textStyle, primary, secondary),
                              ),
                              onDelete: () async {
                                final result =
                                    await _repo.tryRemoveQueueSlot(_kind, i);
                                if (!mounted) return;
                                await _applyResult(
                                  result,
                                  textStyle,
                                  successMessage: 'Removed from queue.',
                                );
                              },
                              onPositionCommit: (pos) => unawaited(
                                _moveQueueSlot(i, pos, textStyle),
                              ),
                            ),
                        ],
                      ),
                    if (_pack.presets.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      CommonUtils.buildText('Presets', textStyle),
                      const SizedBox(height: 8),
                      for (final preset in _pack.presets)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(preset.name, style: textStyle),
                          subtitle: Text(
                            '${preset.queueIds.length} messages',
                            style: textStyle.copyWith(
                              fontWeight: FontWeight.normal,
                              fontSize: (textStyle.fontSize ?? 14) - 2,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  final result = await _repo.tryApplyPreset(
                                    _kind,
                                    preset.id,
                                  );
                                  if (!mounted) return;
                                  await _applyResult(
                                    result,
                                    textStyle,
                                    successMessage:
                                        'Preset "${preset.name}" applied.',
                                  );
                                },
                                child: Text(
                                  'Apply',
                                  style: textStyle.copyWith(color: primary),
                                ),
                              ),
                              IconButton(
                                icon:
                                    Icon(Icons.delete_outline, color: primary),
                                onPressed: () async {
                                  final result = await _repo.tryDeletePreset(
                                    _kind,
                                    preset.id,
                                  );
                                  if (!mounted) return;
                                  await _applyResult(
                                    result,
                                    textStyle,
                                    successMessage: 'Preset deleted.',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _PositionField extends StatelessWidget {
  const _PositionField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.textStyle,
    required this.fillColor,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextStyle textStyle;
  final Color fillColor;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return labeledFormField(
      label: label,
      textStyle: textStyle,
      field: TextFormField(
        controller: controller,
        style: textStyle,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        decoration: formInputDecoration(
          label: label,
          textStyle: textStyle,
          filled: true,
          fillColor: fillColor,
        ).copyWith(
          hintText: hint,
          hintStyle: textStyle.copyWith(
            fontWeight: FontWeight.normal,
            fontSize: (textStyle.fontSize ?? 14) - 2,
          ),
        ),
      ),
    );
  }
}

class _QueueTile extends StatefulWidget {
  const _QueueTile({
    super.key,
    required this.index,
    required this.queueLength,
    required this.message,
    required this.textStyle,
    required this.primary,
    required this.secondary,
    required this.onEdit,
    required this.onDelete,
    required this.onPositionCommit,
  });

  final int index;
  final int queueLength;
  final PhraseMessage? message;
  final TextStyle textStyle;
  final Color primary;
  final Color secondary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<int> onPositionCommit;

  @override
  State<_QueueTile> createState() => _QueueTileState();
}

class _QueueTileState extends State<_QueueTile> {
  late final TextEditingController _posController;

  @override
  void initState() {
    super.initState();
    _posController = TextEditingController(text: '${widget.index + 1}');
  }

  @override
  void didUpdateWidget(covariant _QueueTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = '${widget.index + 1}';
    if (oldWidget.index != widget.index && _posController.text != next) {
      _posController.text = next;
    }
  }

  @override
  void dispose() {
    _posController.dispose();
    super.dispose();
  }

  void _commitPosition() {
    final parsed = int.tryParse(_posController.text.trim());
    final max = widget.queueLength;
    final pos = parsed == null
        ? widget.index + 1
        : PhraseQueuePositions.clampInsert(parsed, max - 1);
    if (_posController.text != '$pos') {
      _posController.text = '$pos';
    }
    if (pos == widget.index + 1) return;
    widget.onPositionCommit(pos);
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.message?.text ?? '(missing)';
    final origin =
        widget.message?.origin.isBaseline == true ? 'Base' : 'Custom';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ReorderableDragStartListener(
        index: widget.index,
        child: Icon(Icons.drag_handle, color: widget.primary),
      ),
      title: Text(
        text,
        style: widget.textStyle.copyWith(fontWeight: FontWeight.normal),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            origin,
            style: widget.textStyle.copyWith(
              fontWeight: FontWeight.normal,
              fontSize: (widget.textStyle.fontSize ?? 14) - 2,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 96,
            child: TextFormField(
              controller: _posController,
              style: widget.textStyle,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              onEditingComplete: _commitPosition,
              onFieldSubmitted: (_) => _commitPosition(),
              decoration: formInputDecoration(
                label: 'Pos',
                textStyle: widget.textStyle,
                filled: true,
                fillColor: widget.secondary,
              ).copyWith(
                isDense: true,
                hintText: PhraseQueuePositions.hintForSize(widget.queueLength),
                hintStyle: widget.textStyle.copyWith(
                  fontWeight: FontWeight.normal,
                  fontSize: (widget.textStyle.fontSize ?? 14) - 2,
                ),
              ),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, color: widget.primary),
            onPressed: widget.onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: widget.primary),
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}

class _BuildSetRow extends StatelessWidget {
  const _BuildSetRow({
    super.key,
    required this.message,
    required this.textStyle,
    required this.primary,
    required this.secondary,
    required this.instances,
    required this.maxPosition,
    required this.onAdd,
    required this.onRemove,
    required this.onPosition,
  });

  final PhraseMessage message;
  final TextStyle textStyle;
  final Color primary;
  final Color secondary;
  final List<({int pickIndex, int position})> instances;
  final int maxPosition;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int pickIndex, int position) onPosition;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            message.text,
            style: textStyle.copyWith(fontWeight: FontWeight.normal),
          ),
          subtitle: Text(
            instances.isEmpty
                ? 'Not in set'
                : '${instances.length} in set',
            style: textStyle.copyWith(
              fontWeight: FontWeight.normal,
              fontSize: (textStyle.fontSize ?? 14) - 2,
            ),
          ),
          trailing: TextButton(
            onPressed: onAdd,
            child: Text(
              'Add to set',
              style: textStyle.copyWith(color: primary),
            ),
          ),
        ),
        for (var n = 0; n < instances.length; n++)
          _BuildSetInstanceRow(
            key: ValueKey('pick-${instances[n].pickIndex}'),
            instanceNumber: n + 1,
            position: instances[n].position,
            maxPosition: maxPosition,
            textStyle: textStyle,
            primary: primary,
            secondary: secondary,
            onRemove: () => onRemove(instances[n].pickIndex),
            onPosition: (pos) => onPosition(instances[n].pickIndex, pos),
          ),
      ],
    );
  }
}

class _BuildSetInstanceRow extends StatefulWidget {
  const _BuildSetInstanceRow({
    super.key,
    required this.instanceNumber,
    required this.position,
    required this.maxPosition,
    required this.textStyle,
    required this.primary,
    required this.secondary,
    required this.onRemove,
    required this.onPosition,
  });

  final int instanceNumber;
  final int position;
  final int maxPosition;
  final TextStyle textStyle;
  final Color primary;
  final Color secondary;
  final VoidCallback onRemove;
  final ValueChanged<int> onPosition;

  @override
  State<_BuildSetInstanceRow> createState() => _BuildSetInstanceRowState();
}

class _BuildSetInstanceRowState extends State<_BuildSetInstanceRow> {
  late final TextEditingController _posController;

  @override
  void initState() {
    super.initState();
    _posController = TextEditingController(text: '${widget.position}');
  }

  @override
  void didUpdateWidget(covariant _BuildSetInstanceRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position &&
        _posController.text != '${widget.position}') {
      _posController.text = '${widget.position}';
    }
  }

  @override
  void dispose() {
    _posController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _PositionField(
              controller: _posController,
              label: 'Instance ${widget.instanceNumber} position',
              hint: PhraseQueuePositions.hintForSize(widget.maxPosition),
              textStyle: widget.textStyle,
              fillColor: widget.secondary,
              onChanged: (value) {
                final parsed = int.tryParse(value.trim());
                if (parsed != null) widget.onPosition(parsed);
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.remove_circle_outline, color: widget.primary),
            tooltip: 'Remove instance',
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}
