// //////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Preview state helpers for custom marking designer //
// //////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Updated to support 64x64 markings //////////////////
// //////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support loaout and job gear /////////////
// //////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support new body marking selector ///////
// //////////////////////////////////////////////////////////////////////////////////////////////////

import {
  GENERIC_PART_KEY,
  applyDiffToGrid,
  cloneGridData,
  createBlankGrid,
  getPreviewGridFromAsset,
  getPreviewPartMapFromAssets,
  getPreviewGridMapFromGearAssets,
  gridHasPixels,
  IconAssetPayload,
  GearOverlayAsset,
} from '../../../utils/character-preview';
import { TRANSPARENT_HEX } from '../../../utils/color';
import { CANVAS_FIT_TARGET } from '../constants';
import type {
  DiffEntry,
  PreviewDirState,
  PreviewDirectionSource,
  PreviewState,
} from '../../../utils/character-preview';
import type {
  BodyPartEntry,
  CustomMarkingDesignerData,
  DirectionCanvasSourceOptions,
  DirectionCanvasSourceResult,
} from '../types';
import { convertCompositeGridToUi } from './gridConversion';

const OVERLAY_SLOT_PRIORITY_MAP: Record<string, number> = {
  tail_lower: 7,
  wing_lower: 8,
  shoes: 9,
  uniform: 10,
  id: 11,
  gloves: 13,
  belt: 14,
  suit: 15,
  tail_upper: 16,
  glasses: 17,
  suit_store: 19,
  back: 20,
  hair: 21,
  hair_accessory: 22,
  ears: 23,
  eyes: 24,
  mask: 25,
  head: 27,
  wing_upper: 32,
  tail_upper_alt: 33,
  modifier: 34,
  vore_belly: 38,
  vore_tail: 39,
  custom_marking: 40,
};
const LARGE_CANVAS_OVERLAY_SLOTS = new Set([
  'tail_lower',
  'tail_upper',
  'tail_upper_alt',
  'wing_lower',
  'wing_upper',
  'vore_tail',
]);
const HIDDEN_LEG_PARTS = new Set(['l_leg', 'r_leg', 'l_foot', 'r_foot']);
const MARKING_MASK_ALPHA_THRESHOLD = 250;

type OverlaySlotFilter = (options: {
  slot: string | null;
  isLarge: boolean;
}) => boolean;

export const buildLocalSessionKey = (dirKey: number, partKey: string) =>
  `${dirKey ?? 'dir'}-${partKey || 'generic'}`;

export type PreviewUpdateOptions = {
  data: CustomMarkingDesignerData;
  sessionKey: string;
  activePartKey: string;
  canvasWidth: number;
  canvasHeight: number;
  canvasGrid?: string[][] | null;
};

const shouldApplyReplacement = (
  partId?: string | null,
  replacements?: Record<string, boolean>,
  presence?: Record<string, boolean>
): boolean =>
  !!partId &&
  partId !== GENERIC_PART_KEY &&
  !!replacements?.[partId] &&
  (presence ? !!presence[partId] : true);

type ReferenceMaskOptions = {
  referenceParts: Record<string, string[][]> | null;
  referenceGrid: string[][] | null;
  partReplacementMap?: Record<string, boolean>;
  partPaintPresenceMap?: Record<string, boolean>;
};

type HiddenPartsMaskOptions = {
  referenceParts: Record<string, string[][]> | null;
  referenceGrid: string[][] | null;
  hiddenBodyParts?: string[] | null;
};

const parseAlphaChannel = (value: string): number | null => {
  if (value.length === 9 && value.startsWith('#')) {
    const alpha = parseInt(value.slice(7, 9), 16);
    return Number.isNaN(alpha) ? null : alpha;
  }
  return null;
};

const pixelHasColor = (value?: string, alphaThreshold?: number): boolean => {
  if (typeof value !== 'string' || !value.length) {
    return false;
  }
  if (value === TRANSPARENT_HEX) {
    return false;
  }
  if (alphaThreshold === undefined) {
    return true;
  }
  const alpha = parseAlphaChannel(value);
  if (alpha === null) {
    return true;
  }
  return alpha >= alphaThreshold;
};

const applyReplacementMaskToGrid = (
  target: string[][],
  mask: string[][],
  options?: { alphaThreshold?: number }
): boolean => {
  if (!Array.isArray(target) || !Array.isArray(mask)) {
    return false;
  }
  let changed = false;
  const alphaThreshold = options?.alphaThreshold;
  const width = Math.min(target.length, mask.length);
  for (let x = 0; x < width; x += 1) {
    const targetColumn = target[x];
    const maskColumn = mask[x];
    if (!Array.isArray(targetColumn) || !Array.isArray(maskColumn)) {
      continue;
    }
    const height = Math.min(targetColumn.length, maskColumn.length);
    for (let y = 0; y < height; y += 1) {
      const maskHasColor = pixelHasColor(maskColumn[y], alphaThreshold);
      const targetHasColor = pixelHasColor(targetColumn[y]);
      if (!maskHasColor || !targetHasColor) {
        continue;
      }
      targetColumn[y] = TRANSPARENT_HEX;
      changed = true;
    }
  }
  return changed;
};

const stripMarkingsFromGrid = (
  grid: string[][] | null,
  markings: string[][] | null
): string[][] | null => {
  if (!grid || !markings || !markings.length) {
    return grid;
  }
  const cloned = cloneGridData(grid);
  const changed = applyReplacementMaskToGrid(cloned, markings, {
    alphaThreshold: MARKING_MASK_ALPHA_THRESHOLD,
  });
  return changed ? cloned : grid;
};

