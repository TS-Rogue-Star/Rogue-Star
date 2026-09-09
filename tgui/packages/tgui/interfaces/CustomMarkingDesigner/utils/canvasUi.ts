// //////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Canvas UI helpers for custom marking designer //
// //////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star August 2026: Character Designer - Species and Prosthetics /////
// //////////////////////////////////////////////////////////////////////////////////////////////

import type { CanvasBackgroundOption } from '../types';
import {
  GENERIC_PART_KEY,
  cloneGridData,
  createBlankGrid,
} from '../../../utils/character-preview';

const REFERENCE_PASSTHROUGH_KEYS = new Set([
  'markings',
  'overlay',
  'gear_equipment',
  'gear_job',
  'gear_loadout',
]);
const EYE_REFERENCE_PART_KEYS = ['eyes', 'native_eyes'] as const;

export const buildGenericCanvasReference = (options: {
  referenceParts: Record<string, string[][]> | null;
  referenceGrid: string[][] | null;
  partOrder?: string[] | null;
  canvasWidth: number;
  canvasHeight: number;
  activePartKey: string;
  mergeGrid: (target: string[][], source: string[][]) => void;
}): Record<string, string[][]> | null => {
  const {
    referenceParts,
    referenceGrid,
    partOrder,
    canvasWidth,
    canvasHeight,
    activePartKey,
    mergeGrid,
  } = options;
  if (!referenceParts && !referenceGrid?.length) {
    return referenceParts;
  }

  const resolvedParts = { ...(referenceParts || {}) };
  const activeReferenceGrid =
    activePartKey !== GENERIC_PART_KEY && resolvedParts[activePartKey]?.length
      ? resolvedParts[activePartKey]
      : null;
  const eyeLayers = EYE_REFERENCE_PART_KEYS.map(
    (partId) => resolvedParts[partId]
  ).filter((grid): grid is string[][] => !!grid?.length);
  const eyeHostKey = resolvedParts.head?.length
    ? 'head'
    : resolvedParts.face?.length
      ? 'face'
      : null;
  if (eyeHostKey && eyeLayers.length) {
    const headWithEyes = cloneGridData(resolvedParts[eyeHostKey]);
    eyeLayers.forEach((grid) => mergeGrid(headWithEyes, grid));
    resolvedParts[eyeHostKey] = headWithEyes;
    EYE_REFERENCE_PART_KEYS.forEach((partId) => delete resolvedParts[partId]);
  }

  const orderedPartIds: string[] = [];
  const seenPartIds = new Set<string>();
  const appendPartId = (partId?: string | null) => {
    if (
      !partId ||
      seenPartIds.has(partId) ||
      partId === GENERIC_PART_KEY ||
      REFERENCE_PASSTHROUGH_KEYS.has(partId) ||
      !resolvedParts[partId]?.length
    ) {
      return;
    }
    seenPartIds.add(partId);
    orderedPartIds.push(partId);
  };
  (partOrder || []).forEach(appendPartId);
  Object.keys(resolvedParts).forEach(appendPartId);
  if (!orderedPartIds.length && !referenceGrid?.length) {
    return referenceParts;
  }

  const genericGrid = createBlankGrid(canvasWidth, canvasHeight);
  if (referenceGrid?.length) {
    mergeGrid(genericGrid, referenceGrid);
  }
  orderedPartIds.forEach((partId) =>
    mergeGrid(genericGrid, resolvedParts[partId])
  );
  const canonicalParts: Record<string, string[][]> = {
    [GENERIC_PART_KEY]: genericGrid,
  };
  if (activePartKey !== GENERIC_PART_KEY && activeReferenceGrid?.length) {
    canonicalParts[activePartKey] = activeReferenceGrid;
  }
  Object.entries(resolvedParts).forEach(([partId, grid]) => {
    if (REFERENCE_PASSTHROUGH_KEYS.has(partId) && grid?.length) {
      canonicalParts[partId] = grid;
    }
  });
  return canonicalParts;
};

export const applyHeadAppearanceToCanvasReferences = (options: {
  referenceParts: Record<string, string[][]>;
  referenceGrid: string[][] | null;
  overlayGrid: string[][];
  mergeGrid: (target: string[][], source: string[][]) => void;
}): {
  referenceParts: Record<string, string[][]>;
  referenceGrid: string[][] | null;
  applied: boolean;
} => {
  const { referenceParts, referenceGrid, overlayGrid, mergeGrid } = options;
  const nextReferenceParts = { ...referenceParts };
  let nextReferenceGrid = referenceGrid;
  let applied = false;
  const mergeIntoPart = (partId: string): boolean => {
    const referencePart = nextReferenceParts[partId];
    if (!referencePart?.length) {
      return false;
    }
    const merged = cloneGridData(referencePart);
    mergeGrid(merged, overlayGrid);
    nextReferenceParts[partId] = merged;
    return true;
  };
  const headPartId = nextReferenceParts.head?.length
    ? 'head'
    : nextReferenceParts.face?.length
      ? 'face'
      : null;
  if (headPartId) {
    applied = mergeIntoPart(headPartId);
  } else if (nextReferenceParts[GENERIC_PART_KEY]?.length) {
    applied = mergeIntoPart(GENERIC_PART_KEY);
  } else if (nextReferenceGrid?.length) {
    const merged = cloneGridData(nextReferenceGrid);
    mergeGrid(merged, overlayGrid);
    nextReferenceGrid = merged;
    applied = true;
  }
  return {
    referenceParts: nextReferenceParts,
    referenceGrid: nextReferenceGrid,
    applied,
  };
};

export const getCanvasFrameStyle = (
  resolvedCanvasBackground: CanvasBackgroundOption | null,
  backgroundFallbackColor: string,
  canvasDisplayWidthPx: number,
  canvasDisplayHeightPx: number
) => ({
  position: 'relative',
  boxSizing: 'content-box',
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

export const buildCanvasKey = ({
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
