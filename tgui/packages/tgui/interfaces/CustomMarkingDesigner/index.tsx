// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2025: New system for allowing players to create custom markings ////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Major refactor to reduce lag, update style, and provide more options //
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Updated to support 64x64 markings /////////////////////////////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support loaout and job gear ////////////////////////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import { Component } from 'inferno';
import { useBackend, useLocalState } from '../../backend';
import { Box, Button, Flex, Section } from '../../components';
import { Window } from '../../layouts';
import { normalizeHex } from '../../utils/color';
import {
  GENERIC_PART_KEY,
  resolveBodyPartLabel,
} from '../../utils/character-preview';
import { PaintCanvas } from '../Canvas';
import {
  DirectionPreviewCanvas,
  MarkingInfoSection,
  PaintToolsSection,
  PhantomClickScheduler,
  LoadingOverlay,
  SavingOverlay,
  SessionControls,
  ToolBootstrapReset,
  ToolBootstrapScheduler,
} from './components';
import {
  CANVAS_FIT_TARGET,
  DOT_SIZE,
  PREVIEW_PIXEL_SIZE,
  DEFAULT_GENERIC_REFERENCE_OPACITY,
  DEFAULT_BODY_PART_REFERENCE_OPACITY,
  ERASER_PREVIEW_COLOR,
  COLOR_PICKER_CUSTOM_SLOTS,
  PLACEHOLDER_TOOL,
  CHIP_BUTTON_CLASS,
  TOOLBAR_GROUP_CLASS,
} from './constants';
import {
  useBrushColorController,
  useCanvasBackground,
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
  buildBodyPartLabelMap,
  buildLocalSessionKey,
  buildReferenceOpacityMapForDesigner,
  convertCompositeLayerMap,
  createSavingHandlers,
  initializeColorPickerSlotsIfNeeded,
} from './utils';
const OVERLAY_PART_KEY = 'overlay';
const HEAD_PART_KEY = 'head';
import type {
  CustomMarkingDesignerData,
  CanvasBackgroundOption,
  StrokeDraftState,
} from './types';
import { useDesignerUiState } from './state';
import CustomEyeIconAsset from '../../../../public/Icons/Rogue Star/eye 1.png';

type UndoHotkeyListenerProps = Readonly<{
  canUndo: boolean;
  onUndo: () => void;
}>;

type CanvasBackgroundToggleProps = Readonly<{
  options: CanvasBackgroundOption[];
  resolvedCanvasBackground: CanvasBackgroundOption | null;
  onCycle: () => void;
}>;

const CanvasBackgroundToggle = ({
  options,
  resolvedCanvasBackground,
  onCycle,
}: CanvasBackgroundToggleProps) => {
  if (!options.length) {
    return null;
  }
  return (
    <Button
      className={CHIP_BUTTON_CLASS}
      icon="image"
      tooltip={`Change canvas background (current: ${resolvedCanvasBackground?.label || 'Default'})`}
      onClick={onCycle}>
      {resolvedCanvasBackground?.label || 'Background'}
    </Button>
  );
};

type PreviewColumnProps = Readonly<{
  renderedPreviewDirs: ReadonlyArray<any>;
  previewRevision: number;
  previewFitToFrame: boolean;
  canvasWidth: number;
  canvasHeight: number;
  resolvedCanvasBackground: CanvasBackgroundOption | null;
  backgroundFallbackColor: string;
  canvasBackgroundScale: number;
}>;

