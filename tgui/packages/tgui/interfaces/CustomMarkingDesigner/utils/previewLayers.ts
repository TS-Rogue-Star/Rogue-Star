// //////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Preview layer helpers for custom marking designer //
// //////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support loaout and job gear /////////////
// //////////////////////////////////////////////////////////////////////////////////////////////////

import {
  GENERIC_PART_KEY,
  applyDiffToGrid,
  cloneGridData,
  createBlankGrid,
  getPreviewGridFromAsset,
  getPreviewPartMapFromAssets,
  gridHasPixels,
  resolveBodyPartLabel,
} from '../../../utils/character-preview';
import type {
  GearOverlayAsset,
  IconAssetPayload,
} from '../../../utils/character-preview';
import { collectReplacementCascadeTargets } from './flags';
import type {
  DiffEntry,
  PreviewDirectionEntry,
  PreviewDirState,
  PreviewLayerEntry,
} from '../../../utils/character-preview';
import { TRANSPARENT_HEX } from '../../../utils/color';

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

type PartPaintPresenceOptions = {
  dirStates: Record<number, PreviewDirState>;
  draftDiffIndex?: Record<number, Record<string, DiffEntry[]>> | null;
  activeDirKey: number;
  activePartKey: string;
  activeDraftDiff?: DiffEntry[] | null;
  canvasWidth: number;
  canvasHeight: number;
  replacementDependents?: Record<string, string[]>;
};

type OrderedOverlayLayer = {
  grid: string[][];
  layer: number | null;
  slot?: string | null;
  source: 'base' | 'job' | 'loadout';
  order: number;
};

export const buildPartPaintPresenceMap = (
  options: PartPaintPresenceOptions
): Record<string, boolean> => {
  const {
    dirStates,
    draftDiffIndex,
    activeDirKey,
    activePartKey,
    activeDraftDiff,
    canvasWidth,
    canvasHeight,
    replacementDependents,
  } = options;
  const presence: Record<string, boolean> = {};
  const processedDirs = new Set<number>();
  const applyDiffWithFallback = (
    grid: string[][] | undefined,
    diff: DiffEntry[] | null | undefined
  ): string[][] | undefined => {
    if (!diff || !diff.length) {
      return grid;
    }
    const baseGrid =
      grid && grid.length ? grid : createBlankGrid(canvasWidth, canvasHeight);
    return applyDiffToGrid(baseGrid, diff, canvasWidth, canvasHeight);
  };
  const processDir = (dirKey: number, dirState?: PreviewDirState) => {
    if (!Number.isFinite(dirKey) || processedDirs.has(dirKey)) {
      return;
    }
    processedDirs.add(dirKey);
    const dirDrafts = draftDiffIndex?.[dirKey] || null;
    const partIds = new Set<string>();
    if (dirState?.customParts) {
      Object.keys(dirState.customParts).forEach((partId) =>
        partIds.add(partId)
      );
    }
    if (dirDrafts) {
      Object.keys(dirDrafts).forEach((partId) => partIds.add(partId));
    }
    if (dirKey === activeDirKey && activePartKey) {
      partIds.add(activePartKey);
    }
    partIds.forEach((partId) => {
      if (!partId || partId === GENERIC_PART_KEY || presence[partId]) {
        return;
      }
      let workingGrid = dirState?.customParts?.[partId]?.grid;
      const pendingDraftDiff = dirDrafts?.[partId] || null;
      const useActiveDraft =
        dirKey === activeDirKey &&
        partId === activePartKey &&
        Array.isArray(activeDraftDiff) &&
        activeDraftDiff.length > 0;
      const diffToApply =
        pendingDraftDiff && pendingDraftDiff.length
          ? pendingDraftDiff
          : useActiveDraft
            ? activeDraftDiff
            : null;
      if (diffToApply && diffToApply.length) {
        workingGrid = applyDiffWithFallback(workingGrid, diffToApply);
      }
      if (gridHasPixels(workingGrid)) {
        presence[partId] = true;
      }
    });
  };
  Object.values(dirStates || {}).forEach((dirState) => {
    if (!dirState || !Number.isFinite(dirState.dir)) {
      return;
    }
    processDir(dirState.dir, dirState);
  });
  if (draftDiffIndex) {
    Object.keys(draftDiffIndex).forEach((rawKey) => {
      const dirKey = Number(rawKey);
      processDir(dirKey);
    });
  }
  if (replacementDependents && Object.keys(replacementDependents).length) {
    Object.keys(presence).forEach((partId) => {
      if (!presence[partId]) {
        return;
      }
      const cascadeTargets = collectReplacementCascadeTargets(
        partId,
        replacementDependents
      );
      cascadeTargets.forEach((target) => {
        if (!target || target === GENERIC_PART_KEY) {
          return;
        }
        presence[target] = true;
      });
    });
  }
  return presence;
};

