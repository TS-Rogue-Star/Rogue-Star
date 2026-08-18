// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Shared grid color helpers for the custom marking designer tabs //
// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star August 2026: Character Designer - Species and Prosthetics //////////////////////
// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

import { normalizeHex, TRANSPARENT_HEX } from '../../../utils/color';
import type {
  PreviewDirectionEntry,
  PreviewLayerEntry,
  PreviewLayerRasterDependency,
} from '../../../utils/character-preview';

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

export const MAX_SHARED_GRID_COLOR_RESULTS = 128;
const MAX_GRID_COLOR_RESULTS_PER_SOURCE = 2;
const cachedGridColors = new WeakMap<string[][], Map<string, string[][]>>();
const sharedGridColorResults = new Map<string, string[][]>();

const getSharedGridColorResult = (key: string) => {
  const cached = sharedGridColorResults.get(key);
  if (!cached) {
    return null;
  }
  sharedGridColorResults.delete(key);
  sharedGridColorResults.set(key, cached);
  return cached;
};

const storeSharedGridColorResult = (key: string, grid: string[][]) => {
  sharedGridColorResults.delete(key);
  sharedGridColorResults.set(key, grid);
  while (sharedGridColorResults.size > MAX_SHARED_GRID_COLOR_RESULTS) {
    const oldestKey = sharedGridColorResults.keys().next().value as
      | string
      | undefined;
    if (!oldestKey) {
      break;
    }
    sharedGridColorResults.delete(oldestKey);
  }
};

export const getSharedGridColorResultCount = () => sharedGridColorResults.size;

export const clearSharedGridColorResults = () => {
  sharedGridColorResults.clear();
};

const resolveCachedGridColor = (
  grid: string[][],
  rasterIdentity: string | undefined,
  signature: string,
  resolver: () => string[][]
): string[][] => {
  const sharedKey = rasterIdentity
    ? `${rasterIdentity}|color:${signature}`
    : null;
  if (sharedKey) {
    const shared = getSharedGridColorResult(sharedKey);
    if (shared) {
      return shared;
    }
  }
  let cache = cachedGridColors.get(grid);
  const cached = cache?.get(signature);
  if (cached) {
    if (sharedKey) {
      storeSharedGridColorResult(sharedKey, cached);
    }
    return cached;
  }
  const resolved = resolver();
  if (!cache) {
    cache = new Map();
    cachedGridColors.set(grid, cache);
  }
  cache.set(signature, resolved);
  while (cache.size > MAX_GRID_COLOR_RESULTS_PER_SOURCE) {
    const oldest = cache.keys().next().value as string | undefined;
    if (!oldest) {
      break;
    }
    cache.delete(oldest);
  }
  if (sharedKey) {
    storeSharedGridColorResult(sharedKey, resolved);
  }
  return resolved;
};

const resolveCachedTintGrid = (
  layer: PreviewLayerEntry,
  targetHex: string,
  mode: number
): { grid: string[][]; signature: string } => {
  const signature = `tint:${resolveBlendMode(mode)}:${targetHex}`;
  return {
    grid: resolveCachedGridColor(
      layer.grid as string[][],
      layer.rasterIdentity,
      signature,
      () => tintGrid(layer.grid as string[][], targetHex, mode)
    ),
    signature,
  };
};

const resolveCachedRecolorGrid = (
  layer: PreviewLayerEntry,
  baseHex: string,
  targetHex: string,
  maxFactor: number
): { grid: string[][]; signature: string } => {
  const signature = `recolor:${baseHex}:${targetHex}:${maxFactor}`;
  return {
    grid: resolveCachedGridColor(
      layer.grid as string[][],
      layer.rasterIdentity,
      signature,
      () => recolorGrid(layer.grid as string[][], baseHex, targetHex, maxFactor)
    ),
    signature,
  };
};

const buildColoredLayerMetadata = (
  layer: PreviewLayerEntry,
  signature: string,
  dependency: PreviewLayerRasterDependency
): Pick<
  PreviewLayerEntry,
  'rasterIdentity' | 'rasterDependency' | 'rasterShareable'
> => ({
  rasterIdentity: layer.rasterIdentity
    ? `${layer.rasterIdentity}|color:${signature}`
    : undefined,
  rasterDependency: dependency,
  rasterShareable: !!layer.rasterIdentity && layer.rasterShareable === true,
});

const colorDistance = (
  r: number,
  g: number,
  b: number,
  target: [number, number, number]
) =>
  Math.abs(r - target[0]) + Math.abs(g - target[1]) + Math.abs(b - target[2]);

const EYE_COLOR_MATCH_THRESHOLD = 90;
const EYE_COLOR_BODY_MARGIN = 12;

const shiftEyeColorGrid = (
  grid: string[][],
  baseHex: string,
  targetHex: string,
  bodyHex?: string | null
): string[][] => {
  const [br, bg, bb] = parseHex(baseHex);
  const [tr, tg, tb] = parseHex(targetHex);
  if (br === tr && bg === tg && bb === tb) {
    return grid;
  }
  const hasBody = typeof bodyHex === 'string' && normalizeHex(bodyHex) !== null;
  const [bodyR, bodyG, bodyB] = hasBody
    ? parseHex(bodyHex as string)
    : ([0, 0, 0] as [number, number, number]);
  const deltaR = tr - br;
  const deltaG = tg - bg;
  const deltaB = tb - bb;
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
      const eyeDist = colorDistance(r, g, b, [br, bg, bb]);
      const bodyDist = hasBody
        ? colorDistance(r, g, b, [bodyR, bodyG, bodyB])
        : Number.POSITIVE_INFINITY;
      const matchesEye =
        eyeDist <= EYE_COLOR_MATCH_THRESHOLD ||
        eyeDist + EYE_COLOR_BODY_MARGIN <= bodyDist;
      if (!matchesEye) {
        recolored[x][y] = px;
        continue;
      }
      recolored[x][y] = toHex(
        clampChannel(r + deltaR),
        clampChannel(g + deltaG),
        clampChannel(b + deltaB),
        a
      );
    }
  }
  return recolored;
};

