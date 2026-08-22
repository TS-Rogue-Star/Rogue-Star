// //////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Character preview helpers for custom markings //
// //////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support loaout and job gear /////////
// //////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support new body marking selector ///
// //////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star August 2026: Character Designer - Species and Prosthetics /////
// //////////////////////////////////////////////////////////////////////////////////////////////

import { normalizeHex, TRANSPARENT_HEX } from '../color';
import type {
  GearOverlayAsset,
  GearOverlayAssetReference,
  IconAssetPayload,
  IconAssetReference,
} from './assets';
import {
  getPreviewGridFromAsset,
  getPreviewGridListFromAssets,
  getPreviewGridMapFromGearAssets,
  getPreviewPartMapFromAssets,
} from './assets';

export type {
  CharacterPreviewWorkHandle,
  CharacterPreviewWorkPriority,
  GearAppearanceAsset,
  GearAppearanceAssetReference,
  GearColorTransform,
  GearOverlayAssetReference,
  IconAssetReference,
  IconAssetRegistry,
  IconAssetRegistryAsset,
  IconAssetPayload,
  ProstheticCatalog,
  ProstheticCatalogModel,
  ProstheticCatalogState,
  GearOverlayAsset,
} from './assets';
export {
  areIconAssetsReady,
  composeGearPreviewGrid,
  getGearPreviewRasterIdentity,
  getIconAssetRasterIdentity,
  getIconAssetReadinessSignature,
  getPreviewGridFromAsset,
  getPreviewGridFromGearAsset,
  getPreviewGridListFromAssets,
  getPreviewPartMapFromAssets,
  getPreviewGridMapFromGearAssets,
  getReferenceGridFromAsset,
  getReferencePartMapFromAssets,
  getStaticProstheticCatalog,
  isStaticIconAssetRegistryLoaded,
  loadStaticIconAssetRegistry,
  registerIconAssetRegistry,
  registerStaticIconAssetRegistry,
  resolveGearOverlayAssetReferences,
  resolveIconAssetReference,
  resolveIconAssetReferenceMap,
  scheduleCharacterPreviewWork,
} from './assets';

export const GENERIC_PART_KEY = 'generic';

export type DiffEntry = {
  x: number;
  y: number;
  color: string;
};

export type PreviewLayerEntry = {
  type: string;
  key: string;
  label?: string;
  source?: string;
  grid?: string[][];
  opacity?: number;
  rasterIdentity?: string;
  rasterDependency?: PreviewLayerRasterDependency;
  rasterShareable?: boolean;
};

export type PreviewLayerRasterDependency =
  | 'stable'
  | 'body-relative'
  | 'body-direct'
  | 'body-eye-fallback'
  | 'eye-direct'
  | 'synth-direct';

export type PreviewLayerColorTransform = {
  color: string;
  multiply: boolean;
  passes: number;
};

const parsePreviewTransformColor = (
  color: string
): [number, number, number, number] | null => {
  const normalized = normalizeHex(color, {
    preserveAlpha: true,
    preserveTransparent: true,
  });
  if (!normalized) {
    return null;
  }
  return [
    parseInt(normalized.slice(1, 3), 16),
    parseInt(normalized.slice(3, 5), 16),
    parseInt(normalized.slice(5, 7), 16),
    normalized.length === 9 ? parseInt(normalized.slice(7, 9), 16) : 255,
  ];
};

export const applyPreviewLayerColorTransformToRgba = (
  source: Uint8ClampedArray,
  target: Uint8ClampedArray,
  activeOffsets: readonly number[],
  transform: PreviewLayerColorTransform
) => {
  const tint = parsePreviewTransformColor(transform.color);
  const passes = Math.max(0, Math.floor(transform.passes));
  for (let index = 0; index < activeOffsets.length; index++) {
    const offset = activeOffsets[index];
    let red = source[offset];
    let green = source[offset + 1];
    let blue = source[offset + 2];
    let alpha = source[offset + 3];
    if (tint) {
      for (let pass = 0; pass < passes; pass++) {
        if (transform.multiply) {
          red = Math.round((red * tint[0]) / 255);
          green = Math.round((green * tint[1]) / 255);
          blue = Math.round((blue * tint[2]) / 255);
          alpha = Math.round((alpha * tint[3]) / 255);
        } else {
          red = Math.min(255, red + tint[0]);
          green = Math.min(255, green + tint[1]);
          blue = Math.min(255, blue + tint[2]);
        }
      }
    }
    target[offset] = red;
    target[offset + 1] = green;
    target[offset + 2] = blue;
    target[offset + 3] = alpha;
  }
};