const PreviewColumn = ({
  renderedPreviewDirs,
  previewRevision,
  previewFitToFrame,
  canvasWidth,
  canvasHeight,
  resolvedCanvasBackground,
  backgroundFallbackColor,
  canvasBackgroundScale,
}: PreviewColumnProps) => {
  if (!renderedPreviewDirs.length) {
    return null;
  }
  return (
    <Flex.Item basis="280px" grow={0} shrink={0}>
      <Box className="RogueStar__previewCard" height="100%">
        <Box
          color="label"
          fontWeight="bold"
          mb={1}
          className="RogueStar__previewTitle RogueStar__previewTitle--center">
          Live Preview
        </Box>
        <Box className="RogueStar__previewList">
          {renderedPreviewDirs.map((entry) => (
            <Box
              key={`${entry.dir}-${previewFitToFrame ? 'fit' : 'crop'}`}
              className="RogueStar__previewItem">
              <DirectionPreviewCanvas
                layers={entry.layers}
                pixelSize={Math.max(1, PREVIEW_PIXEL_SIZE)}
                width={canvasWidth}
                height={canvasHeight}
                fitToFrame={previewFitToFrame}
                backgroundImage={
                  resolvedCanvasBackground?.asset?.png
                    ? `data:image/png;base64,${resolvedCanvasBackground.asset.png}`
                    : null
                }
                backgroundColor={backgroundFallbackColor}
                backgroundScale={canvasBackgroundScale}
                backgroundTileWidth={
                  resolvedCanvasBackground?.asset?.width
                    ? resolvedCanvasBackground.asset.width *
                      canvasBackgroundScale
                    : undefined
                }
                backgroundTileHeight={
                  resolvedCanvasBackground?.asset?.height
                    ? resolvedCanvasBackground.asset.height *
                      canvasBackgroundScale
                    : undefined
                }
              />
            </Box>
          ))}
        </Box>
      </Box>
    </Flex.Item>
  );
};

type SavingOverlayGateProps = Readonly<{
  pendingClose: boolean;
  pendingSave: boolean;
  pendingCloseMessage: { title?: string; subtitle?: string } | null;
  savingProgress: any;
}>;

const SavingOverlayGate = ({
  pendingClose,
  pendingSave,
  pendingCloseMessage,
  savingProgress,
}: SavingOverlayGateProps) => {
  if (!pendingClose && !pendingSave) {
    return null;
  }
  return (
    <SavingOverlay
      title={pendingClose ? pendingCloseMessage?.title : 'Saving your changes…'}
      subtitle={
        pendingClose
          ? pendingCloseMessage?.subtitle
          : 'Please keep the client open while we sync your work. The designer will stay open afterward.'
      }
      progress={savingProgress}
    />
  );
};

class DesignerUndoHotkeyListener extends Component<UndoHotkeyListenerProps> {
  handleKeyDown = (event: KeyboardEvent) => {
    const isModifier = event.ctrlKey || event.metaKey;
    if (!isModifier || event.shiftKey) {
      return;
    }
    const keyName = (event.key || '').toLowerCase();
    if (keyName !== 'z') {
      return;
    }
    event.preventDefault();
    event.stopPropagation();
    if (this.props.canUndo) {
      this.props.onUndo();
    }
  };

  componentDidMount() {
    window.addEventListener('keydown', this.handleKeyDown, true);
  }

  componentWillUnmount() {
    window.removeEventListener('keydown', this.handleKeyDown, true);
  }

  render() {
    return null;
  }
}

type CanvasDisplayState = Readonly<{
  canvasWidth: number;
  canvasHeight: number;
  canvasPixelSize: number;
  canvasDisplayWidthPx: number;
  canvasDisplayHeightPx: number;
  canvasTransform: string;
  canvasFitToFrame: boolean;
  previewFitToFrame: boolean;
  toggleCanvasFit: () => void;
}>;

