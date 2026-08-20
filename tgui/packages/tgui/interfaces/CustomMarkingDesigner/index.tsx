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
// Updated by Lira for Rogue Star February 2026: West - east mirror tool added /////////////////////////////////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star August 2026: Character Designer - Species and Prosthetics ////////////////////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star August 2026: Character Designer - Traits Tab /////////////////////////////////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import { Component } from 'inferno';

import {
  backendSetSharedStates,
  selectBackend,
  useBackend,
  useLocalState,
} from '../../backend';
import { Box, Button, Flex, Icon, Tabs } from '../../components';
import { Window } from '../../layouts';
import { normalizeHex, TRANSPARENT_HEX } from '../../utils/color';
import {
  GENERIC_PART_KEY,
  cloneGridData,
  isStaticIconAssetRegistryLoaded,
  resolveBodyPartLabel,
  type DiffEntry,
  type PreviewDirectionEntry,
  type PreviewDirectionSource,
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
  COLOR_PICKER_CUSTOM_SLOTS,
  EAST,
  ERASER_PREVIEW_COLOR,
  WEST,
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
  applyCustomPreviewOverridesToBasicPayload,
  applyEyeColorToPreview,
  applyLimbHairColorToPreview,
  applyProstheticsToPreviewSources,
  applyHeadAppearanceToCanvasReferences,
  applyPreviewInitialization,
  areAllPreviewLayersLoaded,
  buildCanvasKey,
  buildGenericCanvasReference,
  buildBodyPartLabelMap,
  buildBodyMarkingDefinitions,
  buildBodyMarkingSavePayload,
  buildBodyMarkingChunkPlan,
  buildBodyPayloadSignature,
  buildBasicStateFromPayload,
  buildProstheticSaveParams,
  cloneLimbOverrideState,
  buildBodySavedStateFromPayload,
  createReferenceOpacityControls,
  getCanvasFrameStyle,
  buildLocalSessionKey,
  convertCompositeLayerMap,
  createSavingHandlers,
  deepCopyMarkings,
  initializeColorPickerSlotsIfNeeded,
  mergeSpeciesBodyPreviewSource,
  parseHex,
  resolveExportGridForDirPart,
  resolveReferencePartId,
  resolveSharedPreviewSourceSelection,
  resolveSpeciesBodyPreviewSources,
  resolveSpeciesIconBaseOptions,
  sampleGridColorAt,
  buildBasicAppearanceLoadParams,
  buildBodyMarkingsLoadParams,
  buildSpeciesSaveCacheParams,
  buildTraitsDraftState,
  buildTraitsSavePayload,
  isSpeciesSaveAllowed,
  resolveTraitsSaveAcknowledgement,
  resolveLanguagesDraftValidationError,
  mergeBasicAppearancePayload,
  mergeBodyMarkingsPayload,
  shouldRetainLocalBasicPayload,
  shouldInvalidateSpeciesPayloadForBiologicalGenderChange,
  syncSpeciesSaveResultState,
  traitDraftSelectionsEqual,
  toHex,
} from './utils';
import {
  buildReferencePartMarkingGridsByDir,
  buildSuppressedMarkingPartsByDir,
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
  SpeciesPayload,
  SpeciesSaveResult,
  TraitsDraftState,
  TraitsPayload,
  TraitsSaveResult,
} from './types';
import { useDesignerUiState } from './state';
import CustomEyeIconAsset from '../../../../public/Icons/Rogue Star/eye 1.png';
import {
  BodyMarkingsTab,
  applyAppearanceOverlaysToPreview,
  resolveAppearanceContext,
  type AppearancePreviewContext,
} from './BodyMarkingsTab';
import {
  BasicAppearanceTab,
  applyBodyMarkingsToPreview,
  buildBasicPayloadSignature,
  resolveBodyMarkingsContext,
  type BodyMarkingDefinitionCache,
  type BodyMarkingsPreviewContext,
  type BodyMarkingsPreviewCache,
  type BodyMarkingsSignatureCache,
  type MarkingLayersCacheEntry,
} from './BasicAppearanceTab';
import { SpeciesTab } from './SpeciesTab';
import { TraitsTab } from './TraitsTab';

type DesignerTabId = 'custom' | 'body' | 'basic' | 'species' | 'traits';

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
  'gear_equipment',
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
const HEAD_APPEARANCE_OVERLAY_SLOTS = new Set([
  'hair',
  'hair_accessory',
  'ears',
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

const buildAppearanceOverlayGrids = (
  preview: PreviewDirectionEntry[],
  dirKey: number
): {
  head: string[][] | null;
  other: string[][] | null;
} => {
  const entry = preview.find((dirEntry) => dirEntry.dir === dirKey);
  if (!entry?.layers) {
    return { head: null, other: null };
  }
  const headLayers: PreviewLayerEntry[] = [];
  const otherLayers: PreviewLayerEntry[] = [];
  entry.layers.forEach((layer) => {
    if (
      layer?.type !== 'overlay' ||
      layer?.source !== 'base' ||
      typeof layer.key !== 'string' ||
      !layer.key.startsWith('overlay_body_') ||
      !Array.isArray(layer.grid)
    ) {
      return;
    }
    const slot = resolveOverlaySlotFromKey(
      layer.key,
      dirKey,
      layer.source || 'base'
    );
    if (!slot || !APPEARANCE_OVERLAY_MASK_SLOTS.has(slot)) {
      return;
    }
    if (HEAD_APPEARANCE_OVERLAY_SLOTS.has(slot)) {
      headLayers.push(layer);
    } else {
      otherLayers.push(layer);
    }
  });
  const mergeLayers = (layers: PreviewLayerEntry[]): string[][] | null => {
    const merged: string[][] = [];
    layers.forEach((layer) => {
      if (layer.grid?.length) {
        mergeGrid(merged, layer.grid);
      }
    });
    return merged.length ? merged : null;
  };
  return {
    head: mergeLayers(headLayers),
    other: mergeLayers(otherLayers),
  };
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
          applyLimbHairColorToPreview(
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
              appearanceContext.bodyColorExcludedParts,
              1,
              appearanceContext.bodyColorBlendMode
            ),
            appearanceContext.appearanceState.hair_color
          ),
          appearanceContext.previewBaseEyeColor,
          appearanceContext.previewTargetEyeColor,
          appearanceContext.previewTargetBodyColor
        )
      : null;
  let nextReferenceGrid = referenceGrid;
  let nextReferenceParts: Record<string, string[][]> = {
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
  const mergeIntoCanvasOverlay = (overlayGrid: string[][]) => {
    const existingOverlay = nextReferenceParts.overlay;
    const merged = existingOverlay
      ? cloneGridData(existingOverlay)
      : cloneGridData(overlayGrid);
    if (existingOverlay) {
      mergeGrid(merged, overlayGrid);
    }
    nextReferenceParts.overlay = merged;
  };
  const appearanceOverlayGrids = buildAppearanceOverlayGrids(preview, dirKey);
  if (appearanceOverlayGrids.head) {
    const mergedHeadReferences = applyHeadAppearanceToCanvasReferences({
      referenceParts: nextReferenceParts,
      referenceGrid: nextReferenceGrid,
      overlayGrid: appearanceOverlayGrids.head,
      mergeGrid,
    });
    nextReferenceParts = mergedHeadReferences.referenceParts;
    nextReferenceGrid = mergedHeadReferences.referenceGrid;
    if (!mergedHeadReferences.applied) {
      mergeIntoCanvasOverlay(appearanceOverlayGrids.head);
    }
  }
  if (appearanceOverlayGrids.other) {
    mergeIntoCanvasOverlay(appearanceOverlayGrids.other);
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
const DESIGNER_ZOOM_LEVELS = [50, 60, 70, 80, 90, 100] as const;
const DESIGNER_ZOOM_MIN_PERCENT = 50;
const DESIGNER_ZOOM_MAX_PERCENT = 100;

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
}): {
  bodyPayloadSnapshot: BodyMarkingsPayload | null;
  basicPayloadSnapshot: BasicAppearancePayload | null;
} => {
  const sharedStateSnapshot =
    selectBackend(options.context.store.getState()).shared || {};
  const hasSharedBodyPayload = Object.prototype.hasOwnProperty.call(
    sharedStateSnapshot,
    'bodyPayload'
  );
  const hasSharedBasicPayload = Object.prototype.hasOwnProperty.call(
    sharedStateSnapshot,
    'basicPayload'
  );
  const bodyPayloadSnapshot = hasSharedBodyPayload
    ? (sharedStateSnapshot.bodyPayload as BodyMarkingsPayload | null)
    : options.bodyPayload;
  const basicPayloadSnapshot = hasSharedBasicPayload
    ? (sharedStateSnapshot.basicPayload as BasicAppearancePayload | null)
    : options.basicPayload;
  return { bodyPayloadSnapshot, basicPayloadSnapshot };
};

const isPayloadStaleForSelection = (
  payload:
    | Pick<BodyMarkingsPayload, 'species_id' | 'custom_base'>
    | Pick<BasicAppearancePayload, 'species_id' | 'custom_base'>
    | null
    | undefined,
  speciesId: string | null,
  iconBase: string | null
): boolean =>
  !!payload &&
  ((!!speciesId && payload.species_id !== speciesId) ||
    (!!iconBase && payload.custom_base !== iconBase));

const resolveEnableCustomDisclaimer = (
  data: CustomMarkingDesignerData
): string =>
  data.custom_marking_enable_disclaimer ||
  "This is an advanced character editing tool that allows you to edit individual pixels on your character to adjust or create new markings.  Custom markings have the same standards as markings added to the RogueStar codebase.  They should make realistic sense and must be SFW.  If it wouldn't get approved to add to the code, it should not be done here.  If you are uncertain about something, please let us know and we're happy to chatter about it.";

const resolveCanvasBackgroundDefaults = (
  data: CustomMarkingDesignerData
): {
  canvasBackgroundOptions: CanvasBackgroundOption[];
  defaultCanvasBackgroundKey: string;
} => ({
  canvasBackgroundOptions: Array.isArray(data.canvas_backgrounds)
    ? data.canvas_backgrounds
    : [],
  defaultCanvasBackgroundKey: data.default_canvas_background || 'default',
});

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

const resolveSpeciesPreviewSelection = (options: {
  speciesPayload: SpeciesPayload | null;
  speciesSelection: string | null;
  speciesIconBaseSelection: string | null;
  digitigrade: boolean;
}): {
  selectedSpeciesId: string | null;
  selectedIconBase: string | null;
  selectedSpecies: SpeciesPayload['species'][number] | null;
  speciesPreviewSources: PreviewDirectionSource[] | null;
  speciesPreviewSignature: string;
} => {
  const {
    speciesPayload,
    speciesSelection,
    speciesIconBaseSelection,
    digitigrade,
  } = options;
  const selectedSpeciesId =
    speciesSelection || speciesPayload?.selected_species || null;
  const selectedIconBase =
    speciesIconBaseSelection ||
    speciesPayload?.preview_icon_base ||
    speciesPayload?.selected_icon_base ||
    null;
  const selectedSpecies =
    selectedSpeciesId && speciesPayload?.species
      ? speciesPayload.species.find(
          (entry) => entry.id === selectedSpeciesId
        ) || null
      : null;
  return {
    selectedSpeciesId,
    selectedIconBase,
    selectedSpecies,
    speciesPreviewSources: resolveSpeciesBodyPreviewSources({
      selectedSpecies,
      iconBaseOptions: resolveSpeciesIconBaseOptions(
        speciesPayload,
        selectedSpeciesId
      ),
      iconBaseSelection: selectedIconBase,
      digitigrade,
    }),
    speciesPreviewSignature: `${selectedSpeciesId || ''}:${
      selectedIconBase || ''
    }:${digitigrade ? 'digi' : 'normal'}`,
  };
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
  showEquipment: boolean;
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
    showEquipment,
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
    showEquipment ? 'equipment1' : 'equipment0',
    showJobGear ? 'job1' : 'job0',
    showLoadoutGear ? 'load1' : 'load0',
    partReplacementSignature,
    partPrioritySignature,
    `${canvasWidth}x${canvasHeight}`,
  ]
    .filter((entry) => entry.length > 0)
    .join('|');
};

