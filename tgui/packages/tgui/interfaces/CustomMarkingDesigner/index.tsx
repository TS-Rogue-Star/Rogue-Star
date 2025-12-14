// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2025: New system for allowing players to create custom markings ////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Major refactor to reduce lag, update style, and provide more options //
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Updated to support 64x64 markings /////////////////////////////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support loaout and job gear ////////////////////////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support new body marking selector //////////////////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import { selectBackend, useBackend, useLocalState } from '../../backend';
import { Box, Flex, Tabs } from '../../components';
import { Window } from '../../layouts';
import { normalizeHex } from '../../utils/color';
import {
  GENERIC_PART_KEY,
  resolveBodyPartLabel,
} from '../../utils/character-preview';
import {
  CanvasSection,
  type CanvasHandlers,
  type CanvasToolbarProps,
  DesignerLeftColumn,
  DesignerUndoHotkeyListener,
  EnableCustomMarkingsGate,
  EnableCustomMarkingsScheduler,
  PhantomClickScheduler,
  LoadingOverlay,
  PreviewColumn,
  SavingOverlayGate,
  ToolBootstrapReset,
  ToolBootstrapScheduler,
  UnsavedChangesOverlay,
} from './components';
import { ERASER_PREVIEW_COLOR, COLOR_PICKER_CUSTOM_SLOTS } from './constants';
import {
  useBrushColorController,
  useCanvasBackground,
  useCanvasDisplayState,
  useDesignerPreview,
  usePartFlagState,
  useSyncedDirectionState,
  useToolState,
} from './hooks';
import { createPreviewSyncController } from './services/previewSync';
import { createPendingDraftSync } from './services/pendingDraftSync';
import { createStrokeDraftManager } from './services/strokeDrafts';
import { createExportController } from './services/exportHandlers';
import {
  createCanvasSamplingHelpers,
  generateClearStrokeKey,
  generateFillStrokeKey,
} from './utils/canvasSampling';
import { createPaintHandlers } from './utils/paintHandlers';
import {
  applyPreviewInitialization,
  areAllPreviewLayersLoaded,
  buildCanvasKey,
  buildBodyPartLabelMap,
  buildBodyMarkingDefinitions,
  buildBodyMarkingSavePayload,
  buildBodyMarkingChunkPlan,
  buildBodySavedStateFromPayload,
  createReferenceOpacityControls,
  getCanvasFrameStyle,
  buildLocalSessionKey,
  convertCompositeLayerMap,
  createSavingHandlers,
  deepCopyMarkings,
  initializeColorPickerSlotsIfNeeded,
} from './utils';
import type {
  CustomMarkingDesignerData,
  CanvasBackgroundOption,
  StrokeDraftState,
  BodyMarkingColorTarget,
  BodyMarkingEntry,
  BodyMarkingsPayload,
  BodyMarkingsSavedState,
  BooleanMapState,
} from './types';
import { useDesignerUiState } from './state';
import CustomEyeIconAsset from '../../../../public/Icons/Rogue Star/eye 1.png';
import { BodyMarkingsTab } from './BodyMarkingsTab';

type DesignerTabId = 'custom' | 'body';

const resolveCustomDesignerTabIcon = (allowCustomTab: boolean) =>
  allowCustomTab ? 'paint-brush' : 'lock';

const resolveCustomDesignerTabTooltip = (allowCustomTab: boolean) =>
  allowCustomTab ? undefined : 'Enable Custom Markings to use the designer.';