const useCanvasDisplayState = (
  context: any,
  stateToken: string,
  data: CustomMarkingDesignerData
): CanvasDisplayState => {
  const maxCanvasWidth = Math.max(1, data.max_width || 64);
  const maxCanvasHeight = Math.max(1, data.max_height || 64);
  const defaultCanvasWidth = Math.max(1, data.default_width || 32);
  const defaultCanvasHeight = Math.max(1, data.default_height || 32);
  const canvasWidth = maxCanvasWidth;
  const canvasHeight = maxCanvasHeight;
  const activeCanvasWidth = Math.min(
    maxCanvasWidth,
    Math.max(1, data.active_canvas_width || data.width || defaultCanvasWidth)
  );
  const activeCanvasHeight = Math.min(
    maxCanvasHeight,
    Math.max(1, data.active_canvas_height || data.height || defaultCanvasHeight)
  );
  const baseDisplayUnits = defaultCanvasWidth || CANVAS_FIT_TARGET;
  const canvasTargetDisplayPx = baseDisplayUnits * DOT_SIZE;
  const canvasFitDefault = false;
  const [canvasFitToFrame, setCanvasFitToFrame] = useLocalState(
    context,
    `canvasFitToFrame-${stateToken}`,
    canvasFitDefault
  );
  const previewFitDefault = false;
  const [previewFitToFrame, setPreviewFitToFrame] = useLocalState(
    context,
    `previewFitToFrame-${stateToken}`,
    previewFitDefault
  );
  const largestCanvasDimension = Math.max(
    canvasWidth,
    canvasHeight,
    activeCanvasWidth,
    activeCanvasHeight
  );
  const canvasPixelSize = Math.max(
    1,
    Math.floor(canvasTargetDisplayPx / Math.max(largestCanvasDimension, 1))
  );
  const canvasDisplayWidthPx = Math.max(
    1,
    Math.round(canvasPixelSize * canvasWidth)
  );
  const canvasDisplayHeightPx = Math.max(
    1,
    Math.round(canvasPixelSize * canvasHeight)
  );
  const canvasZoomScale =
    canvasFitToFrame || canvasWidth <= baseDisplayUnits
      ? 1
      : Math.max(
          canvasWidth / baseDisplayUnits,
          canvasHeight / baseDisplayUnits
        );
  const canvasOffsetY =
    canvasFitToFrame || canvasZoomScale === 1
      ? 0
      : -1 * ((canvasZoomScale - 1) / canvasZoomScale) * canvasDisplayHeightPx +
        1;
  const canvasOffsetX =
    canvasFitToFrame || canvasZoomScale === 1
      ? 0
      : ((1 - canvasZoomScale) * canvasDisplayWidthPx) / (2 * canvasZoomScale) +
        191;
  const canvasTransform = `translate(${canvasOffsetX}px, ${canvasOffsetY}px) scale(${canvasZoomScale})`;
  const toggleCanvasFit = () => {
    const next = !canvasFitToFrame;
    setCanvasFitToFrame(next);
    setPreviewFitToFrame(next);
  };
  return {
    canvasWidth,
    canvasHeight,
    canvasPixelSize,
    canvasDisplayWidthPx,
    canvasDisplayHeightPx,
    canvasTransform,
    canvasFitToFrame,
    previewFitToFrame,
    toggleCanvasFit,
  };
};

const areAllPreviewLayersLoaded = ({
  previewRevision,
  renderedPreviewDirs,
  directions,
}: {
  previewRevision: number;
  renderedPreviewDirs: ReadonlyArray<any>;
  directions: CustomMarkingDesignerData['directions'];
}) =>
  previewRevision > 0 &&
  renderedPreviewDirs.length > 0 &&
  directions.every((dir) =>
    renderedPreviewDirs.some((entry) => entry.dir === dir.dir)
  );

type PreviewInitializationParams = Readonly<{
  loadingOverlay: boolean;
  allPreviewLayersLoaded: boolean;
  setLoadingOverlay: (value: boolean) => void;
  colorPickerSlotsLocked: boolean;
  colorPickerSlotsSignature: string | null;
  setColorPickerSlotsLocked: (value: boolean) => void;
}>;

const applyPreviewInitialization = ({
  loadingOverlay,
  allPreviewLayersLoaded,
  setLoadingOverlay,
  colorPickerSlotsLocked,
  colorPickerSlotsSignature,
  setColorPickerSlotsLocked,
}: PreviewInitializationParams) => {
  if (loadingOverlay && allPreviewLayersLoaded) {
    setTimeout(() => setLoadingOverlay(false), 50);
  }

  if (
    allPreviewLayersLoaded &&
    !colorPickerSlotsLocked &&
    colorPickerSlotsSignature
  ) {
    setColorPickerSlotsLocked(true);
  }
};

type ReferenceOpacityControls = Readonly<{
  currentReferenceOpacity: number;
  genericReferenceOpacity: number;
  resolvedReferenceOpacityMap: Record<string, number>;
  getReferenceOpacityForPart: (partId: string) => number;
  setReferenceOpacityForPart: (partId: string, value: number) => void;
}>;

