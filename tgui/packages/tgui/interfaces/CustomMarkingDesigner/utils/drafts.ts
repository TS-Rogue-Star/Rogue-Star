// ////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Draft utilities for custom marking designer //
// ////////////////////////////////////////////////////////////////////////////////////////////

import { normalizeHex, TRANSPARENT_HEX } from '../../../utils/color';
import { GENERIC_PART_KEY, applyDiffToGrid, cloneGridData, createBlankGrid } from '../../../utils/character-preview';
import type { DiffEntry } from '../../../utils/character-preview';
import type { DraftStrokePayload, StrokeDraftEntry, StrokeDraftState } from '../types';
import { normalizeStrokeKey } from './strokeGeometry';

export const sanitizeDraftPixels = (
  pixels: DiffEntry[] | undefined,
  width: number,
  height: number
): DiffEntry[] => {
  if (!Array.isArray(pixels) || !pixels.length) {
    return [];
  }
  const sanitized: DiffEntry[] = [];
  for (const pixel of pixels) {
    if (!pixel) {
      continue;
    }
    const px = Number(pixel.x);
    const py = Number(pixel.y);
    if (
      !Number.isFinite(px) ||
      !Number.isFinite(py) ||
      px < 1 ||
      px > width ||
      py < 1 ||
      py > height
    ) {
      continue;
    }
    sanitized.push({
      x: Math.floor(px),
      y: Math.floor(py),
      color:
        typeof pixel.color === 'string' && pixel.color.length
          ? pixel.color
          : TRANSPARENT_HEX,
    });
  }
  return sanitized;
};

export const buildSessionDraftStrokePayloads = (
  drafts: StrokeDraftState,
  sessionKey: string,
  width: number,
  height: number
): DraftStrokePayload[] => {
  if (!sessionKey || !width || !height || !drafts) {
    return [];
  }
  const payloads: DraftStrokePayload[] = [];
  const entries = Object.values(drafts || {}) as StrokeDraftEntry[];
  for (const entry of entries) {
    if (!entry || entry.session !== sessionKey) {
      continue;
    }
    const pixels = Array.isArray(entry.pixels) ? entry.pixels : [];
    if (!pixels.length) {
      continue;
    }
    const strokeKey = normalizeStrokeKey(entry.stroke);
    if (!strokeKey) {
      continue;
    }
    const normalizedPixels = sanitizeDraftPixels(pixels, width, height);
    if (!normalizedPixels.length) {
      continue;
    }
    const rawSequence = Number(entry.sequence);
    const fallbackSequence = Number(entry.stroke);
    const sequence = Number.isFinite(rawSequence)
      ? rawSequence
      : Number.isFinite(fallbackSequence)
        ? fallbackSequence
        : 0;
    payloads.push({
      stroke: strokeKey,
      sequence,
      pixels: normalizedPixels,
    });
  }
  payloads.sort((a, b) => {
    if (a.sequence !== b.sequence) {
      return a.sequence - b.sequence;
    }
    return a.stroke.localeCompare(b.stroke);
  });
  return payloads;
};

export const buildSessionDraftDiff = (
  drafts: StrokeDraftState,
  sessionKey: string,
  width: number,
  height: number
): DiffEntry[] => {
  const payloads = buildSessionDraftStrokePayloads(
    drafts,
    sessionKey,
    width,
    height
  );
  if (!payloads.length) {
    return [];
  }
  const result: DiffEntry[] = [];
  for (const payload of payloads) {
    result.push(...payload.pixels);
  }
  return result;
};

export const buildDraftDiffIndex = (
  drafts: StrokeDraftState
): Record<number, Record<string, DiffEntry[]>> => {
  const result: Record<number, Record<string, DiffEntry[]>> = {};
  const orderedEntries = (Object.values(drafts || {}) as StrokeDraftEntry[])
    .filter(
      (entry) => entry && Array.isArray(entry.pixels) && entry.pixels.length
    )
    .sort((a, b) => {
      const seqA = Number(a?.sequence);
      const seqB = Number(b?.sequence);
      if (Number.isFinite(seqA) && Number.isFinite(seqB) && seqA !== seqB) {
        return seqA - seqB;
      }
      const strokeA = normalizeStrokeKey(a?.stroke) || '';
      const strokeB = normalizeStrokeKey(b?.stroke) || '';
      return strokeA.localeCompare(strokeB);
    });
  for (const entry of orderedEntries) {
    if (!entry || !entry.pixels || !entry.pixels.length) {
      continue;
    }
    const dirKeyRaw = entry?.dirKey;
    if (!Number.isFinite(dirKeyRaw)) {
      continue;
    }
    const dirKey = dirKeyRaw as number;
    const partKey = entry?.part || GENERIC_PART_KEY;
    if (!result[dirKey]) {
      result[dirKey] = {};
    }
    if (!result[dirKey][partKey]) {
      result[dirKey][partKey] = [];
    }
    result[dirKey][partKey].push(...(entry?.pixels || []));
  }
  return result;
};

export const applyDraftDiffsToLayerMap = (
  layerMap: Record<string, string[][]> | null,
  diffMap: Record<string, DiffEntry[]>,
  canvasWidth: number,
  canvasHeight: number
): Record<string, string[][]> | null => {
  if (!diffMap || !Object.keys(diffMap).length) {
    return layerMap;
  }
  let mutated = false;
  const nextMap: Record<string, string[][]> = layerMap ? { ...layerMap } : {};
  for (const [partKey, diffs] of Object.entries(diffMap)) {
    if (!Array.isArray(diffs) || !diffs.length) {
      continue;
    }
    const baseGrid = nextMap[partKey]
      ? cloneGridData(nextMap[partKey])
      : createBlankGrid(canvasWidth, canvasHeight);
    const updatedGrid = applyDiffToGrid(
      baseGrid,
      diffs,
      canvasWidth,
      canvasHeight
    );
    nextMap[partKey] = updatedGrid;
    mutated = true;
  }
  if (!mutated) {
    return layerMap;
  }
  return nextMap;
};

export const chunkDiffEntries = (
  entries: DiffEntry[],
  chunkSize: number
): DiffEntry[][] => {
  if (!Array.isArray(entries) || !entries.length) {
    return [];
  }
  if (!Number.isFinite(chunkSize) || chunkSize <= 0) {
    return [entries];
  }
  const chunks: DiffEntry[][] = [];
  for (let i = 0; i < entries.length; i += chunkSize) {
    chunks.push(entries.slice(i, i + chunkSize));
  }
  return chunks;
};

export const buildDraftPixelLookup = (
  diffEntries: DiffEntry[]
): Record<string, string | null> => {
  const lookup: Record<string, string | null> = {};
  for (const entry of diffEntries || []) {
    if (!entry) {
      continue;
    }
    const key = `${entry.x}-${entry.y}`;
    lookup[key] = normalizeHex(entry.color);
  }
  return lookup;
};