export type PreviewLayerGroup = {
  key: string;
  layers: PreviewLayerEntry[];
  cacheSignature?: string;
  sharedRasterSignature?: string;
  colorTransform?: PreviewLayerColorTransform;
};

export type PreviewEyeColorMode = 'baked' | 'separate' | 'native' | 'none';

export type PreviewDirectionEntry = {
  dir: number;
  label: string;
  layers: PreviewLayerEntry[];
  bodyAlpha?: number | null;
  eyeColorMode?: PreviewEyeColorMode;
};

export type PreviewDirectionSource = {
  dir: number;
  label: string;
  body_asset?: IconAssetReference;
  reference_part_assets?: Record<string, IconAssetReference>;
  reference_part_hair_assets?: Record<string, IconAssetReference>;
  reference_part_marking_assets?: Record<string, IconAssetReference>;
  overlay_assets?: Array<GearOverlayAssetReference | IconAssetReference>;
  equipment_overlay_assets?: Array<
    GearOverlayAssetReference | IconAssetReference
  >;
  job_overlay_assets?: Array<GearOverlayAssetReference | IconAssetReference>;
  loadout_overlay_assets?: Array<
    GearOverlayAssetReference | IconAssetReference
  >;
  body_color_excluded_parts?: string[];
  body_color_blend_mode?: number | null;
  body_alpha?: number | null;
  eye_color_mode?: PreviewEyeColorMode;
  custom_parts?: Record<string, string[][] | null>;
  part_order?: string[];
  hidden_body_parts?: string[];
  marking_excluded_parts?: string[];
};

export type PreviewCustomPartState = {
  grid: string[][];
  lastSyncKey?: string | null;
};

export type PreviewDirState = {
  dir: number;
  label: string;
  bodyAsset?: IconAssetPayload;
  referencePartAssets?: Record<string, IconAssetPayload>;
  referencePartHairAssets?: Record<string, IconAssetPayload>;
  referencePartMarkingAssets?: Record<string, IconAssetPayload>;
  overlayAssets?: Array<GearOverlayAsset | IconAssetPayload>;
  gearEquipmentOverlayAssets?: Array<GearOverlayAsset | IconAssetPayload>;
  gearJobOverlayAssets?: Array<GearOverlayAsset | IconAssetPayload>;
  gearLoadoutOverlayAssets?: Array<GearOverlayAsset | IconAssetPayload>;
  bodyColorExcludedParts?: string[];
  bodyColorBlendMode?: number | null;
  bodyAlpha?: number | null;
  eyeColorMode?: PreviewEyeColorMode;
  partOrder?: string[];
  hiddenBodyParts?: string[];
  markingExcludedParts?: string[];
  customParts: Record<string, PreviewCustomPartState>;
};

export type PreviewState = {
  revision: number;
  lastDiffSeq: number;
  dirs: Record<number, PreviewDirState>;
};

export const createBlankGrid = (width: number, height: number): string[][] => {
  const clampedWidth = Math.max(1, width);
  const clampedHeight = Math.max(1, height);
  const grid: string[][] = new Array(clampedWidth);
  for (let x = 0; x < clampedWidth; x += 1) {
    grid[x] = new Array(clampedHeight);
  }
  return grid;
};

export const cloneGridData = (grid?: string[][]): string[][] => {
  if (!Array.isArray(grid)) {
    return [];
  }
  return grid.map((column) => (Array.isArray(column) ? [...column] : []));
};

export const applyDiffToGrid = (
  grid: string[][],
  diff: DiffEntry[],
  width: number,
  height: number
): string[][] => {
  const next = grid.length
    ? grid.map((column) => [...column])
    : createBlankGrid(width, height);
  for (const change of diff) {
    if (!change) {
      continue;
    }
    const px = Math.min(width, Math.max(1, Math.floor(change.x)));
    const py = Math.min(height, Math.max(1, Math.floor(change.y)));
    const columnIndex = px - 1;
    const rowIndex = py - 1;
    if (!Array.isArray(next[columnIndex])) {
      next[columnIndex] = [];
    }
    const column = next[columnIndex];
    if (rowIndex >= column.length) {
      column.length = rowIndex + 1;
    }
    column[rowIndex] = change.color || TRANSPARENT_HEX;
  }
  return next;
};