export const buildRenderedPreviewDirs = (
  dirStates: Record<number, PreviewDirState>,
  directions: { dir: number; label: string }[],
  labelMap: Record<string, string>,
  canvasWidth: number,
  canvasHeight: number,
  activeDirKey: number,
  activePartKey: string,
  draftDiffIndex?: Record<number, Record<string, DiffEntry[]>> | null,
  activeDraftDiff?: DiffEntry[] | null,
  partRenderPriorityMap?: Record<string, boolean>,
  partReplacementMap?: Record<string, boolean>,
  partPaintPresenceMap?: Record<string, boolean>,
  showJobGear?: boolean,
  showLoadoutGear?: boolean,
  signalAssetUpdate?: () => void
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
    const previewReferenceParts = getPreviewPartMapFromAssets(
      dirState.referencePartAssets,
      canvasWidth,
      canvasHeight,
      signalAssetUpdate || (() => undefined)
    );
    const previewReferencePartMarkings = getPreviewPartMapFromAssets(
      dirState.referencePartMarkingAssets,
      canvasWidth,
      canvasHeight,
      signalAssetUpdate || (() => undefined)
    );
    const previewBodyGrid = getPreviewGridFromAsset(
      dirState.bodyAsset,
      canvasWidth,
      canvasHeight,
      signalAssetUpdate || (() => undefined)
    );
    const shouldReplaceHead = shouldApplyReplacement(
      'head',
      partReplacementMap,
      partPaintPresenceMap
    );
    const overlayAssets = dirState.overlayAssets as
      | (GearOverlayAsset | IconAssetPayload)[]
      | undefined;
    const overlayLayers = buildOrderedOverlayLayers(
      overlayAssets,
      canvasWidth,
      canvasHeight,
      'base',
      signalAssetUpdate || (() => undefined),
      (slot) =>
        !(
          shouldReplaceHead &&
          slot &&
          (slot === 'hair' || slot === 'hair_accessory' || slot === 'ears')
        )
    );
    const allowLoadout = showLoadoutGear !== false;
    const allowJob = showJobGear !== false;
    const loadoutOverlayLayers = allowLoadout
      ? buildOrderedOverlayLayers(
          dirState.gearLoadoutOverlayAssets as
            | (GearOverlayAsset | IconAssetPayload)[]
            | undefined,
          canvasWidth,
          canvasHeight,
          'loadout',
          signalAssetUpdate || (() => undefined),
          undefined,
          overlayLayers.length
        )
      : [];
    const loadoutSlots = new Set(
      loadoutOverlayLayers
        .map((entry) => entry.slot)
        .filter((slot): slot is string => !!slot)
    );
    const jobOverlayLayersUnfiltered = allowJob
      ? buildOrderedOverlayLayers(
          dirState.gearJobOverlayAssets as
            | (GearOverlayAsset | IconAssetPayload)[]
            | undefined,
          canvasWidth,
          canvasHeight,
          'job',
          signalAssetUpdate || (() => undefined),
          undefined,
          overlayLayers.length + loadoutOverlayLayers.length
        )
      : [];
    const jobOverlayLayers =
      allowLoadout && allowJob
        ? jobOverlayLayersUnfiltered.filter(
            (entry) => !entry.slot || !loadoutSlots.has(entry.slot)
          )
        : jobOverlayLayersUnfiltered;
    const orderedOverlayLayers = mergeOverlayLayerLists(
      overlayLayers,
      jobOverlayLayers,
      loadoutOverlayLayers
    );
    const layers = composePreviewLayers(
      dirState,
      labelMap,
      canvasWidth,
      canvasHeight,
      activeDirKey,
      activePartKey,
      draftDiffIndex,
      activeDraftDiff,
      partRenderPriorityMap,
      partReplacementMap,
      partPaintPresenceMap,
      previewReferenceParts,
      previewReferencePartMarkings,
      previewBodyGrid,
      orderedOverlayLayers,
      showJobGear,
      showLoadoutGear
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

const composePreviewLayers = (
  dirState: PreviewDirState,
  labelMap: Record<string, string>,
  canvasWidth: number,
  canvasHeight: number,
  activeDirKey: number,
  activePartKey: string,
  draftDiffIndex?: Record<number, Record<string, DiffEntry[]>> | null,
  activeDraftDiff?: DiffEntry[] | null,
  partRenderPriorityMap?: Record<string, boolean>,
  partReplacementMap?: Record<string, boolean>,
  partPaintPresenceMap?: Record<string, boolean>,
  resolvedReferenceParts?: Record<string, string[][]> | null,
  resolvedReferencePartMarkings?: Record<string, string[][]> | null,
  resolvedBodyGrid?: string[][] | null,
  orderedOverlayLayers?: OrderedOverlayLayer[] | null,
  showJobGear?: boolean,
  showLoadoutGear?: boolean
): PreviewLayerEntry[] => {
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
  const clonedBodyGrid = resolvedBodyGrid
    ? cloneGridData(resolvedBodyGrid)
    : undefined;
  const bodyGrid = maskBodyGridForReplacements(
    clonedBodyGrid,
    referenceParts,
    partReplacementMap,
    partPaintPresenceMap
  );
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
    const isReplacedPart = shouldApplyReplacement(
      partId,
      partReplacementMap,
      partPaintPresenceMap
    );
    if (!isReplacedPart && referenceGrid && gridHasPixels(referenceGrid)) {
      orderedPartLayers.push({
        type: 'reference_part',
        key: `ref_${partId}`,
        label: `${resolveBodyPartLabel(normalizedPart, labelMap)} Base`,
        grid: referenceGrid,
      });
    } else if (
      isReplacedPart &&
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
    let customGrid = customParts[partId]?.grid
      ? cloneGridData(customParts[partId].grid)
      : undefined;
    const dirDraftMap = draftDiffIndex?.[dirState.dir] || null;
    const pendingDraftDiff = dirDraftMap?.[partId] || null;
    const shouldApplyDraft =
      (pendingDraftDiff && pendingDraftDiff.length) ||
      (activeDraftDiff &&
        activeDraftDiff.length &&
        dirState.dir === activeDirKey &&
        partId === activePartKey);
    const diffToApply = pendingDraftDiff?.length
      ? pendingDraftDiff
      : dirState.dir === activeDirKey && partId === activePartKey
        ? activeDraftDiff
        : null;
    if (shouldApplyDraft && diffToApply?.length) {
      customGrid = applyDiffToGrid(
        customGrid || createBlankGrid(canvasWidth, canvasHeight),
        diffToApply,
        canvasWidth,
        canvasHeight
      );
    }
    if (customGrid && gridHasPixels(customGrid)) {
      const hasOverride =
        !!partRenderPriorityMap &&
        Object.prototype.hasOwnProperty.call(partRenderPriorityMap, partId);
      const shouldFloat =
        hasOverride && partRenderPriorityMap
          ? !!partRenderPriorityMap[partId]
          : false;
      const customLayer: PreviewLayerEntry = {
        type: 'custom',
        key: `custom_${partId}`,
        label: `${resolveBodyPartLabel(normalizedPart, labelMap)} Custom`,
        grid: customGrid,
      };
      if (shouldFloat) {
        floatingCustomLayers.push(customLayer);
      } else {
        orderedPartLayers.push(customLayer);
      }
    }
  }
  if (Array.isArray(orderedOverlayLayers) && orderedOverlayLayers.length) {
    orderedOverlayLayers.forEach((entry, index) => {
      const cloned = cloneGridData(entry.grid);
      if (!gridHasPixels(cloned)) {
        return;
      }
      const opacity =
        entry.source === 'job' && showJobGear === false
          ? 0
          : entry.source === 'loadout' && showLoadoutGear === false
            ? 0
            : 1;
      overlayEntries.push({
        type: 'overlay',
        key: `overlay_${entry.source}_${index}`,
        label:
          entry.source === 'job'
            ? 'Job Gear'
            : entry.source === 'loadout'
              ? 'Loadout Gear'
              : 'Overlay',
        grid: cloned,
        opacity,
      });
    });
  }
  const mergedLayers = [
    ...orderedPartLayers,
    ...overlayEntries,
    ...floatingCustomLayers,
  ];
  return normalizeLayerDimensions(mergedLayers, canvasWidth, canvasHeight);
};

const buildOrderedOverlayLayers = (
  assets: (GearOverlayAsset | IconAssetPayload)[] | undefined,
  canvasWidth: number,
  canvasHeight: number,
  source: OrderedOverlayLayer['source'],
  signalAssetUpdate: () => void,
  slotFilter?: (slot: string | null | undefined) => boolean,
  orderOffset = 0
): OrderedOverlayLayer[] => {
  if (!Array.isArray(assets) || !assets.length) {
    return [];
  }
  const layers: OrderedOverlayLayer[] = [];
  const updateSignal = signalAssetUpdate || (() => undefined);
  for (let i = 0; i < assets.length; i += 1) {
    const entry = assets[i] as GearOverlayAsset | IconAssetPayload;
    const payload =
      (entry as GearOverlayAsset)?.asset ||
      ((entry as IconAssetPayload)?.token ? (entry as IconAssetPayload) : null);
    if (!payload) {
      continue;
    }
    const slot =
      (entry as GearOverlayAsset)?.slot !== undefined
        ? (entry as GearOverlayAsset).slot
        : null;
    if (slotFilter && !slotFilter(slot || null)) {
      continue;
    }
    const grid = getPreviewGridFromAsset(
      payload,
      canvasWidth,
      canvasHeight,
      updateSignal
    );
    if (!grid) {
      continue;
    }
    const hasSlotPriority =
      !!slot &&
      Object.prototype.hasOwnProperty.call(OVERLAY_SLOT_PRIORITY_MAP, slot);
    const fallbackLayer = hasSlotPriority
      ? OVERLAY_SLOT_PRIORITY_MAP[slot as string]
      : null;
    const rawLayer = (entry as GearOverlayAsset)?.layer;
    let layerValue: number | null = null;
    if (typeof rawLayer === 'number') {
      layerValue = rawLayer;
    } else if (hasSlotPriority && fallbackLayer !== null) {
      layerValue = fallbackLayer;
    } else {
      layerValue = orderOffset + i;
    }
    layers.push({
      grid: grid as string[][],
      layer: layerValue,
      slot: (slot as string | null) || null,
      source,
      order: orderOffset + i,
    });
  }
  return layers;
};

const mergeOverlayLayerLists = (
  baseLayers: OrderedOverlayLayer[],
  jobLayers: OrderedOverlayLayer[],
  loadoutLayers: OrderedOverlayLayer[]
): OrderedOverlayLayer[] =>
  [...baseLayers, ...jobLayers, ...loadoutLayers].sort((a, b) => {
    const layerA = Number.isFinite(a.layer)
      ? (a.layer as number)
      : Number.MAX_SAFE_INTEGER;
    const layerB = Number.isFinite(b.layer)
      ? (b.layer as number)
      : Number.MAX_SAFE_INTEGER;
    if (layerA !== layerB) {
      return layerA - layerB;
    }
    return a.order - b.order;
  });

const buildPreviewPartOrderForState = (
  preferredOrder: string[] | undefined,
  referenceParts: Record<string, string[][]>,
  customParts: Record<string, { grid?: string[][] }>
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

const shouldApplyReplacement = (
  partId?: string | null,
  replacements?: Record<string, boolean>,
  partPaintPresenceMap?: Record<string, boolean>
): boolean => {
  if (
    !partId ||
    partId === GENERIC_PART_KEY ||
    !replacements ||
    !replacements[partId]
  ) {
    return false;
  }
  if (partPaintPresenceMap) {
    return !!partPaintPresenceMap[partId];
  }
  return true;
};

const maskBodyGridForReplacements = (
  bodyGrid?: string[][],
  referenceParts?: Record<string, string[][]>,
  replacements?: Record<string, boolean>,
  partPaintPresenceMap?: Record<string, boolean>
): string[][] | undefined => {
  if (!Array.isArray(bodyGrid) || !replacements || !referenceParts) {
    return bodyGrid;
  }
  for (const partId of Object.keys(replacements)) {
    if (!shouldApplyReplacement(partId, replacements, partPaintPresenceMap)) {
      continue;
    }
    const maskGrid = referenceParts[partId];
    if (!maskGrid) {
      continue;
    }
    applyReplacementMaskToGrid(bodyGrid, maskGrid);
  }
  return bodyGrid;
};

const applyReplacementMaskToGrid = (
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

const pixelHasColor = (value?: string): boolean =>
  typeof value === 'string' && value.length > 0 && value !== TRANSPARENT_HEX;

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