const buildSpeciesPreviewSourceMap = (
  sources?: PreviewDirectionSource[] | null
): Record<number, PreviewDirectionSource> | null => {
  if (!Array.isArray(sources) || !sources.length) {
    return null;
  }
  const byDir: Record<number, PreviewDirectionSource> = {};
  sources.forEach((entry) => {
    if (entry && typeof entry.dir === 'number') {
      byDir[entry.dir] = entry;
    }
  });
  return Object.keys(byDir).length ? byDir : null;
};

const resolveSpeciesPreviewSources = (options: {
  baseSources: PreviewDirectionSource[] | null;
  speciesSources: PreviewDirectionSource[] | null;
}): {
  sources: PreviewDirectionSource[] | null;
  hasSpeciesSources: boolean;
  usingSpeciesOnly: boolean;
} => {
  const { baseSources, speciesSources } = options;
  const hasSpeciesSources =
    Array.isArray(speciesSources) && speciesSources.length > 0;
  if (!hasSpeciesSources) {
    return {
      sources: baseSources,
      hasSpeciesSources: false,
      usingSpeciesOnly: false,
    };
  }
  if (!Array.isArray(baseSources) || !baseSources.length) {
    return {
      sources: speciesSources,
      hasSpeciesSources: true,
      usingSpeciesOnly: true,
    };
  }
  const speciesByDir = buildSpeciesPreviewSourceMap(speciesSources);
  if (!speciesByDir) {
    return {
      sources: baseSources,
      hasSpeciesSources: true,
      usingSpeciesOnly: false,
    };
  }
  const merged = baseSources.map((entry) => {
    const override = speciesByDir[entry.dir];
    return override ? mergeSpeciesBodyPreviewSource(entry, override) : entry;
  });
  return {
    sources: merged,
    hasSpeciesSources: true,
    usingSpeciesOnly: false,
  };
};

const shouldUseSpeciesPreviewOverride = (options: {
  speciesPreviewSources: PreviewDirectionSource[] | null;
  selectedSpeciesId: string | null;
  selectedIconBase: string | null;
  payloadSpeciesId: string | null;
  payloadIconBase: string | null;
}) => {
  const {
    speciesPreviewSources,
    selectedSpeciesId,
    selectedIconBase,
    payloadSpeciesId,
    payloadIconBase,
  } = options;
  if (!speciesPreviewSources) {
    return false;
  }
  if (!payloadSpeciesId || selectedSpeciesId !== payloadSpeciesId) {
    return true;
  }
  return !!selectedIconBase && selectedIconBase !== payloadIconBase;
};

const resolvePreviewSourceKey = (options: {
  basePreviewSourceKey: string;
  usingSpeciesOnly: boolean;
  hasSpeciesSources: boolean;
  useSpeciesPreviewOverride: boolean;
  speciesPreviewSignature: string;
}) => {
  const {
    basePreviewSourceKey,
    usingSpeciesOnly,
    hasSpeciesSources,
    useSpeciesPreviewOverride,
    speciesPreviewSignature,
  } = options;
  const resolvedBasePreviewSourceKey = usingSpeciesOnly
    ? 'species'
    : basePreviewSourceKey;
  const speciesKey =
    hasSpeciesSources && useSpeciesPreviewOverride && speciesPreviewSignature
      ? `species:${speciesPreviewSignature}`
      : '';
  return [resolvedBasePreviewSourceKey, speciesKey]
    .filter((entry) => entry.length > 0)
    .join('|');
};