const createReferenceOpacityControls = ({
  referenceOpacityByPart,
  setReferenceOpacityByPart,
  referenceParts,
  bodyParts,
  showJobGear,
  showLoadoutGear,
  activePartKey,
}: {
  referenceOpacityByPart: Record<string, number>;
  setReferenceOpacityByPart: (map: Record<string, number>) => void;
  referenceParts: any;
  bodyParts: CustomMarkingDesignerData['body_parts'];
  showJobGear: boolean;
  showLoadoutGear: boolean;
  activePartKey: string;
}): ReferenceOpacityControls => {
  const getDefaultReferenceOpacityForPart = (partId: string) =>
    partId === GENERIC_PART_KEY
      ? DEFAULT_GENERIC_REFERENCE_OPACITY
      : DEFAULT_BODY_PART_REFERENCE_OPACITY;

  const getReferenceOpacityForPart = (partId: string) => {
    const targetId =
      partId === OVERLAY_PART_KEY ? GENERIC_PART_KEY : partId || HEAD_PART_KEY;
    const stored = referenceOpacityByPart[targetId];
    if (typeof stored === 'number') {
      return stored;
    }
    return getDefaultReferenceOpacityForPart(targetId);
  };

  const setReferenceOpacityForPart = (partId: string, value: number) => {
    const clamped = Math.min(1, Math.max(0, value));
    const targetId =
      partId === OVERLAY_PART_KEY ? GENERIC_PART_KEY : partId || HEAD_PART_KEY;
    setReferenceOpacityByPart({
      ...referenceOpacityByPart,
      [targetId]: clamped,
    });
  };

  const currentReferenceOpacity = getReferenceOpacityForPart(activePartKey);
  const genericReferenceOpacity = getReferenceOpacityForPart(GENERIC_PART_KEY);

  const referenceOpacityMap = buildReferenceOpacityMapForDesigner(
    referenceParts,
    bodyParts,
    getReferenceOpacityForPart
  );
  const resolvedReferenceOpacityMap: Record<string, number> = {
    ...referenceOpacityMap,
    overlay: genericReferenceOpacity,
  };
  if (referenceParts?.gear_job) {
    resolvedReferenceOpacityMap.gear_job = showJobGear
      ? genericReferenceOpacity
      : 0;
  }
  if (referenceParts?.gear_loadout) {
    resolvedReferenceOpacityMap.gear_loadout = showLoadoutGear
      ? genericReferenceOpacity
      : 0;
  }

  return {
    currentReferenceOpacity,
    genericReferenceOpacity,
    resolvedReferenceOpacityMap,
    getReferenceOpacityForPart,
    setReferenceOpacityForPart,
  };
};

type CanvasToolbarProps = Readonly<{
  canvasFitToFrame: boolean;
  toggleCanvasFit: () => void;
  canvasBackgroundOptions: CanvasBackgroundOption[];
  resolvedCanvasBackground: CanvasBackgroundOption | null;
  cycleCanvasBackground: () => void;
  showJobGear: boolean;
  onToggleJobGear: () => void;
  showLoadoutGear: boolean;
  onToggleLoadout: () => void;
}>;

const CanvasToolbar = ({
  canvasFitToFrame,
  toggleCanvasFit,
  canvasBackgroundOptions,
  resolvedCanvasBackground,
  cycleCanvasBackground,
  showJobGear,
  onToggleJobGear,
  showLoadoutGear,
  onToggleLoadout,
}: CanvasToolbarProps) => (
  <Flex
    align="center"
    justify="flex-start"
    gap={0.5}
    className={TOOLBAR_GROUP_CLASS}
    mb={1}>
    <Button
      className={CHIP_BUTTON_CLASS}
      icon={canvasFitToFrame ? 'compress-arrows-alt' : 'expand-arrows-alt'}
      selected={canvasFitToFrame}
      tooltip="Shrink to show the full 64x64 grid"
      onClick={() => toggleCanvasFit()}>
      Full grid
    </Button>
    <CanvasBackgroundToggle
      options={canvasBackgroundOptions}
      resolvedCanvasBackground={resolvedCanvasBackground}
      onCycle={cycleCanvasBackground}
    />
    <Button
      className={CHIP_BUTTON_CLASS}
      icon="id-card"
      selected={showJobGear}
      tooltip="Show or hide job gear overlays."
      onClick={onToggleJobGear}>
      Job gear
    </Button>
    <Button
      className={CHIP_BUTTON_CLASS}
      icon="toolbox"
      selected={showLoadoutGear}
      tooltip="Show or hide loadout overlays."
      onClick={onToggleLoadout}>
      Loadout
    </Button>
  </Flex>
);