const buildCombinedMarkingGrid = (
  partMarkings: Record<string, string[][]> | null,
  canvasWidth: number,
  canvasHeight: number
): string[][] | null => {
  if (!partMarkings) {
    return null;
  }
  const layers: string[][][] = [];
  for (const [partId, grid] of Object.entries(partMarkings)) {
    if (!partId || partId === GENERIC_PART_KEY || !grid || !grid.length) {
      continue;
    }
    layers.push(grid);
  }
  return mergeOverlayLayersNormalized(layers, canvasWidth, canvasHeight);
};

const maskReferenceSourcesForReplacements = (
  options: ReferenceMaskOptions
): {
  referenceParts: Record<string, string[][]> | null;
  referenceGrid: string[][] | null;
} => {
  const {
    referenceParts,
    referenceGrid,
    partReplacementMap,
    partPaintPresenceMap,
  } = options;
  if (!partReplacementMap || !Object.values(partReplacementMap).some(Boolean)) {
    return { referenceParts, referenceGrid };
  }
  let maskedParts = referenceParts;
  let maskedGrid = referenceGrid;
  let partsMutated = false;
  let gridMutated = false;
  const ensureMaskedParts = () => {
    if (partsMutated) {
      return;
    }
    maskedParts = { ...(maskedParts || {}) };
    partsMutated = true;
  };
  const ensureMaskedGrid = () => {
    if (gridMutated || !referenceGrid) {
      return;
    }
    maskedGrid = cloneGridData(referenceGrid);
    gridMutated = true;
  };
  for (const [partId, isReplacement] of Object.entries(partReplacementMap)) {
    if (!isReplacement) {
      continue;
    }
    if (
      !shouldApplyReplacement(partId, partReplacementMap, partPaintPresenceMap)
    ) {
      continue;
    }
    const maskGrid = referenceParts?.[partId];
    if (maskGrid && maskGrid.length) {
      if (maskedGrid) {
        ensureMaskedGrid();
        applyReplacementMaskToGrid(maskedGrid, maskGrid);
      }
      const genericGrid = maskedParts?.[GENERIC_PART_KEY];
      if (genericGrid && genericGrid.length) {
        ensureMaskedParts();
        const clonedGeneric = cloneGridData(genericGrid);
        const changed = applyReplacementMaskToGrid(clonedGeneric, maskGrid);
        if (changed && maskedParts) {
          maskedParts[GENERIC_PART_KEY] = clonedGeneric;
        }
      }
    }
    if (
      maskedParts &&
      Object.prototype.hasOwnProperty.call(maskedParts, partId)
    ) {
      ensureMaskedParts();
      delete maskedParts[partId];
    }
  }
  return {
    referenceParts: maskedParts,
    referenceGrid: maskedGrid,
  };
};

const maskReferenceSourcesForHiddenParts = (
  options: HiddenPartsMaskOptions
): {
  referenceParts: Record<string, string[][]> | null;
  referenceGrid: string[][] | null;
} => {
  const { referenceParts, referenceGrid, hiddenBodyParts } = options;
  if (!Array.isArray(hiddenBodyParts) || !hiddenBodyParts.length) {
    return { referenceParts, referenceGrid };
  }
  let maskedParts = referenceParts;
  let maskedGrid = referenceGrid;
  let partsMutated = false;
  let gridMutated = false;
  const ensureMaskedParts = () => {
    if (partsMutated) {
      return;
    }
    maskedParts = { ...(maskedParts || {}) };
    partsMutated = true;
  };
  const ensureMaskedGrid = () => {
    if (gridMutated || !referenceGrid) {
      return;
    }
    maskedGrid = cloneGridData(referenceGrid);
    gridMutated = true;
  };
  for (const rawPartId of hiddenBodyParts) {
    const partId =
      typeof rawPartId === 'string' && rawPartId.length ? rawPartId : null;
    if (!partId || partId === GENERIC_PART_KEY) {
      continue;
    }
    const maskGrid = referenceParts?.[partId];
    if (maskGrid && maskGrid.length) {
      if (maskedGrid) {
        ensureMaskedGrid();
        applyReplacementMaskToGrid(maskedGrid, maskGrid);
      }
      const genericGrid = maskedParts?.[GENERIC_PART_KEY];
      if (genericGrid && genericGrid.length) {
        ensureMaskedParts();
        const clonedGeneric = cloneGridData(genericGrid);
        const changed = applyReplacementMaskToGrid(clonedGeneric, maskGrid);
        if (changed && maskedParts) {
          maskedParts[GENERIC_PART_KEY] = clonedGeneric;
        }
      }
    }
    if (
      maskedParts &&
      Object.prototype.hasOwnProperty.call(maskedParts, partId)
    ) {
      ensureMaskedParts();
      delete maskedParts[partId];
    }
  }
  return {
    referenceParts: maskedParts,
    referenceGrid: maskedGrid,
  };
};

const collectHiddenLegParts = (hiddenBodyParts?: string[] | null): string[] => {
  if (!Array.isArray(hiddenBodyParts)) {
    return [];
  }
  const parts: string[] = [];
  for (const partId of hiddenBodyParts) {
    if (typeof partId === 'string' && HIDDEN_LEG_PARTS.has(partId)) {
      parts.push(partId);
    }
  }
  return parts;
};

const maskGridForHiddenLegParts = (
  grid: string[][] | null,
  referenceParts: Record<string, string[][]> | null,
  hiddenBodyParts?: string[] | null
): string[][] | null => {
  if (!grid || !referenceParts) {
    return grid;
  }
  const hiddenLegParts = collectHiddenLegParts(hiddenBodyParts);
  if (!hiddenLegParts.length) {
    return grid;
  }
  const masked = cloneGridData(grid);
  for (const partId of hiddenLegParts) {
    const maskGrid = referenceParts[partId];
    if (!maskGrid) {
      continue;
    }
    applyReplacementMaskToGrid(masked, maskGrid);
  }
  return masked;
};

