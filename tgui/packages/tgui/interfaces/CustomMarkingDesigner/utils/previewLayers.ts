// //////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Preview layer helpers for custom marking designer //
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
const HIDDEN_LEG_PARTS = new Set(['l_leg', 'r_leg', 'l_foot', 'r_foot']);
const TAUR_CLOTHING_SLOTS = new Set(['uniform', 'belt', 'suit', 'back']);
const MARKING_MASK_ALPHA_THRESHOLD = 250;

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
    const overlayAssets = dirState.overlayAssets as
      | (GearOverlayAsset | IconAssetPayload)[]
      | undefined;
    const overlaySlotFilter = stripReferenceMarkings
      ? (slot: string | null | undefined) => slot !== 'custom_marking'
      : undefined;
    const overlayLayers = buildOrderedOverlayLayers(
      overlayAssets,
      canvasWidth,
      canvasHeight,
      'base',
      signalAssetUpdate || (() => undefined),
      overlaySlotFilter
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
          overlaySlotFilter,
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
          overlaySlotFilter,
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

const buildHiddenPartsMap = (
  hiddenBodyParts?: string[] | null
): Record<string, boolean> => {
  const map: Record<string, boolean> = {};
  if (!Array.isArray(hiddenBodyParts)) {
    return map;
  }
  for (const partId of hiddenBodyParts) {
    if (!partId || partId === GENERIC_PART_KEY) {
      continue;
    }
    map[partId] = true;
  }
  return map;
};

const collectHiddenLegParts = (
  hiddenPartsMap: Record<string, boolean>
): string[] => {
  const parts: string[] = [];
  for (const partId of Object.keys(hiddenPartsMap)) {
    if (hiddenPartsMap[partId] && HIDDEN_LEG_PARTS.has(partId)) {
      parts.push(partId);
    }
  }
  return parts;
};

const maskGridForHiddenParts = (
  grid: string[][],
  referenceParts: Record<string, string[][]>,
  hiddenParts: string[]
) => {
  if (!hiddenParts.length) {
    return;
  }
  for (const partId of hiddenParts) {
    const maskGrid = referenceParts[partId];
    if (!maskGrid) {
      continue;
    }
    applyReplacementMaskToGrid(grid, maskGrid);
  }
};

type ReferenceLayerAppendOptions = {
  orderedPartLayers: PreviewLayerEntry[];
  partId: string;
  normalizedPart: string | null;
  labelMap: Record<string, string>;
  referenceGrid?: string[][] | null;
  markingReferenceGrid?: string[][] | null;
  isReplacedPart: boolean;
  isHiddenPart: boolean;
};

const appendReferenceLayersForPart = ({
  orderedPartLayers,
  partId,
  normalizedPart,
  labelMap,
  referenceGrid,
  markingReferenceGrid,
  isReplacedPart,
  isHiddenPart,
}: ReferenceLayerAppendOptions) => {
  const resolvedLabel = resolveBodyPartLabel(normalizedPart, labelMap);
  if (isHiddenPart) {
    if (markingReferenceGrid && gridHasPixels(markingReferenceGrid)) {
      orderedPartLayers.push({
        type: 'reference_part',
        key: `ref_${partId}_markings`,
        label: `${resolvedLabel} Markings`,
        grid: markingReferenceGrid,
      });
    }
    return;
  }
  if (!isReplacedPart && referenceGrid && gridHasPixels(referenceGrid)) {
    orderedPartLayers.push({
      type: 'reference_part',
      key: `ref_${partId}`,
      label: `${resolvedLabel} Base`,
      grid: referenceGrid,
    });
    return;
  }
  if (
    isReplacedPart &&
    markingReferenceGrid &&
    gridHasPixels(markingReferenceGrid)
  ) {
    orderedPartLayers.push({
      type: 'reference_part',
      key: `ref_${partId}_markings`,
      label: `${resolvedLabel} Markings`,
      grid: markingReferenceGrid,
    });
  }
};

const appendOverlayEntries = ({
  overlayEntries,
  orderedOverlayLayers,
  showJobGear,
  showLoadoutGear,
  hiddenLegParts,
  hideShoes,
  referenceParts,
}: {
  overlayEntries: PreviewLayerEntry[];
  orderedOverlayLayers?: OrderedOverlayLayer[] | null;
  showJobGear?: boolean;
  showLoadoutGear?: boolean;
  hiddenLegParts?: string[];
  hideShoes?: boolean;
  referenceParts?: Record<string, string[][]> | null;
}) => {
  if (!Array.isArray(orderedOverlayLayers) || !orderedOverlayLayers.length) {
    return;
  }
  const shouldMaskOverlays =
    !!referenceParts && !!hiddenLegParts && hiddenLegParts.length > 0;
  orderedOverlayLayers.forEach((entry, index) => {
    if (hideShoes && entry.slot === 'shoes') {
      return;
    }
    const cloned = cloneGridData(entry.grid);
    if (
      shouldMaskOverlays &&
      referenceParts &&
      hiddenLegParts &&
      entry.slot &&
      TAUR_CLOTHING_SLOTS.has(entry.slot)
    ) {
      maskGridForHiddenParts(cloned, referenceParts, hiddenLegParts);
    }
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
  const hiddenPartsMap = buildHiddenPartsMap(dirState.hiddenBodyParts);
  const hiddenLegParts = collectHiddenLegParts(hiddenPartsMap);
  const hideShoes = !!hiddenPartsMap['l_foot'] || !!hiddenPartsMap['r_foot'];
  const bodyGrid = maskBodyGridForReplacements(
    clonedBodyGrid,
    referenceParts,
    partReplacementMap,
    partPaintPresenceMap,
    hiddenPartsMap
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
    const isHiddenPart = !!hiddenPartsMap[partId];
    const hasReference = hasReferenceForPart(partId);
    const hasCustom = !!customParts[partId]?.grid;
    if (!hasReference && !hasCustom) {
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
    appendReferenceLayersForPart({
      orderedPartLayers,
      partId,
      normalizedPart,
      labelMap,
      referenceGrid,
      markingReferenceGrid,
      isReplacedPart: !!isReplacedPart,
      isHiddenPart,
    });
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
  appendOverlayEntries({
    overlayEntries,
    orderedOverlayLayers,
    showJobGear,
    showLoadoutGear,
    hiddenLegParts,
    hideShoes,
    referenceParts,
  });
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
  partPaintPresenceMap?: Record<string, boolean>,
  hiddenParts?: Record<string, boolean> | null
): string[][] | undefined => {
  if (!Array.isArray(bodyGrid) || !referenceParts) {
    return bodyGrid;
  }
  if (replacements) {
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
  }
  if (hiddenParts) {
    for (const partId of Object.keys(hiddenParts)) {
      if (!hiddenParts[partId]) {
        continue;
      }
      if (!partId || partId === GENERIC_PART_KEY) {
        continue;
      }
      const maskGrid = referenceParts[partId];
      if (!maskGrid) {
        continue;
      }
      applyReplacementMaskToGrid(bodyGrid, maskGrid);
    }
  }
  return bodyGrid;
};

const applyReplacementMaskToGrid = (
  target: string[][],
  mask: string[][],
  options?: { alphaThreshold?: number }
): boolean => {
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
      if (
        !pixelHasColor(maskColumn[y], alphaThreshold) ||
        !pixelHasColor(targetColumn[y])
      ) {
        continue;
      }
      targetColumn[y] = TRANSPARENT_HEX;
      changed = true;
    }
  }
  return changed;
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
      applyReplacementMaskToGrid(nextBodyGrid, markingGrid, {
        alphaThreshold: MARKING_MASK_ALPHA_THRESHOLD,
      });
    }
    const basePartGrid = (nextReferenceParts ||
      referenceParts ||
      ({} as Record<string, string[][]>))[partId];
    if (!basePartGrid) {
      continue;
    }
    ensureParts();
    const strippedPart = cloneGridData(basePartGrid);
    applyReplacementMaskToGrid(strippedPart, markingGrid, {
      alphaThreshold: MARKING_MASK_ALPHA_THRESHOLD,
    });
    if (nextReferenceParts) {
      nextReferenceParts[partId] = strippedPart;
    }
  }
  return {
    referenceParts: nextReferenceParts ?? null,
    bodyGrid: nextBodyGrid ?? null,
  };
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

export type CustomLayerUpdateResult = {
  entry: PreviewDirectionEntry;
  updated: boolean;
  requiresRebuild: boolean;
};

export const updatePreviewEntryCustomLayer = (options: {
  entry: PreviewDirectionEntry;
  partKey: string;
  baseGrid?: string[][] | null;
  diff?: DiffEntry[] | null;
  canvasWidth: number;
  canvasHeight: number;
}): CustomLayerUpdateResult => {
  const { entry, partKey, baseGrid, diff, canvasWidth, canvasHeight } = options;
  const layers = Array.isArray(entry.layers) ? entry.layers : [];
  const layerKey = `custom_${partKey}`;
  const layerIndex = layers.findIndex(
    (layer) => layer?.type === 'custom' && layer.key === layerKey
  );
  const resolvedDiff = Array.isArray(diff) && diff.length > 0 ? diff : null;
  if (layerIndex === -1) {
    if (!resolvedDiff && !gridHasPixels(baseGrid ?? undefined)) {
      return { entry, updated: false, requiresRebuild: false };
    }
    return { entry, updated: false, requiresRebuild: true };
  }
  if (!resolvedDiff) {
    return { entry, updated: false, requiresRebuild: false };
  }
  const existingLayer = layers[layerIndex];
  const seedGrid =
    (Array.isArray(baseGrid) && baseGrid.length ? baseGrid : null) ||
    existingLayer?.grid ||
    createBlankGrid(canvasWidth, canvasHeight);
  const nextGrid = applyDiffToGrid(
    seedGrid,
    resolvedDiff,
    canvasWidth,
    canvasHeight
  );
  const addsColor = resolvedDiff.some(
    (pixel) => pixel && pixel.color && pixel.color !== TRANSPARENT_HEX
  );
  if (!addsColor && !gridHasPixels(nextGrid)) {
    return { entry, updated: false, requiresRebuild: true };
  }
  const nextLayer =
    existingLayer?.grid === nextGrid
      ? existingLayer
      : { ...existingLayer, grid: nextGrid };
  if (nextLayer === existingLayer) {
    return { entry, updated: false, requiresRebuild: false };
  }
  const nextLayers = layers.slice();
  nextLayers[layerIndex] = nextLayer;
  return {
    entry: { ...entry, layers: nextLayers },
    updated: true,
    requiresRebuild: false,
  };
};