type DesignerLeftColumnProps = Readonly<{
  data: CustomMarkingDesignerData;
  currentDirectionKey: number;
  setDirection: (dir: number) => void;
  activePartKey: string;
  activePartLabel: string;
  resolvedPartReplacementMap: Record<string, any>;
  partPaintPresenceMap: Record<string, any>;
  resolvedPartCanvasSizeMap: Record<string, any>;
  resolvePartLayeringState: any;
  togglePartLayerPriority: (partKey: string) => void;
  togglePartReplacement: (partKey: string) => void;
  setBodyPart: (partKey: string) => void;
  uiLocked: boolean;
  getReferenceOpacityForPart: (partId: string) => number;
  setReferenceOpacityForPart: (partId: string, value: number) => void;
  pendingSave: boolean;
  pendingClose: boolean;
  handleSaveProgress: () => void;
  handleSafeClose: () => void;
  handleDiscardAndClose: () => void;
  handleImport: (type: 'png' | 'dmi') => Promise<void>;
  handleExport: (type: 'png' | 'dmi') => Promise<void>;
  primaryTool: string | null;
  secondaryTool: string | null;
  onPrimarySelect: (tool: string) => void;
  onSecondarySelect: (tool: string) => void;
  blendMode: string;
  setBlendMode: (mode: string) => void;
  analogStrength: number;
  setAnalogStrength: (value: number) => void;
  canUndoDrafts: boolean;
  handleUndo: () => void;
  handleClear: (confirm: boolean) => void;
  size: number;
  setSize: (value: number) => void;
  brushColor: string;
  customColorSlots: (string | null)[];
  handleCustomColorUpdate: (colors: (string | null)[]) => void;
  handleColorPickerApply: (hex: string) => void;
}>;

const DesignerLeftColumn = ({
  data,
  currentDirectionKey,
  setDirection,
  activePartKey,
  activePartLabel,
  resolvedPartReplacementMap,
  partPaintPresenceMap,
  resolvedPartCanvasSizeMap,
  resolvePartLayeringState,
  togglePartLayerPriority,
  togglePartReplacement,
  setBodyPart,
  uiLocked,
  getReferenceOpacityForPart,
  setReferenceOpacityForPart,
  pendingSave,
  pendingClose,
  handleSaveProgress,
  handleSafeClose,
  handleDiscardAndClose,
  handleImport,
  handleExport,
  primaryTool,
  secondaryTool,
  onPrimarySelect,
  onSecondarySelect,
  blendMode,
  setBlendMode,
  analogStrength,
  setAnalogStrength,
  canUndoDrafts,
  handleUndo,
  handleClear,
  size,
  setSize,
  brushColor,
  customColorSlots,
  handleCustomColorUpdate,
  handleColorPickerApply,
}: DesignerLeftColumnProps) => (
  <Flex.Item basis="600px" shrink={0}>
    <Flex
      direction="column"
      gap={2}
      height="100%"
      className="RogueStar__column"
      justify="space-between">
      <Flex.Item>
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
      </Flex.Item>

      <Flex.Item>
        <MarkingInfoSection
          bodyParts={data.body_parts}
          directions={data.directions}
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
        />
      </Flex.Item>

      <Flex.Item>
        <Box className="RogueStar__leftFill">
          <PaintToolsSection
            primaryTool={primaryTool}
            secondaryTool={secondaryTool}
            onPrimarySelect={onPrimarySelect}
            onSecondarySelect={onSecondarySelect}
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
      </Flex.Item>
    </Flex>
  </Flex.Item>
);

type CanvasHandlers = Readonly<{
  onFill: (payload: any) => void;
  onEyedropper: (payload: any) => void;
  onPaint: (payload: any) => void;
  onLine: (payload: any) => void;
  resolveCanvasTool: (toolUsed: string | null, button: number) => any;
  handleUndo: () => void;
  handleDiffApplied: (stroke?: unknown) => void;
}>;