type PartPaintPresenceOptions = {
  dirStates: Record<number, PreviewDirState>;
};

export const buildPartPaintPresenceMap = (
  options: PartPaintPresenceOptions
): Record<string, boolean> => {
  const { dirStates } = options;
  const presence: Record<string, boolean> = {};
  Object.values(dirStates || {}).forEach((dirState) => {
    if (!dirState || !dirState.customParts) {
      return;
    }
    const markingExcludedParts = new Set(dirState.markingExcludedParts || []);
    Object.entries(dirState.customParts).forEach(([partId, partState]) => {
      if (
        !partId ||
        partId === GENERIC_PART_KEY ||
        presence[partId] ||
        markingExcludedParts.has(partId)
      ) {
        return;
      }
      if (gridHasPixels(partState?.grid)) {
        presence[partId] = true;
      }
    });
  });
  return presence;
};

export const buildRenderedPreviewDirs = (
  dirStates: Record<number, PreviewDirState>,
  directions: { dir: number; label: string }[],
  labelMap: Record<string, string>,
  canvasWidth: number,
  canvasHeight: number,
  signalAssetUpdate?: () => void,
  stripReferenceMarkings?: boolean
): PreviewDirectionEntry[] => {
  const orderedDirs =
    directions && directions.length
      ? directions
      : Object.values(dirStates).map((entry) => ({
          dir: entry.dir,
          label: entry.label,
        }));
  const result: PreviewDirectionEntry[] = [];
  for (const entry of orderedDirs) {
    const dirState = dirStates[entry.dir];
    if (!dirState) {
      continue;
    }
    let previewReferenceParts = getPreviewPartMapFromAssets(
      dirState.referencePartAssets,
      canvasWidth,
      canvasHeight,
      signalAssetUpdate || (() => undefined)
    );
    const previewReferencePartHair = getPreviewPartMapFromAssets(
      dirState.referencePartHairAssets,
      canvasWidth,
      canvasHeight,
      signalAssetUpdate || (() => undefined)
    );
    let previewReferencePartMarkings = getPreviewPartMapFromAssets(
      dirState.referencePartMarkingAssets,
      canvasWidth,
      canvasHeight,
      signalAssetUpdate || (() => undefined)
    );
    if (
      previewReferencePartMarkings &&
      Array.isArray(dirState.markingExcludedParts)
    ) {
      previewReferencePartMarkings = {
        ...previewReferencePartMarkings,
      };
      for (const partId of dirState.markingExcludedParts) {
        delete previewReferencePartMarkings[partId];
      }
    }
    let previewBodyGrid = getPreviewGridFromAsset(
      dirState.bodyAsset,
      canvasWidth,
      canvasHeight,
      signalAssetUpdate || (() => undefined)
    );
    if (stripReferenceMarkings) {
      const stripped = stripReferenceMarkingsFromSources({
        referenceParts: previewReferenceParts,
        referencePartMarkings: previewReferencePartMarkings,
        bodyGrid: previewBodyGrid,
      });
      previewReferenceParts = stripped.referenceParts ?? null;
      previewBodyGrid = stripped.bodyGrid ?? null;
      previewReferencePartMarkings = null;
    }
    const overlayAssetsRaw = (dirState.overlayAssets || []) as Array<
      GearOverlayAsset | IconAssetPayload
    >;
    const overlayAssets = stripReferenceMarkings
      ? overlayAssetsRaw.filter(
          (entry) => (entry as GearOverlayAsset)?.slot !== 'custom_marking'
        )
      : overlayAssetsRaw;
    const overlayLayersMap = getPreviewGridMapFromGearAssets(
      overlayAssets as GearOverlayAsset[] | IconAssetPayload[],
      canvasWidth,
      canvasHeight,
      signalAssetUpdate || (() => undefined)
    );
    const previewOverlayLayers = overlayLayersMap
      ? (Object.values(overlayLayersMap) as string[][][])
      : getPreviewGridListFromAssets(
          overlayAssets as IconAssetPayload[],
          canvasWidth,
          canvasHeight,
          signalAssetUpdate || (() => undefined)
        );
    const layers = composePreviewLayers(
      dirState,
      labelMap,
      canvasWidth,
      canvasHeight,
      previewReferenceParts,
      previewReferencePartHair,
      previewReferencePartMarkings,
      previewBodyGrid,
      previewOverlayLayers
    );
    if (!layers.length) {
      continue;
    }
    result.push({
      dir: entry.dir,
      label: dirState.label || entry.label,
      layers,
      bodyAlpha: dirState.bodyAlpha,
      eyeColorMode: dirState.eyeColorMode,
    });
  }
  return result;
};

