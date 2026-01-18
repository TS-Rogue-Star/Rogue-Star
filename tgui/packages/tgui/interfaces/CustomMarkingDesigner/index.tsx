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
// Updated by Lira for Rogue Star December 2025: New basic appearence tab added ////////////////////////////////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import { selectBackend, useBackend, useLocalState } from '../../backend';
import { Box, Button, Flex, Tabs } from '../../components';
import { Window } from '../../layouts';
import { normalizeHex, TRANSPARENT_HEX } from '../../utils/color';
import {
  GENERIC_PART_KEY,
  cloneGridData,
  resolveBodyPartLabel,
  type DiffEntry,
  type PreviewDirectionEntry,
  type PreviewLayerEntry,
  type PreviewState,
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
  PayloadPrefetchScheduler,
  PreviewOverrideScheduler,
  PreviewColumn,
  SavingOverlayGate,
  ToolBootstrapReset,
  ToolBootstrapScheduler,
  UnsavedChangesOverlay,
} from './components';
import {
  CHIP_BUTTON_CLASS,
  COLOR_PICKER_CUSTOM_SLOTS,
  ERASER_PREVIEW_COLOR,
} from './constants';
import {
  useBrushColorController,
  useCanvasBackground,
  useCanvasDisplayState,
  useDesignerPreview,
  type RenderedPreviewCache,
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
  applyBodyColorToPreview,
  applyPreviewInitialization,
  areAllPreviewLayersLoaded,
  buildCanvasKey,
  buildBodyPartLabelMap,
  buildBodyMarkingDefinitions,
  buildBodyMarkingSavePayload,
  buildBodyMarkingChunkPlan,
  buildBodyPayloadSignature,
  buildBasicStateFromPayload,
  buildBodySavedStateFromPayload,
  createReferenceOpacityControls,
  getCanvasFrameStyle,
  buildLocalSessionKey,
  convertCompositeLayerMap,
  createSavingHandlers,
  deepCopyMarkings,
  initializeColorPickerSlotsIfNeeded,
  parseHex,
  resolveExportGridForDirPart,
  resolveReferencePartId,
  toHex,
} from './utils';
import {
  buildHiddenBodyPartsByDir,
  buildReferencePartMarkingGridsByDir,
} from './utils/markingOverrides';
import type {
  CustomMarkingDesignerData,
  CanvasBackgroundOption,
  StrokeDraftState,
  BodyMarkingColorTarget,
  BodyMarkingEntry,
  BodyMarkingsPayload,
  BodyMarkingsSavedState,
  BasicAppearancePayload,
  BasicAppearanceState,
  BooleanMapState,
  CustomPreviewOverrideMap,
  PendingPreviewOverrides,
} from './types';
import { useDesignerUiState } from './state';
import CustomEyeIconAsset from '../../../../public/Icons/Rogue Star/eye 1.png';
import {
  BodyMarkingsTab,
  applyAppearanceOverlaysToPreview,
  applyEyeColorToPreview,
  resolveAppearanceContext,
  type AppearancePreviewContext,
} from './BodyMarkingsTab';
import {
  BasicAppearanceTab,
  applyBodyMarkingsToPreview,
  resolveBodyMarkingsContext,
  type BodyMarkingDefinitionCache,
  type BodyMarkingsPreviewContext,
  type BodyMarkingsPreviewCache,
  type BodyMarkingsSignatureCache,
  type MarkingLayersCacheEntry,
} from './BasicAppearanceTab';

type DesignerTabId = 'custom' | 'body' | 'basic';

type PreviewWithMarkingsCache = {
  signature: string;
  previewByDir: Record<number, PreviewDirectionEntry>;
};

type ReferencePartMarkingCache = {
  signature: string;
  gridsByDir: Record<number, Record<string, string[][]>>;
};

type CustomLayerMap = {
  keys: string[];
  layerByKey: Map<string, PreviewLayerEntry>;
};

const REFERENCE_PASSTHROUGH_KEYS = new Set([
  'markings',
  'overlay',
  'gear_job',
  'gear_loadout',
]);
const APPEARANCE_OVERLAY_MASK_SLOTS = new Set([
  'hair',
  'hair_accessory',
  'ears',
  'tail_lower',
  'tail_upper',
  'tail_upper_alt',
  'wing_lower',
  'wing_upper',
]);

const resolveOverlaySlotFromKey = (
  layerKey: string,
  dirKey: number,
  source: string
): string | null => {
  const prefix = `overlay_body_${dirKey}_${source}_`;
  if (!layerKey.startsWith(prefix)) {
    return null;
  }
  const suffix = layerKey.slice(prefix.length);
  const lastUnderscore = suffix.lastIndexOf('_');
  if (lastUnderscore === -1) {
    return null;
  }
  const slot = suffix.slice(0, lastUnderscore);
  return slot || null;
};

const pixelHasColor = (value?: string): boolean =>
  typeof value === 'string' && value.length > 0 && value !== TRANSPARENT_HEX;

const compositePixel = (base: string | undefined, overlay: string): string => {
  if (!pixelHasColor(overlay)) {
    return base || TRANSPARENT_HEX;
  }
  if (!pixelHasColor(base)) {
    return overlay;
  }
  const [sr, sg, sb, sa] = parseHex(overlay);
  if (sa >= 255) {
    return overlay;
  }
  if (sa <= 0) {
    return base || TRANSPARENT_HEX;
  }
  const [dr, dg, db, da] = parseHex(base);
  const srcA = sa / 255;
  const dstA = da / 255;
  const outA = srcA + dstA * (1 - srcA);
  if (outA <= 0) {
    return TRANSPARENT_HEX;
  }
  const outR = Math.round((sr * srcA + dr * dstA * (1 - srcA)) / outA);
  const outG = Math.round((sg * srcA + dg * dstA * (1 - srcA)) / outA);
  const outB = Math.round((sb * srcA + db * dstA * (1 - srcA)) / outA);
  const outAlpha = Math.round(outA * 255);
  if (outAlpha <= 0) {
    return TRANSPARENT_HEX;
  }
  return toHex(outR, outG, outB, outAlpha);
};

const mergeGrid = (target: string[][], source?: string[][] | null) => {
  if (!Array.isArray(target) || !Array.isArray(source)) {
    return;
  }
  for (let x = 0; x < source.length; x += 1) {
    const srcCol = source[x];
    if (!Array.isArray(srcCol)) {
      continue;
    }
    if (!Array.isArray(target[x])) {
      target[x] = [];
    }
    for (let y = 0; y < srcCol.length; y += 1) {
      const val = srcCol[y];
      if (!pixelHasColor(val)) {
        continue;
      }
      target[x][y] = compositePixel(target[x][y], val);
    }
  }
};

const buildAppearanceOverlayGrid = (
  preview: PreviewDirectionEntry[],
  dirKey: number
): string[][] | null => {
  const entry = preview.find((dirEntry) => dirEntry.dir === dirKey);
  if (!entry?.layers) {
    return null;
  }
  const overlayLayers = entry.layers.filter((layer) => {
    if (
      layer?.type !== 'overlay' ||
      layer?.source !== 'base' ||
      typeof layer.key !== 'string' ||
      !layer.key.startsWith('overlay_body_') ||
      !Array.isArray(layer.grid)
    ) {
      return false;
    }
    const slot = resolveOverlaySlotFromKey(
      layer.key,
      dirKey,
      layer.source || 'base'
    );
    return !!slot && APPEARANCE_OVERLAY_MASK_SLOTS.has(slot);
  });
  if (!overlayLayers.length) {
    return null;
  }
  const merged: string[][] = [];
  overlayLayers.forEach((layer) => {
    if (!layer.grid || !layer.grid.length) {
      return;
    }
    mergeGrid(merged, layer.grid);
  });
  return merged.length ? merged : null;
};

const applyAppearanceToReferenceSources = (options: {
  referenceParts: Record<string, string[][]> | null;
  referenceGrid: string[][] | null;
  referenceSignature?: string;
  appearanceContext: AppearancePreviewContext;
  preview: PreviewDirectionEntry[];
  dirKey: number;
}) => {
  const {
    referenceParts,
    referenceGrid,
    referenceSignature,
    appearanceContext,
    preview,
    dirKey,
  } = options;
  const preservedParts: Record<string, string[][]> = {};
  const layers: PreviewLayerEntry[] = [];
  if (referenceGrid && referenceGrid.length) {
    layers.push({
      type: 'body',
      key: 'body',
      grid: referenceGrid,
    });
  }
  if (referenceParts) {
    Object.entries(referenceParts).forEach(([partId, grid]) => {
      if (!grid || !grid.length) {
        return;
      }
      if (REFERENCE_PASSTHROUGH_KEYS.has(partId)) {
        preservedParts[partId] = grid;
        return;
      }
      layers.push({
        type: 'reference_part',
        key: `ref_${partId}`,
        grid,
      });
    });
  }
  const recolored =
    layers.length > 0
      ? applyEyeColorToPreview(
          applyBodyColorToPreview(
            [
              {
                dir: dirKey,
                label: '',
                layers,
              },
            ],
            appearanceContext.previewBaseBodyColor,
            appearanceContext.previewTargetBodyColor,
            appearanceContext.bodyColorExcludedParts
          ),
          appearanceContext.previewBaseEyeColor,
          appearanceContext.previewTargetEyeColor,
          appearanceContext.previewTargetBodyColor
        )
      : null;
  let nextReferenceGrid = referenceGrid;
  const nextReferenceParts: Record<string, string[][]> = {
    ...preservedParts,
  };
  if (recolored?.[0]?.layers) {
    recolored[0].layers.forEach((layer) => {
      if (!layer?.grid) {
        return;
      }
      if (layer.type === 'body' && layer.key === 'body') {
        nextReferenceGrid = layer.grid;
        return;
      }
      if (layer.type !== 'reference_part' || typeof layer.key !== 'string') {
        return;
      }
      const partId = resolveReferencePartId(layer.key);
      if (!partId) {
        return;
      }
      nextReferenceParts[partId] = layer.grid;
    });
  }
  const appearanceOverlayGrid = buildAppearanceOverlayGrid(preview, dirKey);
  if (appearanceOverlayGrid) {
    const existingOverlay = nextReferenceParts.overlay;
    const merged = existingOverlay
      ? cloneGridData(existingOverlay)
      : cloneGridData(appearanceOverlayGrid);
    if (existingOverlay) {
      mergeGrid(merged, appearanceOverlayGrid);
    }
    nextReferenceParts.overlay = merged;
  }
  const nextSignature =
    appearanceContext.appearanceSignature.length > 0
      ? [referenceSignature, `app:${appearanceContext.appearanceSignature}`]
          .filter((entry) => !!entry)
          .join('|')
      : referenceSignature;
  return {
    referenceParts: Object.keys(nextReferenceParts).length
      ? nextReferenceParts
      : referenceParts,
    referenceGrid: nextReferenceGrid,
    referenceSignature: nextSignature,
  };
};