const buildReferenceSignature = ({
  previewRevision,
  dirKey,
  partReplacementMap,
  partPaintPresenceMap,
  hiddenBodyParts,
}: {
  previewRevision?: number;
  dirKey?: number;
  partReplacementMap?: Record<string, boolean>;
  partPaintPresenceMap?: Record<string, boolean>;
  hiddenBodyParts?: string[] | null;
}): string => {
  const replacementSignature = partReplacementMap
    ? Object.keys(partReplacementMap)
        .filter((partId) => typeof partId === 'string' && partId.length)
        .sort()
        .map((partId) => {
          const replaced = partReplacementMap[partId] ? 1 : 0;
          const painted = partPaintPresenceMap?.[partId] ? 1 : 0;
          return `${partId}:${replaced}:${painted}`;
        })
        .join(',')
    : '';
  const hiddenSignature = Array.isArray(hiddenBodyParts)
    ? hiddenBodyParts
        .filter((partId) => typeof partId === 'string' && partId.length)
        .slice()
        .sort()
        .join(',')
    : '';
  const dirSignature = Number.isFinite(dirKey) ? String(dirKey) : '0';
  const revisionSignature = Number.isFinite(previewRevision)
    ? String(previewRevision)
    : '0';
  return [
    revisionSignature,
    dirSignature,
    replacementSignature,
    hiddenSignature,
  ]
    .filter((entry) => entry.length > 0)
    .join('|');
};

type HiddenPartsResolution = {
  gearHiddenParts?: string[] | undefined;
  resolvedHiddenParts?: string[] | undefined;
};

const resolveHiddenParts = (
  activeDirState: PreviewDirState | undefined,
  hiddenBodyPartsOverride?: string[] | null
): HiddenPartsResolution => {
  const gearHiddenParts = activeDirState?.hiddenBodyParts || undefined;
  if (
    Array.isArray(hiddenBodyPartsOverride) &&
    hiddenBodyPartsOverride.length
  ) {
    return {
      gearHiddenParts,
      resolvedHiddenParts: Array.from(
        new Set([...(gearHiddenParts || []), ...hiddenBodyPartsOverride])
      ),
    };
  }
  return { gearHiddenParts, resolvedHiddenParts: gearHiddenParts };
};

const buildOverlaySlotFilter = (
  restrictOverlaySlots: boolean
): OverlaySlotFilter | undefined => {
  if (!restrictOverlaySlots) {
    return undefined;
  }
  return ({ slot, isLarge }) => {
    if (slot && LARGE_CANVAS_OVERLAY_SLOTS.has(slot)) {
      return true;
    }
    return isLarge;
  };
};

type GearLayerResult = {
  gearLoadoutLayers: string[][][] | null;
  gearJobLayers: string[][][] | null;
};

const resolveGearLayers = (options: {
  activeDirState: PreviewDirState | undefined;
  canvasWidth: number;
  canvasHeight: number;
  signalAssetUpdate: () => void;
  allowLoadout: boolean;
  allowJob: boolean;
}): GearLayerResult => {
  const {
    activeDirState,
    canvasWidth,
    canvasHeight,
    signalAssetUpdate,
    allowLoadout,
    allowJob,
  } = options;
  const gearLoadoutSlotMap = allowLoadout
    ? getPreviewGridMapFromGearAssets(
        activeDirState?.gearLoadoutOverlayAssets,
        canvasWidth,
        canvasHeight,
        signalAssetUpdate
      ) || null
    : null;
  const loadoutEntries = orderOverlaySlotLayers(gearLoadoutSlotMap);
  const gearJobSlotMap = allowJob
    ? getPreviewGridMapFromGearAssets(
        activeDirState?.gearJobOverlayAssets,
        canvasWidth,
        canvasHeight,
        signalAssetUpdate
      ) || null
    : null;
  const jobEntriesRaw = orderOverlaySlotLayers(gearJobSlotMap);
  const loadoutSlots =
    loadoutEntries && loadoutEntries.length
      ? new Set(loadoutEntries.map((entry) => entry.slot))
      : null;
  const jobEntries =
    jobEntriesRaw && jobEntriesRaw.length
      ? jobEntriesRaw.filter(
          (entry) =>
            !(
              allowLoadout &&
              allowJob &&
              loadoutSlots &&
              entry.slot &&
              loadoutSlots.has(entry.slot)
            )
        )
      : null;
  return {
    gearLoadoutLayers: loadoutEntries
      ? loadoutEntries.map((entry) => entry.grid)
      : null,
    gearJobLayers: jobEntries ? jobEntries.map((entry) => entry.grid) : null,
  };
};

type ReferenceAssetsResult = {
  referencePartsRaw: Record<string, string[][]> | null;
  referencePartMarkings: Record<string, string[][]> | null;
  combinedMarkingGrid: string[][] | null;
  referenceGrid: string[][] | null;
};

const resolveReferenceAssets = (options: {
  activeDirState: PreviewDirState | undefined;
  canvasWidth: number;
  canvasHeight: number;
  signalAssetUpdate: () => void;
  referencePartMarkingGrids?: Record<string, string[][]> | null;
}): ReferenceAssetsResult => {
  const {
    activeDirState,
    canvasWidth,
    canvasHeight,
    signalAssetUpdate,
    referencePartMarkingGrids,
  } = options;
  const referencePartsRaw: Record<string, string[][]> | null =
    getPreviewPartMapFromAssets(
      activeDirState?.referencePartAssets,
      canvasWidth,
      canvasHeight,
      signalAssetUpdate
    ) || null;
  const referencePartMarkings: Record<string, string[][]> | null =
    (referencePartMarkingGrids ??
      getPreviewPartMapFromAssets(
        activeDirState?.referencePartMarkingAssets,
        canvasWidth,
        canvasHeight,
        signalAssetUpdate
      )) ||
    null;
  const combinedMarkingGrid = buildCombinedMarkingGrid(
    referencePartMarkings,
    canvasWidth,
    canvasHeight
  );
  const referenceGrid: string[][] | null =
    getPreviewGridFromAsset(
      activeDirState?.bodyAsset || activeDirState?.compositeAsset,
      canvasWidth,
      canvasHeight,
      signalAssetUpdate
    ) || null;
  return {
    referencePartsRaw,
    referencePartMarkings,
    combinedMarkingGrid,
    referenceGrid,
  };
};