export const collectPreviewColorCounts = (
  dirs: PreviewDirectionEntry[]
): Map<string, number> => {
  const counts = new Map<string, number>();
  if (!Array.isArray(dirs)) {
    return counts;
  }
  for (const dir of dirs) {
    const layers = dir?.layers || [];
    for (const layer of layers) {
      const grid = layer?.grid;
      if (!Array.isArray(grid)) {
        continue;
      }
      for (const column of grid) {
        if (!Array.isArray(column)) {
          continue;
        }
        for (const rawColor of column) {
          const normalized = normalizeHex(rawColor);
          if (!normalized || normalized === TRANSPARENT_HEX) {
            continue;
          }
          counts.set(normalized, (counts.get(normalized) || 0) + 1);
        }
      }
    }
  }
  return counts;
};

export const buildSuggestedColorsFromCounts = (
  counts: Map<string, number>,
  maxColors: number
): string[] =>
  Array.from(counts.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, maxColors)
    .map(([hex]) => hex);

export const buildColorSignatureFromCounts = (
  counts: Map<string, number>
): string | null => {
  if (!counts.size) {
    return null;
  }
  return Array.from(counts.entries())
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([hex, count]) => `${hex}:${count}`)
    .join('|');
};

export const hasPreviewLayerContent = (
  dirs: PreviewDirectionEntry[]
): boolean => {
  if (!Array.isArray(dirs)) {
    return false;
  }
  return dirs.some((dir) => {
    const layers = dir?.layers;
    if (!Array.isArray(layers)) {
      return false;
    }
    return layers.some((layer) => Array.isArray(layer?.grid));
  });
};

export const resolveBodyPartLabel = (
  partId: string | null,
  labelMap: Record<string, string>
): string => {
  if (!partId) {
    return labelMap[GENERIC_PART_KEY] || 'Generic';
  }
  if (labelMap[partId]) {
    return labelMap[partId];
  }
  return partId
    .split('_')
    .map(
      (chunk) => chunk.charAt(0).toUpperCase() + chunk.slice(1).toLowerCase()
    )
    .join(' ');
};

export const gridHasPixels = (grid?: string[][]): boolean => {
  if (!Array.isArray(grid)) {
    return false;
  }
  for (const column of grid) {
    if (!Array.isArray(column)) {
      continue;
    }
    for (const pixel of column) {
      if (pixel && pixel !== TRANSPARENT_HEX) {
        return true;
      }
    }
  }
  return false;
};

const pixelHasColor = (value?: string): boolean =>
  typeof value === 'string' && value.length > 0 && value !== TRANSPARENT_HEX;

const applyMarkingMaskToGrid = (
  target: string[][],
  mask: string[][]
): boolean => {
  let changed = false;
  const width = Math.min(target.length, mask.length);
  for (let x = 0; x < width; x += 1) {
    const targetColumn = target[x];
    const maskColumn = mask[x];
    if (!Array.isArray(targetColumn) || !Array.isArray(maskColumn)) {
      continue;
    }
    const height = Math.min(targetColumn.length, maskColumn.length);
    for (let y = 0; y < height; y += 1) {
      if (!pixelHasColor(maskColumn[y]) || !pixelHasColor(targetColumn[y])) {
        continue;
      }
      targetColumn[y] = TRANSPARENT_HEX;
      changed = true;
    }
  }
  return changed;
};