type CanvasSectionProps = Readonly<{
  title: string;
  canvasFrameStyle: Record<string, any>;
  canvasBackgroundStyle?: Record<string, any> | null;
  canvasTransform: string;
  canvasKey: string;
  backgroundImage: string | null;
  backgroundFallbackColor: string;
  canvasDisplayWidthPx: number;
  canvasDisplayHeightPx: number;
  canvasPixelSize: number;
  canvasToolbarProps: CanvasToolbarProps;
  referenceGrid: any;
  referenceParts: any;
  currentReferenceOpacity: number;
  resolvedReferenceOpacityMap: Record<string, number>;
  overlayLayerParts: any;
  overlayLayerOrder: any;
  layerRevision: number;
  uiCanvasGrid: any;
  serverDiffPayload: any;
  serverDiffSeq?: number;
  serverDiffStroke: unknown;
  activePartKey: string;
  genericReferenceOpacity: number;
  activePrimaryTool: string | null;
  activeSecondaryTool: string | null;
  size: number;
  brushColor: string;
  strokeDraftState: StrokeDraftState;
  strokeDraftSession: string;
  canvasFlushToken: number;
  canvasHandlers: CanvasHandlers;
  resolveToolForButton: (button: number) => string | null;
}>;

const CanvasSection = ({
  title,
  canvasFrameStyle,
  canvasBackgroundStyle,
  canvasTransform,
  canvasKey,
  backgroundImage,
  backgroundFallbackColor,
  canvasDisplayWidthPx,
  canvasDisplayHeightPx,
  canvasPixelSize,
  canvasToolbarProps,
  referenceGrid,
  referenceParts,
  currentReferenceOpacity,
  resolvedReferenceOpacityMap,
  overlayLayerParts,
  overlayLayerOrder,
  layerRevision,
  uiCanvasGrid,
  serverDiffPayload,
  serverDiffSeq,
  serverDiffStroke,
  activePartKey,
  genericReferenceOpacity,
  activePrimaryTool,
  activeSecondaryTool,
  size,
  brushColor,
  strokeDraftState,
  strokeDraftSession,
  canvasFlushToken,
  canvasHandlers,
  resolveToolForButton,
}: CanvasSectionProps) => {
  const {
    onFill,
    onEyedropper,
    onPaint,
    onLine,
    resolveCanvasTool,
    handleUndo,
    handleDiffApplied,
  } = canvasHandlers;

  const resolveInteractionTool = (toolUsed: string | null, button: number) =>
    resolveCanvasTool(toolUsed, button);

  const handleCanvasClick = (
    x: number,
    y: number,
    brushSize: number,
    stroke: unknown,
    toolUsed: string | null,
    button: number
  ) => {
    const resolvedTool = resolveInteractionTool(toolUsed, button);
    if (resolvedTool === 'fill') {
      return onFill({ x, y, tool: resolvedTool });
    }
    if (resolvedTool === 'eyedropper') {
      return onEyedropper({ x, y, tool: resolvedTool });
    }
    return onPaint({
      x,
      y,
      brushSize,
      stroke,
      tool: resolvedTool,
    });
  };

  const handleCanvasLine = (
    x1: number,
    y1: number,
    x2: number,
    y2: number,
    brushSize: number,
    stroke: unknown,
    toolUsed: string | null,
    button: number
  ) =>
    onLine({
      x1,
      y1,
      x2,
      y2,
      brushSize,
      stroke,
      tool: resolveInteractionTool(toolUsed, button),
    });

  const handleCanvasFill = (
    x: number,
    y: number,
    toolUsed: string | null,
    button: number
  ) =>
    onFill({
      x,
      y,
      tool: resolveInteractionTool(toolUsed, button),
    });

  const handleEyedropper = (
    x: number,
    y: number,
    toolUsed: string | null,
    button: number
  ) =>
    onEyedropper({
      x,
      y,
      tool: resolveInteractionTool(toolUsed, button),
    });

  return (
    <Flex.Item grow basis="0">
      <Section title={title} fill>
        <Box className="RogueStar__canvasScroll" height="100%">
          <CanvasToolbar {...canvasToolbarProps} />
          <Box className="RogueStar__canvasFrame" style={canvasFrameStyle}>
            <Box
              style={{
                position: 'absolute',
                inset: 0,
                zIndex: 0,
                ...(canvasBackgroundStyle || {}),
              }}
            />
            <PaintCanvas
              key={canvasKey}
              value={uiCanvasGrid || []}
              reference={referenceGrid}
              referenceParts={referenceParts}
              referenceOpacity={
                referenceGrid ? currentReferenceOpacity : undefined
              }
              referenceOpacityMap={resolvedReferenceOpacityMap}
              layerParts={overlayLayerParts}
              layerOrder={overlayLayerOrder}
              layerRevision={layerRevision}
              backgroundImage={backgroundImage}
              backgroundColor={backgroundFallbackColor}
              diff={serverDiffPayload}
              diffSeq={serverDiffSeq}
              diffStroke={serverDiffStroke}
              activeLayerKey={activePartKey}
              otherLayerOpacity={genericReferenceOpacity}
              dotsize={canvasPixelSize}
              legacyGridGuideSize={CANVAS_FIT_TARGET}
              tool={activePrimaryTool ? activePrimaryTool : PLACEHOLDER_TOOL}
              secondaryTool={activeSecondaryTool || undefined}
              resolveToolForButton={(button) => resolveToolForButton(button)}
              size={size}
              previewColor={brushColor}
              finalized={false}
              allowUndoShortcut
              style={{
                position: 'relative',
                zIndex: 1,
                width: `${canvasDisplayWidthPx}px`,
                height: `${canvasDisplayHeightPx}px`,
                transform: canvasTransform,
                transformOrigin: 'top left',
                backgroundColor: 'transparent',
              }}
              onUndo={() => handleUndo()}
              onCanvasClick={(x, y, brushSize, stroke, toolUsed, button) =>
                handleCanvasClick(x, y, brushSize, stroke, toolUsed, button)
              }
              onCanvasLine={(
                x1,
                y1,
                x2,
                y2,
                brushSize,
                stroke,
                toolUsed,
                button
              ) =>
                handleCanvasLine(
                  x1,
                  y1,
                  x2,
                  y2,
                  brushSize,
                  stroke,
                  toolUsed,
                  button
                )
              }
              onCanvasFill={(x, y, toolUsed, button) =>
                handleCanvasFill(x, y, toolUsed, button)
              }
              onEyedropper={(x, y, toolUsed, button) =>
                handleEyedropper(x, y, toolUsed, button)
              }
              strokeDrafts={strokeDraftState}
              strokeDraftSession={strokeDraftSession}
              onDiffApplied={handleDiffApplied}
              flushToken={canvasFlushToken}
            />
          </Box>
        </Box>
      </Section>
    </Flex.Item>
  );
};