const buildReferencePartsWithGear = (options: {
  referenceParts: Record<string, string[][]> | null;
  overlayLayers: string[][][] | null;
  gearJobLayers: string[][][] | null;
  gearLoadoutLayers: string[][][] | null;
  restrictOverlaySlots: boolean;
  canvasWidth: number;
  canvasHeight: number;
  gearHiddenParts?: string[] | undefined;
}): Record<string, string[][]> | null => {
  const {
    referenceParts,
    overlayLayers,
    gearJobLayers,
    gearLoadoutLayers,
    restrictOverlaySlots,
    canvasWidth,
    canvasHeight,
    gearHiddenParts,
  } = options;
  const overlayGrid = restrictOverlaySlots
    ? mergeOverlayLayersNormalized(overlayLayers, canvasWidth, canvasHeight)
    : null;
  const resolvedJobGearGrid = gearJobLayers
    ? mergeOverlayLayersNormalized(gearJobLayers, canvasWidth, canvasHeight)
    : null;
  const resolvedLoadoutGearGrid = gearLoadoutLayers
    ? mergeOverlayLayersNormalized(gearLoadoutLayers, canvasWidth, canvasHeight)
    : null;
  const maskedJobGearGrid = maskGridForHiddenLegParts(
    resolvedJobGearGrid,
    referenceParts,
    gearHiddenParts
  );
  const maskedLoadoutGearGrid = maskGridForHiddenLegParts(
    resolvedLoadoutGearGrid,
    referenceParts,
    gearHiddenParts
  );
  const referencePartsWithOverlays =
    overlayGrid && overlayGrid.length
      ? {
          ...(referenceParts || {}),
          overlay: overlayGrid,
        }
      : referenceParts;
  let referencePartsWithGear = referencePartsWithOverlays
    ? { ...referencePartsWithOverlays }
    : null;
  if (maskedJobGearGrid) {
    referencePartsWithGear = referencePartsWithGear || {};
    referencePartsWithGear.gear_job = maskedJobGearGrid;
  }
  if (maskedLoadoutGearGrid) {
    referencePartsWithGear = referencePartsWithGear || {};
    referencePartsWithGear.gear_loadout = maskedLoadoutGearGrid;
  }
  return referencePartsWithGear;
};

const applyMarkingGridToReferenceSources = (options: {
  referenceParts: Record<string, string[][]> | null;
  referenceGrid: string[][] | null;
  combinedMarkingGrid: string[][] | null;
}): {
  referenceParts: Record<string, string[][]> | null;
  referenceGrid: string[][] | null;
} => {
  const { referenceParts, referenceGrid, combinedMarkingGrid } = options;
  const resolvedMarkingGrid =
    combinedMarkingGrid && gridHasPixels(combinedMarkingGrid)
      ? combinedMarkingGrid
      : null;
  if (!resolvedMarkingGrid) {
    return { referenceParts, referenceGrid };
  }
  const strippedGeneric = referenceParts?.[GENERIC_PART_KEY]
    ? stripMarkingsFromGrid(
        referenceParts[GENERIC_PART_KEY],
        resolvedMarkingGrid
      )
    : null;
  const strippedReferenceGrid = stripMarkingsFromGrid(
    referenceGrid,
    resolvedMarkingGrid
  );
  let nextReferenceParts = referenceParts;
  if (strippedGeneric || !nextReferenceParts || !nextReferenceParts.markings) {
    nextReferenceParts = {
      ...(nextReferenceParts || {}),
    };
    if (strippedGeneric) {
      nextReferenceParts[GENERIC_PART_KEY] = strippedGeneric;
    }
    nextReferenceParts.markings = resolvedMarkingGrid;
  }
  return {
    referenceParts: nextReferenceParts,
    referenceGrid: strippedReferenceGrid,
  };
};

const resolveCanvasSourceGrids = (options: {
  activeDirState: PreviewDirState | undefined;
  currentDirectionKey: number;
  activeDirKey: number;
  activePartKey: string;
  serverActivePartKey: string;
  serverCanvasGrid: string[][] | null;
  layerPartsWithDrafts?: Record<string, string[][]> | null;
  canvasWidth: number;
  canvasHeight: number;
  diff?: DiffEntry[] | null;
  diffSeq?: number;
  stroke?: string | number;
}): {
  serverDiffPayload: DiffEntry[] | null;
  serverDiffSeq?: number;
  serverDiffStroke?: string | number;
  uiCanvasGrid: string[][];
} => {
  const {
    activeDirState,
    currentDirectionKey,
    activeDirKey,
    activePartKey,
    serverActivePartKey,
    serverCanvasGrid,
    layerPartsWithDrafts,
    canvasWidth,
    canvasHeight,
    diff,
    diffSeq,
    stroke,
  } = options;
  const previewPartGrid = activeDirState?.customParts?.[activePartKey]?.grid;
  const overlaySourceGrid =
    currentDirectionKey === activeDirKey &&
    activePartKey === serverActivePartKey &&
    serverCanvasGrid
      ? serverCanvasGrid
      : null;
  const serverDiffApplies = currentDirectionKey === activeDirKey;
  const serverDiffPayload = serverDiffApplies ? diff || null : null;
  const serverDiffSeq = serverDiffApplies ? diffSeq : undefined;
  const serverDiffStroke = serverDiffApplies ? stroke : undefined;
  const fallbackLayerGrid = layerPartsWithDrafts?.[activePartKey];
  const uiCanvasGrid = (previewPartGrid ||
    overlaySourceGrid ||
    fallbackLayerGrid ||
    createBlankGrid(canvasWidth, canvasHeight)) as string[][];
  return {
    serverDiffPayload,
    serverDiffSeq,
    serverDiffStroke,
    uiCanvasGrid,
  };
};