const stripReferenceMarkingsFromSources = (options: {
  referenceParts?: Record<string, string[][]> | null;
  referencePartMarkings?: Record<string, string[][]> | null;
  bodyGrid?: string[][] | null;
}): {
  referenceParts: Record<string, string[][]> | null;
  bodyGrid: string[][] | null;
} => {
  const { referenceParts, referencePartMarkings, bodyGrid } = options;
  if (!referencePartMarkings || !Object.keys(referencePartMarkings).length) {
    return {
      referenceParts: referenceParts ?? null,
      bodyGrid: bodyGrid ?? null,
    };
  }
  let nextReferenceParts = referenceParts;
  let nextBodyGrid = bodyGrid;
  let partsCloned = false;
  let bodyCloned = false;
  const ensureParts = () => {
    if (partsCloned) {
      return;
    }
    nextReferenceParts = { ...(referenceParts || {}) };
    partsCloned = true;
  };
  const ensureBody = () => {
    if (bodyCloned || !bodyGrid) {
      return;
    }
    nextBodyGrid = cloneGridData(bodyGrid);
    bodyCloned = true;
  };
  for (const [partId, markingGrid] of Object.entries(referencePartMarkings)) {
    if (!partId || !gridHasPixels(markingGrid)) {
      continue;
    }
    if (nextBodyGrid) {
      ensureBody();
      applyMarkingMaskToGrid(nextBodyGrid, markingGrid);
    }
    const basePartGrid = (nextReferenceParts ||
      referenceParts ||
      ({} as Record<string, string[][]>))[partId];
    if (!basePartGrid) {
      continue;
    }
    ensureParts();
    const strippedPart = cloneGridData(basePartGrid);
    applyMarkingMaskToGrid(strippedPart, markingGrid);
    if (nextReferenceParts) {
      nextReferenceParts[partId] = strippedPart;
    }
  }
  return {
    referenceParts: nextReferenceParts ?? null,
    bodyGrid: nextBodyGrid ?? null,
  };
};