const resolveCustomDesignerTabIcon = (allowCustomTab: boolean) =>
  allowCustomTab ? 'paint-brush' : 'lock';

const resolveCustomDesignerTabTooltip = (allowCustomTab: boolean) =>
  allowCustomTab ? undefined : 'Enable Custom Markings to use the designer.';

const CLIENT_PREVIEW_EPOCH_STRIDE = 1000000;

const buildBooleanMapSignature = (
  map?: Record<string, boolean> | null
): string => {
  if (!map) {
    return '';
  }
  return Object.keys(map)
    .filter((key) => map[key])
    .sort()
    .join(',');
};

const buildBooleanDirMapSignature = (
  map?: Record<number, Record<string, boolean>> | null
): string => {
  if (!map) {
    return '';
  }
  const segments: string[] = [];
  Object.keys(map).forEach((rawKey) => {
    const dirKey = Number(rawKey);
    if (!Number.isFinite(dirKey)) {
      return;
    }
    const partSig = buildBooleanMapSignature(map[dirKey]);
    if (partSig.length) {
      segments.push(`${dirKey}:${partSig}`);
    }
  });
  return segments.sort().join('|');
};

const collectCustomLayerMap = (
  layers: PreviewLayerEntry[] | null | undefined
): CustomLayerMap => {
  const keys: string[] = [];
  const layerByKey = new Map<string, PreviewLayerEntry>();
  (layers || []).forEach((layer) => {
    if (layer?.type !== 'custom') {
      return;
    }
    const key = layer.key;
    if (typeof key !== 'string' || !key.length) {
      return;
    }
    keys.push(key);
    layerByKey.set(key, layer);
  });
  return { keys, layerByKey };
};

const customLayerKeysMatch = (a: string[], b: string[]): boolean => {
  if (a.length !== b.length) {
    return false;
  }
  if (!a.length) {
    return true;
  }
  const setB = new Set(b);
  return a.every((key) => setB.has(key));
};

const resolvePreviewDirsWithMarkings = (options: {
  preview: PreviewDirectionEntry[];
  context: BodyMarkingsPreviewContext | null;
  stripReferenceMarkings: boolean;
  suppressedPartsByDir?: Record<number, Record<string, boolean>>;
  activeDirKey: number;
  cache: PreviewWithMarkingsCache;
  signature: string;
}): PreviewDirectionEntry[] => {
  const {
    preview,
    context,
    stripReferenceMarkings,
    suppressedPartsByDir,
    activeDirKey,
    cache,
    signature,
  } = options;
  if (!preview.length) {
    cache.signature = signature;
    cache.previewByDir = {};
    return preview;
  }
  if (cache.signature !== signature) {
    cache.signature = signature;
    const markedPreview = applyBodyMarkingsToPreview({
      preview,
      context,
      stripReferenceMarkings,
      suppressedPartsByDir,
    });
    const previewByDir: Record<number, PreviewDirectionEntry> = {};
    markedPreview.forEach((entry) => {
      previewByDir[entry.dir] = entry;
    });
    cache.previewByDir = previewByDir;
    return markedPreview;
  }
  const previewByDir = cache.previewByDir || {};
  return preview.map((entry) => {
    const cachedEntry = previewByDir[entry.dir];
    if (!cachedEntry) {
      const markedPreview = applyBodyMarkingsToPreview({
        preview: [entry],
        context,
        stripReferenceMarkings,
        suppressedPartsByDir,
      });
      const markedEntry = markedPreview[0] || entry;
      previewByDir[entry.dir] = markedEntry;
      return markedEntry;
    }
    if (entry.dir !== activeDirKey) {
      return cachedEntry;
    }
    const cachedLayers = cachedEntry.layers || [];
    const baseLayers = entry.layers || [];
    const cachedCustom = collectCustomLayerMap(cachedLayers);
    const baseCustom = collectCustomLayerMap(baseLayers);
    if (!customLayerKeysMatch(cachedCustom.keys, baseCustom.keys)) {
      const markedPreview = applyBodyMarkingsToPreview({
        preview: [entry],
        context,
        stripReferenceMarkings,
        suppressedPartsByDir,
      });
      const markedEntry = markedPreview[0] || entry;
      previewByDir[entry.dir] = markedEntry;
      return markedEntry;
    }
    let changed = false;
    const nextLayers = cachedLayers.map((layer) => {
      if (layer?.type !== 'custom' || typeof layer.key !== 'string') {
        return layer;
      }
      const baseLayer = baseCustom.layerByKey.get(layer.key);
      if (!baseLayer || baseLayer.grid === layer.grid) {
        return layer;
      }
      changed = true;
      return { ...layer, grid: baseLayer.grid };
    });
    if (!changed) {
      return cachedEntry;
    }
    const nextEntry = { ...cachedEntry, layers: nextLayers };
    previewByDir[entry.dir] = nextEntry;
    return nextEntry;
  });
};

const resolvePreviewRefreshToken = (token?: number | null): number =>
  typeof token === 'number' ? token : 0;

const resolveDirectionSignature = (
  directions: CustomMarkingDesignerData['directions']
): string =>
  Array.isArray(directions)
    ? directions.map((entry) => entry.dir).join('|')
    : '';

const resolveLayerParts = (options: {
  resolvedActiveTab: DesignerTabId;
  bodyPartLayers: CustomMarkingDesignerData['body_part_layers'];
  canvasWidth: number;
  canvasHeight: number;
}) =>
  options.resolvedActiveTab === 'custom'
    ? convertCompositeLayerMap(
        options.bodyPartLayers,
        options.canvasWidth,
        options.canvasHeight
      )
    : null;

const resolvePayloadSnapshots = (options: {
  context: any;
  bodyPayload: BodyMarkingsPayload | null;
  basicPayload: BasicAppearancePayload | null;
  dataBodyPayload?: BodyMarkingsPayload | null;
  dataBasicPayload?: BasicAppearancePayload | null;
}): {
  bodyPayloadSnapshot: BodyMarkingsPayload | null;
  basicPayloadSnapshot: BasicAppearancePayload | null;
} => {
  const sharedStateSnapshot =
    selectBackend(options.context.store.getState()).shared || {};
  const bodyPayloadSnapshot =
    (sharedStateSnapshot.bodyPayload as
      | BodyMarkingsPayload
      | null
      | undefined) ??
    options.bodyPayload ??
    options.dataBodyPayload ??
    null;
  const basicPayloadSnapshot =
    (sharedStateSnapshot.basicPayload as
      | BasicAppearancePayload
      | null
      | undefined) ??
    options.basicPayload ??
    options.dataBasicPayload ??
    null;
  return { bodyPayloadSnapshot, basicPayloadSnapshot };
};

const resolveDigitigradeAppearanceState = (options: {
  bodyPayloadSnapshot: BodyMarkingsPayload | null;
  basicPayloadSnapshot: BasicAppearancePayload | null;
  basicAppearanceState: BasicAppearanceState;
}): {
  resolvedDigitigrade: boolean;
  markingsAppearanceState: BasicAppearanceState;
} => {
  const { bodyPayloadSnapshot, basicPayloadSnapshot, basicAppearanceState } =
    options;
  const bodyDigitigrade = bodyPayloadSnapshot?.digitigrade;
  const basicDigitigrade = basicPayloadSnapshot?.digitigrade;
  let resolvedDigitigrade = basicAppearanceState.digitigrade;
  if (!basicPayloadSnapshot) {
    if (typeof bodyDigitigrade === 'boolean') {
      resolvedDigitigrade = bodyDigitigrade;
    } else if (typeof basicDigitigrade === 'boolean') {
      resolvedDigitigrade = basicDigitigrade;
    }
  }
  const markingsAppearanceState =
    resolvedDigitigrade === basicAppearanceState.digitigrade
      ? basicAppearanceState
      : { ...basicAppearanceState, digitigrade: resolvedDigitigrade };
  return { resolvedDigitigrade, markingsAppearanceState };
};

