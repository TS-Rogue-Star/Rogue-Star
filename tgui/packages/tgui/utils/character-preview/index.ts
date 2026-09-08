// //////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Character preview helpers for custom markings //
// //////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support loaout and job gear /////////
// //////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support new body marking selector ///
// //////////////////////////////////////////////////////////////////////////////////////////////

import { normalizeHex, TRANSPARENT_HEX } from '../color';
import type { GearOverlayAsset, IconAssetPayload } from './assets';
import {
  getPreviewGridFromAsset,
  getPreviewGridListFromAssets,
  getPreviewGridMapFromGearAssets,
  getPreviewPartMapFromAssets,
} from './assets';

export type { IconAssetPayload, GearOverlayAsset } from './assets';
export {
  getPreviewGridFromAsset,
  getPreviewGridListFromAssets,
  getPreviewPartMapFromAssets,
  getPreviewGridMapFromGearAssets,
  getReferenceGridFromAsset,
  getReferencePartMapFromAssets,
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
};

export type PreviewDirectionEntry = {
  dir: number;
  label: string;
  layers: PreviewLayerEntry[];
};

export type PreviewDirectionSource = {
  dir: number;
  label: string;
  body_asset?: IconAssetPayload;
  composite_asset?: IconAssetPayload;
  reference_part_assets?: Record<string, IconAssetPayload>;
  reference_part_marking_assets?: Record<string, IconAssetPayload>;
  overlay_assets?: GearOverlayAsset[] | IconAssetPayload[];
  job_overlay_assets?: GearOverlayAsset[] | IconAssetPayload[];
  loadout_overlay_assets?: GearOverlayAsset[] | IconAssetPayload[];
  body_color_excluded_parts?: string[];
  custom_parts?: Record<string, string[][]>;
  part_order?: string[];
  hidden_body_parts?: string[];
};

export type PreviewCustomPartState = {
  grid: string[][];
  lastSyncKey?: string | null;
};

export type PreviewDirState = {
  dir: number;
  label: string;
  bodyAsset?: IconAssetPayload;
  compositeAsset?: IconAssetPayload;
  referencePartAssets?: Record<string, IconAssetPayload>;
  referencePartMarkingAssets?: Record<string, IconAssetPayload>;
  overlayAssets?: GearOverlayAsset[] | IconAssetPayload[];
  gearJobOverlayAssets?: GearOverlayAsset[];
  gearLoadoutOverlayAssets?: GearOverlayAsset[];
  bodyColorExcludedParts?: string[];
  partOrder?: string[];
  hiddenBodyParts?: string[];
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
    Object.entries(dirState.customParts).forEach(([partId, partState]) => {
      if (!partId || partId === GENERIC_PART_KEY || presence[partId]) {
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
    let previewReferencePartMarkings = getPreviewPartMapFromAssets(
      dirState.referencePartMarkingAssets,
      canvasWidth,
      canvasHeight,
      signalAssetUpdate || (() => undefined)
    );
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
  const referencePartMarkings: Record<string, string[][]> =
    resolvedReferencePartMarkings || ({} as Record<string, string[][]>);
  const referencePartAssets = dirState.referencePartAssets || {};
  const referencePartMarkingAssets = dirState.referencePartMarkingAssets || {};
  const customParts = dirState.customParts || {};
  const hasReferenceParts = Object.keys(referenceParts).length > 0;
  const hasReferenceForPart = (partId: string) =>
    partId === GENERIC_PART_KEY ||
    Object.prototype.hasOwnProperty.call(referenceParts, partId) ||
    Object.prototype.hasOwnProperty.call(referencePartMarkings, partId) ||
    Object.prototype.hasOwnProperty.call(referencePartAssets, partId) ||
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
    const normalizedPart = partId === GENERIC_PART_KEY ? null : partId;
    const baseReferenceGrid = referenceParts[partId];
    let referenceGrid = baseReferenceGrid && cloneGridData(baseReferenceGrid);
    if (partId === GENERIC_PART_KEY && bodyGrid) {
      referenceGrid = cloneGridData(bodyGrid);
    }
    const markingReferenceGrid =
      referencePartMarkings && referencePartMarkings[partId]
        ? cloneGridData(referencePartMarkings[partId])
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
    } else if (markingReferenceGrid && gridHasPixels(markingReferenceGrid)) {
      orderedPartLayers.push({
        type: 'reference_part',
        key: `ref_${partId}_markings`,
        label: `${resolveBodyPartLabel(normalizedPart, labelMap)} Markings`,
        grid: markingReferenceGrid,
      });
    }
    let customGrid = customParts[partId]?.grid
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