export const resolveDirectionCanvasSources = (
  options: DirectionCanvasSourceOptions
): DirectionCanvasSourceResult => {
  const {
    derivedPreviewState,
    currentDirectionKey,
    activePartKey,
    serverActivePartKey,
    serverCanvasGrid,
    layerPartsWithDrafts,
    canvasWidth,
    canvasHeight,
    activeDirKey,
    diff,
    diffSeq,
    stroke,
    signalAssetUpdate,
    showJobGear,
    showLoadoutGear,
    partPaintPresenceMap,
    partReplacementMap,
    referencePartMarkingGrids,
    hiddenBodyPartsOverride,
  } = options;
  const activeDirState = derivedPreviewState.dirs[currentDirectionKey];
  const { gearHiddenParts, resolvedHiddenParts } = resolveHiddenParts(
    activeDirState,
    hiddenBodyPartsOverride
  );
  const overlayAssets = activeDirState?.overlayAssets as
    | GearOverlayAsset[]
    | IconAssetPayload[]
    | undefined;
  const restrictOverlaySlots =
    canvasWidth > CANVAS_FIT_TARGET || canvasHeight > CANVAS_FIT_TARGET;
  const overlaySlotFilter = buildOverlaySlotFilter(restrictOverlaySlots);
  const allowLoadout = showLoadoutGear !== false;
  const allowJob = showJobGear !== false;
  const { gearLoadoutLayers, gearJobLayers } = resolveGearLayers({
    activeDirState,
    canvasWidth,
    canvasHeight,
    signalAssetUpdate,
    allowLoadout,
    allowJob,
  });
  const overlayLayers = pickOverlayLayers(
    overlayAssets,
    canvasWidth,
    canvasHeight,
    signalAssetUpdate || (() => undefined),
    overlaySlotFilter
  );
  const { referencePartsRaw, combinedMarkingGrid, referenceGrid } =
    resolveReferenceAssets({
      activeDirState,
      canvasWidth,
      canvasHeight,
      signalAssetUpdate,
      referencePartMarkingGrids,
    });
  const referencePartsWithGear = buildReferencePartsWithGear({
    referenceParts: referencePartsRaw,
    overlayLayers,
    gearJobLayers,
    gearLoadoutLayers,
    restrictOverlaySlots,
    canvasWidth,
    canvasHeight,
    gearHiddenParts,
  });
  const {
    referenceParts: resolvedReferenceParts,
    referenceGrid: resolvedReferenceGrid,
  } = maskReferenceSourcesForReplacements({
    referenceParts: referencePartsWithGear,
    referenceGrid,
    partReplacementMap,
    partPaintPresenceMap,
  });
  const {
    referenceParts: resolvedReferencePartsWithHidden,
    referenceGrid: resolvedReferenceGridWithHidden,
  } = maskReferenceSourcesForHiddenParts({
    referenceParts: resolvedReferenceParts,
    referenceGrid: resolvedReferenceGrid,
    hiddenBodyParts: resolvedHiddenParts,
  });
  const {
    referenceParts: resolvedReferencePartsFinal,
    referenceGrid: resolvedReferenceGridFinal,
  } = applyMarkingGridToReferenceSources({
    referenceParts: resolvedReferencePartsWithHidden,
    referenceGrid: resolvedReferenceGridWithHidden,
    combinedMarkingGrid,
  });
  const { serverDiffPayload, serverDiffSeq, serverDiffStroke, uiCanvasGrid } =
    resolveCanvasSourceGrids({
      activeDirState,
      currentDirectionKey,
      activeDirKey,
      activePartKey,
      serverActivePartKey,
      serverCanvasGrid,
      layerPartsWithDrafts,
      canvasWidth,
      canvasHeight,
      diff,
      diffSeq,
      stroke,
    });
  const referenceSignature = buildReferenceSignature({
    previewRevision: derivedPreviewState.revision,
    dirKey: currentDirectionKey,
    partReplacementMap,
    partPaintPresenceMap,
    hiddenBodyParts: resolvedHiddenParts,
  });
  return {
    referenceParts: resolvedReferencePartsFinal,
    referenceGrid: resolvedReferenceGridFinal,
    referenceSignature,
    serverDiffPayload,
    serverDiffSeq,
    serverDiffStroke,
    uiCanvasGrid,
  };
};