const resolveMarkingsPreviewState = (options: {
  bodyPayloadSnapshot: BodyMarkingsPayload | null;
  bodyMarkingsState: Record<string, BodyMarkingEntry>;
  bodyMarkingsOrder: string[];
  markingsAppearanceState: BasicAppearanceState;
  canvasWidth: number;
  canvasHeight: number;
  assetRevision: number;
  directionSignature: string;
  directions: CustomMarkingDesignerData['directions'];
  markingLayersCache: Record<string, MarkingLayersCacheEntry>;
  notifyAssetReady: () => void;
  bodyMarkingDefinitionCache: BodyMarkingDefinitionCache;
  bodyMarkingsSignatureCache: BodyMarkingsSignatureCache;
  bodyMarkingsPreviewCache: BodyMarkingsPreviewCache;
  referencePartMarkingCache: ReferencePartMarkingCache;
}): {
  bodyMarkingsContext: BodyMarkingsPreviewContext | null;
  bodyMarkingsContextSignature: string | null;
  stripReferenceMarkings: boolean;
  resolvedBodyMarkingsSignature: string;
  referencePartMarkingGridsByDir: Record<number, Record<string, string[][]>>;
  markingsHiddenParts: string[];
} => {
  const {
    bodyPayloadSnapshot,
    bodyMarkingsState,
    bodyMarkingsOrder,
    markingsAppearanceState,
    canvasWidth,
    canvasHeight,
    assetRevision,
    directionSignature,
    directions,
    markingLayersCache,
    notifyAssetReady,
    bodyMarkingDefinitionCache,
    bodyMarkingsSignatureCache,
    bodyMarkingsPreviewCache,
    referencePartMarkingCache,
  } = options;
  const {
    definitions: bodyMarkingsDefinitions,
    contextSignature: bodyMarkingsContextSignature,
    context: bodyMarkingsContext,
  } = resolveBodyMarkingsContext({
    bodyPayload: bodyPayloadSnapshot,
    bodyMarkingsState,
    bodyMarkingsOrder,
    appearanceState: markingsAppearanceState,
    canvasWidth,
    canvasHeight,
    assetRevision,
    directionSignature,
    directions,
    markingLayersCache,
    signalAssetUpdate: notifyAssetReady,
    definitionCache: bodyMarkingDefinitionCache,
    signatureCache: bodyMarkingsSignatureCache,
    previewCache: bodyMarkingsPreviewCache,
  });
  const stripReferenceMarkings =
    Object.keys(bodyMarkingsDefinitions || {}).length > 0;
  const resolvedBodyMarkingsSignature = bodyMarkingsContextSignature || '';
  syncReferencePartMarkingCache({
    cache: referencePartMarkingCache,
    signature: resolvedBodyMarkingsSignature,
    layersByDir: bodyMarkingsContext?.layersByDir,
  });
  const referencePartMarkingGridsByDir = referencePartMarkingCache.gridsByDir;
  const markingsHiddenParts = bodyMarkingsContext?.hasHiddenParts
    ? Object.keys(bodyMarkingsContext.hiddenPartsMap)
    : [];
  return {
    bodyMarkingsContext,
    bodyMarkingsContextSignature,
    stripReferenceMarkings,
    resolvedBodyMarkingsSignature,
    referencePartMarkingGridsByDir,
    markingsHiddenParts,
  };
};

const buildRenderedPreviewSignature = (options: {
  previewSourceKey: string;
  previewRevisionKey: string;
  diffSeq?: number | null;
  assetRevision: number;
  directionSignature: string;
  showJobGear: boolean;
  showLoadoutGear: boolean;
  partReplacementSignature: string;
  partPrioritySignature: string;
  canvasWidth: number;
  canvasHeight: number;
}): string => {
  const {
    previewSourceKey,
    previewRevisionKey,
    diffSeq,
    assetRevision,
    directionSignature,
    showJobGear,
    showLoadoutGear,
    partReplacementSignature,
    partPrioritySignature,
    canvasWidth,
    canvasHeight,
  } = options;
  return [
    previewSourceKey,
    previewRevisionKey,
    `diff:${diffSeq ?? 0}`,
    `asset:${assetRevision}`,
    directionSignature,
    showJobGear ? 'job1' : 'job0',
    showLoadoutGear ? 'load1' : 'load0',
    partReplacementSignature,
    partPrioritySignature,
    `${canvasWidth}x${canvasHeight}`,
  ]
    .filter((entry) => entry.length > 0)
    .join('|');
};

const resolvePreviewSourceState = (options: {
  data: CustomMarkingDesignerData;
  bodyPayloadSnapshot: BodyMarkingsPayload | null;
  basicPayloadSnapshot: BasicAppearancePayload | null;
  markingsAppearanceState: BasicAppearanceState;
  previewStateRevision: number;
  clientPreviewEpoch: number;
  setClientPreviewEpoch: (value: number) => void;
  resolvedPartReplacementMap: Record<string, boolean>;
  resolvedPartPriorityMap: Record<string, boolean>;
  assetRevision: number;
  directionSignature: string;
  canvasWidth: number;
  canvasHeight: number;
  showJobGear: boolean;
  showLoadoutGear: boolean;
}): {
  previewData: CustomMarkingDesignerData;
  usingClientPreview: boolean;
  clientPreviewRevision: number;
  renderedPreviewSignature: string;
} => {
  const {
    data,
    bodyPayloadSnapshot,
    basicPayloadSnapshot,
    markingsAppearanceState,
    previewStateRevision,
    clientPreviewEpoch,
    setClientPreviewEpoch,
    resolvedPartReplacementMap,
    resolvedPartPriorityMap,
    assetRevision,
    directionSignature,
    canvasWidth,
    canvasHeight,
    showJobGear,
    showLoadoutGear,
  } = options;
  const bodyPreviewSourceList = bodyPayloadSnapshot?.preview_sources;
  const bodyPreviewSources =
    Array.isArray(bodyPreviewSourceList) && bodyPreviewSourceList.length
      ? bodyPreviewSourceList
      : null;
  const basicPreviewUsesAltSources =
    !!basicPayloadSnapshot?.preview_sources_alt &&
    markingsAppearanceState.digitigrade !== !!basicPayloadSnapshot?.digitigrade;
  const basicPreviewSources = basicPreviewUsesAltSources
    ? basicPayloadSnapshot?.preview_sources_alt
    : basicPayloadSnapshot?.preview_sources;
  const resolvedBasicPreviewSources =
    Array.isArray(basicPreviewSources) && basicPreviewSources.length
      ? basicPreviewSources
      : null;
  const basicPreviewRevision = basicPreviewUsesAltSources
    ? (basicPayloadSnapshot?.preview_revision_alt ??
      basicPayloadSnapshot?.preview_revision ??
      0)
    : (basicPayloadSnapshot?.preview_revision ?? 0);
  const clientPreviewSources =
    resolvedBasicPreviewSources || bodyPreviewSources || null;
  const clientPreviewRevisionBase = resolvedBasicPreviewSources
    ? basicPreviewRevision
    : bodyPreviewSources
      ? (bodyPayloadSnapshot?.preview_revision ?? 0)
      : basicPreviewRevision;
  const usingClientPreview = !!clientPreviewSources;
  const clientPreviewRevision = resolveClientPreviewRevision({
    usingClientPreview,
    clientPreviewRevisionBase,
    clientPreviewEpoch,
    previewStateRevision,
    setClientPreviewEpoch,
  });
  const previewData =
    usingClientPreview && clientPreviewSources
      ? {
          ...data,
          preview_sources: clientPreviewSources,
          preview_revision: clientPreviewRevision,
        }
      : data;
  const partReplacementSignature = buildBooleanMapSignature(
    resolvedPartReplacementMap
  );
  const partPrioritySignature = buildBooleanMapSignature(
    resolvedPartPriorityMap
  );
  const previewSourceKey = resolvedBasicPreviewSources
    ? basicPreviewUsesAltSources
      ? 'basic-alt'
      : 'basic'
    : bodyPreviewSources
      ? 'body'
      : 'none';
  const previewRevisionKey = usingClientPreview
    ? `client:${clientPreviewRevisionBase}`
    : `server:${data.preview_revision ?? 0}`;
  const renderedPreviewSignature = buildRenderedPreviewSignature({
    previewSourceKey,
    previewRevisionKey,
    diffSeq: data.diff_seq,
    assetRevision,
    directionSignature,
    showJobGear,
    showLoadoutGear,
    partReplacementSignature,
    partPrioritySignature,
    canvasWidth,
    canvasHeight,
  });
  return {
    previewData,
    usingClientPreview,
    clientPreviewRevision,
    renderedPreviewSignature,
  };
};

const resolvePreviewMarkingSignatures = (options: {
  appearanceContext: AppearancePreviewContext;
  renderedPreviewSignature: string;
  draftMutationToken: number;
  stripReferenceMarkings: boolean;
  resolvedBodyMarkingsSignature: string;
}): {
  previewHiddenPartsByDir: Record<number, Record<string, boolean>>;
  previewMarkingsSignature: string;
} => {
  const {
    appearanceContext,
    renderedPreviewSignature,
    draftMutationToken,
    stripReferenceMarkings,
    resolvedBodyMarkingsSignature,
  } = options;
  const previewHiddenPartsByDir = buildHiddenBodyPartsByDir(
    appearanceContext.previewDirStatesForLive
  );
  const previewHiddenPartsSignature = buildBooleanDirMapSignature(
    previewHiddenPartsByDir
  );
  const draftMutationSignature = Number.isFinite(draftMutationToken)
    ? `draft:${draftMutationToken}`
    : '';
  const previewMergeSignature = [
    renderedPreviewSignature,
    draftMutationSignature,
  ]
    .filter((entry) => entry.length > 0)
    .join('|');
  const previewMarkingsSignature = [
    previewMergeSignature,
    appearanceContext.appearanceSignature,
    stripReferenceMarkings ? 'strip' : 'keep',
    resolvedBodyMarkingsSignature || 'none',
    previewHiddenPartsSignature,
  ]
    .filter((entry) => entry.length > 0)
    .join('|');
  return { previewHiddenPartsByDir, previewMarkingsSignature };
};

const resolveReferenceSignature = (options: {
  canvasReferenceSignature?: string;
  bodyMarkingsContextSignature: string | null;
}): string | undefined => {
  const { canvasReferenceSignature, bodyMarkingsContextSignature } = options;
  if (!bodyMarkingsContextSignature) {
    return canvasReferenceSignature;
  }
  return [canvasReferenceSignature, `bm:${bodyMarkingsContextSignature}`]
    .filter((entry) => !!entry)
    .join('|');
};