const resolveCachedEyeShiftGrid = (
  layer: PreviewLayerEntry,
  baseHex: string,
  targetHex: string,
  bodyHex?: string | null
): { grid: string[][]; signature: string } => {
  const signature = `eye:${baseHex}:${targetHex}:${normalizeHex(bodyHex) || ''}`;
  return {
    grid: resolveCachedGridColor(
      layer.grid as string[][],
      layer.rasterIdentity,
      signature,
      () =>
        shiftEyeColorGrid(layer.grid as string[][], baseHex, targetHex, bodyHex)
    ),
    signature,
  };
};

const resolveEyeReferencePartId = (layer: {
  key?: string;
  type?: string;
}): string | null => {
  if (
    layer.type !== 'reference_part' ||
    typeof layer.key !== 'string' ||
    !layer.key.startsWith('ref_') ||
    layer.key.endsWith('_markings')
  ) {
    return null;
  }
  return layer.key.slice(4).toLowerCase();
};

export const applyEyeColorToPreview = (
  preview: PreviewDirectionEntry[],
  baseHex: string | null,
  targetHex: string | null,
  bodyHex?: string | null
): PreviewDirectionEntry[] => {
  const base = normalizeHex(baseHex);
  const target = normalizeHex(targetHex);
  if (!target) {
    return preview;
  }
  const hasDedicatedEyeReference = preview.some((entry) =>
    (entry.layers || []).some((layer) => {
      const partId = resolveEyeReferencePartId(layer);
      return partId === 'eyes' || partId === 'native_eyes';
    })
  );
  let changed = false;
  const next = preview.map((entry) => {
    const hasExplicitNonBakedEyeMode =
      entry.eyeColorMode === 'separate' ||
      entry.eyeColorMode === 'native' ||
      entry.eyeColorMode === 'none';
    let layersChanged = false;
    const layers = (entry.layers || []).map((layer) => {
      if (!layer?.grid) {
        return layer;
      }
      const partId = resolveEyeReferencePartId(layer);
      const isEyeOverlay = layer.type === 'overlay' && layer.source === 'eyes';
      if (!partId && !isEyeOverlay) {
        return layer;
      }
      let shifted: { grid: string[][]; signature: string };
      let dependency = layer.rasterDependency || 'stable';
      if (isEyeOverlay) {
        if (!base || base === target) {
          return layer;
        }
        shifted = resolveCachedRecolorGrid(layer, base, target, 3);
        dependency = 'eye-direct';
      } else if (partId === 'eyes') {
        shifted = resolveCachedTintGrid(layer, target, ICON_BLEND_MODE.ADD);
        dependency = 'eye-direct';
      } else {
        if (
          hasDedicatedEyeReference ||
          hasExplicitNonBakedEyeMode ||
          (partId !== 'head' && partId !== 'face') ||
          !base ||
          base === target
        ) {
          return layer;
        }
        shifted = resolveCachedEyeShiftGrid(layer, base, target, bodyHex);
        dependency = 'body-eye-fallback';
      }
      if (shifted.grid === layer.grid) {
        return layer;
      }
      layersChanged = true;
      return {
        ...layer,
        grid: shifted.grid,
        ...buildColoredLayerMetadata(layer, shifted.signature, dependency),
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

export const applyLimbHairColorToPreview = (
  preview: PreviewDirectionEntry[],
  targetHex: string | null
): PreviewDirectionEntry[] => {
  const target = normalizeHex(targetHex);
  if (!target) {
    return preview;
  }
  let changed = false;
  const next = preview.map((entry) => {
    let layersChanged = false;
    const layers = (entry.layers || []).map((layer) => {
      if (layer?.type !== 'limb_hair' || !layer.grid) {
        return layer;
      }
      const tinted = resolveCachedTintGrid(
        layer,
        target,
        ICON_BLEND_MODE.MULTIPLY
      );
      layersChanged = true;
      return {
        ...layer,
        grid: tinted.grid,
        ...buildColoredLayerMetadata(
          layer,
          tinted.signature,
          layer.rasterDependency || 'stable'
        ),
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

export const applyBodyColorToPreview = (
  preview: PreviewDirectionEntry[],
  baseHex: string | null,
  targetHex: string | null,
  excludedParts?: Set<string> | null,
  maxFactor = 1,
  blendMode?: number | null
): PreviewDirectionEntry[] => {
  const base = normalizeHex(baseHex);
  const target = normalizeHex(targetHex);
  if (
    !target ||
    (typeof blendMode !== 'number' && (!base || base === target))
  ) {
    return preview;
  }
  let changed = false;
  const next = preview.map((entry) => {
    let layersChanged = false;
    const layers = (entry.layers || []).map((layer) => {
      if (!layer?.grid) {
        return layer;
      }
      const isSpeciesTail =
        layer.type === 'overlay' && layer.source === 'species_tail';
      if (
        layer.type !== 'body' &&
        layer.type !== 'reference_part' &&
        !isSpeciesTail
      ) {
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
      const recolored =
        typeof blendMode === 'number'
          ? resolveCachedTintGrid(layer, target, blendMode)
          : resolveCachedRecolorGrid(layer, base as string, target, maxFactor);
      if (recolored.grid === layer.grid) {
        return layer;
      }
      layersChanged = true;
      return {
        ...layer,
        grid: recolored.grid,
        ...buildColoredLayerMetadata(
          layer,
          recolored.signature,
          'body-relative'
        ),
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