export const updatePreviewStateFromPayload = (
  prev: PreviewState,
  options: PreviewUpdateOptions
): PreviewState => {
  const {
    data,
    sessionKey,
    activePartKey,
    canvasWidth,
    canvasHeight,
    canvasGrid,
  } = options;
  let nextDirs = prev.dirs;
  let dirsMutated = false;
  let changed = false;
  let revision = prev.revision;
  let lastDiffSeq = prev.lastDiffSeq;

  const assignDirEntry = (dir: number, entry: PreviewDirState | undefined) => {
    if (!entry || nextDirs[dir] === entry) {
      return;
    }
    if (!dirsMutated) {
      nextDirs = { ...nextDirs };
      dirsMutated = true;
    }
    nextDirs[dir] = entry;
    changed = true;
  };

  const incomingRevision = data.preview_revision || 0;
  const previewSources = data.preview_sources || [];
  if (
    incomingRevision &&
    incomingRevision > prev.revision &&
    previewSources.length
  ) {
    for (const source of previewSources) {
      if (!source) {
        continue;
      }
      assignDirEntry(
        source.dir,
        mergePreviewSourceState(
          nextDirs[source.dir],
          source,
          canvasWidth,
          canvasHeight
        )
      );
    }
    revision = incomingRevision;
    changed = true;
  }

  const resolvedCanvasGrid =
    Array.isArray(canvasGrid) && canvasGrid.length
      ? canvasGrid
      : Array.isArray(data.grid) && data.grid.length
        ? (data.grid as string[][])
        : null;

  if (resolvedCanvasGrid && resolvedCanvasGrid.length) {
    assignDirEntry(
      data.active_dir_key,
      updateDirCustomPartFromGrid(nextDirs[data.active_dir_key], {
        dir: data.active_dir_key,
        label: data.active_dir,
        part: activePartKey,
        sessionKey,
        grid: resolvedCanvasGrid,
      })
    );
  }

  if (
    Array.isArray(data.diff) &&
    data.diff.length &&
    typeof data.diff_seq === 'number' &&
    data.diff_seq !== prev.lastDiffSeq
  ) {
    assignDirEntry(
      data.active_dir_key,
      updateDirCustomPartFromDiff(nextDirs[data.active_dir_key], {
        dir: data.active_dir_key,
        label: data.active_dir,
        part: activePartKey,
        diff: data.diff,
        canvasWidth,
        canvasHeight,
      })
    );
    lastDiffSeq = data.diff_seq;
    changed = true;
  }

  if (!changed) {
    return prev;
  }

  return {
    revision,
    lastDiffSeq,
    dirs: dirsMutated ? nextDirs : prev.dirs,
  };
};

export const cloneDirForUpdate = (
  entry: PreviewDirState | undefined,
  dir: number,
  label?: string
): PreviewDirState => {
  if (entry) {
    return {
      ...entry,
      label: label || entry.label,
      customParts: { ...entry.customParts },
    };
  }
  return {
    dir,
    label: label || `Dir ${dir}`,
    customParts: {},
  };
};

export const mergePreviewSourceState = (
  existing: PreviewDirState | undefined,
  source: PreviewDirectionSource,
  canvasWidth: number,
  canvasHeight: number
): PreviewDirState => {
  const next = cloneDirForUpdate(existing, source.dir, source.label);
  next.bodyAsset = source.body_asset || existing?.bodyAsset;
  next.compositeAsset = source.composite_asset || existing?.compositeAsset;
  next.referencePartAssets =
    source.reference_part_assets || existing?.referencePartAssets;
  next.referencePartMarkingAssets =
    source.reference_part_marking_assets ||
    existing?.referencePartMarkingAssets;
  next.bodyColorExcludedParts =
    source.body_color_excluded_parts || existing?.bodyColorExcludedParts;
  next.overlayAssets = source.overlay_assets as typeof next.overlayAssets;
  next.gearJobOverlayAssets =
    source.job_overlay_assets as typeof next.gearJobOverlayAssets;
  next.gearLoadoutOverlayAssets =
    source.loadout_overlay_assets as typeof next.gearLoadoutOverlayAssets;
  next.partOrder = source.part_order || existing?.partOrder;
  next.hiddenBodyParts =
    source.hidden_body_parts || existing?.hiddenBodyParts || undefined;
  if (source.custom_parts) {
    for (const partId of Object.keys(source.custom_parts)) {
      const partGrid = source.custom_parts[partId];
      if (!partGrid) {
        continue;
      }
      const converted = convertCompositeGridToUi(
        partGrid,
        canvasWidth,
        canvasHeight
      );
      if (!converted) {
        continue;
      }
      next.customParts[partId] = {
        grid: converted,
        lastSyncKey: null,
      };
    }
  }
  return next;
};

export const updateDirCustomPartFromGrid = (
  entry: PreviewDirState | undefined,
  payload: {
    dir: number;
    label?: string;
    part: string;
    sessionKey: string;
    grid: string[][];
  }
): PreviewDirState | undefined => {
  if (!Array.isArray(payload.grid) || !payload.grid.length) {
    return entry;
  }
  const newGrid = cloneGridData(payload.grid);
  const currentPart = entry?.customParts?.[payload.part];
  if (
    currentPart &&
    currentPart.lastSyncKey === payload.sessionKey &&
    gridsEqual(currentPart.grid, newGrid)
  ) {
    return entry;
  }
  const next = cloneDirForUpdate(entry, payload.dir, payload.label);
  next.customParts[payload.part] = {
    grid: newGrid,
    lastSyncKey: payload.sessionKey,
  };
  return next;
};

export const updateDirCustomPartFromDiff = (
  entry: PreviewDirState | undefined,
  payload: {
    dir: number;
    label?: string;
    part: string;
    diff: DiffEntry[];
    canvasWidth: number;
    canvasHeight: number;
  }
): PreviewDirState | undefined => {
  if (!payload.diff.length) {
    return entry;
  }
  const baseGrid =
    entry?.customParts?.[payload.part]?.grid ||
    createBlankGrid(payload.canvasWidth, payload.canvasHeight);
  const updatedGrid = applyDiffToGrid(
    cloneGridData(baseGrid),
    payload.diff,
    payload.canvasWidth,
    payload.canvasHeight
  );
  if (
    entry?.customParts?.[payload.part] &&
    gridsEqual(entry.customParts[payload.part].grid, updatedGrid)
  ) {
    return entry;
  }
  const next = cloneDirForUpdate(entry, payload.dir, payload.label);
  const existingPart = next.customParts[payload.part] || {
    grid: createBlankGrid(payload.canvasWidth, payload.canvasHeight),
    lastSyncKey: null,
  };
  next.customParts[payload.part] = {
    ...existingPart,
    grid: updatedGrid,
  };
  return next;
};