const resolveBackgroundImage = (
  resolvedCanvasBackground: CanvasBackgroundOption | null
): string | null =>
  resolvedCanvasBackground?.asset?.png
    ? `data:image/png;base64,${resolvedCanvasBackground.asset.png}`
    : null;

type DesignerTabStateOptions = {
  initialTab?: string | null;
  allowCustomTab: boolean;
  activeTab: DesignerTabId;
  lastInitialTab: DesignerTabId | null;
  setActiveTab: (tab: DesignerTabId) => void;
  setLastInitialTab: (tab: DesignerTabId | null) => void;
};

const resolveDesignerTabState = (
  options: DesignerTabStateOptions
): {
  resolvedActiveTab: DesignerTabId;
} => {
  const {
    initialTab,
    allowCustomTab,
    activeTab,
    lastInitialTab,
    setActiveTab,
    setLastInitialTab,
  } = options;
  let desiredTab: DesignerTabId | null = null;
  if (
    initialTab === 'body' ||
    initialTab === 'custom' ||
    initialTab === 'basic'
  ) {
    desiredTab = initialTab;
  }
  if (!allowCustomTab && desiredTab === 'custom') {
    desiredTab = 'body';
  }
  if (desiredTab && desiredTab !== lastInitialTab) {
    if (desiredTab !== activeTab) {
      setActiveTab(desiredTab);
    }
    setLastInitialTab(desiredTab);
  }
  const fallbackTab: DesignerTabId =
    desiredTab && desiredTab !== 'custom' ? desiredTab : 'body';
  if (!allowCustomTab && activeTab === 'custom') {
    setActiveTab(fallbackTab);
  }
  const resolvedActiveTab: DesignerTabId =
    !allowCustomTab && activeTab === 'custom' ? fallbackTab : activeTab;
  return { resolvedActiveTab };
};

const syncReferencePartMarkingCache = (options: {
  cache: ReferencePartMarkingCache;
  signature: string;
  layersByDir?: BodyMarkingsPreviewContext['layersByDir'];
}) => {
  const { cache, signature, layersByDir } = options;
  if (cache.signature === signature) {
    return;
  }
  cache.signature = signature;
  cache.gridsByDir = buildReferencePartMarkingGridsByDir(layersByDir);
};

const resolveClientPreviewRevision = (options: {
  usingClientPreview: boolean;
  clientPreviewRevisionBase: number;
  clientPreviewEpoch: number;
  previewStateRevision: number;
  setClientPreviewEpoch: (value: number) => void;
}): number => {
  const {
    usingClientPreview,
    clientPreviewRevisionBase,
    clientPreviewEpoch,
    previewStateRevision,
    setClientPreviewEpoch,
  } = options;
  if (!usingClientPreview) {
    return clientPreviewRevisionBase;
  }
  const initialEpoch = clientPreviewEpoch || 1;
  let resolvedEpoch = initialEpoch;
  const desiredRevision =
    clientPreviewRevisionBase + initialEpoch * CLIENT_PREVIEW_EPOCH_STRIDE;
  if (desiredRevision < previewStateRevision) {
    resolvedEpoch =
      Math.floor(
        (previewStateRevision - clientPreviewRevisionBase) /
          CLIENT_PREVIEW_EPOCH_STRIDE
      ) + 1;
  }
  if (resolvedEpoch !== clientPreviewEpoch) {
    setClientPreviewEpoch(resolvedEpoch);
  }
  return (
    clientPreviewRevisionBase + resolvedEpoch * CLIENT_PREVIEW_EPOCH_STRIDE
  );
};

const syncCustomPreviewInitialization = (options: {
  resolvedActiveTab: DesignerTabId;
  previewDirsWithMarkings: PreviewDirectionEntry[];
  customColorSlots: (string | null)[];
  setCustomColorSlots: (slots: (string | null)[]) => void;
  previewRevision: number;
  colorPickerSlotsSignature: string | null;
  setColorPickerSlotsSignature: (signature: string | null) => void;
  colorPickerSlotsLocked: boolean;
  setColorPickerSlotsLocked: (locked: boolean) => void;
  loadingOverlay: boolean;
  setLoadingOverlay: (value: boolean) => void;
  reloadTargetRevision: number;
  setReloadTargetRevision: (value: number) => void;
  reloadPending: boolean;
  setReloadPending: (value: boolean) => void;
  reloadOverlayMinUntil: number;
  setReloadOverlayMinUntil: (value: number) => void;
  referenceBuildInProgress: boolean;
  directions: CustomMarkingDesignerData['directions'];
}) => {
  const {
    resolvedActiveTab,
    previewDirsWithMarkings,
    customColorSlots,
    setCustomColorSlots,
    previewRevision,
    colorPickerSlotsSignature,
    setColorPickerSlotsSignature,
    colorPickerSlotsLocked,
    setColorPickerSlotsLocked,
    loadingOverlay,
    setLoadingOverlay,
    reloadTargetRevision,
    setReloadTargetRevision,
    reloadPending,
    setReloadPending,
    reloadOverlayMinUntil,
    setReloadOverlayMinUntil,
    referenceBuildInProgress,
    directions,
  } = options;
  if (resolvedActiveTab !== 'custom') {
    return;
  }
  initializeColorPickerSlotsIfNeeded({
    locked: colorPickerSlotsLocked,
    previewDirs: previewDirsWithMarkings,
    customSlots: customColorSlots,
    setCustomSlots: setCustomColorSlots,
    previewRevision,
    colorSignature: colorPickerSlotsSignature,
    setColorSignature: setColorPickerSlotsSignature,
  });

  const allPreviewLayersLoaded = areAllPreviewLayersLoaded({
    previewRevision,
    renderedPreviewDirs: previewDirsWithMarkings,
    directions,
  });

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
};

const syncServerBodyPayload = (options: {
  resolvedActiveTab: DesignerTabId;
  serverBodyPayload: BodyMarkingsPayload | null;
  bodyMarkingsDirty: boolean;
  bodyPayload: BodyMarkingsPayload | null;
  bodyPayloadSignature: string | null;
  setBodyPayloadSignature: (signature: string | null) => void;
  setBodyPayload: (payload: BodyMarkingsPayload | null) => void;
  setBodySavedState: (state: BodyMarkingsSavedState) => void;
  setBodyMarkingsState: (state: Record<string, BodyMarkingEntry>) => void;
  setBodyMarkingsOrder: (order: string[]) => void;
  setBodyMarkingsSelected: (id: string | null) => void;
  setBodyMarkingsDirty: (dirty: boolean) => void;
}) => {
  const {
    resolvedActiveTab,
    serverBodyPayload,
    bodyMarkingsDirty,
    bodyPayload,
    bodyPayloadSignature,
    setBodyPayloadSignature,
    setBodyPayload,
    setBodySavedState,
    setBodyMarkingsState,
    setBodyMarkingsOrder,
    setBodyMarkingsSelected,
    setBodyMarkingsDirty,
  } = options;
  if (resolvedActiveTab === 'body' || !serverBodyPayload || bodyMarkingsDirty) {
    return;
  }
  const isPreviewOnly = !!serverBodyPayload.preview_only;
  const localRevision = bodyPayload?.preview_revision || 0;
  const incomingRevision = serverBodyPayload.preview_revision || 0;
  const shouldApplyPreview = !bodyPayload || incomingRevision >= localRevision;
  const nextSignature = buildBodyPayloadSignature(serverBodyPayload);
  const signatureChanged = nextSignature !== bodyPayloadSignature;
  if ((!isPreviewOnly || shouldApplyPreview) && signatureChanged) {
    setBodyPayloadSignature(nextSignature);
    setBodyPayload(serverBodyPayload);
    const savedState = buildBodySavedStateFromPayload(serverBodyPayload);
    setBodySavedState(savedState);
    setBodyMarkingsState(deepCopyMarkings(savedState.markings));
    setBodyMarkingsOrder([...savedState.order]);
    setBodyMarkingsSelected(savedState.selectedId);
    setBodyMarkingsDirty(false);
  }
};

type ActFn = (action: string, params?: Record<string, unknown>) => void;

