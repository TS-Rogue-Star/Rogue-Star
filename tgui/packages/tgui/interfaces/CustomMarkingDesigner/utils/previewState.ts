// //////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Preview state helpers for custom marking designer //
// //////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Updated to support 64x64 markings //////////////////
// //////////////////////////////////////////////////////////////////////////////////////////////////

import {
  GENERIC_PART_KEY,
  applyDiffToGrid,
  cloneGridData,
  createBlankGrid,
  getPreviewGridFromAsset,
  getPreviewPartMapFromAssets,
  getPreviewGridListFromAssets,
  IconAssetPayload,
} from '../../../utils/character-preview';
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
  } = options;
  const activeDirState = derivedPreviewState.dirs[currentDirectionKey];
  const overlayLayers =
    getPreviewGridListFromAssets(
      activeDirState?.overlayAssets,
      canvasWidth,
      canvasHeight,
      signalAssetUpdate
    ) || null;
  const largeOverlayLayers = pickLargeOverlayLayers(
    activeDirState?.overlayAssets,
    overlayLayers
  );
  const referenceParts: Record<string, string[][]> | null =
    getPreviewPartMapFromAssets(
      activeDirState?.referencePartAssets,
      canvasWidth,
      canvasHeight,
      signalAssetUpdate
    ) || null;
  const referenceGrid: string[][] | null =
    getPreviewGridFromAsset(
      activeDirState?.bodyAsset || activeDirState?.compositeAsset,
      canvasWidth,
      canvasHeight,
      signalAssetUpdate
    ) || null;
  const overlayGrid =
    canvasWidth > CANVAS_FIT_TARGET || canvasHeight > CANVAS_FIT_TARGET
      ? normalizeOverlayGrid(
          mergeOverlayLayers(largeOverlayLayers),
          canvasWidth,
          canvasHeight
        )
      : null;
  const referencePartsWithOverlays =
    overlayGrid && overlayGrid.length
      ? {
          ...(referenceParts || {}),
          overlay: overlayGrid,
        }
      : referenceParts;
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
    referenceParts: referencePartsWithOverlays,
    referenceGrid,
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
  next.overlayAssets = source.overlay_assets || existing?.overlayAssets;
  next.partOrder = source.part_order || existing?.partOrder;
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
        if (!color) {
          continue;
        }
        merged[x][y] = color;
      }
    }
  }
  return merged;
};

const pickLargeOverlayLayers = (
  assets: IconAssetPayload[] | undefined,
  layers: string[][][] | null
): string[][][] | null => {
  if (!Array.isArray(assets) || !assets.length || !Array.isArray(layers)) {
    return null;
  }
  const result: string[][][] = [];
  const count = Math.min(assets.length, layers.length);
  for (let i = 0; i < count; i += 1) {
    const asset = assets[i];
    const layer = layers[i];
    if (
      !asset ||
      !layer ||
      (!asset.width && !asset.height) ||
      !Array.isArray(layer) ||
      !layer.length
    ) {
      continue;
    }
    const isLarge =
      (asset.width || 0) > CANVAS_FIT_TARGET ||
      (asset.height || 0) > CANVAS_FIT_TARGET;
    if (isLarge) {
      result.push(layer);
    }
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
