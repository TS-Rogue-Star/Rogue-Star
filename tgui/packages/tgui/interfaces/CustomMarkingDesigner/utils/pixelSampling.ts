// ///////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Pixel sampling helpers for custom marking designer //
// ///////////////////////////////////////////////////////////////////////////////////////////////////

import { clamp01 } from 'common/math';
import {
  normalizeHex,
  resolvePixelColorFromHex,
  TRANSPARENT_HEX,
} from '../../../utils/color';
import type { DiffEntry } from '../../../utils/character-preview';

export type PreviewGrid = (string | null)[][] | null | undefined;

export type ResolvePreviewPixelsOptions = {
  pixels: DiffEntry[];
  brushHex?: string | null;
  blendMode: string;
  strength: number;
  grid?: PreviewGrid;
  referenceParts?: Record<string, PreviewGrid> | null;
  referenceGrid?: PreviewGrid;
  activePartKey: string;
  genericPartKey: string;
  pendingPixelLookup?: Record<string, string | null>;
};

export const resolvePreviewStrokePixels = (
  options: ResolvePreviewPixelsOptions
): DiffEntry[] => {
  if (!Array.isArray(options.pixels) || !options.pixels.length) {
    return [];
  }
  const normalizedMode = normalizeBlendMode(options.blendMode);
  if (normalizedMode === 'erase') {
    return options.pixels.map((pixel) => ({
      x: pixel.x,
      y: pixel.y,
      color: TRANSPARENT_HEX,
    }));
  }
  const strokeHex = normalizeHex(options.brushHex);
  if (!strokeHex) {
    return [];
  }
  const weight = resolveStrokeStrengthValue(normalizedMode, options.strength);
  return options.pixels.map((pixel) => {
    const draftBase = samplePendingPixelColor(
      options.pendingPixelLookup,
      pixel.x,
      pixel.y
    );
    const baseColor =
      draftBase ?? sampleGridColorAt(options.grid, pixel.x, pixel.y);
    const fallbackColor = baseColor
      ? null
      : resolveReferencePixelColor(
          options.referenceParts,
          options.activePartKey,
          options.genericPartKey,
          options.referenceGrid,
          pixel.x,
          pixel.y
        );
    const resolved =
      resolvePixelColorFromHex(
        baseColor,
        strokeHex,
        normalizedMode,
        weight,
        fallbackColor
      ) || strokeHex;
    return {
      x: pixel.x,
      y: pixel.y,
      color: resolved,
    };
  });
};

export const normalizeBlendMode = (mode: string | null | undefined): string =>
  typeof mode === 'string' ? mode.toLowerCase() : 'analog';

export const sampleGridColorAt = (
  grid: PreviewGrid,
  x: number,
  y: number
): string | null => {
  if (!Array.isArray(grid) || x < 1 || y < 1) {
    return null;
  }
  const column = grid[x - 1];
  if (!Array.isArray(column)) {
    return null;
  }
  const raw = column[y - 1];
  if (typeof raw !== 'string') {
    return null;
  }
  if (!raw.length || raw === TRANSPARENT_HEX) {
    return null;
  }
  return normalizeHex(raw);
};

export const samplePendingPixelColor = (
  lookup: Record<string, string | null> | undefined,
  x: number,
  y: number
): string | null => {
  if (!lookup) {
    return null;
  }
  const key = `${x}-${y}`;
  const raw = lookup[key];
  if (!raw || raw === TRANSPARENT_HEX) {
    return null;
  }
  return normalizeHex(raw);
};

export const resolveReferencePixelColor = (
  referenceParts: Record<string, PreviewGrid> | null | undefined,
  activePartKey: string,
  genericPartKey: string,
  referenceGrid: PreviewGrid,
  x: number,
  y: number
): string | null => {
  const sample = (grid?: PreviewGrid) => sampleGridColorAt(grid, x, y);
  if (referenceParts && activePartKey && referenceParts[activePartKey]) {
    const color = sample(referenceParts[activePartKey]);
    if (color) {
      return color;
    }
  }
  if (
    activePartKey === genericPartKey &&
    referenceParts &&
    referenceParts[genericPartKey]
  ) {
    const color = sample(referenceParts[genericPartKey]);
    if (color) {
      return color;
    }
  }
  if (activePartKey === genericPartKey) {
    return sample(referenceGrid);
  }
  return null;
};

export const resolveStrokeStrengthValue = (
  blendMode: string,
  strength: number
): number => {
  if (typeof strength === 'number' && !Number.isNaN(strength)) {
    return clamp01(strength);
  }
  return blendMode === 'analog' ? 0.5 : 1;
};