const resolvePreviewSourceState = (options: {
  data: CustomMarkingDesignerData;
  bodyPayloadSnapshot: BodyMarkingsPayload | null;
  basicPayloadSnapshot: BasicAppearancePayload | null;
  markingsAppearanceState: BasicAppearanceState;
  selectedSpeciesId: string | null;
  selectedIconBase: string | null;
  speciesPreviewSources: PreviewDirectionSource[] | null;
  speciesPreviewSignature: string;
  previewStateRevision: number;
  clientPreviewEpoch: number;
  setClientPreviewEpoch: (value: number) => void;
  previewSourceSignature: string;
  setPreviewSourceSignature: (value: string) => void;
  resolvedPartReplacementMap: Record<string, boolean>;
  resolvedPartPriorityMap: Record<string, boolean>;
  assetRevision: number;
  directionSignature: string;
  canvasWidth: number;
  canvasHeight: number;
  showEquipment: boolean;
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
    selectedSpeciesId,
    selectedIconBase,
    speciesPreviewSources,
    speciesPreviewSignature,
    previewStateRevision,
    clientPreviewEpoch,
    setClientPreviewEpoch,
    previewSourceSignature,
    setPreviewSourceSignature,
    resolvedPartReplacementMap,
    resolvedPartPriorityMap,
    assetRevision,
    directionSignature,
    canvasWidth,
    canvasHeight,
    showEquipment,
    showJobGear,
    showLoadoutGear,
  } = options;
  const {
    sources: basePreviewSources,
    assetRegistry: basePreviewAssetRegistry,
    revision: basePreviewRevision,
    sourceKey: basePreviewSourceKey,
    payloadSpeciesId,
    payloadIconBaseId: payloadIconBase,
  } = resolveSharedPreviewSourceSelection({
    basicPayload: basicPayloadSnapshot,
    bodyPayload: bodyPayloadSnapshot,
    digitigrade: markingsAppearanceState.digitigrade,
    basicAppearanceState: markingsAppearanceState,
  });
  const useSpeciesPreviewOverride =
    !basePreviewSources ||
    shouldUseSpeciesPreviewOverride({
      speciesPreviewSources,
      selectedSpeciesId,
      selectedIconBase,
      payloadSpeciesId,
      payloadIconBase,
    });
  const activeSpeciesPreviewSources = useSpeciesPreviewOverride
    ? speciesPreviewSources
    : null;
  const transformedSpeciesPreviewSources = applyProstheticsToPreviewSources(
    activeSpeciesPreviewSources,
    markingsAppearanceState,
    basicPayloadSnapshot?.prosthetic_context
  );
  const {
    sources: clientPreviewSources,
    hasSpeciesSources,
    usingSpeciesOnly,
  } = resolveSpeciesPreviewSources({
    baseSources: basePreviewSources,
    speciesSources: transformedSpeciesPreviewSources,
  });
  const clientPreviewRevisionBase = basePreviewRevision;
  const usingClientPreview = !!clientPreviewSources;
  const previewSourceKey = resolvePreviewSourceKey({
    basePreviewSourceKey,
    usingSpeciesOnly,
    hasSpeciesSources,
    useSpeciesPreviewOverride,
    speciesPreviewSignature,
  });
  const signatureChanged = previewSourceKey !== previewSourceSignature;
  const signatureInitialized = previewSourceSignature.length > 0;
  const initialEpoch = clientPreviewEpoch || 1;
  const requestedEpoch =
    signatureChanged && signatureInitialized && usingClientPreview
      ? (initialEpoch % 1000000) + 1
      : initialEpoch;
  const { revision: clientPreviewRevision, epoch: resolvedEpoch } =
    resolveClientPreviewRevision({
      usingClientPreview,
      clientPreviewRevisionBase,
      clientPreviewEpoch: requestedEpoch,
      previewStateRevision,
    });
  if (signatureChanged) {
    setPreviewSourceSignature(previewSourceKey);
  }
  if (usingClientPreview && resolvedEpoch !== clientPreviewEpoch) {
    setClientPreviewEpoch(resolvedEpoch);
  }
  const previewData =
    usingClientPreview && clientPreviewSources
      ? {
          ...data,
          preview_sources: clientPreviewSources,
          preview_asset_registry: usingSpeciesOnly
            ? undefined
            : basePreviewAssetRegistry || undefined,
          preview_revision: clientPreviewRevision,
        }
      : data;
  const partReplacementSignature = buildBooleanMapSignature(
    resolvedPartReplacementMap
  );
  const partPrioritySignature = buildBooleanMapSignature(
    resolvedPartPriorityMap
  );
  const previewRevisionKey = usingClientPreview
    ? `client:${clientPreviewRevisionBase}`
    : `server:${data.preview_revision ?? 0}`;
  const renderedPreviewSignature = buildRenderedPreviewSignature({
    previewSourceKey,
    previewRevisionKey,
    diffSeq: data.diff_seq,
    assetRevision,
    directionSignature,
    showEquipment,
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
  const previewHiddenPartsByDir = buildSuppressedMarkingPartsByDir(
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
    initialTab === 'basic' ||
    initialTab === 'species' ||
    initialTab === 'traits'
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
}): { revision: number; epoch: number } => {
  const {
    usingClientPreview,
    clientPreviewRevisionBase,
    clientPreviewEpoch,
    previewStateRevision,
  } = options;
  if (!usingClientPreview) {
    return { revision: clientPreviewRevisionBase, epoch: clientPreviewEpoch };
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
  return {
    revision:
      clientPreviewRevisionBase + resolvedEpoch * CLIENT_PREVIEW_EPOCH_STRIDE,
    epoch: resolvedEpoch,
  };
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

type ServerPayloadSyncSchedulerProps = Readonly<{
  resolvedActiveTab: DesignerTabId;
  serverBodyPayload: BodyMarkingsPayload | null;
  serverBasicPayload: BasicAppearancePayload | null;
  targetSpeciesId: string | null;
  targetIconBase: string | null;
  bodyPayload: BodyMarkingsPayload | null;
  basicPayload: BasicAppearancePayload | null;
  bodyMarkingsDirty: boolean;
  basicAppearanceDirty: boolean;
  bodyReloadPending: boolean;
  basicReloadPending: boolean;
  bodyLoadInProgress: boolean;
  basicLoadInProgress: boolean;
  setBodyPayload: (payload: BodyMarkingsPayload | null) => void;
  setBasicPayload: (payload: BasicAppearancePayload | null) => void;
  setBodySavedState: (state: BodyMarkingsSavedState) => void;
  setBodyMarkingsState: (state: Record<string, BodyMarkingEntry>) => void;
  setBodyMarkingsOrder: (order: string[]) => void;
  setBodyMarkingsSelected: (id: string | null) => void;
  setBodyMarkingsDirty: (dirty: boolean) => void;
  setBasicAppearanceState: (state: BasicAppearanceState) => void;
  setBasicSavedState: (state: BasicAppearanceState) => void;
  setBasicAppearanceDirty: (dirty: boolean) => void;
  setBodyLoadInProgress: (value: boolean) => void;
  setBasicLoadInProgress: (value: boolean) => void;
  clearBodyReloadPending: () => void;
  clearBasicReloadPending: () => void;
}>;

class ServerPayloadSyncScheduler extends Component<ServerPayloadSyncSchedulerProps> {
  private staleBodyPayload: BodyMarkingsPayload | null = null;
  private staleBasicPayload: BasicAppearancePayload | null = null;

  componentDidMount() {
    this.sync();
  }

  componentDidUpdate(prevProps: ServerPayloadSyncSchedulerProps) {
    const bodyWasWaiting =
      !prevProps.bodyPayload &&
      (prevProps.bodyReloadPending || prevProps.bodyLoadInProgress);
    const bodyIsWaiting =
      !this.props.bodyPayload &&
      (this.props.bodyReloadPending || this.props.bodyLoadInProgress);
    if (!bodyWasWaiting && bodyIsWaiting) {
      this.staleBodyPayload = this.props.serverBodyPayload;
    }
    const basicWasWaiting =
      !prevProps.basicPayload &&
      (prevProps.basicReloadPending || prevProps.basicLoadInProgress);
    const basicIsWaiting =
      !this.props.basicPayload &&
      (this.props.basicReloadPending || this.props.basicLoadInProgress);
    if (!basicWasWaiting && basicIsWaiting) {
      this.staleBasicPayload = this.props.serverBasicPayload;
    }
    this.sync();
  }

  syncBodyPayload() {
    const {
      resolvedActiveTab,
      serverBodyPayload,
      targetSpeciesId,
      targetIconBase,
      bodyPayload,
      bodyMarkingsDirty,
      bodyReloadPending,
      bodyLoadInProgress,
      setBodyPayload,
      setBodySavedState,
      setBodyMarkingsState,
      setBodyMarkingsOrder,
      setBodyMarkingsSelected,
      setBodyMarkingsDirty,
      setBodyLoadInProgress,
      clearBodyReloadPending,
    } = this.props;
    if (
      resolvedActiveTab === 'body' ||
      !serverBodyPayload ||
      serverBodyPayload.preview_only ||
      bodyMarkingsDirty
    ) {
      return;
    }
    const mergedServerBodyPayload = mergeBodyMarkingsPayload(
      bodyPayload,
      serverBodyPayload,
      this.props.basicPayload
    );
    if (
      isPayloadStaleForSelection(
        mergedServerBodyPayload,
        targetSpeciesId,
        targetIconBase
      )
    ) {
      return;
    }
    const waitingForReload =
      !bodyPayload && (bodyReloadPending || bodyLoadInProgress);
    if (
      waitingForReload &&
      this.staleBodyPayload &&
      serverBodyPayload === this.staleBodyPayload
    ) {
      return;
    }
    if (bodyPayload && !bodyReloadPending && !bodyLoadInProgress) {
      this.staleBodyPayload = null;
      return;
    }
    const nextSignature = buildBodyPayloadSignature(mergedServerBodyPayload);
    const currentSignature = buildBodyPayloadSignature(bodyPayload);
    if (nextSignature === currentSignature) {
      if (bodyLoadInProgress) {
        setBodyLoadInProgress(false);
      }
      if (bodyReloadPending) {
        clearBodyReloadPending();
      }
      this.staleBodyPayload = null;
      return;
    }
    const savedState = buildBodySavedStateFromPayload(mergedServerBodyPayload);
    setBodyPayload(mergedServerBodyPayload);
    setBodySavedState(savedState);
    setBodyMarkingsState(deepCopyMarkings(savedState.markings));
    setBodyMarkingsOrder([...savedState.order]);
    setBodyMarkingsSelected(savedState.selectedId);
    setBodyMarkingsDirty(false);
    if (bodyLoadInProgress) {
      setBodyLoadInProgress(false);
    }
    if (bodyReloadPending) {
      clearBodyReloadPending();
    }
    this.staleBodyPayload = null;
  }

  syncBasicPayload() {
    const {
      resolvedActiveTab,
      serverBasicPayload,
      targetSpeciesId,
      targetIconBase,
      basicPayload,
      basicAppearanceDirty,
      basicReloadPending,
      basicLoadInProgress,
      setBasicPayload,
      setBasicAppearanceState,
      setBasicSavedState,
      setBasicAppearanceDirty,
      setBasicLoadInProgress,
      clearBasicReloadPending,
    } = this.props;
    if (
      resolvedActiveTab === 'basic' ||
      !serverBasicPayload ||
      serverBasicPayload.preview_only ||
      basicAppearanceDirty
    ) {
      return;
    }
    const mergedServerBasicPayload = mergeBasicAppearancePayload(
      basicPayload,
      serverBasicPayload,
      this.props.bodyPayload
    );
    if (
      isPayloadStaleForSelection(
        mergedServerBasicPayload,
        targetSpeciesId,
        targetIconBase
      )
    ) {
      return;
    }
    const waitingForReload =
      !basicPayload && (basicReloadPending || basicLoadInProgress);
    if (
      waitingForReload &&
      this.staleBasicPayload &&
      serverBasicPayload === this.staleBasicPayload
    ) {
      return;
    }
    if (
      shouldRetainLocalBasicPayload({
        basicPayload,
        reloadPending: basicReloadPending,
        loadInProgress: basicLoadInProgress,
      })
    ) {
      this.staleBasicPayload = null;
      return;
    }
    const nextSignature = buildBasicPayloadSignature(mergedServerBasicPayload);
    const currentSignature = buildBasicPayloadSignature(basicPayload);
    if (nextSignature === currentSignature) {
      if (basicLoadInProgress) {
        setBasicLoadInProgress(false);
      }
      if (basicReloadPending) {
        clearBasicReloadPending();
      }
      this.staleBasicPayload = null;
      return;
    }
    const nextState = buildBasicStateFromPayload(mergedServerBasicPayload);
    setBasicPayload(mergedServerBasicPayload);
    setBasicAppearanceState(nextState);
    setBasicSavedState(nextState);
    setBasicAppearanceDirty(false);
    if (basicLoadInProgress) {
      setBasicLoadInProgress(false);
    }
    if (basicReloadPending) {
      clearBasicReloadPending();
    }
    this.staleBasicPayload = null;
  }

  sync() {
    this.syncBasicPayload();
    this.syncBodyPayload();
  }

  render() {
    return null;
  }
}

type SpeciesSaveResultSyncSchedulerProps = Readonly<{
  speciesSaveResult?: SpeciesSaveResult | null;
  onSaveResult?: (result: SpeciesSaveResult) => void;
  speciesPayload: SpeciesPayload | null;
  bodyPayload: BodyMarkingsPayload | null;
  basicPayload: BasicAppearancePayload | null;
  stateToken: string;
  writeStates: (states: Record<string, unknown>) => void;
}>;

class SpeciesSaveResultSyncScheduler extends Component<SpeciesSaveResultSyncSchedulerProps> {
  private lastRevision = 0;

  componentDidMount() {
    this.sync();
  }

  componentDidUpdate(prevProps: SpeciesSaveResultSyncSchedulerProps) {
    if (prevProps.speciesSaveResult !== this.props.speciesSaveResult) {
      this.sync();
    }
  }

  sync() {
    const {
      speciesSaveResult,
      onSaveResult,
      speciesPayload,
      bodyPayload,
      basicPayload,
      stateToken,
      writeStates,
    } = this.props;
    if (
      !speciesSaveResult ||
      !speciesSaveResult.revision ||
      speciesSaveResult.revision === this.lastRevision
    ) {
      return;
    }
    this.lastRevision = speciesSaveResult.revision;
    syncSpeciesSaveResultState(writeStates, {
      result: speciesSaveResult,
      stateToken,
      speciesPayload,
      bodyPayload,
      basicPayload,
    });
    onSaveResult?.(speciesSaveResult);
  }

  render() {
    return null;
  }
}

type TraitsSaveResultSyncSchedulerProps = Readonly<{
  saveResult: TraitsSaveResult | null;
  payload: TraitsPayload | null;
  pendingRequest: PendingTraitsSaveRequest | null;
  onAcknowledged: (
    accepted: boolean,
    pendingRequest: PendingTraitsSaveRequest,
    saveResult: TraitsSaveResult
  ) => void;
}>;

class TraitsSaveResultSyncScheduler extends Component<TraitsSaveResultSyncSchedulerProps> {
  private lastAcknowledgedRequestId: string | null = null;

  componentDidMount() {
    this.sync();
  }

  componentDidUpdate() {
    this.sync();
  }

  sync() {
    const { saveResult, payload, pendingRequest, onAcknowledged } = this.props;
    if (!pendingRequest) {
      return;
    }
    const accepted = resolveTraitsSaveAcknowledgement(
      pendingRequest.requestId,
      saveResult,
      payload
    );
    if (
      accepted === null ||
      pendingRequest.requestId === this.lastAcknowledgedRequestId
    ) {
      return;
    }
    this.lastAcknowledgedRequestId = pendingRequest.requestId;
    if (saveResult) {
      onAcknowledged(accepted, pendingRequest, saveResult);
    }
  }

  render() {
    return null;
  }
}

const syncServerSpeciesPayload = (options: {
  resolvedActiveTab: DesignerTabId;
  serverSpeciesPayload: SpeciesPayload | null;
  speciesSavedSelection: string | null;
  speciesSavedIconBaseSelection: string | null;
  speciesSavedCustomName: string;
  speciesDirty: boolean;
  speciesPayload: SpeciesPayload | null;
  setSpeciesPayload: (payload: SpeciesPayload | null) => void;
  setSpeciesSelection: (selection: string | null) => void;
  setSpeciesSavedSelection: (selection: string | null) => void;
  setSpeciesIconBaseSelection: (selection: string | null) => void;
  setSpeciesSavedIconBaseSelection: (selection: string | null) => void;
  setSpeciesCustomName: (name: string) => void;
  setSpeciesSavedCustomName: (name: string) => void;
  setSpeciesDirty: (dirty: boolean) => void;
  speciesLoadInProgress: boolean;
  setSpeciesLoadInProgress: (value: boolean) => void;
  speciesReloadPending: boolean;
}) => {
  const {
    resolvedActiveTab,
    serverSpeciesPayload,
    speciesSavedSelection,
    speciesSavedIconBaseSelection,
    speciesSavedCustomName,
    speciesDirty,
    speciesPayload,
    setSpeciesPayload,
    setSpeciesSelection,
    setSpeciesSavedSelection,
    setSpeciesIconBaseSelection,
    setSpeciesSavedIconBaseSelection,
    setSpeciesCustomName,
    setSpeciesSavedCustomName,
    setSpeciesDirty,
    speciesLoadInProgress,
    setSpeciesLoadInProgress,
    speciesReloadPending,
  } = options;
  if (speciesReloadPending) {
    return;
  }
  if (
    resolvedActiveTab === 'species' ||
    !serverSpeciesPayload ||
    speciesDirty
  ) {
    if (speciesLoadInProgress && serverSpeciesPayload) {
      setSpeciesLoadInProgress(false);
    }
    return;
  }
  const serverSelection = serverSpeciesPayload.selected_species || null;
  const serverIconBase =
    serverSpeciesPayload.selected_icon_base ||
    serverSpeciesPayload.preview_icon_base ||
    null;
  const localSelection =
    speciesSavedSelection || speciesPayload?.selected_species || null;
  const localIconBase =
    speciesSavedIconBaseSelection || speciesPayload?.selected_icon_base || null;
  const serverCustomSpeciesName = serverSpeciesPayload.custom_species || '';
  if (
    (localSelection !== null && serverSelection !== localSelection) ||
    (localIconBase !== null && serverIconBase !== localIconBase) ||
    serverCustomSpeciesName !== speciesSavedCustomName
  ) {
    if (speciesLoadInProgress && serverSpeciesPayload) {
      setSpeciesLoadInProgress(false);
    }
    return;
  }
  if (serverSpeciesPayload !== speciesPayload) {
    setSpeciesPayload(serverSpeciesPayload);
    const selected = serverSpeciesPayload.selected_species || null;
    const selectedIconBase =
      serverSpeciesPayload.selected_icon_base ||
      serverSpeciesPayload.preview_icon_base ||
      null;
    setSpeciesSelection(selected);
    setSpeciesSavedSelection(selected);
    setSpeciesIconBaseSelection(selectedIconBase);
    setSpeciesSavedIconBaseSelection(selectedIconBase);
    setSpeciesCustomName(serverCustomSpeciesName);
    setSpeciesSavedCustomName(serverCustomSpeciesName);
    setSpeciesDirty(false);
  }
  if (speciesLoadInProgress) {
    setSpeciesLoadInProgress(false);
  }
};

type ActFn = (action: string, params?: Record<string, unknown>) => void;

const resolveSpeciesCustomName = (payload?: SpeciesPayload | null) =>
  payload?.custom_species || '';

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
      act(
        'load_body_markings',
        buildBodyMarkingsLoadParams(bodyPayloadSnapshot, basicPayloadSnapshot, {
          preview_only: 1,
        })
      );
    } else {
      setBodyReloadPending(true);
    }
  }
  if (basicPayloadSnapshot) {
    if (resolvedActiveTab === 'basic') {
      setBasicAppearanceLoadInProgress(true);
      act(
        'load_basic_appearance',
        buildBasicAppearanceLoadParams(
          basicPayloadSnapshot,
          bodyPayloadSnapshot,
          { preview_only: 1 }
        )
      );
    } else {
      setBasicReloadPending(true);
    }
  }
};

// eslint-disable-next-line complexity
type DesignerTitleTabsProps = Readonly<{
  resolvedActiveTab: DesignerTabId;
  tabsLocked: boolean;
  allowCustomTab: boolean;
  zoomPercent: number;
  setZoomPercent: (value: number) => void;
  setEnableCustomPromptOpen: (value: boolean) => void;
  onTabChange: (tab: DesignerTabId) => void;
}>;

const DesignerTitleTabs = ({
  resolvedActiveTab,
  tabsLocked,
  allowCustomTab,
  zoomPercent,
  setZoomPercent,
  setEnableCustomPromptOpen,
  onTabChange,
}: DesignerTitleTabsProps) => (
  <>
    <Tabs className="RogueStar__titleTabs">
      <Tabs.Tab
        selected={resolvedActiveTab === 'species'}
        icon="paw"
        className={tabsLocked ? 'Tab--disabled' : undefined}
        aria-disabled={tabsLocked}
        onClick={() => {
          if (!tabsLocked) {
            onTabChange('species');
          }
        }}>
        Species
      </Tabs.Tab>
      <Tabs.Tab
        selected={resolvedActiveTab === 'basic'}
        icon="user"
        className={tabsLocked ? 'Tab--disabled' : undefined}
        aria-disabled={tabsLocked}
        onClick={() => {
          if (!tabsLocked) {
            onTabChange('basic');
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
            onTabChange('body');
          }
        }}>
        Body Markings
      </Tabs.Tab>
      <Tabs.Tab
        selected={resolvedActiveTab === 'traits'}
        icon="dna"
        className={tabsLocked ? 'Tab--disabled' : undefined}
        aria-disabled={tabsLocked}
        onClick={() => {
          if (!tabsLocked) {
            onTabChange('traits');
          }
        }}>
        Traits
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
          onTabChange('custom');
        }}>
        Custom Marking Designer
      </Tabs.Tab>
    </Tabs>
    <Box
      className="RogueStar__zoomControl"
      role="group"
      aria-label={`Designer zoom, currently ${zoomPercent}%`}
      ml="auto">
      <Box className="RogueStar__zoomControlLabel">
        <Icon name="search" />
        Zoom
      </Box>
      <Box className="RogueStar__zoomTrack">
        <Box
          className="RogueStar__zoomTrackFill"
          style={{
            transform: `scaleX(${
              (zoomPercent - DESIGNER_ZOOM_MIN_PERCENT) /
              (DESIGNER_ZOOM_MAX_PERCENT - DESIGNER_ZOOM_MIN_PERCENT)
            })`,
          }}
        />
        {DESIGNER_ZOOM_LEVELS.map((percent) => (
          <Button
            key={percent}
            className={`RogueStar__zoomStop${
              percent < zoomPercent ? ' RogueStar__zoomStop--filled' : ''
            }`}
            selected={zoomPercent === percent}
            aria-label={`Set designer zoom to ${percent}%`}
            tooltip={
              zoomPercent === percent
                ? `Current zoom: ${percent}%`
                : `Set zoom to ${percent}%`
            }
            tooltipPosition="bottom"
            onClick={() => setZoomPercent(percent)}
          />
        ))}
      </Box>
      <Box className="RogueStar__zoomValue">{zoomPercent}%</Box>
    </Box>
  </>
);

