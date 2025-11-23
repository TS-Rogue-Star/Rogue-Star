// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2025: New system for allowing players to create custom markings ////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Major refactor to reduce lag, update style, and provide more options //
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import { useBackend, useLocalState } from '../../backend';
import { Box, Flex, Section } from '../../components';
import { Window } from '../../layouts';
import { normalizeHex } from '../../utils/color';
import {
  GENERIC_PART_KEY,
  resolveBodyPartLabel,
} from '../../utils/character-preview';
import type { DiffEntry } from '../../utils/character-preview';
import { PaintCanvas } from '../Canvas';
import {
  DirectionPreviewCanvas,
  MarkingInfoSection,
  PaintToolsSection,
  PhantomClickScheduler,
  SavingOverlay,
  SessionControls,
  ToolBootstrapReset,
  ToolBootstrapScheduler,
} from './components';
import {
  DOT_SIZE,
  PREVIEW_CANVAS_TARGET,
  PREVIEW_PIXEL_MIN,
  PREVIEW_PIXEL_MAX,
  PREVIEW_DIFF_CHUNK_SIZE,
  DEFAULT_GENERIC_REFERENCE_OPACITY,
  DEFAULT_BODY_PART_REFERENCE_OPACITY,
  ERASER_PREVIEW_COLOR,
  COLOR_PICKER_CUSTOM_SLOTS,
  PLACEHOLDER_TOOL,
} from './constants';
import { useBrushColorController, useSyncedDirectionState } from './hooks';
import { createPreviewSyncController } from './services/previewSync';
import { createStrokeDraftManager } from './services/strokeDrafts';
import { createExportController } from './services/exportHandlers';
import {
  createCanvasSamplingHelpers,
  generateClearStrokeKey,
  generateFillStrokeKey,
} from './utils/canvasSampling';
import { createPaintHandlers } from './utils/paintHandlers';
import {
  applyDraftDiffsToLayerMap,
  buildBodyPartLabelMap,
  buildDraftDiffIndex,
  buildDraftPixelLookup,
  buildFlagStateFromServer,
  buildLocalSessionKey,
  buildOverlayLayerParts,
  buildReferenceOpacityMapForDesigner,
  buildSessionDraftDiff,
  buildPartPaintPresenceMap,
  buildRenderedPreviewDirs,
  chunkDiffEntries,
  convertCompositeGridToUi,
  convertCompositeLayerMap,
  createLayerPriorityToggler,
  createPartReplacementToggler,
  createSavingHandlers,
  initializeColorPickerSlotsIfNeeded,
  resolveDirectionCanvasSources,
  resolveLayeringState,
  syncFlagStateIfNeeded,
  syncPreviewStateIfNeeded,
  updatePreviewStateFromPayload,
} from './utils';
import type {
  CustomMarkingDesignerData,
  PartRenderPriorityState,
  PartReplacementState,
  StrokeDraftState,
} from './types';
import { useDesignerUiState } from './state';
import CustomEyeIconAsset from '../../../../public/Icons/Rogue Star/eye 1.png';

