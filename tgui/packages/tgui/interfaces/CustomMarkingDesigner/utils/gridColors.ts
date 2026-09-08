// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Shared grid color helpers for the custom marking designer tabs //
// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

import { normalizeHex, TRANSPARENT_HEX } from '../../../utils/color';
import type { PreviewDirectionEntry } from '../../../utils/character-preview';

export const ICON_BLEND_MODE = {
  ADD: 0,
  SUBTRACT: 1,
  MULTIPLY: 2,
  OVERLAY: 3,
  AND: 4,
  OR: 5,
} as const;

const clampFactor = (value: number, maxFactor: number) =>
  Math.max(0, Math.min(maxFactor, value));

export const clampChannel = (value: number) =>
  Math.max(0, Math.min(255, Math.floor(value)));

export const resolveBlendMode = (mode?: number) => {
  switch (mode) {
    case ICON_BLEND_MODE.ADD:
    case ICON_BLEND_MODE.SUBTRACT:
    case ICON_BLEND_MODE.MULTIPLY:
    case ICON_BLEND_MODE.OVERLAY:
    case ICON_BLEND_MODE.AND:
    case ICON_BLEND_MODE.OR:
      return mode;
    default:
      return ICON_BLEND_MODE.MULTIPLY;
  }
};

export const blendChannel = (base: number, tint: number, mode: number) => {
  switch (resolveBlendMode(mode)) {
    case ICON_BLEND_MODE.MULTIPLY:
      return clampChannel((base * tint) / 255);
    case ICON_BLEND_MODE.OVERLAY:
      return clampChannel(tint);
    case ICON_BLEND_MODE.SUBTRACT:
      return clampChannel(base - tint);
    case ICON_BLEND_MODE.AND:
      return base & tint;
    case ICON_BLEND_MODE.OR:
      return base | tint;
    default:
      return clampChannel(base + tint);
  }
};

export const parseHex = (
  hex?: string | null
): [number, number, number, number] => {
  if (!hex || typeof hex !== 'string') {
    return [0, 0, 0, 0];
  }
  const cleaned = normalizeHex(hex, {
    preserveTransparent: true,
    preserveAlpha: true,
  });
  if (!cleaned) {
    return [0, 0, 0, 0];
  }
  const raw = cleaned.startsWith('#') ? cleaned.slice(1) : cleaned;
  const safeRaw = raw || '';
  const r = parseInt(safeRaw.slice(0, 2), 16) || 0;
  const g = parseInt(safeRaw.slice(2, 4), 16) || 0;
  const b = parseInt(safeRaw.slice(4, 6), 16) || 0;
  const a = safeRaw.length >= 8 ? parseInt(safeRaw.slice(6, 8), 16) || 0 : 255;
  return [r, g, b, a];
};

export const toHex = (r: number, g: number, b: number, a?: number) => {
  const channel = (value: number) =>
    (value < 16 ? '0' : '') + Math.max(0, Math.min(255, value)).toString(16);
  if (typeof a === 'number') {
    return `#${channel(r)}${channel(g)}${channel(b)}${channel(a)}`;
  }
  return `#${channel(r)}${channel(g)}${channel(b)}`;
};

export const tintGrid = (
  grid: string[][],
  tintHex: string,
  mode: number
): string[][] => {
  const blendMode = resolveBlendMode(mode);
  const [tr, tg, tb] = parseHex(tintHex);
  const tinted: string[][] = [];
  for (let x = 0; x < grid.length; x += 1) {
    const column = grid[x];
    if (!Array.isArray(column)) {
      tinted[x] = [];
      continue;
    }
    tinted[x] = [];
    for (let y = 0; y < column.length; y += 1) {
      const px = column[y];
      if (typeof px !== 'string' || px === TRANSPARENT_HEX) {
        tinted[x][y] = TRANSPARENT_HEX;
        continue;
      }
      const [r, g, b, a] = parseHex(px);
      const rr = blendChannel(r, tr, blendMode);
      const gg = blendChannel(g, tg, blendMode);
      const bb = blendChannel(b, tb, blendMode);
      tinted[x][y] = toHex(rr, gg, bb, a);
    }
  }
  return tinted;
};

export const recolorGrid = (
  grid: string[][],
  baseHex: string,
  targetHex: string,
  maxFactor = 1
): string[][] => {
  const [br, bg, bb] = parseHex(baseHex);
  const [tr, tg, tb] = parseHex(targetHex);
  if (br === tr && bg === tg && bb === tb) {
    return grid;
  }
  const recolored: string[][] = [];
  for (let x = 0; x < grid.length; x += 1) {
    const column = grid[x];
    if (!Array.isArray(column)) {
      recolored[x] = [];
      continue;
    }
    recolored[x] = [];
    for (let y = 0; y < column.length; y += 1) {
      const px = column[y];
      if (typeof px !== 'string' || px === TRANSPARENT_HEX) {
        recolored[x][y] = TRANSPARENT_HEX;
        continue;
      }
      const [r, g, b, a] = parseHex(px);
      let factor = 0;
      let count = 0;
      if (br) {
        factor += r / br;
        count += 1;
      }
      if (bg) {
        factor += g / bg;
        count += 1;
      }
      if (bb) {
        factor += b / bb;
        count += 1;
      }
      if (!count) {
        factor = (r + g + b) / (3 * 255);
      } else {
        factor /= count;
      }
      factor = clampFactor(factor, maxFactor);
      recolored[x][y] = toHex(
        Math.round(tr * factor),
        Math.round(tg * factor),
        Math.round(tb * factor),
        a
      );
    }
  }
  return recolored;
};

export const resolveReferencePartId = (layerKey: string): string | null => {
  if (!layerKey.startsWith('ref_')) {
    return null;
  }
  let partId = layerKey.slice(4);
  if (!partId.length) {
    return null;
  }
  if (partId.endsWith('_markings')) {
    partId = partId.slice(0, -9);
  }
  return partId || null;
};

export const applyBodyColorToPreview = (
  preview: PreviewDirectionEntry[],
  baseHex: string | null,
  targetHex: string | null,
  excludedParts?: Set<string> | null,
  maxFactor = 1
): PreviewDirectionEntry[] => {
  const base = normalizeHex(baseHex);
  const target = normalizeHex(targetHex);
  if (!base || !target || base === target) {
    return preview;
  }
  let changed = false;
  const next = preview.map((entry) => {
    let layersChanged = false;
    const layers = (entry.layers || []).map((layer) => {
      if (!layer?.grid) {
        return layer;
      }
      if (layer.type !== 'body' && layer.type !== 'reference_part') {
        return layer;
      }
      if (typeof layer.key === 'string' && layer.key.includes('_markings')) {
        return layer;
      }
      if (layer.type === 'reference_part' && excludedParts?.size) {
        const partId = resolveReferencePartId(layer.key);
        if (partId && excludedParts.has(partId)) {
          return layer;
        }
      }
      const recolored = recolorGrid(layer.grid, base, target, maxFactor);
      if (recolored === layer.grid) {
        return layer;
      }
      layersChanged = true;
      return {
        ...layer,
        grid: recolored,
      };
    });
    if (!layersChanged) {
      return entry;
    }
    changed = true;
    return {
      ...entry,
      layers,
    };
  });
  return changed ? next : preview;
};