const composePreviewLayers = (
  dirState: PreviewDirState,
  labelMap: Record<string, string>,
  canvasWidth: number,
  canvasHeight: number,
  resolvedReferenceParts?: Record<string, string[][]> | null,
  resolvedReferencePartHair?: Record<string, string[][]> | null,
  resolvedReferencePartMarkings?: Record<string, string[][]> | null,
  resolvedBodyGrid?: string[][] | null,
  resolvedOverlayLayers?: string[][][] | null
): PreviewLayerEntry[] => {
  const hiddenPartsMap: Record<string, boolean> = {};
  if (Array.isArray(dirState.hiddenBodyParts)) {
    for (const partId of dirState.hiddenBodyParts) {
      if (
        typeof partId !== 'string' ||
        !partId.length ||
        partId === GENERIC_PART_KEY
      ) {
        continue;
      }
      hiddenPartsMap[partId] = true;
    }
  }
  const orderedPartLayers: PreviewLayerEntry[] = [];
  const floatingCustomLayers: PreviewLayerEntry[] = [];
  const overlayEntries: PreviewLayerEntry[] = [];
  const referenceParts: Record<string, string[][]> =
    resolvedReferenceParts || ({} as Record<string, string[][]>);
  const referencePartHair: Record<string, string[][]> =
    resolvedReferencePartHair || ({} as Record<string, string[][]>);
  const referencePartMarkings: Record<string, string[][]> =
    resolvedReferencePartMarkings || ({} as Record<string, string[][]>);
  const referencePartAssets = dirState.referencePartAssets || {};
  const referencePartHairAssets = dirState.referencePartHairAssets || {};
  const referencePartMarkingAssets = dirState.referencePartMarkingAssets || {};
  const customParts = dirState.customParts || {};
  const markingExcludedParts = new Set(dirState.markingExcludedParts || []);
  const hasReferenceParts = Object.keys(referenceParts).length > 0;
  const hasReferenceForPart = (partId: string) =>
    partId === GENERIC_PART_KEY ||
    Object.prototype.hasOwnProperty.call(referenceParts, partId) ||
    Object.prototype.hasOwnProperty.call(referencePartHair, partId) ||
    Object.prototype.hasOwnProperty.call(referencePartMarkings, partId) ||
    Object.prototype.hasOwnProperty.call(referencePartAssets, partId) ||
    Object.prototype.hasOwnProperty.call(referencePartHairAssets, partId) ||
    Object.prototype.hasOwnProperty.call(referencePartMarkingAssets, partId);
  const bodyGrid = resolvedBodyGrid
    ? cloneGridData(resolvedBodyGrid)
    : undefined;
  if (bodyGrid && Object.keys(hiddenPartsMap).length) {
    const applyMaskToGrid = (target: string[][], mask: string[][]) => {
      const width = Math.min(target.length, mask.length);
      for (let x = 0; x < width; x += 1) {
        const targetColumn = target[x];
        const maskColumn = mask[x];
        if (!Array.isArray(targetColumn) || !Array.isArray(maskColumn)) {
          continue;
        }
        const height = Math.min(targetColumn.length, maskColumn.length);
        for (let y = 0; y < height; y += 1) {
          if (
            typeof maskColumn[y] !== 'string' ||
            maskColumn[y].length === 0 ||
            maskColumn[y] === TRANSPARENT_HEX
          ) {
            continue;
          }
          if (
            typeof targetColumn[y] !== 'string' ||
            targetColumn[y].length === 0 ||
            targetColumn[y] === TRANSPARENT_HEX
          ) {
            continue;
          }
          targetColumn[y] = TRANSPARENT_HEX;
        }
      }
    };
    Object.keys(hiddenPartsMap).forEach((partId) => {
      if (!hiddenPartsMap[partId]) {
        return;
      }
      const maskGrid = referenceParts[partId];
      if (!maskGrid) {
        return;
      }
      applyMaskToGrid(bodyGrid, maskGrid);
    });
  }
  if (!hasReferenceParts && bodyGrid) {
    orderedPartLayers.push({
      type: 'body',
      key: 'body',
      label: 'Body',
      grid: bodyGrid,
    });
  }
  const partOrder = buildPreviewPartOrderForState(
    dirState.partOrder,
    referenceParts,
    customParts
  );
  for (const partId of partOrder) {
    if (!hasReferenceForPart(partId)) {
      continue;
    }
    const isHiddenPart = !!hiddenPartsMap[partId];
    const isMarkingExcludedPart = markingExcludedParts.has(partId);
    const normalizedPart = partId === GENERIC_PART_KEY ? null : partId;
    const baseReferenceGrid = referenceParts[partId];
    let referenceGrid = baseReferenceGrid && cloneGridData(baseReferenceGrid);
    if (partId === GENERIC_PART_KEY && bodyGrid) {
      referenceGrid = cloneGridData(bodyGrid);
    }
    const markingReferenceGrid =
      !isMarkingExcludedPart &&
      referencePartMarkings &&
      referencePartMarkings[partId]
        ? cloneGridData(referencePartMarkings[partId])
        : null;
    const hairReferenceGrid = referencePartHair[partId]
      ? cloneGridData(referencePartHair[partId])
      : null;
    if (isHiddenPart) {
      if (markingReferenceGrid && gridHasPixels(markingReferenceGrid)) {
        orderedPartLayers.push({
          type: 'reference_part',
          key: `ref_${partId}_markings`,
          label: `${resolveBodyPartLabel(normalizedPart, labelMap)} Markings`,
          grid: markingReferenceGrid,
        });
      }
    } else if (referenceGrid && gridHasPixels(referenceGrid)) {
      orderedPartLayers.push({
        type: 'reference_part',
        key: `ref_${partId}`,
        label: `${resolveBodyPartLabel(normalizedPart, labelMap)} Base`,
        grid: referenceGrid,
      });
    }
    if (
      !isHiddenPart &&
      hairReferenceGrid &&
      gridHasPixels(hairReferenceGrid)
    ) {
      orderedPartLayers.push({
        type: 'limb_hair',
        key: `ref_${partId}_hair`,
        label: `${resolveBodyPartLabel(normalizedPart, labelMap)} Hair`,
        grid: hairReferenceGrid,
      });
    }
    if (
      !isHiddenPart &&
      !referenceGrid &&
      markingReferenceGrid &&
      gridHasPixels(markingReferenceGrid)
    ) {
      orderedPartLayers.push({
        type: 'reference_part',
        key: `ref_${partId}_markings`,
        label: `${resolveBodyPartLabel(normalizedPart, labelMap)} Markings`,
        grid: markingReferenceGrid,
      });
    }
    const customGrid =
      !isMarkingExcludedPart && customParts[partId]?.grid
        ? cloneGridData(customParts[partId].grid)
        : undefined;
    if (customGrid && gridHasPixels(customGrid)) {
      const customLayer: PreviewLayerEntry = {
        type: 'custom',
        key: `custom_${partId}`,
        label: `${resolveBodyPartLabel(normalizedPart, labelMap)} Custom`,
        grid: customGrid,
      };
      orderedPartLayers.push(customLayer);
    }
  }
  const overlayLayers = resolvedOverlayLayers || [];
  overlayLayers.forEach((grid, index) => {
    const cloned = cloneGridData(grid);
    if (!gridHasPixels(cloned)) {
      return;
    }
    overlayEntries.push({
      type: 'overlay',
      key: `overlay_${index}`,
      label: 'Overlay',
      grid: cloned,
    });
  });
  const mergedLayers = [
    ...orderedPartLayers,
    ...overlayEntries,
    ...floatingCustomLayers,
  ];
  return normalizeLayerDimensions(mergedLayers, canvasWidth, canvasHeight);
};