type TabSwitchPromptState = {
  sourceTab: DesignerTabId;
  targetTab: DesignerTabId;
};

type PendingSpeciesTabSwitch = {
  prompt: TabSwitchPromptState;
  speciesId: string;
  iconBase: string | null;
};

type PendingTraitsSaveRequest = {
  requestId: string;
  traitsChanged: boolean;
  tabSwitchPrompt: TabSwitchPromptState | null;
};

type TabSwitchOverlayProps = Readonly<{
  prompt: TabSwitchPromptState | null;
  busy: boolean;
  saveDisabled: boolean;
  onSave: () => void;
  onDiscard: () => void;
  onCancel: () => void;
}>;

const resolveTabSwitchLabel = (tab: DesignerTabId) => {
  if (tab === 'custom') {
    return 'Custom Marking Designer';
  }
  if (tab === 'body') {
    return 'Body Markings tab';
  }
  if (tab === 'species') {
    return 'Species tab';
  }
  if (tab === 'traits') {
    return 'Traits tab';
  }
  return 'Basic Appearance tab';
};

const isTabSwitchSaveDisabled = (
  prompt: TabSwitchPromptState | null,
  speciesSelection: string | null,
  customSpeciesName: string,
  traitsValidationError: string | null
) =>
  (prompt?.sourceTab === 'species' &&
    !isSpeciesSaveAllowed(speciesSelection, customSpeciesName)) ||
  (prompt?.sourceTab === 'traits' && !!traitsValidationError);

const TabSwitchOverlay = ({
  prompt,
  busy,
  saveDisabled,
  onSave,
  onDiscard,
  onCancel,
}: TabSwitchOverlayProps) => {
  if (!prompt) {
    return null;
  }
  return (
    <UnsavedChangesOverlay
      title="Unsaved changes"
      subtitle={
        saveDisabled
          ? prompt.sourceTab === 'traits'
            ? 'Resolve the language selection issue before saving, or discard the changes.'
            : 'A name is required before you can save this custom species. Keep editing to add one, or discard the changes.'
          : `You have unsaved changes in the ${resolveTabSwitchLabel(
              prompt.sourceTab
            )}. Save them before switching?`
      }
      saveLabel="Save and switch"
      discardLabel="Discard and switch"
      busy={busy}
      saveDisabled={saveDisabled}
      onSave={onSave}
      onDiscard={onDiscard}
      onCancel={() => {
        if (!busy) {
          onCancel();
        }
      }}
    />
  );
};

const resolveDesignerLoadingState = (options: {
  resolvedActiveTab: DesignerTabId;
  loadingOverlay: boolean;
  pendingSave: boolean;
  pendingClose: boolean;
  bodyPayloadSnapshot: BodyMarkingsPayload | null;
  basicPayloadSnapshot: BasicAppearancePayload | null;
  speciesPayload: SpeciesPayload | null;
  tabSwitchBusy: boolean;
  bodyPendingSave: boolean;
  bodyPendingClose: boolean;
  basicPendingSave: boolean;
  basicPendingClose: boolean;
  speciesPendingSave: boolean;
  speciesPendingClose: boolean;
  traitsPendingSave: boolean;
  traitsPendingClose: boolean;
}) => {
  const {
    resolvedActiveTab,
    loadingOverlay,
    pendingSave,
    pendingClose,
    bodyPayloadSnapshot,
    basicPayloadSnapshot,
    speciesPayload,
    tabSwitchBusy,
    bodyPendingSave,
    bodyPendingClose,
    basicPendingSave,
    basicPendingClose,
    speciesPendingSave,
    speciesPendingClose,
    traitsPendingSave,
    traitsPendingClose,
  } = options;
  const shouldShowLoadingOverlay =
    loadingOverlay && !pendingSave && !pendingClose;
  const customTabLoading = resolvedActiveTab === 'custom' && loadingOverlay;
  const bodyTabLoading = resolvedActiveTab === 'body' && !bodyPayloadSnapshot;
  const basicPayloadReady =
    !!basicPayloadSnapshot && !basicPayloadSnapshot.preview_only;
  const basicTabLoading = resolvedActiveTab === 'basic' && !basicPayloadReady;
  const speciesTabLoading = resolvedActiveTab === 'species' && !speciesPayload;
  const tabSwitchBusyState =
    tabSwitchBusy ||
    pendingSave ||
    pendingClose ||
    bodyPendingSave ||
    bodyPendingClose ||
    basicPendingSave ||
    basicPendingClose ||
    speciesPendingSave ||
    speciesPendingClose ||
    traitsPendingSave ||
    traitsPendingClose;
  const tabsLocked =
    tabSwitchBusyState ||
    customTabLoading ||
    bodyTabLoading ||
    basicTabLoading ||
    speciesTabLoading;

  return {
    shouldShowLoadingOverlay,
    tabSwitchBusyState,
    tabsLocked,
  };
};

const resolveTraitsDraftContext = (
  data: CustomMarkingDesignerData,
  stateToken: string
) => {
  const payload = data.traits_payload || null;
  const revisionMatches =
    !data.traits_revision || payload?.revision === data.traits_revision;
  const speciesMatches =
    !data.traits_species || payload?.species_id === data.traits_species;
  const resolvedPayload =
    payload && revisionMatches && speciesMatches ? payload : null;
  const identity = resolvedPayload
    ? `${resolvedPayload.revision}-${resolvedPayload.species_id}`
    : `loading-${data.traits_revision || 0}-${data.traits_species || ''}`;
  return {
    resolvedPayload,
    draftKey: `traitsDraft-${stateToken}-${identity}`,
    dirtyKey: `traitsDirty-${stateToken}-${identity}`,
  };
};

const buildInitialTraitsDraft = (payload: TraitsPayload | null) =>
  payload ? buildTraitsDraftState(payload) : null;

let traitsSaveRequestCounter = 0;

const createTraitsSaveRequestId = (stateToken: string) => {
  traitsSaveRequestCounter = (traitsSaveRequestCounter + 1) % 1000000;
  return `${stateToken}-${Date.now()}-${traitsSaveRequestCounter}`;
};