export const CustomMarkingDesigner = (_props, context) => {
  const { act, data } = useBackend<CustomMarkingDesignerData>(context);
  const stateToken = data.state_token || 'session';
  const [tool, setTool] = useLocalState(
    context,
    `tool-${stateToken}`,
    PLACEHOLDER_TOOL
  );
  const [toolBootstrapScheduled, setToolBootstrapScheduled] = useLocalState(
    context,
    `toolBootstrapScheduled-${stateToken}`,
    false
  );
  const isPlaceholderTool = tool === PLACEHOLDER_TOOL;
  const activeTool = isPlaceholderTool ? null : tool;
  const {
    size,
    setSize,
    blendMode,
    setBlendMode,
    analogStrength,
    setAnalogStrength,
    draftSequence,
    setDraftSequence,
    allocateDraftSequence,
    canvasFlushToken,
    setCanvasFlushToken,
    pendingClose,
    setPendingClose,
    pendingSave,
    setPendingSave,
    pendingCloseMessage,
    setPendingCloseMessage,
    customColorSlots,
    setCustomColorSlots,
    colorPickerSlotsSignature,
    setColorPickerSlotsSignature,
    colorPickerSlotsLocked,
    setColorPickerSlotsLocked,
    referenceOpacityByPart,
    setReferenceOpacityByPart,
    previewState,
    setPreviewState,
    assetRevision,
    setAssetRevision,
    savingProgress,
    setSavingProgress,
  } = useDesignerUiState(context, stateToken);
  const [strokeDraftState] = useLocalState<StrokeDraftState>(
    context,
    'strokeDrafts',
    {}
  );
  const notifyAssetReady = () =>
    setAssetRevision((assetRevision + 1) % 1000000);
  const limited = !!data.limited;
  const canvasWidth = Math.max(1, data.width || DOT_SIZE);
  const canvasHeight = Math.max(1, data.height || DOT_SIZE);
  const layerParts = convertCompositeLayerMap(
    data.body_part_layers,
    canvasWidth,
    canvasHeight
  );
  const draftDiffIndex = buildDraftDiffIndex(strokeDraftState);
  const sessionToken = data.session_token || null;
  const phantomClickKey = `phantomClickScheduled-${stateToken}`;
  const [phantomClickScheduled, setPhantomClickScheduled] = useLocalState(
    context,
    phantomClickKey,
    false
  );
  const handleToolBootstrapReset = () => {
    const shouldResetTool =
      !tool || tool === 'brush' || tool === PLACEHOLDER_TOOL;
    if (!shouldResetTool) {
      if (phantomClickScheduled) {
        setPhantomClickScheduled(false);
      }
      return;
    }
    if (tool !== PLACEHOLDER_TOOL) {
      setTool(PLACEHOLDER_TOOL);
    }
    if (toolBootstrapScheduled) {
      setToolBootstrapScheduled(false);
    }
    if (phantomClickScheduled) {
      setPhantomClickScheduled(false);
    }
  };
  const { currentDirectionKey, setUiDirectionKey } = useSyncedDirectionState(
    context,
    sessionToken,
    data.active_dir_key
  );
  const pendingActiveDirDiffs =
    draftDiffIndex[currentDirectionKey] || ({} as Record<string, DiffEntry[]>);
  const layerPartsWithDrafts = applyDraftDiffsToLayerMap(
    layerParts,
    pendingActiveDirDiffs,
    canvasWidth,
    canvasHeight
  );
  const layerOrder = data.body_part_layer_order || null;
  const serverReplacementState = buildFlagStateFromServer(
    data.part_replacements
  );
  const replacementStateKey = `partReplacements-${stateToken}`;
  const [replacementState, setReplacementState] =
    useLocalState<PartReplacementState>(
      context,
      replacementStateKey,
      serverReplacementState
    );
  const shouldAdoptServerState =
    !replacementState.dirty &&
    replacementState.sourceHash !== serverReplacementState.sourceHash;
  const resolvedReplacementState = shouldAdoptServerState
    ? serverReplacementState
    : replacementState;
  if (shouldAdoptServerState) {
    syncFlagStateIfNeeded(
      serverReplacementState,
      replacementState,
      setReplacementState
    );
  }
  const resolvedPartReplacementMap = resolvedReplacementState.map;
  const replacementDependents = data.replacement_dependents || {};
  const serverPriorityState = buildFlagStateFromServer(
    data.part_render_priority
  );
  const priorityStateKey = `partRenderPriority-${stateToken}`;
  const [priorityState, setPriorityState] =
    useLocalState<PartRenderPriorityState>(
      context,
      priorityStateKey,
      serverPriorityState
    );
  const shouldAdoptPriorityState =
    !priorityState.dirty &&
    priorityState.sourceHash !== serverPriorityState.sourceHash;
  const resolvedPriorityState = shouldAdoptPriorityState
    ? serverPriorityState
    : priorityState;
  if (shouldAdoptPriorityState) {
    syncFlagStateIfNeeded(serverPriorityState, priorityState, setPriorityState);
  }
  const resolvedPartPriorityMap = resolvedPriorityState.map;
  const uiLocked = !!data.ui_locked;
  const serverActivePartKey = data.active_body_part || GENERIC_PART_KEY;
  const activePartStateKey = `activeBodyPart-${sessionToken || 'session'}`;
  const [activePartKey, setActivePartKey] = useLocalState(
    context,
    activePartStateKey,
    serverActivePartKey
  );
  const bodyPartLabelMap = buildBodyPartLabelMap(data.body_parts);
  const activePartLabel = resolveBodyPartLabel(activePartKey, bodyPartLabelMap);
  const directionLabelMap = new Map(
    data.directions.map((dir) => [dir.dir, dir.label])
  );
  const resolveDirectionLabel = (dirKey: number) =>
    directionLabelMap.get(dirKey) || `${dirKey}`;
  const previewPixelSize = Math.min(
    PREVIEW_PIXEL_MAX,
    Math.max(
      PREVIEW_PIXEL_MIN,
      Math.floor(
        PREVIEW_CANVAS_TARGET / Math.max(canvasWidth, canvasHeight, 1)
      ) || PREVIEW_PIXEL_MIN
    )
  );

  const serverCanvasGrid = convertCompositeGridToUi(
    data.grid,
    canvasWidth,
    canvasHeight
  );

  const serverSessionSyncKey = `${sessionToken || 'session'}-${
    data.active_dir_key
  }-${serverActivePartKey}`;
  const derivedPreviewState = updatePreviewStateFromPayload(previewState, {
    data,
    sessionKey: serverSessionSyncKey,
    activePartKey: serverActivePartKey,
    canvasWidth,
    canvasHeight,
    canvasGrid: serverCanvasGrid,
  });

  syncPreviewStateIfNeeded(derivedPreviewState, previewState, setPreviewState);

  const fallbackOverlayParts =
    currentDirectionKey === data.active_dir_key ? layerPartsWithDrafts : null;
  const overlayLayerParts = buildOverlayLayerParts({
    previewState: derivedPreviewState,
    dirKey: currentDirectionKey,
    activePartKey,
    fallbackLayerParts: fallbackOverlayParts,
    draftDiffIndex,
    canvasWidth,
    canvasHeight,
  });
  const overlayLayerOrder = Array.isArray(layerOrder)
    ? layerOrder.filter((part) => part !== activePartKey)
    : layerOrder;

  const {
    referenceParts,
    referenceGrid,
    serverDiffPayload,
    serverDiffSeq,
    serverDiffStroke,
    uiCanvasGrid,
  } = resolveDirectionCanvasSources({
    derivedPreviewState,
    currentDirectionKey,
    activePartKey,
    serverActivePartKey,
    serverCanvasGrid,
    layerPartsWithDrafts,
    canvasWidth,
    canvasHeight,
    activeDirKey: data.active_dir_key,
    diff: data.diff,
    diffSeq: data.diff_seq,
    stroke: data.stroke,
    signalAssetUpdate: notifyAssetReady,
  });

  const localSessionKey = buildLocalSessionKey(
    currentDirectionKey,
    activePartKey
  );
  const activeDraftDiff = buildSessionDraftDiff(
    strokeDraftState,
    localSessionKey,
    canvasWidth,
    canvasHeight
  );
  const draftPixelLookup = buildDraftPixelLookup(activeDraftDiff);
  const partPaintPresenceMap = buildPartPaintPresenceMap({
    dirStates: derivedPreviewState.dirs,
    draftDiffIndex,
    activeDirKey: currentDirectionKey,
    activePartKey,
    activeDraftDiff,
    canvasWidth,
    canvasHeight,
  });
  const activePartReplaced =
    activePartKey !== GENERIC_PART_KEY &&
    !!resolvedPartReplacementMap[activePartKey] &&
    !!partPaintPresenceMap[activePartKey];
  const renderedPreviewDirs = buildRenderedPreviewDirs(
    derivedPreviewState.dirs,
    data.directions,
    bodyPartLabelMap,
    canvasWidth,
    canvasHeight,
    currentDirectionKey,
    activePartKey,
    draftDiffIndex,
    activeDraftDiff,
    resolvedPartPriorityMap,
    resolvedPartReplacementMap,
    partPaintPresenceMap,
    notifyAssetReady
  );
  const previewRevision = derivedPreviewState.revision;

  initializeColorPickerSlotsIfNeeded({
    locked: colorPickerSlotsLocked,
    previewDirs: renderedPreviewDirs,
    customSlots: customColorSlots,
    setCustomSlots: setCustomColorSlots,
    previewRevision,
    colorSignature: colorPickerSlotsSignature,
    setColorSignature: setColorPickerSlotsSignature,
  });

  const allPreviewLayersLoaded =
    previewRevision > 0 &&
    renderedPreviewDirs.length > 0 &&
    data.directions.every((dir) =>
      renderedPreviewDirs.some((entry) => entry.dir === dir.dir)
    );

  if (
    allPreviewLayersLoaded &&
    !colorPickerSlotsLocked &&
    colorPickerSlotsSignature
  ) {
    setColorPickerSlotsLocked(true);
  }

  const strokeDraftManager = createStrokeDraftManager({
    context,
    getLocalSessionKey: () => localSessionKey,
    getActivePartKey: () => activePartKey,
    getCurrentDirectionKey: () => currentDirectionKey,
    allocateDraftSequence,
  });
  const {
    getStoredStrokeDrafts,
    appendStrokePreviewPixels,
    removeStrokeDraft,
    updateStrokeDrafts,
    clearSessionDrafts,
    getPendingDraftSessions,
    removeLastLocalStroke,
    clearAllLocalDrafts,
  } = strokeDraftManager;

  const previewSyncController = createPreviewSyncController({
    context,
    act,
    sessionToken,
    canvasWidth,
    canvasHeight,
    getStoredStrokeDrafts,
    clearSessionDrafts,
    getActivePartKey: () => activePartKey,
    getCurrentDirectionKey: () => currentDirectionKey,
    buildLocalSessionKey,
  });
  const {
    sendAction,
    sendActionAfterSync,
    commitPreviewToServer,
    reportClientWarning,
    describeError,
  } = previewSyncController;

  const requestCanvasFlush = () => {
    setCanvasFlushToken((canvasFlushToken + 1) % 1000000);
  };

  const { brushColor, applyBrushColorChange } = useBrushColorController(
    context,
    stateToken
  );

  const getDefaultReferenceOpacityForPart = (partId: string) =>
    partId === GENERIC_PART_KEY
      ? DEFAULT_GENERIC_REFERENCE_OPACITY
      : DEFAULT_BODY_PART_REFERENCE_OPACITY;

  const getReferenceOpacityForPart = (partId: string) => {
    const stored = referenceOpacityByPart[partId];
    if (typeof stored === 'number') {
      return stored;
    }
    return getDefaultReferenceOpacityForPart(partId);
  };

  const setReferenceOpacityForPart = (partId: string, value: number) => {
    const clamped = Math.min(1, Math.max(0, value));
    setReferenceOpacityByPart({
      ...referenceOpacityByPart,
      [partId]: clamped,
    });
  };

  const currentReferenceOpacity = getReferenceOpacityForPart(activePartKey);

  const referenceOpacityMap = buildReferenceOpacityMapForDesigner(
    referenceParts,
    data.body_parts,
    getReferenceOpacityForPart
  );

  const currentBlendMode =
    activeTool === 'eraser' ? 'erase' : limited ? 'analog' : blendMode;
  const isBrushTool =
    activeTool === 'brush' || activeTool === 'eraser' || activeTool === 'line';

  const syncAllPendingDraftSessions = async () => {
    const pendingSessions = getPendingDraftSessions();
    if (!pendingSessions.length) {
      return;
    }
    const sessionChunkPlan = pendingSessions.map((sessionInfo) => {
      const sessionDiff = buildSessionDraftDiff(
        strokeDraftState,
        sessionInfo.sessionKey,
        canvasWidth,
        canvasHeight
      );
      const chunkCount = chunkDiffEntries(
        sessionDiff,
        PREVIEW_DIFF_CHUNK_SIZE
      ).length;
      return {
        ...sessionInfo,
        chunkCount,
      };
    });
    const totalChunks =
      sessionChunkPlan.reduce((sum, entry) => sum + entry.chunkCount, 0) || 0;
    let completedChunks = 0;
    for (const sessionInfo of sessionChunkPlan) {
      const sessionTotal = sessionInfo.chunkCount;
      const handleProgress = (doneChunks: number) => {
        const safeTotal = totalChunks || 1;
        const completed = Math.min(completedChunks + doneChunks, safeTotal);
        const labelPart =
          sessionInfo.partKey === GENERIC_PART_KEY
            ? 'Generic layer'
            : resolveBodyPartLabel(sessionInfo.partKey, bodyPartLabelMap);
        const label = `${labelPart} — ${resolveDirectionLabel(
          sessionInfo.dirKey
        )}`;
        setSavingProgress({
          value: safeTotal > 0 ? completed / safeTotal : null,
          label: totalChunks
            ? `Syncing strokes (${completed}/${safeTotal}) • ${label}`
            : `Syncing strokes • ${label}`,
        });
      };
      if (sessionTotal === 0) {
        continue;
      }
      await commitPreviewToServer({
        partKey: sessionInfo.partKey,
        sessionKey: sessionInfo.sessionKey,
        dirKey: sessionInfo.dirKey,
        onProgress: ({ completedChunks: doneChunks }) => {
          handleProgress(doneChunks);
        },
      });
      completedChunks += sessionTotal;
      handleProgress(0);
    }
  };

  const { handleSafeClose, handleSaveProgress, handleDiscardAndClose } =
    createSavingHandlers({
      pendingClose,
      pendingSave,
      setPendingClose,
      setPendingSave,
      setPendingCloseMessage,
      syncAllPendingDraftSessions,
      resolvedReplacementState,
      resolvedPartReplacementMap,
      resolvedPriorityState,
      resolvedPartPriorityMap,
      sendActionAfterSync,
      clearAllLocalDrafts,
      setSavingProgress,
      sendAction,
      reportClientWarning,
      formatError: describeError,
    });

  const handleDiffApplied = (stroke?: unknown) => {
    if (stroke !== undefined && stroke !== null) {
      removeStrokeDraft(stroke);
    }
  };

  const previewColorForBlend =
    currentBlendMode === 'erase' ? ERASER_PREVIEW_COLOR : brushColor;

  const canvasSampling = createCanvasSamplingHelpers({
    canvasWidth,
    canvasHeight,
    uiCanvasGrid,
    referenceGrid,
    referenceParts,
    layerPartsWithDrafts,
    layerParts,
    layerOrder,
    draftPixelLookup,
    brushColor,
    currentBlendMode,
    analogStrength,
    activePartKey,
  });

  const {
    decoratePreviewPixels,
    buildFillPreviewDiff,
    buildClearPreviewDiff,
    sampleEyedropperPixelColor,
  } = canvasSampling;

  const paintHandlers = createPaintHandlers({
    canvasWidth,
    canvasHeight,
    size,
    previewColorForBlend,
    isBrushTool,
    appendStrokePreviewPixels,
    decoratePreviewPixels,
    buildFillPreviewDiff,
    buildClearPreviewDiff,
    sampleEyedropperPixelColor,
    applyBrushColorChange,
    generateFillStrokeKey,
    generateClearStrokeKey,
  });

  const { onPaint, onLine, onFill, onEyedropper, queueCanvasClearPreview } =
    paintHandlers;

  const handleUndo = () => {
    if (!removeLastLocalStroke()) {
      return;
    }
    requestCanvasFlush();
  };

  const handleClear = (confirm: boolean) => {
    if (!confirm) {
      return;
    }
    if (queueCanvasClearPreview()) {
      requestCanvasFlush();
    }
  };

  const exportController = createExportController({
    data,
    uiCanvasGrid,
    strokeDraftState,
    localSessionKey,
    canvasWidth,
    canvasHeight,
    activePartKey,
    currentDirectionKey,
    derivedPreviewState,
    draftDiffIndex,
    activeDraftDiff,
    updateStrokeDrafts,
    clearSessionDrafts,
    allocateDraftSequence,
    sendActionAfterSync,
  });
  const { handleExport, handleImport } = exportController;

  const setBodyPart = (id: string) => {
    if (uiLocked || id === activePartKey) {
      return;
    }

    const previousPartKey = activePartKey;
    const previousOpacity = getReferenceOpacityForPart(previousPartKey);

    setReferenceOpacityByPart({
      ...referenceOpacityByPart,
      [previousPartKey]: 0,
      [id]: previousOpacity,
    });

    setActivePartKey(id);
    requestCanvasFlush();
  };

  const setDirection = (dir: number) => {
    if (uiLocked || dir === currentDirectionKey) {
      return;
    }
    setUiDirectionKey(dir);
    requestCanvasFlush();
  };

  const canUndoDrafts = Object.values(strokeDraftState || {}).some(
    (entry) => entry && entry.session === localSessionKey
  );

  const handleColorPickerApply = async (hex: string) => {
    await applyBrushColorChange(hex);
  };

  const handleCustomColorUpdate = (colors: (string | null)[]) => {
    const normalized = Array.from(
      { length: COLOR_PICKER_CUSTOM_SLOTS },
      (_, index) => {
        const entry = colors[index];
        return typeof entry === 'string' ? normalizeHex(entry) : null;
      }
    );
    setCustomColorSlots(normalized);
    if (!colorPickerSlotsLocked) {
      setColorPickerSlotsLocked(true);
    }
  };
  const resolvePartLayeringState = (partKey: string | null | undefined) =>
    resolveLayeringState(partKey, resolvedPartPriorityMap);

  const togglePartLayerPriority = createLayerPriorityToggler({
    uiLocked,
    activePartKey,
    resolvedPartPriorityMap,
    resolvedPriorityState,
    setPriorityState,
    resolveLayeringState: resolvePartLayeringState,
  });

  const togglePartReplacement = createPartReplacementToggler({
    uiLocked,
    activePartKey,
    resolvedPartReplacementMap,
    resolvedReplacementState,
    setReplacementState,
    replacementDependents,
  });

  const customStatusIcon = (
    <img
      className="TitleBar__statusIcon RogueStar__statusIcon"
      src={CustomEyeIconAsset}
      alt=""
    />
  );

  return (
    <Window
      theme="nanotrasen rogue-star-window"
      width={1720}
      height={950}
      resizable
      canClose={false}
      statusIcon={customStatusIcon}>
      <ToolBootstrapScheduler
        isPlaceholderTool={isPlaceholderTool}
        toolBootstrapScheduled={toolBootstrapScheduled}
        setToolBootstrapScheduled={setToolBootstrapScheduled}
        setTool={setTool}
      />
      <PhantomClickScheduler
        phantomClickScheduled={phantomClickScheduled}
        isPlaceholderTool={isPlaceholderTool}
        activeTool={activeTool}
        setPhantomClickScheduled={setPhantomClickScheduled}
        setTool={setTool}
      />
      <ToolBootstrapReset
        stateToken={stateToken}
        onReset={handleToolBootstrapReset}
      />
      <Window.Content scrollable overflowX="auto">
        <Box className="RogueStar" position="relative" minHeight="100%">
          <Flex direction="row" fill gap={2} wrap={false} align="stretch">
            <Flex.Item basis="600px" shrink={0}>
              <Flex
                direction="column"
                gap={2}
                height="100%"
                className="RogueStar__column">
                <SessionControls
                  pendingSave={pendingSave}
                  pendingClose={pendingClose}
                  uiLocked={uiLocked}
                  handleSaveProgress={handleSaveProgress}
                  handleSafeClose={handleSafeClose}
                  handleDiscardAndClose={handleDiscardAndClose}
                  handleImport={handleImport}
                  handleExport={handleExport}
                />

                <MarkingInfoSection
                  bodyParts={data.body_parts}
                  directions={data.directions}
                  currentDirectionKey={currentDirectionKey}
                  setDirection={setDirection}
                  activePartKey={activePartKey}
                  activePartLabel={activePartLabel}
                  resolvedPartReplacementMap={resolvedPartReplacementMap}
                  resolvePartLayeringState={resolvePartLayeringState}
                  togglePartLayerPriority={togglePartLayerPriority}
                  togglePartReplacement={togglePartReplacement}
                  setBodyPart={setBodyPart}
                  uiLocked={uiLocked}
                  getReferenceOpacityForPart={getReferenceOpacityForPart}
                  setReferenceOpacityForPart={setReferenceOpacityForPart}
                />

                <Box className="RogueStar__leftFill">
                  <PaintToolsSection
                    tool={activeTool}
                    setTool={setTool}
                    blendMode={blendMode}
                    setBlendMode={setBlendMode}
                    analogStrength={analogStrength}
                    setAnalogStrength={setAnalogStrength}
                    canUndoDrafts={canUndoDrafts}
                    handleUndo={handleUndo}
                    handleClear={handleClear}
                    size={size}
                    setSize={setSize}
                    brushColor={brushColor}
                    customColorSlots={customColorSlots}
                    handleCustomColorUpdate={handleCustomColorUpdate}
                    handleColorPickerApply={handleColorPickerApply}
                  />
                </Box>
              </Flex>
            </Flex.Item>

            <Flex.Item grow basis="0">
              <Section
                title={`Direction: ${
                  data.directions.find((dir) => dir.dir === currentDirectionKey)
                    ?.label || data.active_dir
                } • Part: ${activePartLabel}`}
                fill>
                <Flex align="stretch" gap={2} wrap={false}>
                  <Flex.Item grow>
                    <Box className="RogueStar__canvasScroll">
                      <Box className="RogueStar__canvasFrame">
                        <PaintCanvas
                          key={`${
                            data.session_token || 'session'
                          }-${currentDirectionKey}-${activePartKey}`}
                          value={uiCanvasGrid || []}
                          reference={referenceGrid}
                          referenceParts={referenceParts}
                          referenceOpacity={
                            referenceGrid ? currentReferenceOpacity : undefined
                          }
                          referenceOpacityMap={referenceOpacityMap}
                          layerParts={overlayLayerParts}
                          layerOrder={overlayLayerOrder}
                          layerRevision={data.body_part_layer_revision || 0}
                          diff={serverDiffPayload}
                          diffSeq={serverDiffSeq}
                          diffStroke={serverDiffStroke}
                          activeLayerKey={activePartKey}
                          otherLayerOpacity={getReferenceOpacityForPart(
                            GENERIC_PART_KEY
                          )}
                          dotsize={DOT_SIZE}
                          tool={activeTool ? activeTool : PLACEHOLDER_TOOL}
                          size={size}
                          previewColor={brushColor}
                          finalized={false}
                          allowUndoShortcut
                          onUndo={() => handleUndo()}
                          onCanvasClick={(x, y, s, stroke) =>
                            activeTool === 'fill'
                              ? onFill({ x, y })
                              : activeTool === 'eyedropper'
                                ? onEyedropper({ x, y })
                                : onPaint({ x, y, brushSize: s, stroke })
                          }
                          onCanvasLine={(x1, y1, x2, y2, s, stroke) =>
                            onLine({ x1, y1, x2, y2, brushSize: s, stroke })
                          }
                          onCanvasFill={(x, y) => onFill({ x, y })}
                          onEyedropper={(x, y) => onEyedropper({ x, y })}
                          strokeDrafts={strokeDraftState}
                          strokeDraftSession={localSessionKey}
                          onDiffApplied={handleDiffApplied}
                          flushToken={canvasFlushToken}
                        />
                      </Box>
                    </Box>
                  </Flex.Item>
                  {renderedPreviewDirs.length ? (
                    <Flex.Item basis="220px" grow={0} shrink={0}>
                      <Box className="RogueStar__previewCard" height="100%">
                        <Box
                          mb={1}
                          color="label"
                          fontWeight="bold"
                          className="RogueStar__previewTitle RogueStar__previewTitle--center">
                          Live Preview
                        </Box>
                        <Box className="RogueStar__previewList">
                          {renderedPreviewDirs.map((entry) => (
                            <Box
                              key={`${entry.dir}-${previewRevision}`}
                              mb={1}
                              className="RogueStar__previewItem">
                              <DirectionPreviewCanvas
                                layers={entry.layers}
                                pixelSize={previewPixelSize}
                                width={canvasWidth}
                                height={canvasHeight}
                              />
                            </Box>
                          ))}
                        </Box>
                      </Box>
                    </Flex.Item>
                  ) : null}
                </Flex>
              </Section>
            </Flex.Item>
          </Flex>
          {pendingClose || pendingSave ? (
            <SavingOverlay
              title={
                pendingClose
                  ? pendingCloseMessage?.title
                  : 'Saving your changes…'
              }
              subtitle={
                pendingClose
                  ? pendingCloseMessage?.subtitle
                  : 'Please keep the client open while we sync your work. The designer will stay open afterward.'
              }
              progress={savingProgress}
            />
          ) : null}
        </Box>
      </Window.Content>
    </Window>
  );
};