export type ExportGridOptions = {
  dirState?: PreviewDirState;
  dirKey: number;
  partKey: string;
  canvasWidth: number;
  canvasHeight: number;
  dirDrafts?: Record<string, DiffEntry[]> | null;
  activeDirKey: number;
  activePartKey: string;
  activeDraftDiff?: DiffEntry[] | null;
};

export const resolveExportGridForDirPart = (
  options: ExportGridOptions
): string[][] | null => {
  const {
    dirState,
    dirKey,
    partKey,
    canvasWidth,
    canvasHeight,
    dirDrafts,
    activeDirKey,
    activePartKey,
    activeDraftDiff,
  } = options;
  const baseGrid = dirState?.customParts?.[partKey]?.grid;
  let workingGrid =
    baseGrid && baseGrid.length ? cloneGridData(baseGrid) : null;
  const pendingDraft = dirDrafts?.[partKey];
  const useActiveDraft =
    dirKey === activeDirKey &&
    partKey === activePartKey &&
    Array.isArray(activeDraftDiff) &&
    activeDraftDiff.length > 0;
  const diffToApply =
    pendingDraft && pendingDraft.length
      ? pendingDraft
      : useActiveDraft
        ? activeDraftDiff
        : null;
  if (diffToApply && diffToApply.length) {
    workingGrid = applyDiffToGrid(
      workingGrid || createBlankGrid(canvasWidth, canvasHeight),
      diffToApply,
      canvasWidth,
      canvasHeight
    );
  }
  return workingGrid && workingGrid.length ? workingGrid : null;
};

export const gridsEqual = (left?: string[][], right?: string[][]): boolean => {
  if (left === right) {
    return true;
  }
  if (!Array.isArray(left) || !Array.isArray(right)) {
    return !left?.length && !right?.length;
  }
  if (left.length !== right.length) {
    return false;
  }
  for (let x = 0; x < left.length; x += 1) {
    const columnA = left[x] || [];
    const columnB = right[x] || [];
    if (columnA.length !== columnB.length) {
      return false;
    }
    for (let y = 0; y < columnA.length; y += 1) {
      if (columnA[y] !== columnB[y]) {
        return false;
      }
    }
  }
  return true;
};

export const syncPreviewStateIfNeeded = (
  nextState: PreviewState,
  currentState: PreviewState,
  setState: (state: PreviewState) => void
) => {
  if (nextState !== currentState) {
    setState(nextState);
  }
};

export const buildReferenceOpacityMapForDesigner = (
  referenceParts: Record<string, string[][]> | null,
  bodyParts: BodyPartEntry[],
  getOpacity: (partId: string) => number
): Record<string, number> => {
  const map: Record<string, number> = {
    [GENERIC_PART_KEY]: getOpacity(GENERIC_PART_KEY),
  };
  if (referenceParts) {
    for (const partId of Object.keys(referenceParts)) {
      map[partId] = getOpacity(partId);
    }
    return map;
  }
  for (const part of bodyParts || []) {
    if (!part || !part.id) {
      continue;
    }
    map[part.id] = getOpacity(part.id);
  }
  return map;
};

export type OverlayLayerPartsOptions = {
  previewState: PreviewState;
  dirKey: number;
  activePartKey: string;
  fallbackLayerParts?: Record<string, string[][]> | null;
  draftDiffIndex?: Record<number, Record<string, DiffEntry[]>> | null;
  canvasWidth: number;
  canvasHeight: number;
};

type PreviewCustomPart = {
  grid?: string[][] | null;
};

export const buildOverlayLayerParts = (
  options: OverlayLayerPartsOptions
): Record<string, string[][]> | null => {
  const {
    previewState,
    dirKey,
    activePartKey,
    fallbackLayerParts,
    draftDiffIndex,
    canvasWidth,
    canvasHeight,
  } = options;
  if (!previewState || !dirKey || !activePartKey) {
    return fallbackLayerParts || null;
  }
  const dirState = previewState.dirs[dirKey];
  const overlayParts: Record<string, string[][]> = {};
  const dirDrafts = draftDiffIndex?.[dirKey] || null;
  if (fallbackLayerParts) {
    for (const key of Object.keys(fallbackLayerParts)) {
      if (key === activePartKey) {
        continue;
      }
      const grid = fallbackLayerParts[key];
      if (!Array.isArray(grid) || !grid.length) {
        continue;
      }
      overlayParts[key] = cloneGridData(grid);
    }
  }
  if (dirState?.customParts) {
    for (const [partId, partState] of Object.entries(dirState.customParts)) {
      if (!partId || partId === activePartKey || overlayParts[partId]) {
        continue;
      }
      const typedPart = partState as PreviewCustomPart | undefined;
      const sourceGrid = typedPart?.grid;
      let grid =
        Array.isArray(sourceGrid) && sourceGrid.length
          ? cloneGridData(sourceGrid)
          : null;
      const pendingDiff = dirDrafts?.[partId];
      if (pendingDiff?.length) {
        grid = applyDiffToGrid(
          grid || createBlankGrid(canvasWidth, canvasHeight),
          pendingDiff,
          canvasWidth,
          canvasHeight
        );
      }
      if (!grid || !grid.length) {
        continue;
      }
      overlayParts[partId] = grid;
    }
  }
  if (dirDrafts) {
    for (const [partId, diffs] of Object.entries(dirDrafts)) {
      if (
        !partId ||
        partId === activePartKey ||
        overlayParts[partId] ||
        !Array.isArray(diffs) ||
        !diffs.length
      ) {
        continue;
      }
      const grid = applyDiffToGrid(
        createBlankGrid(canvasWidth, canvasHeight),
        diffs,
        canvasWidth,
        canvasHeight
      );
      overlayParts[partId] = grid;
    }
  }
  return Object.keys(overlayParts).length ? overlayParts : null;
};