const handlePreviewRefreshTokenUpdate = (options: {
  serverPreviewRefreshToken: number;
  lastPreviewRefreshToken: number;
  setLastPreviewRefreshToken: (value: number) => void;
  previewRefreshSkips: number;
  setPreviewRefreshSkips: (value: number) => void;
  resolvedActiveTab: DesignerTabId;
  usingClientPreview: boolean;
  clientPreviewRevision: number;
  dataPreviewRevision?: number | null;
  setReloadTargetRevision: (value: number) => void;
  setReloadPending: (value: boolean) => void;
  bodyPayloadSnapshot: BodyMarkingsPayload | null;
  basicPayloadSnapshot: BasicAppearancePayload | null;
  setBodyMarkingsLoadInProgress: (value: boolean) => void;
  setBodyReloadPending: (value: boolean) => void;
  setBasicAppearanceLoadInProgress: (value: boolean) => void;
  setBasicReloadPending: (value: boolean) => void;
  act: ActFn;
}) => {
  const {
    serverPreviewRefreshToken,
    lastPreviewRefreshToken,
    setLastPreviewRefreshToken,
    previewRefreshSkips,
    setPreviewRefreshSkips,
    resolvedActiveTab,
    usingClientPreview,
    clientPreviewRevision,
    dataPreviewRevision,
    setReloadTargetRevision,
    setReloadPending,
    bodyPayloadSnapshot,
    basicPayloadSnapshot,
    setBodyMarkingsLoadInProgress,
    setBodyReloadPending,
    setBasicAppearanceLoadInProgress,
    setBasicReloadPending,
    act,
  } = options;
  if (serverPreviewRefreshToken === lastPreviewRefreshToken) {
    return;
  }
  setLastPreviewRefreshToken(serverPreviewRefreshToken);
  const shouldSkipPreviewRefresh = previewRefreshSkips > 0;
  if (shouldSkipPreviewRefresh) {
    setPreviewRefreshSkips(Math.max(0, previewRefreshSkips - 1));
    return;
  }
  if (resolvedActiveTab !== 'custom') {
    const previewRevisionValue = usingClientPreview
      ? clientPreviewRevision
      : typeof dataPreviewRevision === 'number'
        ? dataPreviewRevision
        : 0;
    setReloadTargetRevision(previewRevisionValue + 1);
    setReloadPending(true);
  }
  if (bodyPayloadSnapshot) {
    if (resolvedActiveTab === 'body') {
      setBodyMarkingsLoadInProgress(true);
      act('load_body_markings', { preview_only: 1 });
    } else {
      setBodyReloadPending(true);
    }
  }
  if (basicPayloadSnapshot) {
    if (resolvedActiveTab === 'basic') {
      setBasicAppearanceLoadInProgress(true);
      act('load_basic_appearance', { preview_only: 1 });
    } else {
      setBasicReloadPending(true);
    }
  }
};

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
  const [compactMode, setCompactMode] = useLocalState<boolean>(
    context,
    `customMarkingDesignerCompact-${stateToken}`,
    false
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
  const { resolvedActiveTab } = resolveDesignerTabState({
    initialTab: data.initial_tab,
    allowCustomTab,
    activeTab,
    lastInitialTab,
    setActiveTab,
    setLastInitialTab,
  });
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
  const [bodyMarkingsLoadInProgress, setBodyMarkingsLoadInProgress] =
    useLocalState<boolean>(
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
  const [markingLayersCache] = useLocalState<
    Record<string, MarkingLayersCacheEntry>
  >(context, 'customPreviewBodyMarkingLayersCache', {});
  const [bodyMarkingsPreviewCache] = useLocalState<BodyMarkingsPreviewCache>(
    context,
    'customPreviewBodyMarkingPreviewCache',
    { signature: '', context: null }
  );
  const [bodyMarkingDefinitionCache] =
    useLocalState<BodyMarkingDefinitionCache>(
      context,
      'customPreviewBodyMarkingDefinitionCache',
      { payloadRef: null, definitions: {}, offsetX: 0 }
    );
  const [bodyMarkingsSignatureCache] =
    useLocalState<BodyMarkingsSignatureCache>(
      context,
      'customPreviewBodyMarkingsSignatureCache',
      {
        markingsRef: null,
        orderRef: null,
        definitionsRef: null,
        signature: 'none',
      }
    );
  const [referencePartMarkingCache] = useLocalState<ReferencePartMarkingCache>(
    context,
    `customPreviewReferencePartMarkingCache-${stateToken}`,
    { signature: '', gridsByDir: {} }
  );
  const [previewWithMarkingsCache] = useLocalState<PreviewWithMarkingsCache>(
    context,
    `customPreviewMarkedPreviewCache-${stateToken}`,
    { signature: '', previewByDir: {} }
  );
  const [renderedPreviewCache] = useLocalState<RenderedPreviewCache>(
    context,
    `customPreviewRenderedPreviewCache-${stateToken}`,
    { signature: '', previewByDir: {} }
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
  const [bodyPayloadSignature, setBodyPayloadSignature] = useLocalState<
    string | null
  >(
    context,
    `bodyMarkingsPayloadSignature-${stateToken}`,
    data.body_markings_payload
      ? buildBodyPayloadSignature(data.body_markings_payload)
      : null
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
  const [basicReloadPending, setBasicReloadPending] = useLocalState<boolean>(
    context,
    `basicAppearanceReloadPending-${stateToken}`,
    false
  );
  const serverPreviewRefreshToken = resolvePreviewRefreshToken(
    data.preview_refresh_token
  );
  const [lastPreviewRefreshToken, setLastPreviewRefreshToken] =
    useLocalState<number>(
      context,
      `customMarkingPreviewRefreshToken-${stateToken}`,
      serverPreviewRefreshToken
    );
  const [previewRefreshSkips, setPreviewRefreshSkips] = useLocalState<number>(
    context,
    `customMarkingDesignerPreviewRefreshSkips-${stateToken}`,
    0
  );
  const [pendingPreviewOverrides, setPendingPreviewOverrides] =
    useLocalState<PendingPreviewOverrides | null>(
      context,
      `customMarkingPreviewOverrides-${stateToken}`,
      null
    );
  const [clientPreviewEpoch, setClientPreviewEpoch] = useLocalState<number>(
    context,
    `customMarkingDesignerClientPreviewEpoch-${stateToken}`,
    0
  );
  const [basicAppearanceLoadInProgress, setBasicAppearanceLoadInProgress] =
    useLocalState<boolean>(
      context,
      `basicAppearanceLoadInProgress-${stateToken}`,
      false
    );
  const [basicPayload, setBasicPayload] =
    useLocalState<BasicAppearancePayload | null>(
      context,
      'basicPayload',
      data.basic_appearance_payload || null
    );
  const basicInitialState = buildBasicStateFromPayload(
    data.basic_appearance_payload
  );
  const [basicAppearanceState, setBasicAppearanceState] =
    useLocalState<BasicAppearanceState>(
      context,
      'basicAppearanceState',
      basicInitialState
    );
  const [basicAppearanceDirty, setBasicAppearanceDirty] =
    useLocalState<boolean>(context, 'basicAppearanceDirty', false);
  const [basicSavedState, setBasicSavedState] =
    useLocalState<BasicAppearanceState>(
      context,
      'basicAppearanceSavedState',
      basicInitialState
    );
  const [basicPendingSave, setBasicPendingSave] = useLocalState<boolean>(
    context,
    'basicAppearancePendingSave',
    false
  );
  const [basicPendingClose, setBasicPendingClose] = useLocalState<boolean>(
    context,
    'basicAppearancePendingClose',
    false
  );
  const [strokeDraftState] = useLocalState<StrokeDraftState>(
    context,
    'strokeDrafts',
    {}
  );
  const [draftMutationToken, setDraftMutationToken] = useLocalState<number>(
    context,
    `customMarkingDraftMutationToken-${stateToken}`,
    0
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

  const layerParts = resolveLayerParts({
    resolvedActiveTab,
    bodyPartLayers: data.body_part_layers,
    canvasWidth,
    canvasHeight,
  });
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
    commitFlagStates,
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
  const { bodyPayloadSnapshot, basicPayloadSnapshot } = resolvePayloadSnapshots(
    {
      context,
      bodyPayload,
      basicPayload,
      dataBodyPayload: data.body_markings_payload,
      dataBasicPayload: data.basic_appearance_payload,
    }
  );
  const directionSignature = resolveDirectionSignature(data.directions);
  const { resolvedDigitigrade, markingsAppearanceState } =
    resolveDigitigradeAppearanceState({
      bodyPayloadSnapshot,
      basicPayloadSnapshot,
      basicAppearanceState,
    });
  const {
    bodyMarkingsContext,
    bodyMarkingsContextSignature,
    stripReferenceMarkings,
    resolvedBodyMarkingsSignature,
    referencePartMarkingGridsByDir,
    markingsHiddenParts,
  } = resolveMarkingsPreviewState({
    bodyPayloadSnapshot,
    bodyMarkingsState,
    bodyMarkingsOrder,
    markingsAppearanceState,
    canvasWidth,
    canvasHeight,
    assetRevision,
    directionSignature,
    directions: data.directions,
    markingLayersCache,
    notifyAssetReady,
    bodyMarkingDefinitionCache,
    bodyMarkingsSignatureCache,
    bodyMarkingsPreviewCache,
    referencePartMarkingCache,
  });
  const {
    previewData,
    usingClientPreview,
    clientPreviewRevision,
    renderedPreviewSignature,
  } = resolvePreviewSourceState({
    data,
    bodyPayloadSnapshot,
    basicPayloadSnapshot,
    markingsAppearanceState,
    previewStateRevision: previewState.revision,
    clientPreviewEpoch,
    setClientPreviewEpoch,
    resolvedPartReplacementMap,
    resolvedPartPriorityMap,
    assetRevision,
    directionSignature,
    canvasWidth,
    canvasHeight,
    showJobGear,
    showLoadoutGear,
  });
  const {
    derivedPreviewState,
    overlayLayerParts,
    overlayLayerOrder,
    referenceParts,
    referenceGrid,
    referenceSignature,
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
    data: previewData,
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
    referencePartMarkingGridsByDir,
    markingsHiddenParts,
    renderedPreviewCache,
    renderedPreviewSignature,
    draftMutationToken,
    enabled: resolvedActiveTab === 'custom',
  });
  const appearanceContext = resolveAppearanceContext({
    previewDirStates: derivedPreviewState.dirs,
    basicPayload: basicPayloadSnapshot,
    basicAppearanceState: markingsAppearanceState,
    fallbackDigitigrade: resolvedDigitigrade,
  });
  const previewWithBaseColors = applyEyeColorToPreview(
    applyBodyColorToPreview(
      renderedPreviewDirs,
      appearanceContext.previewBaseBodyColor,
      appearanceContext.previewTargetBodyColor,
      appearanceContext.bodyColorExcludedParts
    ),
    appearanceContext.previewBaseEyeColor,
    appearanceContext.previewTargetEyeColor,
    appearanceContext.previewTargetBodyColor
  );
  const previewWithAppearance = applyAppearanceOverlaysToPreview({
    preview: previewWithBaseColors,
    previewDirStatesForLive: appearanceContext.previewDirStatesForLive,
    appearanceContext,
    canvasWidth,
    canvasHeight,
    showJobGear,
    showLoadoutGear,
    signalAssetUpdate: notifyAssetReady,
  });
  const { previewHiddenPartsByDir, previewMarkingsSignature } =
    resolvePreviewMarkingSignatures({
      appearanceContext,
      renderedPreviewSignature,
      draftMutationToken,
      stripReferenceMarkings,
      resolvedBodyMarkingsSignature,
    });
  const previewDirsWithMarkings = resolvePreviewDirsWithMarkings({
    preview: previewWithAppearance,
    context: bodyMarkingsContext,
    stripReferenceMarkings,
    suppressedPartsByDir: previewHiddenPartsByDir,
    activeDirKey: currentDirectionKey,
    cache: previewWithMarkingsCache,
    signature: previewMarkingsSignature,
  });
  const {
    referenceParts: canvasReferenceParts,
    referenceGrid: canvasReferenceGrid,
    referenceSignature: canvasReferenceSignature,
  } = applyAppearanceToReferenceSources({
    referenceParts,
    referenceGrid,
    referenceSignature,
    appearanceContext,
    preview: previewWithAppearance,
    dirKey: currentDirectionKey,
  });
  const resolvedReferenceSignature = resolveReferenceSignature({
    canvasReferenceSignature,
    bodyMarkingsContextSignature,
  });

  syncCustomPreviewInitialization({
    resolvedActiveTab,
    previewDirsWithMarkings,
    customColorSlots,
    setCustomColorSlots,
    previewRevision,
    colorPickerSlotsSignature,
    setColorPickerSlotsSignature,
    colorPickerSlotsLocked,
    setColorPickerSlotsLocked,
    loadingOverlay,
    setLoadingOverlay,
    reloadTargetRevision,
    setReloadTargetRevision,
    reloadPending,
    setReloadPending,
    reloadOverlayMinUntil,
    setReloadOverlayMinUntil,
    referenceBuildInProgress: !!data.reference_build_in_progress,
    directions: data.directions,
  });

  const strokeDraftManager = createStrokeDraftManager({
    context,
    getLocalSessionKey: () => localSessionKey,
    getActivePartKey: () => activePartKey,
    getCurrentDirectionKey: () => currentDirectionKey,
    allocateDraftSequence,
    notifyDraftMutation: () =>
      setDraftMutationToken((draftMutationToken + 1) % 1000000),
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
    referenceParts: canvasReferenceParts,
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
  const convertUiGridToComposite = (grid?: string[][]): string[][] | null => {
    if (!Array.isArray(grid) || !grid.length) {
      return null;
    }
    const width = grid.length;
    let height = 0;
    for (const column of grid) {
      if (Array.isArray(column) && column.length > height) {
        height = column.length;
      }
    }
    if (!height) {
      return null;
    }
    const result: string[][] = Array.from({ length: width }, () =>
      Array.from({ length: height }, () => TRANSPARENT_HEX)
    );
    for (let x = 0; x < width; x += 1) {
      const column = grid[x];
      if (!Array.isArray(column)) {
        continue;
      }
      for (let uiY = 0; uiY < column.length; uiY += 1) {
        const y = height - 1 - uiY;
        if (y < 0 || y >= height) {
          continue;
        }
        const value = column[uiY];
        result[x][y] = value || TRANSPARENT_HEX;
      }
    }
    return result;
  };
  type CustomPartsMergeOverrides = {
    draftDiffIndex?: Record<number, Record<string, DiffEntry[]>> | null;
    activeDraftDiff?: DiffEntry[] | null;
    previewOverrides?: CustomPreviewOverrideMap | null;
  };
  const buildCustomPartsPayload = (
    dirKey: number,
    dirState: PreviewState['dirs'][number] | undefined,
    dirDrafts?: Record<string, DiffEntry[]> | null,
    activeDraftOverride?: DiffEntry[] | null
  ): Record<string, string[][]> | null => {
    const partIds = new Set<string>();
    if (dirState?.customParts) {
      for (const partId of Object.keys(dirState.customParts)) {
        if (partId) {
          partIds.add(partId);
        }
      }
    }
    if (dirDrafts) {
      for (const partId of Object.keys(dirDrafts)) {
        if (partId) {
          partIds.add(partId);
        }
      }
    }
    if (dirKey === currentDirectionKey && activePartKey) {
      partIds.add(activePartKey);
    }
    if (!partIds.size) {
      return null;
    }
    const next: Record<string, string[][]> = {};
    partIds.forEach((partId) => {
      if (!partId) {
        return;
      }
      const resolvedGrid = resolveExportGridForDirPart({
        dirState,
        dirKey,
        partKey: partId,
        canvasWidth,
        canvasHeight,
        dirDrafts: dirDrafts || null,
        activeDirKey: currentDirectionKey,
        activePartKey,
        activeDraftDiff:
          activeDraftOverride !== undefined
            ? activeDraftOverride
            : activeDraftDiff,
      });
      if (!resolvedGrid) {
        return;
      }
      const converted = convertUiGridToComposite(resolvedGrid);
      if (converted) {
        next[partId] = converted;
      }
    });
    return Object.keys(next).length ? next : null;
  };
  const buildCustomPreviewOverrides = (
    overrides?: CustomPartsMergeOverrides
  ): CustomPreviewOverrideMap | null => {
    if (!derivedPreviewState || !derivedPreviewState.dirs) {
      return null;
    }
    const resolvedDraftIndex =
      overrides?.draftDiffIndex !== undefined
        ? overrides.draftDiffIndex
        : draftDiffIndex;
    const resolvedActiveDraft =
      overrides?.activeDraftDiff !== undefined
        ? overrides.activeDraftDiff
        : activeDraftDiff;
    const entries = Object.entries(derivedPreviewState.dirs);
    const nextOverrides: CustomPreviewOverrideMap = {};
    for (const [rawDirKey, dirState] of entries) {
      const dirKey = Number(rawDirKey);
      if (!Number.isFinite(dirKey)) {
        continue;
      }
      const dirDrafts = resolvedDraftIndex?.[dirKey] || null;
      const customParts = buildCustomPartsPayload(
        dirKey,
        dirState,
        dirDrafts,
        resolvedActiveDraft
      );
      const partOrder =
        Array.isArray(dirState?.partOrder) && dirState.partOrder.length
          ? dirState.partOrder
          : null;
      if (!customParts && !partOrder) {
        continue;
      }
      nextOverrides[dirKey] = {
        ...(customParts ? { custom_parts: customParts } : {}),
        ...(partOrder ? { part_order: partOrder } : {}),
      };
    }
    return Object.keys(nextOverrides).length ? nextOverrides : null;
  };
  const mergePreviewSourcesWithCustomParts = (
    sources:
      | BodyMarkingsPayload['preview_sources']
      | BasicAppearancePayload['preview_sources'],
    previewState: PreviewState,
    overrides?: CustomPartsMergeOverrides
  ) => {
    if (!Array.isArray(sources) || !sources.length) {
      return { sources, changed: false };
    }
    const previewOverrides = overrides?.previewOverrides || null;
    const resolvedDraftIndex =
      overrides?.draftDiffIndex !== undefined
        ? overrides.draftDiffIndex
        : draftDiffIndex;
    const resolvedActiveDraft =
      overrides?.activeDraftDiff !== undefined
        ? overrides.activeDraftDiff
        : activeDraftDiff;
    let changed = false;
    const nextSources = sources.map((source) => {
      if (!source) {
        return source;
      }
      if (previewOverrides) {
        const overrideEntry = previewOverrides[source.dir];
        if (!overrideEntry) {
          return source;
        }
        const customParts = overrideEntry.custom_parts || null;
        const partOrder = overrideEntry.part_order || null;
        if (!customParts && !partOrder) {
          return source;
        }
        changed = true;
        return {
          ...source,
          ...(customParts ? { custom_parts: customParts } : {}),
          ...(partOrder ? { part_order: partOrder } : {}),
        };
      }
      const dirState = previewState.dirs?.[source.dir];
      if (!dirState) {
        return source;
      }
      const dirDrafts = resolvedDraftIndex?.[source.dir] || null;
      const customParts = buildCustomPartsPayload(
        source.dir,
        dirState,
        dirDrafts,
        resolvedActiveDraft
      );
      const partOrder =
        Array.isArray(dirState.partOrder) && dirState.partOrder.length
          ? dirState.partOrder
          : null;
      if (!customParts && !partOrder) {
        return source;
      }
      changed = true;
      return {
        ...source,
        ...(customParts ? { custom_parts: customParts } : {}),
        ...(partOrder ? { part_order: partOrder } : {}),
      };
    });
    return { sources: nextSources, changed };
  };
  const applyPreviewOverridesToBodyPayload = (
    payload: BodyMarkingsPayload,
    overrides: CustomPreviewOverrideMap
  ) => {
    const { sources, changed } = mergePreviewSourcesWithCustomParts(
      payload.preview_sources,
      derivedPreviewState,
      { previewOverrides: overrides }
    );
    if (!changed) {
      return payload;
    }
    return {
      ...payload,
      preview_sources: sources,
      preview_revision: (payload.preview_revision || 0) + 1,
    };
  };
  const applyPreviewOverridesToBasicPayload = (
    payload: BasicAppearancePayload,
    overrides: CustomPreviewOverrideMap
  ) => {
    let changed = false;
    let next = payload;
    const primary = mergePreviewSourcesWithCustomParts(
      payload.preview_sources,
      derivedPreviewState,
      { previewOverrides: overrides }
    );
    if (primary.changed) {
      changed = true;
      next = {
        ...next,
        preview_sources: primary.sources,
        preview_revision: (payload.preview_revision || 0) + 1,
      };
    }
    const alt = mergePreviewSourcesWithCustomParts(
      payload.preview_sources_alt,
      derivedPreviewState,
      { previewOverrides: overrides }
    );
    if (alt.changed) {
      if (!changed) {
        next = { ...next };
      }
      next = {
        ...next,
        preview_sources_alt: alt.sources,
        preview_revision_alt: (payload.preview_revision_alt || 0) + 1,
      };
      changed = true;
    }
    return changed ? next : payload;
  };
  const syncExternalPreviewSources = (
    overrides?: CustomPartsMergeOverrides
  ) => {
    if (!derivedPreviewState || !derivedPreviewState.dirs) {
      return;
    }
    const previewOverrides = buildCustomPreviewOverrides(overrides);
    if (!previewOverrides) {
      setPendingPreviewOverrides(null);
      return;
    }
    const pendingBody = !bodyPayload;
    const pendingBasic = !basicPayload;
    if (bodyPayload) {
      const nextBody = applyPreviewOverridesToBodyPayload(
        bodyPayload,
        previewOverrides
      );
      if (nextBody !== bodyPayload) {
        setBodyPayload(nextBody);
      }
    }
    if (basicPayload) {
      const nextBasic = applyPreviewOverridesToBasicPayload(
        basicPayload,
        previewOverrides
      );
      if (nextBasic !== basicPayload) {
        setBasicPayload(nextBasic);
      }
    }
    if (pendingBody || pendingBasic) {
      setPendingPreviewOverrides({
        overrides: previewOverrides,
        pendingBody,
        pendingBasic,
      });
    } else {
      setPendingPreviewOverrides(null);
    }
  };
  const handleApplyPendingPreviewOverrides = (options: {
    overrides: CustomPreviewOverrideMap;
    applyBody: boolean;
    applyBasic: boolean;
  }) => {
    const { overrides, applyBody, applyBasic } = options;
    if (applyBody && bodyPayload) {
      const nextBody = applyPreviewOverridesToBodyPayload(
        bodyPayload,
        overrides
      );
      if (nextBody !== bodyPayload) {
        setBodyPayload(nextBody);
      }
    }
    if (applyBasic && basicPayload) {
      const nextBasic = applyPreviewOverridesToBasicPayload(
        basicPayload,
        overrides
      );
      if (nextBasic !== basicPayload) {
        setBasicPayload(nextBasic);
      }
    }
    if (!pendingPreviewOverrides) {
      return;
    }
    const nextPending = {
      overrides,
      pendingBody: pendingPreviewOverrides.pendingBody && !applyBody,
      pendingBasic: pendingPreviewOverrides.pendingBasic && !applyBasic,
    };
    if (nextPending.pendingBody || nextPending.pendingBasic) {
      setPendingPreviewOverrides(nextPending);
    } else {
      setPendingPreviewOverrides(null);
    }
  };
  const handleSaveProgress = async () => {
    const pendingDrafts = getPendingDraftSessions();
    const draftDiffIndexSnapshot = draftDiffIndex;
    const activeDraftDiffSnapshot = activeDraftDiff;
    const wasDirty = detectCustomUnsaved();
    const saved = await rawSavingHandlers.handleSaveProgress();
    if (saved) {
      commitFlagStates();
    }
    if (saved && wasDirty) {
      setPreviewRefreshSkips((previewRefreshSkips || 0) + 1);
      syncExternalPreviewSources(
        pendingDrafts.length
          ? {
              draftDiffIndex: draftDiffIndexSnapshot,
              activeDraftDiff: activeDraftDiffSnapshot,
            }
          : undefined
      );
    }
    return saved;
  };
  const handleSafeClose = async () => {
    await rawSavingHandlers.handleSafeClose();
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
    referenceGrid: canvasReferenceGrid,
    referenceParts: canvasReferenceParts,
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
  const serverBodyPayload = data.body_markings_payload || null;
  syncServerBodyPayload({
    resolvedActiveTab,
    serverBodyPayload,
    bodyMarkingsDirty,
    bodyPayload,
    bodyPayloadSignature,
    setBodyPayloadSignature,
    setBodyPayload,
    setBodySavedState,
    setBodyMarkingsState,
    setBodyMarkingsOrder,
    setBodyMarkingsSelected,
    setBodyMarkingsDirty,
  });
  handlePreviewRefreshTokenUpdate({
    serverPreviewRefreshToken,
    lastPreviewRefreshToken,
    setLastPreviewRefreshToken,
    previewRefreshSkips,
    setPreviewRefreshSkips,
    resolvedActiveTab,
    usingClientPreview,
    clientPreviewRevision,
    dataPreviewRevision: data.preview_revision,
    setReloadTargetRevision,
    setReloadPending,
    bodyPayloadSnapshot,
    basicPayloadSnapshot,
    setBodyMarkingsLoadInProgress,
    setBodyReloadPending,
    setBasicAppearanceLoadInProgress,
    setBasicReloadPending,
    act,
  });
  const basicPayloadReady =
    !!basicPayloadSnapshot && !basicPayloadSnapshot.preview_only;
  const bodyTabLoading = resolvedActiveTab === 'body' && !bodyPayloadSnapshot;
  const basicTabLoading = resolvedActiveTab === 'basic' && !basicPayloadReady;
  const tabSwitchBusyState =
    tabSwitchBusy ||
    pendingSave ||
    pendingClose ||
    bodyPendingSave ||
    bodyPendingClose ||
    basicPendingSave ||
    basicPendingClose;
  const tabsLocked =
    tabSwitchBusyState || customTabLoading || bodyTabLoading || basicTabLoading;

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
  const backgroundImage = resolveBackgroundImage(resolvedCanvasBackground);

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

  const detectBasicUnsaved = () => {
    const sharedState = selectBackend(context.store.getState()).shared || {};
    const dirtyFlag =
      typeof sharedState.basicAppearanceDirty === 'boolean'
        ? (sharedState.basicAppearanceDirty as boolean)
        : basicAppearanceDirty;
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

  const resolveBasicReloadPending = () => {
    const sharedState = selectBackend(context.store.getState()).shared || {};
    const pendingValue =
      sharedState[`basicAppearanceReloadPending-${stateToken}`];
    if (typeof pendingValue === 'boolean') {
      return pendingValue;
    }
    return basicReloadPending;
  };

  const resolveLatestBodyPayload = () => {
    const sharedState = selectBackend(context.store.getState()).shared || {};
    const payload = sharedState.bodyPayload as
      | BodyMarkingsPayload
      | null
      | undefined;
    return payload !== undefined ? payload : bodyPayload;
  };

  const resolveLatestBasicPayload = () => {
    const sharedState = selectBackend(context.store.getState()).shared || {};
    const payload = sharedState.basicPayload as
      | BasicAppearancePayload
      | null
      | undefined;
    return payload !== undefined ? payload : basicPayload;
  };

  const resolveUnsavedForTab = (tab: DesignerTabId) =>
    tab === 'custom'
      ? detectCustomUnsaved()
      : tab === 'body'
        ? detectBodyUnsaved()
        : detectBasicUnsaved();

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
      setPreviewRefreshSkips((previewRefreshSkips || 0) + 1);
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

  const resolveLatestBasicState = () => {
    const sharedState = selectBackend(context.store.getState()).shared || {};
    return {
      latestState:
        (sharedState.basicAppearanceState as BasicAppearanceState) ||
        basicAppearanceState,
      latestSavedState:
        (sharedState.basicAppearanceSavedState as BasicAppearanceState) ||
        basicSavedState,
    };
  };

  const saveBasicChanges = async (): Promise<boolean> => {
    const wasDirty = detectBasicUnsaved();
    if (!wasDirty) {
      return true;
    }
    const { latestState } = resolveLatestBasicState();
    setBasicPendingSave(true);
    setBasicPendingClose(false);
    try {
      setPreviewRefreshSkips((previewRefreshSkips || 0) + 1);
      await act('save_basic_appearance', {
        digitigrade: latestState.digitigrade ? 1 : 0,
        body_color: latestState.body_color,
        eye_color: latestState.eye_color,
        hair_style: latestState.hair_style,
        hair_color: latestState.hair_color,
        hair_gradient_style: latestState.hair_gradient_style,
        hair_gradient_color: latestState.hair_gradient_color,
        facial_hair_style: latestState.facial_hair_style,
        facial_hair_color: latestState.facial_hair_color,
        ear_style: latestState.ear_style,
        ear_colors: latestState.ear_colors,
        horn_style: latestState.horn_style,
        horn_colors: latestState.horn_colors,
        tail_style: latestState.tail_style,
        tail_colors: latestState.tail_colors,
        wing_style: latestState.wing_style,
        wing_colors: latestState.wing_colors,
        close: false,
      });
      setBasicAppearanceDirty(false);
      setBasicSavedState(latestState);
      setBasicAppearanceState(latestState);
      return true;
    } catch (error) {
      return false;
    } finally {
      setBasicPendingSave(false);
      setBasicPendingClose(false);
    }
  };

  const discardBasicChanges = () => {
    const { latestSavedState } = resolveLatestBasicState();
    const fallbackSaved = latestSavedState || basicInitialState;
    const next: BasicAppearanceState = {
      ...fallbackSaved,
      ear_colors: [...(fallbackSaved.ear_colors || [])],
      horn_colors: [...(fallbackSaved.horn_colors || [])],
      tail_colors: [...(fallbackSaved.tail_colors || [])],
      wing_colors: [...(fallbackSaved.wing_colors || [])],
    };
    setBasicAppearanceState(next);
    setBasicAppearanceDirty(false);
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
      const dataBodyPayload = data.body_markings_payload || null;
      const resolvedBodyPayload = latestBodyPayload ?? dataBodyPayload ?? null;
      if (!latestBodyPayload && dataBodyPayload && !latestReloadPending) {
        setBodyPayload(dataBodyPayload);
      }
      if (!resolvedBodyPayload || latestReloadPending) {
        if (!resolvedBodyPayload) {
          setBodyPayload(null);
        }
        setBodyMarkingsLoadInProgress(true);
        if (resolvedBodyPayload && latestReloadPending) {
          act('load_body_markings', { preview_only: 1 });
        } else {
          act('load_body_markings');
        }
        if (latestReloadPending) {
          setBodyReloadPending(false);
        }
      }
    }
    if (nextTab === 'basic') {
      const latestBasicPayload = resolveLatestBasicPayload();
      const latestReloadPending = resolveBasicReloadPending();
      const dataBasicPayload = data.basic_appearance_payload || null;
      const dataBasicUsable =
        !!dataBasicPayload && !dataBasicPayload.preview_only;
      const resolvedBasicPayload =
        latestBasicPayload && !latestBasicPayload.preview_only
          ? latestBasicPayload
          : dataBasicUsable
            ? dataBasicPayload
            : null;
      if (
        (!latestBasicPayload || latestBasicPayload.preview_only) &&
        dataBasicUsable &&
        !latestReloadPending
      ) {
        setBasicPayload(dataBasicPayload);
      }
      if (!resolvedBasicPayload || latestReloadPending) {
        if (!resolvedBasicPayload) {
          setBasicPayload(null);
        }
        setBasicAppearanceLoadInProgress(true);
        if (resolvedBasicPayload && latestReloadPending) {
          act('load_basic_appearance', { preview_only: 1 });
        } else {
          act('load_basic_appearance');
        }
        if (latestReloadPending) {
          setBasicReloadPending(false);
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

  const ensureBodyPayloadForSwitch = async (forceReload: boolean) => {
    setBodyColorTarget({ type: 'galleryPreview' });
    const dataBodyPayload = data.body_markings_payload || null;
    const resolvedBodyPayload = bodyPayload ?? dataBodyPayload ?? null;
    if (!bodyPayload && dataBodyPayload && !bodyReloadPending) {
      setBodyPayload(dataBodyPayload);
    }
    const shouldReload =
      !resolvedBodyPayload || bodyReloadPending || forceReload;
    if (!shouldReload) {
      return;
    }
    if (!resolvedBodyPayload) {
      setBodyPayload(null);
    }
    setBodyMarkingsLoadInProgress(true);
    if (resolvedBodyPayload && (bodyReloadPending || forceReload)) {
      await act('load_body_markings', { preview_only: 1 });
    } else {
      await act('load_body_markings');
    }
    if (bodyReloadPending || forceReload) {
      setBodyReloadPending(false);
    }
  };

  const ensureBasicPayloadForSwitch = async (forceReload: boolean) => {
    const latestBasicPayload = resolveLatestBasicPayload();
    const latestReloadPending = resolveBasicReloadPending();
    const dataBasicPayload = data.basic_appearance_payload || null;
    const dataBasicUsable =
      !!dataBasicPayload && !dataBasicPayload.preview_only;
    const resolvedBasicPayload =
      latestBasicPayload && !latestBasicPayload.preview_only
        ? latestBasicPayload
        : dataBasicUsable
          ? dataBasicPayload
          : null;
    if (
      (!latestBasicPayload || latestBasicPayload.preview_only) &&
      dataBasicUsable &&
      !latestReloadPending
    ) {
      setBasicPayload(dataBasicPayload);
    }
    const shouldReload =
      !resolvedBasicPayload || latestReloadPending || forceReload;
    if (!shouldReload) {
      return;
    }
    if (!resolvedBasicPayload) {
      setBasicPayload(null);
    }
    setBasicAppearanceLoadInProgress(true);
    if (resolvedBasicPayload && (latestReloadPending || forceReload)) {
      await act('load_basic_appearance', { preview_only: 1 });
    } else {
      await act('load_basic_appearance');
    }
    if (latestReloadPending || forceReload) {
      setBasicReloadPending(false);
    }
  };

  const saveTabBeforeSwitch = async (sourceTab: DesignerTabId) => {
    if (sourceTab === 'custom') {
      await handleSaveProgress();
      return !detectCustomUnsaved();
    }
    if (sourceTab === 'body') {
      const saved = await saveBodyChanges();
      return !!saved && !detectBodyUnsaved();
    }
    const saved = await saveBasicChanges();
    return !!saved && !detectBasicUnsaved();
  };

  const handleTabSwitchSave = async () => {
    if (!tabSwitchPrompt) {
      return;
    }
    const prompt = tabSwitchPrompt;
    const wasBodyDirty = prompt.sourceTab === 'body' && detectBodyUnsaved();
    const wasCustomDirty =
      prompt.sourceTab === 'custom' && detectCustomUnsaved();
    const wasBasicDirty = prompt.sourceTab === 'basic' && detectBasicUnsaved();
    setTabSwitchBusy(true);
    setTabSwitchPrompt(null);
    try {
      const saved = await saveTabBeforeSwitch(prompt.sourceTab);
      if (!saved) {
        setTabSwitchPrompt(prompt);
        return;
      }
      if (
        prompt.targetTab === 'custom' &&
        (reloadPending || wasBodyDirty || wasBasicDirty)
      ) {
        if (!reloadPending) {
          setReloadTargetRevision(0);
        }
        setLoadingOverlay(true);
        setReloadOverlayMinUntil(Date.now() + 400);
        setReloadPending(false);
      }
      if (prompt.targetTab === 'body') {
        await ensureBodyPayloadForSwitch(wasCustomDirty);
      }
      if (prompt.targetTab === 'basic') {
        await ensureBasicPayloadForSwitch(wasCustomDirty);
      }
      act('set_active_tab', { tab: prompt.targetTab });
      setActiveTab(prompt.targetTab);
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
      } else if (tabSwitchPrompt.sourceTab === 'body') {
        discardBodyChanges();
      } else {
        discardBasicChanges();
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
        await ensureBodyPayloadForSwitch(false);
      }
      if (tabSwitchPrompt.targetTab === 'basic') {
        await ensureBasicPayloadForSwitch(false);
      }
      act('set_active_tab', { tab: tabSwitchPrompt.targetTab });
      setActiveTab(tabSwitchPrompt.targetTab);
    } finally {
      setTabSwitchBusy(false);
    }
  };

  const titleTabs = (
    <>
      <Tabs className="RogueStar__titleTabs">
        <Tabs.Tab
          selected={resolvedActiveTab === 'basic'}
          icon="user"
          className={tabsLocked ? 'Tab--disabled' : undefined}
          aria-disabled={tabsLocked}
          onClick={() => {
            if (!tabsLocked) {
              handleTabChange('basic');
            }
          }}>
          Basic Appearance
        </Tabs.Tab>
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
      <Button
        className={CHIP_BUTTON_CLASS}
        icon={compactMode ? 'search-plus' : 'search-minus'}
        content={compactMode ? '50%' : '100%'}
        tooltip={
          compactMode ? 'Return to normal size.' : 'Toggle compact mode (50%).'
        }
        ml="auto"
        onClick={() => setCompactMode(!compactMode)}
      />
    </>
  );

  return (
    <Window
      theme="nanotrasen rogue-star-window"
      width={1720}
      height={950}
      scale={compactMode ? 0.5 : 1}
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
      <PayloadPrefetchScheduler
        bodyPayload={bodyPayloadSnapshot}
        basicPayload={basicPayloadSnapshot}
        bodyLoadInProgress={bodyMarkingsLoadInProgress}
        basicLoadInProgress={basicAppearanceLoadInProgress}
        bodyReloadPending={bodyReloadPending}
        basicReloadPending={basicReloadPending}
        setBodyLoadInProgress={setBodyMarkingsLoadInProgress}
        setBasicLoadInProgress={setBasicAppearanceLoadInProgress}
        clearBodyReloadPending={() => setBodyReloadPending(false)}
        clearBasicReloadPending={() => setBasicReloadPending(false)}
        requestBody={() => act('load_body_markings')}
        requestBasic={() => act('load_basic_appearance')}
      />
      <PreviewOverrideScheduler
        pendingOverrides={pendingPreviewOverrides}
        hasBodyPayload={!!bodyPayload}
        hasBasicPayload={!!basicPayload}
        onApply={handleApplyPendingPreviewOverrides}
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
                referenceGrid={canvasReferenceGrid}
                referenceParts={canvasReferenceParts}
                referenceSignature={resolvedReferenceSignature}
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
                renderedPreviewDirs={previewDirsWithMarkings}
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
        ) : resolvedActiveTab === 'body' ? (
          <BodyMarkingsTab
            data={data}
            setPendingClose={setPendingClose}
            setPendingSave={setPendingSave}
            canvasBackgroundOptions={canvasBackgroundOptions}
            resolvedCanvasBackground={resolvedCanvasBackground}
            backgroundFallbackColor={backgroundFallbackColor}
            cycleCanvasBackground={cycleCanvasBackground}
            canvasBackgroundScale={canvasBackgroundScale}
            resolvedPartPriorityMap={resolvedPartPriorityMap}
            resolvedPartReplacementMap={resolvedPartReplacementMap}
            showJobGear={showJobGear}
            onToggleJobGear={() => setShowJobGear(!showJobGear)}
            showLoadoutGear={showLoadoutGear}
            onToggleLoadout={() => setShowLoadoutGear(!showLoadoutGear)}
          />
        ) : (
          <BasicAppearanceTab
            data={data}
            setPendingClose={setPendingClose}
            setPendingSave={setPendingSave}
            canvasBackgroundOptions={canvasBackgroundOptions}
            resolvedCanvasBackground={resolvedCanvasBackground}
            backgroundFallbackColor={backgroundFallbackColor}
            cycleCanvasBackground={cycleCanvasBackground}
            canvasBackgroundScale={canvasBackgroundScale}
            resolvedPartPriorityMap={resolvedPartPriorityMap}
            resolvedPartReplacementMap={resolvedPartReplacementMap}
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
              : tabSwitchPrompt.sourceTab === 'body'
                ? 'Body Markings tab'
                : 'Basic Appearance tab'
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