export const CustomMarkingDesigner = (_props, context) => {
  const { act, data } = useBackend<CustomMarkingDesignerData>(context);
  const stateToken = data.state_token || 'session';
  const [activeTab, setActiveTab] = useLocalState<DesignerTabId>(
    context,
    'customMarkingTab',
    'custom'
  );
  const [lastInitialTab, setLastInitialTab] =
    useLocalState<DesignerTabId | null>(
      context,
      `customMarkingLastInitialTab-${stateToken}`,
      null
    );
  const allowCustomTab = data.allow_custom_tab ?? true;
  const enableCustomDisclaimer =
    data.custom_marking_enable_disclaimer ||
    "This is an advanced character editing tool that allows you to edit individual pixels on your character to adjust or create new markings.  Custom markings have the same standards as markings added to the RogueStar codebase.  They should make realistic sense and must be SFW.  If it wouldn't get approved to add to the code, it should not be done here.  If you are uncertain about something, please let us know and we're happy to chatter about it.";
  const [enableCustomPromptOpen, setEnableCustomPromptOpen] =
    useLocalState<boolean>(
      context,
      `customMarkingEnablePromptOpen-${stateToken}`,
      false
    );
  const [enableCustomPromptBusy, setEnableCustomPromptBusy] =
    useLocalState<boolean>(
      context,
      `customMarkingEnablePromptBusy-${stateToken}`,
      false
    );
  const [enableCustomSwitchPending, setEnableCustomSwitchPending] =
    useLocalState<boolean>(
      context,
      `customMarkingEnablePromptSwitchPending-${stateToken}`,
      false
    );
  let desiredTab: DesignerTabId | null = null;
  if (data.initial_tab === 'body' || data.initial_tab === 'custom') {
    desiredTab = data.initial_tab;
  }
  if (!allowCustomTab) {
    desiredTab = 'body';
  }
  if (desiredTab && desiredTab !== lastInitialTab) {
    if (desiredTab !== activeTab) {
      setActiveTab(desiredTab);
    }
    setLastInitialTab(desiredTab);
  }
  if (!allowCustomTab && activeTab === 'custom') {
    setActiveTab('body');
  }
  const resolvedActiveTab: DesignerTabId = allowCustomTab ? activeTab : 'body';
  const {
    isPlaceholderTool,
    activePrimaryTool,
    activeSecondaryTool,
    toolBootstrapScheduled,
    setToolBootstrapScheduled,
    phantomClickScheduled,
    setPhantomClickScheduled,
    handleToolBootstrapReset,
    assignPrimaryTool,
    assignSecondaryTool,
    resolveToolForButton,
    resolveCanvasTool,
    resolveDefaultTool,
    setPrimaryTool,
  } = useToolState({
    context,
    stateToken,
  });
  const canvasBackgroundOptions: CanvasBackgroundOption[] = Array.isArray(
    data.canvas_backgrounds
  )
    ? data.canvas_backgrounds
    : [];
  const defaultCanvasBackgroundKey =
    data.default_canvas_background || 'default';
  const {
    resolvedCanvasBackground,
    backgroundFallbackColor,
    canvasBackgroundStyle,
    cycleCanvasBackground,
  } = useCanvasBackground({
    context,
    stateToken,
    options: canvasBackgroundOptions,
    defaultKey: defaultCanvasBackgroundKey,
  });
  const {
    size,
    setSize,
    blendMode,
    setBlendMode,
    analogStrength,
    setAnalogStrength,
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
    showJobGear,
    setShowJobGear,
    showLoadoutGear,
    setShowLoadoutGear,
    loadingOverlay,
    setLoadingOverlay,
  } = useDesignerUiState(context, stateToken, {
    showJobGear: !!data.show_job_gear,
    showLoadoutGear: !!data.show_loadout_gear,
  });
  const [reloadPending, setReloadPending] = useLocalState<boolean>(
    context,
    `customMarkingDesignerReloadPending-${stateToken}`,
    false
  );
  const [reloadTargetRevision, setReloadTargetRevision] = useLocalState<number>(
    context,
    `customMarkingDesignerReloadTargetRevision-${stateToken}`,
    0
  );
  const [reloadOverlayMinUntil, setReloadOverlayMinUntil] =
    useLocalState<number>(
      context,
      `customMarkingDesignerReloadOverlayMinUntil-${stateToken}`,
      0
    );
  const [bodyReloadPending, setBodyReloadPending] = useLocalState<boolean>(
    context,
    `bodyMarkingsReloadPending-${stateToken}`,
    false
  );
  const [, setBodyMarkingsLoadInProgress] = useLocalState<boolean>(
    context,
    `bodyMarkingsLoadInProgress-${stateToken}`,
    false
  );
  const [bodyPayload, setBodyPayload] =
    useLocalState<BodyMarkingsPayload | null>(
      context,
      'bodyPayload',
      data.body_markings_payload || null
    );
  const [bodyMarkingsState, setBodyMarkingsState] = useLocalState<
    Record<string, BodyMarkingEntry>
  >(
    context,
    'bodyMarkingsState',
    deepCopyMarkings(data.body_markings_payload?.body_markings)
  );
  const [bodyMarkingsOrder, setBodyMarkingsOrder] = useLocalState<string[]>(
    context,
    'bodyMarkingsOrder',
    (data.body_markings_payload?.order as string[]) || []
  );
  const [bodyMarkingsSelected, setBodyMarkingsSelected] = useLocalState<
    string | null
  >(
    context,
    'bodyMarkingsSelected',
    (data.body_markings_payload?.order?.[0] as string) || null
  );
  const [bodyMarkingsDirty, setBodyMarkingsDirty] = useLocalState<boolean>(
    context,
    'bodyMarkingsDirty',
    false
  );
  const [, setBodyColorTarget] = useLocalState<BodyMarkingColorTarget | null>(
    context,
    'bodyMarkingsColorTarget',
    null
  );
  const [, setBodyPreviewColor] = useLocalState<string | null>(
    context,
    'bodyMarkingsPreviewColor',
    null
  );
  const [bodySavedState, setBodySavedState] =
    useLocalState<BodyMarkingsSavedState>(
      context,
      'bodyMarkingsSavedState',
      buildBodySavedStateFromPayload(data.body_markings_payload)
    );
  const [bodyPendingSave, setBodyPendingSave] = useLocalState<boolean>(
    context,
    'bodyMarkingsPendingSave',
    false
  );
  const [bodyPendingClose, setBodyPendingClose] = useLocalState<boolean>(
    context,
    'bodyMarkingsPendingClose',
    false
  );
  const [strokeDraftState] = useLocalState<StrokeDraftState>(
    context,
    'strokeDrafts',
    {}
  );
  const [tabSwitchPrompt, setTabSwitchPrompt] = useLocalState<{
    sourceTab: DesignerTabId;
    targetTab: DesignerTabId;
  } | null>(context, 'customMarkingTabSwitchPrompt', null);
  const [tabSwitchBusy, setTabSwitchBusy] = useLocalState(
    context,
    'customMarkingTabSwitchBusy',
    false
  );
  const notifyAssetReady = () =>
    setAssetRevision((assetRevision + 1) % 1000000);
  const limited = !!data.limited;

  const {
    canvasWidth,
    canvasHeight,
    canvasPixelSize,
    canvasDisplayWidthPx,
    canvasDisplayHeightPx,
    canvasTransform,
    canvasFitToFrame,
    previewFitToFrame,
    toggleCanvasFit,
  } = useCanvasDisplayState(context, stateToken, data);

  const layerParts = convertCompositeLayerMap(
    data.body_part_layers,
    canvasWidth,
    canvasHeight
  );
  const sessionToken = data.session_token || null;
  const { currentDirectionKey, setUiDirectionKey } = useSyncedDirectionState(
    context,
    sessionToken,
    data.active_dir_key
  );
  const layerOrder = data.body_part_layer_order || null;
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
  const {
    resolvedReplacementState,
    resolvedPriorityState,
    resolvedCanvasSizeState,
    resolvedPartReplacementMap,
    resolvedPartPriorityMap,
    resolvedPartCanvasSizeMap,
    resolvePartLayeringState,
    togglePartLayerPriority,
    togglePartReplacement,
    resetFlagStates,
  } = usePartFlagState({
    context,
    stateToken,
    activePartKey,
    uiLocked,
    replacementStateFromServer: data.part_replacements,
    replacementDependents: data.replacement_dependents || {},
    priorityStateFromServer: data.part_render_priority,
    canvasSizeStateFromServer: data.part_canvas_size,
  });
  const {
    derivedPreviewState,
    overlayLayerParts,
    overlayLayerOrder,
    referenceParts,
    referenceGrid,
    serverDiffPayload,
    serverDiffSeq,
    serverDiffStroke,
    uiCanvasGrid,
    draftDiffIndex,
    layerPartsWithDrafts,
    localSessionKey,
    activeDraftDiff,
    draftPixelLookup,
    partPaintPresenceMap,
    renderedPreviewDirs,
    previewRevision,
  } = useDesignerPreview({
    data,
    previewState,
    setPreviewState,
    strokeDraftState,
    currentDirectionKey,
    activePartKey,
    layerParts,
    layerOrder,
    canvasWidth,
    canvasHeight,
    notifyAssetReady,
    bodyPartLabelMap,
    resolvedPartPriorityMap,
    resolvedPartReplacementMap,
    sessionToken,
    showJobGear,
    showLoadoutGear,
  });

  initializeColorPickerSlotsIfNeeded({
    locked: colorPickerSlotsLocked,
    previewDirs: renderedPreviewDirs,
    customSlots: customColorSlots,
    setCustomSlots: setCustomColorSlots,
    previewRevision,
    colorSignature: colorPickerSlotsSignature,
    setColorSignature: setColorPickerSlotsSignature,
  });

  const allPreviewLayersLoaded = areAllPreviewLayersLoaded({
    previewRevision,
    renderedPreviewDirs,
    directions: data.directions,
  });

  const referenceBuildInProgress = !!data.reference_build_in_progress;
  if (referenceBuildInProgress) {
    if (reloadTargetRevision) {
      setReloadTargetRevision(0);
    }
    if (reloadPending) {
      setReloadPending(false);
    }
    if (!loadingOverlay) {
      const now = Date.now();
      setLoadingOverlay(true);
      if (!reloadOverlayMinUntil || reloadOverlayMinUntil < now) {
        setReloadOverlayMinUntil(now + 400);
      }
    }
  }

  applyPreviewInitialization({
    loadingOverlay,
    allPreviewLayersLoaded,
    previewRevision,
    loadingOverlayTargetRevision: reloadTargetRevision,
    loadingOverlayMinUntil: reloadOverlayMinUntil,
    referenceBuildInProgress,
    setLoadingOverlay,
    colorPickerSlotsLocked,
    colorPickerSlotsSignature,
    setColorPickerSlotsLocked,
  });

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

  const referenceOpacityControls = createReferenceOpacityControls({
    referenceOpacityByPart,
    setReferenceOpacityByPart,
    referenceParts,
    bodyParts: data.body_parts,
    showJobGear,
    showLoadoutGear,
    activePartKey,
  });
  const {
    currentReferenceOpacity,
    genericReferenceOpacity,
    getReferenceOpacityForPart,
    setReferenceOpacityForPart,
    resolvedReferenceOpacityMap,
  } = referenceOpacityControls;

  const resolveBlendModeForTool = (toolName?: string | null) =>
    toolName === 'eraser' ? 'erase' : limited ? 'analog' : blendMode;

  const resolveToolContext = (toolName?: string | null) => {
    const normalized = toolName || resolveDefaultTool();
    const blendModeForTool = resolveBlendModeForTool(normalized);
    const mirror = normalized === 'mirror-brush';
    const isBrush =
      normalized === 'brush' ||
      normalized === 'eraser' ||
      normalized === 'line' ||
      mirror;
    const previewColorForBlend =
      blendModeForTool === 'erase' ? ERASER_PREVIEW_COLOR : brushColor;
    return {
      tool: normalized,
      blendMode: blendModeForTool,
      mirrorBrush: mirror,
      isBrushTool: isBrush,
      previewColorForBlend,
    };
  };

  const syncAllPendingDraftSessions = createPendingDraftSync({
    strokeDraftState,
    canvasWidth,
    canvasHeight,
    getPendingDraftSessions,
    commitPreviewToServer,
    setSavingProgress,
    resolveDirectionLabel,
    resolvePartLabel: (partKey) =>
      resolveBodyPartLabel(partKey, bodyPartLabelMap),
  });

  const rawSavingHandlers = createSavingHandlers({
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
    resolvedCanvasSizeState,
    resolvedPartCanvasSizeMap,
    sendActionAfterSync,
    clearAllLocalDrafts,
    setSavingProgress,
    sendAction,
    reportClientWarning,
    formatError: describeError,
  });
  const handleSaveProgress = async () => {
    const wasDirty = detectCustomUnsaved();
    await rawSavingHandlers.handleSaveProgress();
    if (wasDirty) {
      setBodyReloadPending(true);
    }
  };
  const handleSafeClose = async () => {
    const wasDirty = detectCustomUnsaved();
    await rawSavingHandlers.handleSafeClose();
    if (wasDirty) {
      setBodyReloadPending(true);
    }
  };
  const handleDiscardAndClose = rawSavingHandlers.handleDiscardAndClose;

  const handleDiffApplied = (stroke?: unknown) => {
    if (stroke !== undefined && stroke !== null) {
      removeStrokeDraft(stroke, localSessionKey);
    }
  };

  const defaultToolContext = resolveToolContext(activePrimaryTool);

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
    currentBlendMode: defaultToolContext.blendMode,
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
    resolveToolContext,
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

  const canvasBackgroundScale = 1;

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

  const customStatusIcon = (
    <img
      className="TitleBar__statusIcon RogueStar__statusIcon"
      src={CustomEyeIconAsset}
      alt=""
    />
  );

  const shouldShowLoadingOverlay =
    loadingOverlay && !pendingSave && !pendingClose;
  const customTabLoading = resolvedActiveTab === 'custom' && loadingOverlay;
  const bodyTabLoading = resolvedActiveTab === 'body' && !bodyPayload;
  const tabSwitchBusyState =
    tabSwitchBusy ||
    pendingSave ||
    pendingClose ||
    bodyPendingSave ||
    bodyPendingClose;
  const tabsLocked = tabSwitchBusyState || customTabLoading || bodyTabLoading;

  const canvasBackgroundId = resolvedCanvasBackground?.id || 'default';
  const directionTitle = `Direction: ${resolveDirectionLabel(
    currentDirectionKey
  )} • Part: ${activePartLabel}`;
  const canvasFrameStyle = getCanvasFrameStyle(
    resolvedCanvasBackground,
    backgroundFallbackColor,
    canvasDisplayWidthPx,
    canvasDisplayHeightPx
  );
  const canvasKey = buildCanvasKey({
    sessionToken,
    dirKey: currentDirectionKey,
    partKey: activePartKey,
    canvasWidth,
    canvasHeight,
    backgroundId: canvasBackgroundId,
  });
  const backgroundImage = resolvedCanvasBackground?.asset?.png
    ? `data:image/png;base64,${resolvedCanvasBackground.asset.png}`
    : null;

  const canvasToolbarProps: CanvasToolbarProps = {
    canvasFitToFrame,
    toggleCanvasFit,
    canvasBackgroundOptions,
    resolvedCanvasBackground,
    cycleCanvasBackground,
    showJobGear,
    onToggleJobGear: () => setShowJobGear(!showJobGear),
    showLoadoutGear,
    onToggleLoadout: () => setShowLoadoutGear(!showLoadoutGear),
  };

  const canvasHandlers: CanvasHandlers = {
    onFill,
    onEyedropper,
    onPaint,
    onLine,
    resolveCanvasTool,
    handleUndo,
    handleDiffApplied,
  };

  const detectCustomUnsaved = () => {
    const sharedState = selectBackend(context.store.getState()).shared || {};
    const replacementState =
      (sharedState[`partReplacements-${stateToken}`] as BooleanMapState) ||
      resolvedReplacementState;
    const priorityState =
      (sharedState[`partRenderPriority-${stateToken}`] as BooleanMapState) ||
      resolvedPriorityState;
    const canvasSizeState =
      (sharedState[`partCanvasSize-${stateToken}`] as BooleanMapState) ||
      resolvedCanvasSizeState;
    const draftsPending = getPendingDraftSessions().length > 0;
    const flagDirty =
      replacementState?.dirty || priorityState?.dirty || canvasSizeState?.dirty;
    return draftsPending || flagDirty;
  };

  const detectBodyUnsaved = () => {
    const sharedState = selectBackend(context.store.getState()).shared || {};
    const dirtyFlag =
      typeof sharedState.bodyMarkingsDirty === 'boolean'
        ? (sharedState.bodyMarkingsDirty as boolean)
        : bodyMarkingsDirty;
    return !!dirtyFlag;
  };

  const resolveBodyReloadPending = () => {
    const sharedState = selectBackend(context.store.getState()).shared || {};
    const pendingValue = sharedState[`bodyMarkingsReloadPending-${stateToken}`];
    if (typeof pendingValue === 'boolean') {
      return pendingValue;
    }
    return bodyReloadPending;
  };

  const resolveLatestBodyPayload = () => {
    const sharedState = selectBackend(context.store.getState()).shared || {};
    const payload = sharedState.bodyPayload as
      | BodyMarkingsPayload
      | null
      | undefined;
    return payload !== undefined ? payload : bodyPayload;
  };

  const resolveUnsavedForTab = (tab: DesignerTabId) =>
    tab === 'custom' ? detectCustomUnsaved() : detectBodyUnsaved();

  const clearCustomChanges = () => {
    clearAllLocalDrafts();
    resetFlagStates();
    requestCanvasFlush();
  };

  const saveBodyChanges = async (): Promise<boolean> => {
    const wasDirty = detectBodyUnsaved();
    if (!wasDirty) {
      return true;
    }
    const definitions = buildBodyMarkingDefinitions(bodyPayload);
    if (!Object.keys(definitions).length) {
      return false;
    }
    const { body_markings: outgoing, order: outgoingOrder } =
      buildBodyMarkingSavePayload({
        order: bodyMarkingsOrder,
        markings: bodyMarkingsState,
        definitions,
      });
    setBodyPendingSave(true);
    setBodyPendingClose(false);
    try {
      if (!outgoingOrder.length) {
        await act('save_body_markings', {
          body_markings: outgoing,
          order: outgoingOrder,
          close: false,
        });
      } else {
        const { chunkId, chunks } = buildBodyMarkingChunkPlan({
          order: outgoingOrder,
          markings: outgoing,
          maxEntriesPerChunk: 1,
        });
        const totalChunks = Math.max(chunks.length, 1);
        for (let idx = 0; idx < totalChunks; idx += 1) {
          const payload: Record<string, unknown> = {
            chunk_id: chunkId,
            chunk_index: idx,
            chunk_total: totalChunks,
            body_markings: chunks[idx] || {},
          };
          if (idx === 0) {
            payload.order = outgoingOrder;
          }
          await act('save_body_markings', payload);
        }
      }
      const nextSelected = bodyMarkingsSelected || outgoingOrder[0] || null;
      setBodyMarkingsDirty(false);
      setBodySavedState({
        order: [...outgoingOrder],
        markings: deepCopyMarkings(outgoing),
        selectedId: nextSelected,
      });
      if (bodyPayload) {
        const updatedPayload: BodyMarkingsPayload = {
          ...bodyPayload,
          body_markings: outgoing,
          order: outgoingOrder,
        };
        setBodyPayload(updatedPayload);
      }
      return true;
    } catch (error) {
      return false;
    } finally {
      setBodyPendingSave(false);
      setBodyPendingClose(false);
    }
  };

  const discardBodyChanges = () => {
    const fallbackSaved = bodySavedState
      ? {
          ...bodySavedState,
          markings: deepCopyMarkings(bodySavedState.markings),
        }
      : buildBodySavedStateFromPayload(bodyPayload);
    const nextOrder = fallbackSaved?.order || [];
    const nextMarkings = deepCopyMarkings(fallbackSaved?.markings);
    const nextSelected = fallbackSaved?.selectedId || nextOrder[0] || null;
    setBodyMarkingsState(nextMarkings);
    setBodyMarkingsOrder([...nextOrder]);
    setBodyMarkingsSelected(nextSelected);
    setBodyColorTarget(null);
    setBodyPreviewColor(null);
    if (bodyPayload) {
      const updatedPayload: BodyMarkingsPayload = {
        ...bodyPayload,
        body_markings: nextMarkings,
        order: nextOrder,
      };
      setBodyPayload(updatedPayload);
    }
    setBodyMarkingsDirty(false);
  };

  const handleTabChange = (nextTab: DesignerTabId) => {
    if (tabsLocked) {
      return;
    }
    if (nextTab === 'custom' && !allowCustomTab) {
      return;
    }
    if (nextTab === resolvedActiveTab) {
      return;
    }
    if (resolveUnsavedForTab(resolvedActiveTab)) {
      setTabSwitchPrompt({
        sourceTab: resolvedActiveTab,
        targetTab: nextTab,
      });
      return;
    }
    if (nextTab === 'custom' && reloadPending) {
      setLoadingOverlay(true);
      setReloadOverlayMinUntil(Date.now() + 400);
      setReloadPending(false);
    }
    if (nextTab === 'body') {
      setBodyColorTarget({ type: 'galleryPreview' });
      const latestBodyPayload = resolveLatestBodyPayload();
      const latestReloadPending = resolveBodyReloadPending();
      if (!latestBodyPayload || latestReloadPending) {
        setBodyPayload(null);
        setBodyMarkingsLoadInProgress(true);
        act('load_body_markings');
        if (latestReloadPending) {
          setBodyReloadPending(false);
        }
      }
    }
    act('set_active_tab', { tab: nextTab });
    setActiveTab(nextTab);
  };

  const handleEnableCustomMarkings = async () => {
    if (enableCustomPromptBusy) {
      return;
    }
    setEnableCustomPromptBusy(true);
    try {
      await act('enable_custom_markings');
      setEnableCustomSwitchPending(true);
    } finally {
      setEnableCustomPromptBusy(false);
    }
  };

  const handleEnableCustomReady = () => {
    setEnableCustomSwitchPending(false);
    setEnableCustomPromptOpen(false);
    handleTabChange('custom');
  };

  const handleTabSwitchSave = async () => {
    if (!tabSwitchPrompt) {
      return;
    }
    const wasBodyDirty =
      tabSwitchPrompt.sourceTab === 'body' && detectBodyUnsaved();
    const wasCustomDirty =
      tabSwitchPrompt.sourceTab === 'custom' && detectCustomUnsaved();
    const startingPreviewRevision = previewRevision;
    setTabSwitchBusy(true);
    setTabSwitchPrompt(null);
    try {
      if (tabSwitchPrompt.sourceTab === 'custom') {
        await handleSaveProgress();
        if (detectCustomUnsaved()) {
          setTabSwitchPrompt(tabSwitchPrompt);
          return;
        }
      } else {
        const saved = await saveBodyChanges();
        if (!saved || detectBodyUnsaved()) {
          setTabSwitchPrompt(tabSwitchPrompt);
          return;
        }
      }
      if (
        tabSwitchPrompt.targetTab === 'custom' &&
        (reloadPending || wasBodyDirty)
      ) {
        if (wasBodyDirty) {
          setReloadTargetRevision(startingPreviewRevision + 1);
        }
        setLoadingOverlay(true);
        setReloadOverlayMinUntil(Date.now() + 400);
        setReloadPending(false);
      }
      if (tabSwitchPrompt.targetTab === 'body') {
        setBodyColorTarget({ type: 'galleryPreview' });
        if (!bodyPayload || bodyReloadPending || wasCustomDirty) {
          setBodyPayload(null);
          setBodyMarkingsLoadInProgress(true);
          await act('load_body_markings');
          if (bodyReloadPending) {
            setBodyReloadPending(false);
          }
          if (wasCustomDirty && !bodyReloadPending) {
            setBodyReloadPending(false);
          }
        }
      }
      act('set_active_tab', { tab: tabSwitchPrompt.targetTab });
      setActiveTab(tabSwitchPrompt.targetTab);
    } finally {
      setTabSwitchBusy(false);
    }
  };

  const handleTabSwitchDiscard = async () => {
    if (!tabSwitchPrompt) {
      return;
    }
    setTabSwitchBusy(true);
    setTabSwitchPrompt(null);
    try {
      if (tabSwitchPrompt.sourceTab === 'custom') {
        clearCustomChanges();
      } else {
        discardBodyChanges();
      }
      if (resolveUnsavedForTab(tabSwitchPrompt.sourceTab)) {
        setTabSwitchPrompt(tabSwitchPrompt);
        return;
      }
      if (tabSwitchPrompt.targetTab === 'custom' && reloadPending) {
        setLoadingOverlay(true);
        setReloadOverlayMinUntil(Date.now() + 400);
        setReloadPending(false);
      }
      if (tabSwitchPrompt.targetTab === 'body') {
        setBodyColorTarget({ type: 'galleryPreview' });
        if (!bodyPayload || bodyReloadPending) {
          setBodyPayload(null);
          setBodyMarkingsLoadInProgress(true);
          await act('load_body_markings');
          if (bodyReloadPending) {
            setBodyReloadPending(false);
          }
        }
      }
      act('set_active_tab', { tab: tabSwitchPrompt.targetTab });
      setActiveTab(tabSwitchPrompt.targetTab);
    } finally {
      setTabSwitchBusy(false);
    }
  };

  const titleTabs = (
    <Tabs className="RogueStar__titleTabs">
      <Tabs.Tab
        selected={resolvedActiveTab === 'body'}
        icon="list"
        className={tabsLocked ? 'Tab--disabled' : undefined}
        aria-disabled={tabsLocked}
        onClick={() => {
          if (!tabsLocked) {
            handleTabChange('body');
          }
        }}>
        Body Markings
      </Tabs.Tab>
      <Tabs.Tab
        selected={resolvedActiveTab === 'custom'}
        icon={resolveCustomDesignerTabIcon(allowCustomTab)}
        className={tabsLocked ? 'Tab--disabled' : undefined}
        aria-disabled={tabsLocked}
        tooltip={resolveCustomDesignerTabTooltip(allowCustomTab)}
        onClick={() => {
          if (tabsLocked) {
            return;
          }
          if (!allowCustomTab) {
            setEnableCustomPromptOpen(true);
            return;
          }
          handleTabChange('custom');
        }}>
        Custom Marking Designer
      </Tabs.Tab>
    </Tabs>
  );

  return (
    <Window
      theme="nanotrasen rogue-star-window"
      width={1720}
      height={950}
      resizable
      canClose={false}
      statusIcon={customStatusIcon}
      buttons={titleTabs}>
      <ToolBootstrapScheduler
        isPlaceholderTool={isPlaceholderTool}
        toolBootstrapScheduled={toolBootstrapScheduled}
        setToolBootstrapScheduled={setToolBootstrapScheduled}
        setTool={setPrimaryTool}
      />
      <EnableCustomMarkingsScheduler
        allowCustomTab={allowCustomTab}
        switchPending={enableCustomSwitchPending}
        onReady={handleEnableCustomReady}
      />
      <PhantomClickScheduler
        phantomClickScheduled={phantomClickScheduled}
        isPlaceholderTool={isPlaceholderTool}
        activeTool={activePrimaryTool}
        setPhantomClickScheduled={setPhantomClickScheduled}
        setTool={setPrimaryTool}
      />
      <ToolBootstrapReset
        stateToken={stateToken}
        onReset={handleToolBootstrapReset}
      />
      <DesignerUndoHotkeyListener canUndo={canUndoDrafts} onUndo={handleUndo} />
      <Window.Content scrollable overflowX="auto">
        {resolvedActiveTab === 'custom' ? (
          <Box className="RogueStar" position="relative" minHeight="100%">
            <Flex direction="row" fill gap={2} wrap={false} align="stretch">
              <DesignerLeftColumn
                data={data}
                currentDirectionKey={currentDirectionKey}
                setDirection={setDirection}
                activePartKey={activePartKey}
                activePartLabel={activePartLabel}
                resolvedPartReplacementMap={resolvedPartReplacementMap}
                partPaintPresenceMap={partPaintPresenceMap}
                resolvedPartCanvasSizeMap={resolvedPartCanvasSizeMap}
                resolvePartLayeringState={resolvePartLayeringState}
                togglePartLayerPriority={togglePartLayerPriority}
                togglePartReplacement={togglePartReplacement}
                setBodyPart={setBodyPart}
                uiLocked={uiLocked}
                getReferenceOpacityForPart={getReferenceOpacityForPart}
                setReferenceOpacityForPart={setReferenceOpacityForPart}
                pendingSave={pendingSave}
                pendingClose={pendingClose}
                handleSaveProgress={handleSaveProgress}
                handleSafeClose={handleSafeClose}
                handleDiscardAndClose={handleDiscardAndClose}
                handleImport={handleImport}
                handleExport={handleExport}
                primaryTool={activePrimaryTool}
                secondaryTool={activeSecondaryTool}
                onPrimarySelect={assignPrimaryTool}
                onSecondarySelect={assignSecondaryTool}
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
              <CanvasSection
                title={directionTitle}
                canvasFrameStyle={canvasFrameStyle}
                canvasBackgroundStyle={canvasBackgroundStyle}
                canvasTransform={canvasTransform}
                canvasKey={canvasKey}
                backgroundImage={backgroundImage}
                backgroundFallbackColor={backgroundFallbackColor}
                canvasDisplayWidthPx={canvasDisplayWidthPx}
                canvasDisplayHeightPx={canvasDisplayHeightPx}
                canvasPixelSize={canvasPixelSize}
                canvasToolbarProps={canvasToolbarProps}
                referenceGrid={referenceGrid}
                referenceParts={referenceParts}
                currentReferenceOpacity={currentReferenceOpacity}
                resolvedReferenceOpacityMap={resolvedReferenceOpacityMap}
                overlayLayerParts={overlayLayerParts}
                overlayLayerOrder={overlayLayerOrder}
                layerRevision={data.body_part_layer_revision || 0}
                uiCanvasGrid={uiCanvasGrid}
                serverDiffPayload={serverDiffPayload}
                serverDiffSeq={serverDiffSeq}
                serverDiffStroke={serverDiffStroke}
                activePartKey={activePartKey}
                genericReferenceOpacity={genericReferenceOpacity}
                activePrimaryTool={activePrimaryTool}
                activeSecondaryTool={activeSecondaryTool}
                size={size}
                brushColor={brushColor}
                strokeDraftState={strokeDraftState}
                strokeDraftSession={localSessionKey}
                canvasFlushToken={canvasFlushToken}
                canvasHandlers={canvasHandlers}
                resolveToolForButton={resolveToolForButton}
              />
              <PreviewColumn
                renderedPreviewDirs={renderedPreviewDirs}
                previewRevision={previewRevision}
                previewFitToFrame={previewFitToFrame}
                canvasWidth={canvasWidth}
                canvasHeight={canvasHeight}
                resolvedCanvasBackground={resolvedCanvasBackground}
                backgroundFallbackColor={backgroundFallbackColor}
                canvasBackgroundScale={canvasBackgroundScale}
              />
            </Flex>
            {shouldShowLoadingOverlay ? <LoadingOverlay /> : null}
            <SavingOverlayGate
              pendingClose={pendingClose}
              pendingSave={pendingSave}
              pendingCloseMessage={pendingCloseMessage}
              savingProgress={savingProgress}
            />
          </Box>
        ) : (
          <BodyMarkingsTab
            data={data}
            setPendingClose={setPendingClose}
            setPendingSave={setPendingSave}
            canvasBackgroundOptions={canvasBackgroundOptions}
            resolvedCanvasBackground={resolvedCanvasBackground}
            backgroundFallbackColor={backgroundFallbackColor}
            cycleCanvasBackground={cycleCanvasBackground}
            canvasBackgroundScale={canvasBackgroundScale}
            showJobGear={showJobGear}
            onToggleJobGear={() => setShowJobGear(!showJobGear)}
            showLoadoutGear={showLoadoutGear}
            onToggleLoadout={() => setShowLoadoutGear(!showLoadoutGear)}
          />
        )}
      </Window.Content>
      {tabSwitchPrompt ? (
        <UnsavedChangesOverlay
          title="Unsaved changes"
          subtitle={`You have unsaved changes in the ${
            tabSwitchPrompt.sourceTab === 'custom'
              ? 'Custom Marking Designer'
              : 'Body Markings tab'
          }. Save them before switching?`}
          saveLabel="Save and switch"
          discardLabel="Discard and switch"
          busy={tabSwitchBusyState}
          onSave={handleTabSwitchSave}
          onDiscard={handleTabSwitchDiscard}
          onCancel={() => {
            if (!tabSwitchBusyState) {
              setTabSwitchPrompt(null);
            }
          }}
        />
      ) : null}
      <EnableCustomMarkingsGate
        open={enableCustomPromptOpen}
        allowCustomTab={allowCustomTab}
        message={enableCustomDisclaimer}
        busy={enableCustomPromptBusy}
        onConfirm={handleEnableCustomMarkings}
        onCancel={() => {
          if (!enableCustomPromptBusy) {
            setEnableCustomPromptOpen(false);
            setEnableCustomSwitchPending(false);
          }
        }}
      />
    </Window>
  );
};