const getCanvasFrameStyle = (
  resolvedCanvasBackground: CanvasBackgroundOption | null,
  backgroundFallbackColor: string,
  canvasDisplayWidthPx: number,
  canvasDisplayHeightPx: number
) => ({
  position: 'relative',
  width: `${canvasDisplayWidthPx}px`,
  height: `${canvasDisplayHeightPx}px`,
  borderColor:
    resolvedCanvasBackground && resolvedCanvasBackground.id !== 'default'
      ? backgroundFallbackColor
      : undefined,
  boxShadow:
    resolvedCanvasBackground && resolvedCanvasBackground.id !== 'default'
      ? `0 0 12px ${backgroundFallbackColor}`
      : undefined,
});

const buildCanvasKey = ({
  sessionToken,
  dirKey,
  partKey,
  canvasWidth,
  canvasHeight,
  backgroundId,
}: {
  sessionToken: string | null;
  dirKey: number;
  partKey: string;
  canvasWidth: number;
  canvasHeight: number;
  backgroundId: string;
}) =>
  `${sessionToken || 'session'}-${dirKey}-${partKey}-${canvasWidth}x${canvasHeight}-bg:${backgroundId}`;

export const CustomMarkingDesigner = (_props, context) => {
  const { act, data } = useBackend<CustomMarkingDesignerData>(context);
  const stateToken = data.state_token || 'session';
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
  const [strokeDraftState] = useLocalState<StrokeDraftState>(
    context,
    'strokeDrafts',
    {}
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

  applyPreviewInitialization({
    loadingOverlay,
    allPreviewLayersLoaded,
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
      resolvedCanvasSizeState,
      resolvedPartCanvasSizeMap,
      sendActionAfterSync,
      clearAllLocalDrafts,
      setSavingProgress,
      sendAction,
      reportClientWarning,
      formatError: describeError,
    });

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
        setTool={setPrimaryTool}
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
      </Window.Content>
    </Window>
  );
};