const mergeOverlayLayers = (layers: string[][][] | null): string[][] | null => {
  if (!layers || !layers.length) {
    return null;
  }
  let maxWidth = 0;
  let maxHeight = 0;
  for (const layer of layers) {
    if (!Array.isArray(layer) || !layer.length) {
      continue;
    }
    maxWidth = Math.max(maxWidth, layer.length);
    for (const column of layer) {
      if (Array.isArray(column)) {
        maxHeight = Math.max(maxHeight, column.length);
      }
    }
  }
  if (!maxWidth || !maxHeight) {
    return null;
  }
  const merged = createBlankGrid(maxWidth, maxHeight);
  for (const layer of layers) {
    if (!Array.isArray(layer)) {
      continue;
    }
    for (let x = 0; x < layer.length; x += 1) {
      const column = layer[x];
      if (!Array.isArray(column)) {
        continue;
      }
      for (let y = 0; y < column.length; y += 1) {
        const color = column[y];
        if (!pixelHasColor(color)) {
          continue;
        }
        merged[x][y] = color;
      }
    }
  }
  return merged;
};

const mergeOverlayLayersNormalized = (
  layers: string[][][] | null,
  targetWidth: number,
  targetHeight: number
): string[][] | null => {
  if (!layers || !layers.length) {
    return null;
  }
  const normalizedLayers: string[][][] = [];
  for (const layer of layers) {
    const normalized = normalizeOverlayGrid(layer, targetWidth, targetHeight);
    if (normalized && normalized.length) {
      normalizedLayers.push(normalized);
    }
  }
  return mergeOverlayLayers(normalizedLayers);
};

const pickOverlayLayers = (
  assets: (GearOverlayAsset | IconAssetPayload)[] | undefined,
  canvasWidth: number,
  canvasHeight: number,
  signalAssetUpdate: () => void,
  slotFilter?: OverlaySlotFilter
): string[][][] | null => {
  if (!Array.isArray(assets) || !assets.length) {
    return null;
  }
  const result: string[][][] = [];
  const updateSignal = signalAssetUpdate || (() => undefined);
  for (const entry of assets) {
    const payload =
      (entry as GearOverlayAsset)?.asset || (entry as IconAssetPayload);
    if (!payload || (!payload.width && !payload.height)) {
      continue;
    }
    const slot = (entry as GearOverlayAsset)?.slot || null;
    const isLarge =
      (payload.width || 0) > CANVAS_FIT_TARGET ||
      (payload.height || 0) > CANVAS_FIT_TARGET;
    if (slotFilter && !slotFilter({ slot, isLarge })) {
      continue;
    }
    const grid = getPreviewGridFromAsset(
      payload,
      canvasWidth,
      canvasHeight,
      updateSignal
    );
    if (!grid || !grid.length) {
      continue;
    }
    result.push(grid as string[][]);
  }
  return result.length ? result : null;
};

const normalizeOverlayGrid = (
  grid: string[][] | null,
  targetWidth: number,
  targetHeight: number
): string[][] | null => {
  if (!grid || !grid.length || targetWidth <= 0 || targetHeight <= 0) {
    return grid;
  }
  const sourceWidth = grid.length;
  const sourceHeight = grid[0]?.length || 0;
  if (!sourceWidth || !sourceHeight) {
    return grid;
  }
  if (sourceWidth === targetWidth && sourceHeight === targetHeight) {
    return grid;
  }
  const targetGrid = createBlankGrid(
    Math.max(1, targetWidth),
    Math.max(1, targetHeight)
  );
  const xOffset = Math.round((targetWidth - sourceWidth) / 2);
  const yOffset = targetHeight - sourceHeight;
  for (let x = 0; x < sourceWidth; x += 1) {
    const column = grid[x];
    if (!Array.isArray(column)) {
      continue;
    }
    for (let y = 0; y < column.length; y += 1) {
      const value = column[y];
      if (!value) {
        continue;
      }
      const tx = x + xOffset;
      const ty = y + yOffset;
      if (tx < 0 || tx >= targetWidth || ty < 0 || ty >= targetHeight) {
        continue;
      }
      targetGrid[tx][ty] = value;
    }
  }
  return targetGrid;
};

type OrderedOverlayEntry = {
  slot: string | null;
  grid: string[][];
  priority: number;
};

const orderOverlaySlotLayers = (
  slotMap?: Record<string, string[][]> | null
): OrderedOverlayEntry[] | null => {
  if (!slotMap || !Object.keys(slotMap).length) {
    return null;
  }
  const entries: OrderedOverlayEntry[] = Object.entries(slotMap)
    .filter(([, grid]) => Array.isArray(grid) && grid.length)
    .map(([slot, grid]) => ({
      slot: slot || null,
      grid,
      priority: OVERLAY_SLOT_PRIORITY_MAP[slot] ?? Number.MAX_SAFE_INTEGER,
    }));
  entries.sort((a, b) => {
    if (a.priority !== b.priority) {
      return a.priority - b.priority;
    }
    if (a.slot === b.slot) {
      return 0;
    }
    return (a.slot || '').localeCompare(b.slot || '');
  });
  return entries;
};

export const buildBodyPartLabelMap = (
  parts: BodyPartEntry[]
): Record<string, string> => {
  const map: Record<string, string> = {
    [GENERIC_PART_KEY]: 'Generic',
  };
  for (const part of parts || []) {
    if (!part) {
      continue;
    }
    map[part.id] = part.label;
  }
  return map;
};