const CustomMarkingDesignerContent = (_props, context) => {
  const { act, data } = useBackend<CustomMarkingDesignerData>(context);
  const stateToken = data.state_token || 'session';
  const {
    resolvedPayload: resolvedTraitsPayload,
    draftKey: traitsDraftKey,
    dirtyKey: traitsDirtyKey,
  } = resolveTraitsDraftContext(data, stateToken);
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
  const [zoomPercent, setZoomPercent] = useLocalState<number>(
    context,
    `customMarkingDesignerZoom-${stateToken}`,
    DESIGNER_ZOOM_MAX_PERCENT
  );
  const allowCustomTab = data.allow_custom_tab ?? true;
  const enableCustomDisclaimer = resolveEnableCustomDisclaimer(data);
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
  const { canvasBackgroundOptions, defaultCanvasBackgroundKey } =
    resolveCanvasBackgroundDefaults(data);
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
    showEquipment,
    setShowEquipment,
    showJobGear,
    setShowJobGear,
    showLoadoutGear,
    setShowLoadoutGear,
    loadingOverlay,
    setLoadingOverlay,
  } = useDesignerUiState(context, stateToken, {
    showEquipment: !!data.show_equipment,
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
    useLocalState<BodyMarkingsPayload | null>(context, 'bodyPayload', null);
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
  const [previewSourceSignature, setPreviewSourceSignature] =
    useLocalState<string>(
      context,
      `customMarkingDesignerPreviewSourceSignature-${stateToken}`,
      ''
    );
  const [basicAppearanceLoadInProgress, setBasicAppearanceLoadInProgress] =
    useLocalState<boolean>(
      context,
      `basicAppearanceLoadInProgress-${stateToken}`,
      false
    );
  const [basicPayload, setBasicPayload] =
    useLocalState<BasicAppearancePayload | null>(context, 'basicPayload', null);
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
  const [speciesPayload, setSpeciesPayload] =
    useLocalState<SpeciesPayload | null>(
      context,
      'speciesPayload',
      data.species_payload || null
    );
  const [speciesSelection, setSpeciesSelection] = useLocalState<string | null>(
    context,
    'speciesSelection',
    data.species_payload?.selected_species || null
  );
  const [speciesSavedSelection, setSpeciesSavedSelection] = useLocalState<
    string | null
  >(
    context,
    'speciesSavedSelection',
    data.species_payload?.selected_species || null
  );
  const [speciesIconBaseSelection, setSpeciesIconBaseSelection] = useLocalState<
    string | null
  >(
    context,
    'speciesIconBaseSelection',
    data.species_payload?.preview_icon_base ||
      data.species_payload?.selected_icon_base ||
      null
  );
  const [speciesSavedIconBaseSelection, setSpeciesSavedIconBaseSelection] =
    useLocalState<string | null>(
      context,
      'speciesSavedIconBaseSelection',
      data.species_payload?.selected_icon_base ||
        data.species_payload?.preview_icon_base ||
        null
    );
  const [speciesCustomName, setSpeciesCustomName] = useLocalState<string>(
    context,
    'speciesCustomName',
    resolveSpeciesCustomName(data.species_payload)
  );
  const [speciesSavedCustomName, setSpeciesSavedCustomName] =
    useLocalState<string>(
      context,
      'speciesSavedCustomName',
      resolveSpeciesCustomName(data.species_payload)
    );
  const [speciesDirty, setSpeciesDirty] = useLocalState<boolean>(
    context,
    'speciesDirty',
    false
  );
  const [speciesPendingSave, setSpeciesPendingSave] = useLocalState<boolean>(
    context,
    'speciesPendingSave',
    false
  );
  const [speciesPendingClose, setSpeciesPendingClose] = useLocalState<boolean>(
    context,
    'speciesPendingClose',
    false
  );
  const [traitsDraftState, setTraitsDraftState] =
    useLocalState<TraitsDraftState | null>(
      context,
      traitsDraftKey,
      buildInitialTraitsDraft(resolvedTraitsPayload)
    );
  const [traitsDirty, setTraitsDirty] = useLocalState<boolean>(
    context,
    traitsDirtyKey,
    false
  );
  const [traitsPendingSave, setTraitsPendingSave] = useLocalState<boolean>(
    context,
    'traitsPendingSave',
    false
  );
  const [traitsPendingClose, setTraitsPendingClose] = useLocalState<boolean>(
    context,
    'traitsPendingClose',
    false
  );
  const [traitsPendingSaveRequest, setTraitsPendingSaveRequest] =
    useLocalState<PendingTraitsSaveRequest | null>(
      context,
      `traitsPendingSaveRequest-${stateToken}`,
      null
    );
  const [traitsSaveError, setTraitsSaveError] = useLocalState<string | null>(
    context,
    `traitsSaveError-${stateToken}`,
    null
  );
  const [speciesLoadInProgress, setSpeciesLoadInProgress] =
    useLocalState<boolean>(
      context,
      `speciesLoadInProgress-${stateToken}`,
      false
    );
  const [speciesReloadPending, setSpeciesReloadPending] =
    useLocalState<boolean>(
      context,
      `speciesReloadPending-${stateToken}`,
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
  const [tabSwitchPrompt, setTabSwitchPrompt] =
    useLocalState<TabSwitchPromptState | null>(
      context,
      'customMarkingTabSwitchPrompt',
      null
    );
  const [tabSwitchBusy, setTabSwitchBusy] = useLocalState(
    context,
    'customMarkingTabSwitchBusy',
    false
  );
  const [pendingSpeciesTabSwitch, setPendingSpeciesTabSwitch] =
    useLocalState<PendingSpeciesTabSwitch | null>(
      context,
      `customMarkingPendingSpeciesTabSwitch-${stateToken}`,
      null
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
    canvasRenderWidthPx,
    canvasRenderHeightPx,
    canvasOffsetX,
    canvasOffsetY,
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
    selectedSpeciesId,
    selectedIconBase,
    speciesPreviewSources,
    speciesPreviewSignature,
  } = resolveSpeciesPreviewSelection({
    speciesPayload,
    speciesSelection,
    speciesIconBaseSelection,
    digitigrade: markingsAppearanceState.digitigrade,
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
    selectedSpeciesId,
    selectedIconBase,
    speciesPreviewSources,
    speciesPreviewSignature,
    previewStateRevision: previewState.revision,
    clientPreviewEpoch,
    setClientPreviewEpoch,
    previewSourceSignature,
    setPreviewSourceSignature,
    resolvedPartReplacementMap,
    resolvedPartPriorityMap,
    assetRevision,
    directionSignature,
    canvasWidth,
    canvasHeight,
    showEquipment,
    showJobGear,
    showLoadoutGear,
  });
  const sharedPreviewEnabled =
    resolvedActiveTab === 'custom' || resolvedActiveTab === 'traits';
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
    showEquipment,
    showJobGear,
    showLoadoutGear,
    referencePartMarkingGridsByDir,
    markingsHiddenParts,
    renderedPreviewCache,
    renderedPreviewSignature,
    draftMutationToken,
    enabled: sharedPreviewEnabled,
  });
  const appearanceContext = resolveAppearanceContext({
    previewDirStates: derivedPreviewState.dirs,
    basicPayload: basicPayloadSnapshot,
    basicAppearanceState: markingsAppearanceState,
    fallbackDigitigrade: resolvedDigitigrade,
  });
  const previewWithBaseColors = applyEyeColorToPreview(
    applyLimbHairColorToPreview(
      applyBodyColorToPreview(
        renderedPreviewDirs,
        appearanceContext.previewBaseBodyColor,
        appearanceContext.previewTargetBodyColor,
        appearanceContext.bodyColorExcludedParts,
        1,
        appearanceContext.bodyColorBlendMode
      ),
      appearanceContext.appearanceState.hair_color
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
    showEquipment,
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
  const tabLivePreview = sharedPreviewEnabled ? previewDirsWithMarkings : [];
  const canvasReferenceSources = applyAppearanceToReferenceSources({
    referenceParts,
    referenceGrid,
    referenceSignature,
    appearanceContext,
    preview: previewWithAppearance,
    dirKey: currentDirectionKey,
  });
  const canvasReferenceParts = buildGenericCanvasReference({
    referenceParts: canvasReferenceSources.referenceParts,
    referenceGrid: canvasReferenceSources.referenceGrid,
    partOrder: derivedPreviewState.dirs[currentDirectionKey]?.partOrder,
    canvasWidth,
    canvasHeight,
    activePartKey,
    mergeGrid,
  });
  const canvasReferenceGrid = canvasReferenceSources.referenceGrid;
  const canvasReferenceSignature = canvasReferenceSources.referenceSignature;
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
    appendStrokePreviewPixelsForTarget,
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
    showEquipment,
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
      const nextBasic = applyCustomPreviewOverridesToBasicPayload(
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
      const nextBasic = applyCustomPreviewOverridesToBasicPayload(
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

  const canMirrorWestToEast =
    currentDirectionKey === WEST || currentDirectionKey === EAST;
  const mirrorSourceDir = currentDirectionKey === EAST ? EAST : WEST;
  const mirrorTargetDir = mirrorSourceDir === EAST ? WEST : EAST;
  const mirrorDirectionLabel =
    mirrorSourceDir === EAST ? 'East -> West' : 'West -> East';

  const handleMirrorWestToEast = () => {
    if (uiLocked || !canMirrorWestToEast || !activePartKey) {
      return;
    }
    const sourceGrid = resolveExportGridForDirPart({
      dirState: derivedPreviewState.dirs?.[mirrorSourceDir],
      dirKey: mirrorSourceDir,
      partKey: activePartKey,
      canvasWidth,
      canvasHeight,
      dirDrafts: draftDiffIndex?.[mirrorSourceDir] || null,
      activeDirKey: currentDirectionKey,
      activePartKey,
      activeDraftDiff,
    });
    if (!sourceGrid?.length) {
      return;
    }
    const targetGrid = resolveExportGridForDirPart({
      dirState: derivedPreviewState.dirs?.[mirrorTargetDir],
      dirKey: mirrorTargetDir,
      partKey: activePartKey,
      canvasWidth,
      canvasHeight,
      dirDrafts: draftDiffIndex?.[mirrorTargetDir] || null,
      activeDirKey: currentDirectionKey,
      activePartKey,
      activeDraftDiff,
    });
    const mirrorDiff: DiffEntry[] = [];
    for (let x = 1; x <= canvasWidth; x += 1) {
      for (let y = 1; y <= canvasHeight; y += 1) {
        const sourceColor = sampleGridColorAt(sourceGrid, x, y);
        if (!sourceColor) {
          continue;
        }
        const mirroredX = canvasWidth - x + 1;
        const targetColor = sampleGridColorAt(targetGrid, mirroredX, y);
        if (targetColor === sourceColor) {
          continue;
        }
        mirrorDiff.push({
          x: mirroredX,
          y,
          color: sourceColor,
        });
      }
    }
    if (!mirrorDiff.length) {
      return;
    }
    const mirrorStrokeKey = `mirror-we-${Date.now().toString(36)}-${Math.random()
      .toString(36)
      .slice(2, 8)}`;
    appendStrokePreviewPixelsForTarget({
      stroke: mirrorStrokeKey,
      pixels: mirrorDiff,
      dirKey: mirrorTargetDir,
      partKey: activePartKey,
      sessionKey: buildLocalSessionKey(mirrorTargetDir, activePartKey),
    });
    setDraftMutationToken((draftMutationToken + 1) % 1000000);
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

  const serverSpeciesPayload = data.species_payload || null;
  syncServerSpeciesPayload({
    resolvedActiveTab,
    serverSpeciesPayload,
    speciesSavedSelection,
    speciesSavedIconBaseSelection,
    speciesSavedCustomName,
    speciesDirty,
    speciesPayload,
    setSpeciesPayload,
    setSpeciesSelection,
    setSpeciesSavedSelection,
    setSpeciesIconBaseSelection,
    setSpeciesSavedIconBaseSelection,
    setSpeciesCustomName,
    setSpeciesSavedCustomName,
    setSpeciesDirty,
    speciesLoadInProgress,
    setSpeciesLoadInProgress,
    speciesReloadPending,
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
  const { shouldShowLoadingOverlay, tabSwitchBusyState, tabsLocked } =
    resolveDesignerLoadingState({
      resolvedActiveTab,
      loadingOverlay,
      pendingSave,
      pendingClose,
      bodyPayloadSnapshot,
      basicPayloadSnapshot,
      speciesPayload,
      tabSwitchBusy,
      bodyPendingSave,
      bodyPendingClose,
      basicPendingSave,
      basicPendingClose,
      speciesPendingSave,
      speciesPendingClose,
      traitsPendingSave,
      traitsPendingClose,
    });

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
    showEquipment,
    onToggleEquipment: () => setShowEquipment(!showEquipment),
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

  const detectSpeciesUnsaved = () => {
    const sharedState = selectBackend(context.store.getState()).shared || {};
    const dirtyFlag =
      typeof sharedState.speciesDirty === 'boolean'
        ? (sharedState.speciesDirty as boolean)
        : speciesDirty;
    return !!dirtyFlag;
  };

  const detectTraitsUnsaved = () => {
    const sharedState = selectBackend(context.store.getState()).shared || {};
    const dirtyFlag = sharedState[traitsDirtyKey];
    return typeof dirtyFlag === 'boolean' ? dirtyFlag : traitsDirty;
  };

  const resolveLatestTraitsDraft = () => {
    const sharedState = selectBackend(context.store.getState()).shared || {};
    const draft = sharedState[traitsDraftKey] as
      | TraitsDraftState
      | null
      | undefined;
    return draft !== undefined ? draft : traitsDraftState;
  };

  const resolveLatestTraitsValidationError = () => {
    const draft = resolveLatestTraitsDraft();
    return resolvedTraitsPayload && draft
      ? resolveLanguagesDraftValidationError(resolvedTraitsPayload, draft)
      : null;
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

  const resolveSpeciesReloadPending = () => {
    const sharedState = selectBackend(context.store.getState()).shared || {};
    const pendingValue = sharedState[`speciesReloadPending-${stateToken}`];
    if (typeof pendingValue === 'boolean') {
      return pendingValue;
    }
    return speciesReloadPending;
  };

  const hasSharedStateKey = (key: string) => {
    const sharedState = selectBackend(context.store.getState()).shared || {};
    return Object.prototype.hasOwnProperty.call(sharedState, key);
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

  const requestBodyPayload = (
    extra: Record<string, unknown> = {},
    retainKnown = true
  ) =>
    act(
      'load_body_markings',
      buildBodyMarkingsLoadParams(
        resolveLatestBodyPayload(),
        resolveLatestBasicPayload(),
        extra,
        retainKnown
      )
    );

  const requestBasicPayload = (
    extra: Record<string, unknown> = {},
    retainKnown = true
  ) =>
    act(
      'load_basic_appearance',
      buildBasicAppearanceLoadParams(
        resolveLatestBasicPayload(),
        resolveLatestBodyPayload(),
        extra,
        retainKnown
      )
    );

  const resolveLatestSpeciesPayload = () => {
    const sharedState = selectBackend(context.store.getState()).shared || {};
    const payload = sharedState.speciesPayload as
      | SpeciesPayload
      | null
      | undefined;
    return payload !== undefined ? payload : speciesPayload;
  };

  const resolveBodyPayloadForSwitch = () => {
    const latestBodyPayload = resolveLatestBodyPayload();
    const latestReloadPending = resolveBodyReloadPending();
    const dataBodyPayload = data.body_markings_payload || null;
    const sharedBodyPayloadCleared =
      hasSharedStateKey('bodyPayload') && latestBodyPayload === null;
    const resolvedBodyPayload = sharedBodyPayloadCleared
      ? null
      : (latestBodyPayload ?? dataBodyPayload ?? null);
    return {
      latestBodyPayload,
      latestReloadPending,
      dataBodyPayload,
      resolvedBodyPayload,
      sharedBodyPayloadCleared,
    };
  };

  const resolveBasicPayloadForSwitch = () => {
    const latestBasicPayload = resolveLatestBasicPayload();
    const latestReloadPending = resolveBasicReloadPending();
    const dataBasicPayload = data.basic_appearance_payload || null;
    const dataBasicUsable =
      !!dataBasicPayload && !dataBasicPayload.preview_only;
    const sharedBasicPayloadCleared =
      hasSharedStateKey('basicPayload') && latestBasicPayload === null;
    const resolvedBasicPayload = sharedBasicPayloadCleared
      ? null
      : latestBasicPayload && !latestBasicPayload.preview_only
        ? latestBasicPayload
        : dataBasicUsable
          ? dataBasicPayload
          : null;
    return {
      latestBasicPayload,
      latestReloadPending,
      dataBasicPayload,
      dataBasicUsable,
      resolvedBasicPayload,
      sharedBasicPayloadCleared,
    };
  };

  const unsavedDetectors: Record<DesignerTabId, () => boolean> = {
    custom: detectCustomUnsaved,
    body: detectBodyUnsaved,
    basic: detectBasicUnsaved,
    species: detectSpeciesUnsaved,
    traits: detectTraitsUnsaved,
  };
  const resolveUnsavedForTab = (tab: DesignerTabId) => unsavedDetectors[tab]();

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
    const { latestState, latestSavedState } = resolveLatestBasicState();
    const speciesPreviewStale =
      shouldInvalidateSpeciesPayloadForBiologicalGenderChange(
        latestSavedState.biological_gender,
        latestState.biological_gender
      );
    setBasicPendingSave(true);
    setBasicPendingClose(false);
    try {
      setPreviewRefreshSkips((previewRefreshSkips || 0) + 1);
      await act('save_basic_appearance', {
        biological_gender: latestState.biological_gender,
        digitigrade: latestState.digitigrade ? 1 : 0,
        body_color: latestState.body_color,
        eye_color: latestState.eye_color,
        blood_type: latestState.blood_type,
        blood_reagent: latestState.blood_reagent,
        blood_color: latestState.blood_color,
        needs_glasses: latestState.needs_glasses ? 1 : 0,
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
        ...buildProstheticSaveParams(
          latestState,
          basicPayload?.prosthetic_context
        ),
        close: false,
      });
      if (speciesPreviewStale) {
        setSpeciesPayload(null);
        setSpeciesReloadPending(true);
      }
      const committedState: BasicAppearanceState = {
        ...latestState,
        limbs: cloneLimbOverrideState(latestState.limbs),
        limb_operations: [],
        organ_operations: [],
      };
      setBasicAppearanceDirty(false);
      setBasicSavedState(committedState);
      setBasicAppearanceState(committedState);
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
      limbs: cloneLimbOverrideState(fallbackSaved.limbs),
      limb_operations: [],
      organ_operations: [],
    };
    setBasicAppearanceState(next);
    setBasicAppearanceDirty(false);
  };

  const resolveLatestSpeciesSelection = () => {
    const sharedState = selectBackend(context.store.getState()).shared || {};
    const selection = sharedState.speciesSelection as string | null | undefined;
    return selection !== undefined ? selection : speciesSelection;
  };

  const resolveLatestSpeciesIconBaseSelection = () => {
    const sharedState = selectBackend(context.store.getState()).shared || {};
    const selection = sharedState.speciesIconBaseSelection as
      | string
      | null
      | undefined;
    return selection !== undefined ? selection : speciesIconBaseSelection;
  };

  const resolveLatestSpeciesCustomName = () => {
    const sharedState = selectBackend(context.store.getState()).shared || {};
    const name = sharedState.speciesCustomName as string | undefined;
    return name !== undefined ? name : speciesCustomName;
  };

  const isPayloadSpeciesStale = (
    payload?: { species_id?: string | null; custom_base?: string | null } | null
  ) => {
    const currentSpecies =
      resolveLatestSpeciesSelection() ||
      speciesSavedSelection ||
      speciesPayload?.selected_species ||
      data.species_payload?.selected_species ||
      null;
    const currentIconBase =
      resolveLatestSpeciesIconBaseSelection() ||
      speciesSavedIconBaseSelection ||
      speciesPayload?.preview_icon_base ||
      speciesPayload?.selected_icon_base ||
      data.species_payload?.preview_icon_base ||
      data.species_payload?.selected_icon_base ||
      null;
    return (
      !!payload &&
      ((!!currentSpecies && payload.species_id !== currentSpecies) ||
        (!!currentIconBase && payload.custom_base !== currentIconBase))
    );
  };

  const saveSpeciesChanges = async (): Promise<boolean> => {
    const wasDirty = detectSpeciesUnsaved();
    if (!wasDirty) {
      return true;
    }
    const latestSelection = resolveLatestSpeciesSelection();
    const latestCustomSpeciesName = resolveLatestSpeciesCustomName();
    if (!isSpeciesSaveAllowed(latestSelection, latestCustomSpeciesName)) {
      return false;
    }
    const latestIconBase = resolveLatestSpeciesIconBaseSelection();
    const previousSelection = speciesSavedSelection;
    const previousIconBase = speciesSavedIconBaseSelection;
    setSpeciesPendingSave(true);
    setSpeciesPendingClose(false);
    try {
      await act('save_species', {
        species: latestSelection,
        icon_base: latestIconBase,
        custom_species: latestCustomSpeciesName,
        close: false,
        ...buildSpeciesSaveCacheParams(
          resolveLatestBodyPayload(),
          resolveLatestBasicPayload()
        ),
      });
      setSpeciesDirty(false);
      setSpeciesSelection(latestSelection);
      setSpeciesSavedSelection(latestSelection);
      setSpeciesIconBaseSelection(latestIconBase);
      setSpeciesSavedIconBaseSelection(latestIconBase);
      setSpeciesCustomName(latestCustomSpeciesName);
      setSpeciesSavedCustomName(latestCustomSpeciesName);
      if (speciesPayload) {
        setSpeciesPayload({
          ...speciesPayload,
          selected_species: latestSelection,
          selected_icon_base: latestIconBase,
          preview_icon_base: latestIconBase,
          custom_species: latestCustomSpeciesName,
        });
      }
      if (
        previousSelection !== latestSelection ||
        previousIconBase !== latestIconBase
      ) {
        setBodyReloadPending(true);
        setBasicReloadPending(true);
        setBodyMarkingsDirty(false);
        setBasicAppearanceDirty(false);
        setReloadTargetRevision(0);
        setReloadPending(true);
      }
      return true;
    } catch (error) {
      return false;
    } finally {
      setSpeciesPendingSave(false);
      setSpeciesPendingClose(false);
    }
  };

  const discardSpeciesChanges = () => {
    const fallbackSelection =
      speciesSavedSelection || speciesPayload?.selected_species || null;
    const fallbackIconBase =
      speciesSavedIconBaseSelection ||
      speciesPayload?.selected_icon_base ||
      speciesPayload?.preview_icon_base ||
      null;
    const fallbackCustomSpeciesName = speciesSavedCustomName;
    setSpeciesSelection(fallbackSelection);
    setSpeciesIconBaseSelection(fallbackIconBase);
    setSpeciesCustomName(fallbackCustomSpeciesName);
    setSpeciesDirty(false);
    if (speciesPayload && fallbackSelection) {
      setSpeciesPayload({
        ...speciesPayload,
        selected_species: fallbackSelection,
        preview_species: fallbackSelection,
        selected_icon_base: fallbackIconBase,
        preview_icon_base: fallbackIconBase,
        custom_species: fallbackCustomSpeciesName,
      });
    }
  };

  const saveTraitsChanges = async (
    close = false,
    tabSwitchPrompt: TabSwitchPromptState | null = null
  ): Promise<boolean> => {
    const latestDraft = resolveLatestTraitsDraft();
    if (!latestDraft) {
      return false;
    }
    const wasDirty = detectTraitsUnsaved();
    if (!wasDirty && !close) {
      return true;
    }
    if (!resolvedTraitsPayload) {
      setTraitsSaveError(
        'The Traits draft is still loading. Please try again.'
      );
      return false;
    }
    const validationError = resolveLanguagesDraftValidationError(
      resolvedTraitsPayload,
      latestDraft
    );
    if (validationError) {
      setTraitsSaveError(validationError);
      return false;
    }
    const canonicalDraft = buildTraitsDraftState(resolvedTraitsPayload);
    const traitsChanged = !traitDraftSelectionsEqual(
      latestDraft,
      canonicalDraft
    );
    setTraitsSaveError(null);
    setPendingSave(true);
    setPendingClose(close);
    setTraitsPendingSave(true);
    setTraitsPendingClose(close);
    const requestId = createTraitsSaveRequestId(stateToken);
    setTraitsPendingSaveRequest({
      requestId,
      traitsChanged,
      tabSwitchPrompt,
    });
    try {
      act('save_traits', {
        ...buildTraitsSavePayload(latestDraft),
        request_id: requestId,
        close,
      });
      return true;
    } catch (error) {
      setPendingSave(false);
      setPendingClose(false);
      setTraitsPendingSave(false);
      setTraitsPendingClose(false);
      setTraitsPendingSaveRequest(null);
      setTraitsSaveError(
        'The Traits save could not be sent. Please try again.'
      );
      return false;
    }
  };

  const discardTraitsChanges = () => {
    setTraitsDraftState(
      resolvedTraitsPayload
        ? buildTraitsDraftState(resolvedTraitsPayload)
        : null
    );
    setTraitsDirty(false);
    setTraitsSaveError(null);
  };

  const closeTraitsWithoutSaving = async () => {
    setTraitsSaveError(null);
    setPendingClose(true);
    setTraitsPendingClose(true);
    try {
      await act('close_traits');
    } finally {
      setPendingClose(false);
      setTraitsPendingClose(false);
    }
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
      const {
        latestBodyPayload,
        latestReloadPending,
        dataBodyPayload,
        resolvedBodyPayload,
        sharedBodyPayloadCleared,
      } = resolveBodyPayloadForSwitch();
      if (
        !sharedBodyPayloadCleared &&
        !latestBodyPayload &&
        dataBodyPayload &&
        !latestReloadPending &&
        !isPayloadSpeciesStale(dataBodyPayload)
      ) {
        setBodyPayload(
          mergeBodyMarkingsPayload(
            null,
            dataBodyPayload,
            resolveLatestBasicPayload()
          )
        );
      }
      const speciesStale = isPayloadSpeciesStale(resolvedBodyPayload);
      if (!resolvedBodyPayload || latestReloadPending || speciesStale) {
        if (!resolvedBodyPayload || speciesStale) {
          setBodyPayload(null);
        }
        setBodyMarkingsLoadInProgress(true);
        if (resolvedBodyPayload && latestReloadPending && !speciesStale) {
          requestBodyPayload({ preview_only: 1 });
        } else {
          requestBodyPayload();
        }
        if (latestReloadPending) {
          setBodyReloadPending(false);
        }
      }
    }
    if (nextTab === 'basic') {
      const {
        latestBasicPayload,
        latestReloadPending,
        dataBasicPayload,
        dataBasicUsable,
        resolvedBasicPayload,
        sharedBasicPayloadCleared,
      } = resolveBasicPayloadForSwitch();
      if (
        !sharedBasicPayloadCleared &&
        (!latestBasicPayload || latestBasicPayload.preview_only) &&
        dataBasicUsable &&
        !latestReloadPending &&
        !isPayloadSpeciesStale(dataBasicPayload)
      ) {
        setBasicPayload(
          mergeBasicAppearancePayload(
            null,
            dataBasicPayload!,
            resolveLatestBodyPayload()
          )
        );
      }
      const speciesStale = isPayloadSpeciesStale(resolvedBasicPayload);
      if (!resolvedBasicPayload || latestReloadPending || speciesStale) {
        if (!resolvedBasicPayload || speciesStale) {
          setBasicPayload(null);
        }
        setBasicAppearanceLoadInProgress(true);
        if (resolvedBasicPayload && latestReloadPending && !speciesStale) {
          requestBasicPayload({ preview_only: 1 });
        } else {
          requestBasicPayload();
        }
        if (latestReloadPending) {
          setBasicReloadPending(false);
        }
      }
    }
    if (nextTab === 'species') {
      const latestSpeciesPayload = resolveLatestSpeciesPayload();
      const latestReloadPending = resolveSpeciesReloadPending();
      const dataSpeciesPayload = data.species_payload || null;
      const resolvedSpeciesPayload =
        latestSpeciesPayload ?? dataSpeciesPayload ?? null;
      if (!latestSpeciesPayload && dataSpeciesPayload && !latestReloadPending) {
        setSpeciesPayload(dataSpeciesPayload);
      }
      if (!resolvedSpeciesPayload || latestReloadPending) {
        if (!resolvedSpeciesPayload) {
          setSpeciesPayload(null);
        }
        setSpeciesLoadInProgress(true);
        act('load_species');
      }
    }
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
    const {
      latestBodyPayload,
      latestReloadPending,
      dataBodyPayload,
      resolvedBodyPayload,
      sharedBodyPayloadCleared,
    } = resolveBodyPayloadForSwitch();
    if (
      !forceReload &&
      !sharedBodyPayloadCleared &&
      !latestBodyPayload &&
      dataBodyPayload &&
      !latestReloadPending &&
      !isPayloadSpeciesStale(dataBodyPayload)
    ) {
      setBodyPayload(
        mergeBodyMarkingsPayload(
          null,
          dataBodyPayload,
          resolveLatestBasicPayload()
        )
      );
    }
    const speciesStale = isPayloadSpeciesStale(resolvedBodyPayload);
    const shouldReload =
      !resolvedBodyPayload ||
      latestReloadPending ||
      forceReload ||
      speciesStale;
    if (!shouldReload) {
      return;
    }
    if (forceReload || speciesStale || !resolvedBodyPayload) {
      setBodyPayload(null);
    }
    setBodyMarkingsLoadInProgress(true);
    if (
      resolvedBodyPayload &&
      latestReloadPending &&
      !forceReload &&
      !speciesStale
    ) {
      await requestBodyPayload({ preview_only: 1 });
    } else {
      await requestBodyPayload({}, !forceReload && !speciesStale);
    }
    if (latestReloadPending || forceReload) {
      setBodyReloadPending(false);
    }
  };

  const ensureBasicPayloadForSwitch = async (forceReload: boolean) => {
    const {
      latestBasicPayload,
      latestReloadPending,
      dataBasicPayload,
      dataBasicUsable,
      resolvedBasicPayload,
      sharedBasicPayloadCleared,
    } = resolveBasicPayloadForSwitch();
    if (
      !forceReload &&
      !sharedBasicPayloadCleared &&
      (!latestBasicPayload || latestBasicPayload.preview_only) &&
      dataBasicUsable &&
      !latestReloadPending &&
      !isPayloadSpeciesStale(dataBasicPayload)
    ) {
      setBasicPayload(
        mergeBasicAppearancePayload(
          null,
          dataBasicPayload!,
          resolveLatestBodyPayload()
        )
      );
    }
    const speciesStale = isPayloadSpeciesStale(resolvedBasicPayload);
    const shouldReload =
      !resolvedBasicPayload ||
      latestReloadPending ||
      forceReload ||
      speciesStale;
    if (!shouldReload) {
      return;
    }
    if (forceReload || speciesStale || !resolvedBasicPayload) {
      setBasicPayload(null);
    }
    setBasicAppearanceLoadInProgress(true);
    if (
      resolvedBasicPayload &&
      latestReloadPending &&
      !forceReload &&
      !speciesStale
    ) {
      await requestBasicPayload({ preview_only: 1 });
    } else {
      await requestBasicPayload({}, !forceReload && !speciesStale);
    }
    if (latestReloadPending || forceReload) {
      setBasicReloadPending(false);
    }
  };

  const ensureSpeciesPayloadForSwitch = async (forceReload: boolean) => {
    const latestSpeciesPayload = resolveLatestSpeciesPayload();
    const latestReloadPending = resolveSpeciesReloadPending();
    const dataSpeciesPayload = data.species_payload || null;
    const resolvedSpeciesPayload =
      latestSpeciesPayload ?? dataSpeciesPayload ?? null;
    if (!latestSpeciesPayload && dataSpeciesPayload && !latestReloadPending) {
      setSpeciesPayload(dataSpeciesPayload);
    }
    const shouldReload =
      !resolvedSpeciesPayload || latestReloadPending || forceReload;
    if (!shouldReload) {
      return;
    }
    if (!resolvedSpeciesPayload) {
      setSpeciesPayload(null);
    }
    setSpeciesLoadInProgress(true);
    await act('load_species');
  };

  const completeSpeciesTabSwitch = async (result: SpeciesSaveResult) => {
    if (!pendingSpeciesTabSwitch) {
      return;
    }
    if (result.accepted === false) {
      setPendingSpeciesTabSwitch(null);
      setTabSwitchPrompt(null);
      setTabSwitchBusy(false);
      return;
    }
    if (
      result.species_id !== pendingSpeciesTabSwitch.speciesId ||
      (!!pendingSpeciesTabSwitch.iconBase &&
        result.custom_base !== pendingSpeciesTabSwitch.iconBase)
    ) {
      return;
    }
    const { prompt } = pendingSpeciesTabSwitch;
    setPendingSpeciesTabSwitch(null);
    try {
      if (prompt.targetTab === 'custom') {
        setReloadTargetRevision(0);
        setLoadingOverlay(true);
        setReloadOverlayMinUntil(Date.now() + 400);
        setReloadPending(false);
      }
      if (prompt.targetTab === 'body') {
        await ensureBodyPayloadForSwitch(false);
      }
      if (prompt.targetTab === 'basic') {
        await ensureBasicPayloadForSwitch(false);
      }
      if (prompt.targetTab === 'species') {
        await ensureSpeciesPayloadForSwitch(false);
      }
      setActiveTab(prompt.targetTab);
      setTabSwitchPrompt(null);
    } finally {
      setTabSwitchBusy(false);
    }
  };

  const completeTraitsSave = async (
    accepted: boolean,
    pendingRequest: PendingTraitsSaveRequest,
    saveResult: TraitsSaveResult
  ) => {
    setTraitsPendingSaveRequest(null);
    const clearPendingState = () => {
      setPendingSave(false);
      setPendingClose(false);
      setTraitsPendingSave(false);
      setTraitsPendingClose(false);
    };

    const prompt = pendingRequest.tabSwitchPrompt;
    if (!accepted) {
      setTraitsSaveError(
        saveResult.error ||
          'The server rejected this trait set. Resolve its incompatibilities and try again.'
      );
      clearPendingState();
      if (prompt) {
        setTabSwitchPrompt(prompt);
        setTabSwitchBusy(false);
      }
      return;
    }

    setTraitsSaveError(null);
    setTraitsDirty(false);
    if (pendingRequest.traitsChanged) {
      setBodyReloadPending(true);
      setBasicReloadPending(true);
      setReloadTargetRevision(0);
      setReloadPending(true);
    }
    if (!prompt) {
      clearPendingState();
      return;
    }

    try {
      if (
        prompt.targetTab === 'custom' &&
        (pendingRequest.traitsChanged || reloadPending)
      ) {
        if (pendingRequest.traitsChanged) {
          setReloadTargetRevision(0);
        }
        setLoadingOverlay(true);
        setReloadOverlayMinUntil(Date.now() + 400);
        setReloadPending(false);
      }
      if (prompt.targetTab === 'body') {
        await ensureBodyPayloadForSwitch(pendingRequest.traitsChanged);
      }
      if (prompt.targetTab === 'basic') {
        await ensureBasicPayloadForSwitch(pendingRequest.traitsChanged);
      }
      if (prompt.targetTab === 'species') {
        await ensureSpeciesPayloadForSwitch(false);
      }
      setActiveTab(prompt.targetTab);
      setTabSwitchPrompt(null);
    } finally {
      clearPendingState();
      setTabSwitchBusy(false);
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
    if (sourceTab === 'species') {
      const saved = await saveSpeciesChanges();
      return !!saved && !detectSpeciesUnsaved();
    }
    if (sourceTab === 'traits') {
      const saved = await saveTraitsChanges();
      return !!saved && !detectTraitsUnsaved();
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
    const wasSpeciesDirty =
      prompt.sourceTab === 'species' && detectSpeciesUnsaved();
    const wasTraitsDirty =
      prompt.sourceTab === 'traits' && detectTraitsUnsaved();
    setTabSwitchBusy(true);
    if (wasSpeciesDirty) {
      const pendingSpecies = resolveLatestSpeciesSelection();
      if (!pendingSpecies) {
        setTabSwitchBusy(false);
        return;
      }
      setPendingSpeciesTabSwitch({
        prompt,
        speciesId: pendingSpecies,
        iconBase: resolveLatestSpeciesIconBaseSelection(),
      });
      const saved = await saveSpeciesChanges();
      if (!saved) {
        setPendingSpeciesTabSwitch(null);
        setTabSwitchBusy(false);
      }
      return;
    }
    if (wasTraitsDirty) {
      setTabSwitchPrompt(null);
      const saved = await saveTraitsChanges(false, prompt);
      if (!saved) {
        setTabSwitchPrompt(prompt);
        setTabSwitchBusy(false);
      }
      return;
    }
    setTabSwitchPrompt(null);
    try {
      const saved = await saveTabBeforeSwitch(prompt.sourceTab);
      if (!saved) {
        setTabSwitchPrompt(prompt);
        return;
      }
      if (
        prompt.targetTab === 'custom' &&
        (reloadPending ||
          wasBodyDirty ||
          wasBasicDirty ||
          wasSpeciesDirty ||
          wasTraitsDirty)
      ) {
        if (!reloadPending) {
          setReloadTargetRevision(0);
        }
        setLoadingOverlay(true);
        setReloadOverlayMinUntil(Date.now() + 400);
        setReloadPending(false);
      }
      if (prompt.targetTab === 'body') {
        await ensureBodyPayloadForSwitch(
          wasCustomDirty || wasSpeciesDirty || wasTraitsDirty
        );
      }
      if (prompt.targetTab === 'basic') {
        await ensureBasicPayloadForSwitch(
          wasCustomDirty || wasSpeciesDirty || wasTraitsDirty
        );
      }
      if (prompt.targetTab === 'species') {
        await ensureSpeciesPayloadForSwitch(wasCustomDirty);
      }
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
      } else if (tabSwitchPrompt.sourceTab === 'species') {
        discardSpeciesChanges();
      } else if (tabSwitchPrompt.sourceTab === 'traits') {
        discardTraitsChanges();
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
      if (tabSwitchPrompt.targetTab === 'species') {
        await ensureSpeciesPayloadForSwitch(false);
      }
      setActiveTab(tabSwitchPrompt.targetTab);
    } finally {
      setTabSwitchBusy(false);
    }
  };

  const titleTabs = (
    <DesignerTitleTabs
      resolvedActiveTab={resolvedActiveTab}
      tabsLocked={tabsLocked}
      allowCustomTab={allowCustomTab}
      zoomPercent={zoomPercent}
      setZoomPercent={setZoomPercent}
      setEnableCustomPromptOpen={setEnableCustomPromptOpen}
      onTabChange={handleTabChange}
    />
  );

  return (
    <Window
      theme="nanotrasen rogue-star-window"
      width={1720}
      height={950}
      scale={zoomPercent / 100}
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
      <ServerPayloadSyncScheduler
        resolvedActiveTab={resolvedActiveTab}
        serverBodyPayload={data.body_markings_payload || null}
        serverBasicPayload={data.basic_appearance_payload || null}
        targetSpeciesId={resolveLatestSpeciesSelection()}
        targetIconBase={resolveLatestSpeciesIconBaseSelection()}
        bodyPayload={bodyPayload}
        basicPayload={basicPayload}
        bodyMarkingsDirty={bodyMarkingsDirty}
        basicAppearanceDirty={basicAppearanceDirty}
        bodyReloadPending={bodyReloadPending}
        basicReloadPending={basicReloadPending}
        bodyLoadInProgress={bodyMarkingsLoadInProgress}
        basicLoadInProgress={basicAppearanceLoadInProgress}
        setBodyPayload={setBodyPayload}
        setBasicPayload={setBasicPayload}
        setBodySavedState={setBodySavedState}
        setBodyMarkingsState={setBodyMarkingsState}
        setBodyMarkingsOrder={setBodyMarkingsOrder}
        setBodyMarkingsSelected={setBodyMarkingsSelected}
        setBodyMarkingsDirty={setBodyMarkingsDirty}
        setBasicAppearanceState={setBasicAppearanceState}
        setBasicSavedState={setBasicSavedState}
        setBasicAppearanceDirty={setBasicAppearanceDirty}
        setBodyLoadInProgress={setBodyMarkingsLoadInProgress}
        setBasicLoadInProgress={setBasicAppearanceLoadInProgress}
        clearBodyReloadPending={() => setBodyReloadPending(false)}
        clearBasicReloadPending={() => setBasicReloadPending(false)}
      />
      <SpeciesSaveResultSyncScheduler
        speciesSaveResult={data.species_save_result || null}
        onSaveResult={completeSpeciesTabSwitch}
        speciesPayload={speciesPayload}
        bodyPayload={bodyPayload}
        basicPayload={basicPayload}
        stateToken={stateToken}
        writeStates={(states) =>
          context.store.dispatch(backendSetSharedStates({ states }))
        }
      />
      <TraitsSaveResultSyncScheduler
        saveResult={data.traits_save_result || null}
        payload={resolvedTraitsPayload}
        pendingRequest={traitsPendingSaveRequest}
        onAcknowledged={completeTraitsSave}
      />
      <PayloadPrefetchScheduler
        enabled={
          resolvedActiveTab !== 'species' ||
          (!bodyReloadPending && !basicReloadPending)
        }
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
        requestBody={() => requestBodyPayload()}
        requestBasic={() => requestBasicPayload()}
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
                canMirrorWestToEast={canMirrorWestToEast}
                mirrorDirectionLabel={mirrorDirectionLabel}
                onMirrorWestToEast={handleMirrorWestToEast}
                brushColor={brushColor}
                customColorSlots={customColorSlots}
                handleCustomColorUpdate={handleCustomColorUpdate}
                handleColorPickerApply={handleColorPickerApply}
              />
              <CanvasSection
                title={directionTitle}
                canvasFrameStyle={canvasFrameStyle}
                canvasBackgroundStyle={canvasBackgroundStyle}
                canvasRenderWidthPx={canvasRenderWidthPx}
                canvasRenderHeightPx={canvasRenderHeightPx}
                canvasOffsetX={canvasOffsetX}
                canvasOffsetY={canvasOffsetY}
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
                iconScaleX={data.trait_icon_scale_x}
                iconScaleY={data.trait_icon_scale_y}
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
            livePreview={tabLivePreview}
            resolvedPartPriorityMap={resolvedPartPriorityMap}
            resolvedPartReplacementMap={resolvedPartReplacementMap}
            showEquipment={showEquipment}
            onToggleEquipment={() => setShowEquipment(!showEquipment)}
            showJobGear={showJobGear}
            onToggleJobGear={() => setShowJobGear(!showJobGear)}
            showLoadoutGear={showLoadoutGear}
            onToggleLoadout={() => setShowLoadoutGear(!showLoadoutGear)}
          />
        ) : resolvedActiveTab === 'species' ? (
          <SpeciesTab
            data={data}
            setPendingClose={setPendingClose}
            canvasBackgroundOptions={canvasBackgroundOptions}
            resolvedCanvasBackground={resolvedCanvasBackground}
            backgroundFallbackColor={backgroundFallbackColor}
            cycleCanvasBackground={cycleCanvasBackground}
            canvasBackgroundScale={canvasBackgroundScale}
            livePreview={tabLivePreview}
            resolvedPartPriorityMap={resolvedPartPriorityMap}
            resolvedPartReplacementMap={resolvedPartReplacementMap}
            showEquipment={showEquipment}
            onToggleEquipment={() => setShowEquipment(!showEquipment)}
            showJobGear={showJobGear}
            onToggleJobGear={() => setShowJobGear(!showJobGear)}
            showLoadoutGear={showLoadoutGear}
            onToggleLoadout={() => setShowLoadoutGear(!showLoadoutGear)}
          />
        ) : resolvedActiveTab === 'traits' ? (
          <TraitsTab
            data={data}
            draftState={traitsDraftState}
            setDraftState={setTraitsDraftState}
            dirty={traitsDirty}
            setDirty={setTraitsDirty}
            pendingSave={traitsPendingSave}
            pendingClose={traitsPendingClose}
            saveError={traitsSaveError}
            onSave={() => saveTraitsChanges(false)}
            onSaveAndClose={() => saveTraitsChanges(true)}
            onDiscardAndClose={closeTraitsWithoutSaving}
            canvasBackgroundOptions={canvasBackgroundOptions}
            resolvedCanvasBackground={resolvedCanvasBackground}
            backgroundFallbackColor={backgroundFallbackColor}
            cycleCanvasBackground={cycleCanvasBackground}
            canvasBackgroundScale={canvasBackgroundScale}
            livePreview={tabLivePreview}
            canvasWidth={canvasWidth}
            canvasHeight={canvasHeight}
            previewFitToFrame={previewFitToFrame}
            onTogglePreviewFit={toggleCanvasFit}
            showEquipment={showEquipment}
            onToggleEquipment={() => setShowEquipment(!showEquipment)}
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
            livePreview={tabLivePreview}
            resolvedPartPriorityMap={resolvedPartPriorityMap}
            resolvedPartReplacementMap={resolvedPartReplacementMap}
            showEquipment={showEquipment}
            onToggleEquipment={() => setShowEquipment(!showEquipment)}
            showJobGear={showJobGear}
            onToggleJobGear={() => setShowJobGear(!showJobGear)}
            showLoadoutGear={showLoadoutGear}
            onToggleLoadout={() => setShowLoadoutGear(!showLoadoutGear)}
          />
        )}
      </Window.Content>
      <TabSwitchOverlay
        prompt={tabSwitchPrompt}
        busy={tabSwitchBusyState}
        saveDisabled={isTabSwitchSaveDisabled(
          tabSwitchPrompt,
          resolveLatestSpeciesSelection(),
          resolveLatestSpeciesCustomName(),
          resolveLatestTraitsValidationError()
        )}
        onSave={handleTabSwitchSave}
        onDiscard={handleTabSwitchDiscard}
        onCancel={() => setTabSwitchPrompt(null)}
      />
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

type StaticAssetRegistryErrorProps = {
  readonly message: string;
  readonly onShown: () => void;
};

type StaticAssetRegistryReadyProps = {
  readonly asset: string;
  readonly revision: number;
  readonly onReady: () => void;
};

type StaticAssetFallbackReadyProps = {
  readonly onReady: () => void;
};

class StaticAssetRegistryReady extends Component<StaticAssetRegistryReadyProps> {
  componentDidMount() {
    this.props.onReady();
  }

  componentDidUpdate(prevProps: StaticAssetRegistryReadyProps) {
    if (
      prevProps.asset !== this.props.asset ||
      prevProps.revision !== this.props.revision
    ) {
      this.props.onReady();
    }
  }

  render() {
    return <CustomMarkingDesignerContent />;
  }
}

class StaticAssetFallbackReady extends Component<StaticAssetFallbackReadyProps> {
  componentDidMount() {
    this.props.onReady();
  }

  render() {
    return <CustomMarkingDesignerContent />;
  }
}

class StaticAssetRegistryError extends Component<StaticAssetRegistryErrorProps> {
  componentDidMount() {
    this.props.onShown();
  }

  render() {
    return (
      <Window
        theme="nanotrasen rogue-star-window"
        width={1720}
        height={950}
        resizable>
        <Window.Content>
          <Box
            position="fixed"
            style={{
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              display: 'flex',
              'align-items': 'center',
              'justify-content': 'center',
              background:
                'linear-gradient(135deg, rgba(4, 2, 8, 0.97), rgba(18, 6, 32, 0.95))',
              'text-align': 'center',
            }}>
            <Box
              style={{
                width: 'min(560px, 90%)',
                padding: '2.5rem 2rem',
                'border-radius': '20px',
                background: 'rgba(14, 7, 26, 0.94)',
                border: '1px solid rgba(239, 96, 96, 0.55)',
                'box-shadow': '0 25px 70px rgba(3, 1, 10, 0.85)',
              }}>
              <Box fontSize={1.35} bold mb={1}>
                Sprite atlas could not be loaded
              </Box>
              <Box color="label" lineHeight={1.6}>
                {this.props.message}
              </Box>
              <Box color="label" lineHeight={1.6} mt={1}>
                Close and reopen the designer to retry.
              </Box>
            </Box>
          </Box>
        </Window.Content>
      </Window>
    );
  }
}

export const CustomMarkingDesigner = (_props, context) => {
  const { act, data } = useBackend<CustomMarkingDesignerData>(context);
  const manifest = data.static_asset_manifest;
  if (data.static_asset_manifest_fallback) {
    return (
      <StaticAssetFallbackReady
        onReady={() => act('static_asset_manifest_fallback_ready')}
      />
    );
  }
  if (
    data.static_asset_manifest_error ||
    !manifest ||
    !isStaticIconAssetRegistryLoaded(manifest)
  ) {
    return (
      <StaticAssetRegistryError
        message={
          data.static_asset_manifest_error ||
          'The server did not provide a hydrated sprite atlas manifest.'
        }
        onShown={() => act('static_asset_manifest_failed', manifest || {})}
      />
    );
  }
  return (
    <StaticAssetRegistryReady
      asset={manifest.asset}
      revision={manifest.revision}
      onReady={() => act('static_asset_manifest_ready', manifest)}
    />
  );
};