const buildPreviewPartOrderForState = (
  preferredOrder: string[] | undefined,
  referenceParts: Record<string, string[][]>,
  customParts: Record<string, PreviewCustomPartState>
): string[] => {
  const order: string[] = [];
  if (preferredOrder && preferredOrder.length) {
    order.push(...preferredOrder);
  }
  const ensurePart = (part: string) => {
    if (!part) {
      return;
    }
    if (!order.includes(part)) {
      order.push(part);
    }
  };
  ensurePart(GENERIC_PART_KEY);
  Object.keys(referenceParts || {}).forEach(ensurePart);
  Object.keys(customParts || {}).forEach(ensurePart);
  return order;
};

const getGridDimensions = (
  grid?: string[][]
): { width: number; height: number } | null => {
  if (!Array.isArray(grid) || !grid.length) {
    return null;
  }
  let height = 0;
  for (const column of grid) {
    if (Array.isArray(column) && column.length > height) {
      height = column.length;
    }
  }
  return {
    width: grid.length,
    height,
  };
};

const normalizeLayerDimensions = (
  layers: PreviewLayerEntry[],
  canvasWidth: number,
  canvasHeight: number
): PreviewLayerEntry[] => {
  let maxWidth = canvasWidth;
  let maxHeight = canvasHeight;
  for (const layer of layers) {
    const dims = getGridDimensions(layer.grid);
    if (!dims) {
      continue;
    }
    maxWidth = Math.max(maxWidth, dims.width);
    maxHeight = Math.max(maxHeight, dims.height);
  }
  if (maxWidth <= 0 || maxHeight <= 0) {
    return layers;
  }
  return layers.map((layer) => {
    if (!layer.grid) {
      return layer;
    }
    return {
      ...layer,
      grid: padGrid(layer.grid, maxWidth, maxHeight),
    };
  });
};

const padGrid = (
  grid: string[][],
  targetWidth: number,
  targetHeight: number
): string[][] => {
  const dims = getGridDimensions(grid);
  if (!dims || dims.width <= 0 || dims.height <= 0) {
    return createBlankGrid(targetWidth, targetHeight);
  }
  const result = createBlankGrid(targetWidth, targetHeight);
  const leftPad = Math.max(0, Math.round((targetWidth - dims.width) / 2));
  const topPad = Math.max(0, targetHeight - dims.height);
  for (let x = 0; x < dims.width; x += 1) {
    const column = grid[x];
    if (!Array.isArray(column)) {
      continue;
    }
    const targetX = x + leftPad;
    if (targetX < 0 || targetX >= targetWidth) {
      continue;
    }
    const targetColumn = result[targetX];
    for (let y = 0; y < dims.height; y += 1) {
      const value = column[y];
      if (!value) {
        continue;
      }
      const targetY = y + topPad;
      if (targetY < 0 || targetY >= targetHeight) {
        continue;
      }
      targetColumn[targetY] = value;
    }
  }
  return result;
};
