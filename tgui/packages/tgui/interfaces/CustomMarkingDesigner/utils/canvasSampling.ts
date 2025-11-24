// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Canvas sampling helpers for custom marking designer //
// ////////////////////////////////////////////////////////////////////////////////////////////////////

import { normalizeHex, TRANSPARENT_HEX } from '../../../utils/color';
import { GENERIC_PART_KEY } from '../../../utils/character-preview';
import type { DiffEntry } from '../../../utils/character-preview';
import {
  isValidCanvasPoint,
  resolvePreviewStrokePixels,
  resolveReferencePixelColor,
  sampleGridColorAt,
} from './index';

type CanvasSamplingOptions = {
  canvasWidth: number;
  canvasHeight: number;
  uiCanvasGrid: string[][] | null;
  referenceGrid: string[][] | null;
  referenceParts: Record<string, string[][]> | null;
  layerPartsWithDrafts: Record<string, string[][]> | null;
  layerParts: Record<string, string[][]> | null;
  layerOrder: string[] | null;
  draftPixelLookup: Record<string, string | null> | null;
  brushColor: string;
  currentBlendMode: string;
  analogStrength: number;
  activePartKey: string;
};

export type CanvasSamplingHelpers = {
  decoratePreviewPixels: (pixels: DiffEntry[]) => DiffEntry[];
  buildFillPreviewDiff: (startX: number, startY: number) => DiffEntry[];
  buildClearPreviewDiff: () => DiffEntry[];
  sampleEyedropperPixelColor: (x: number, y: number) => string | null;
  sampleCurrentPixelColor: (x: number, y: number) => string | null;
};

const getDraftPixelKey = (x: number, y: number) => `${x}-${y}`;

const normalizeDiffColor = (color?: string | null): string | null => {
  if (!color || color === TRANSPARENT_HEX) {
    return null;
  }
  return normalizeHex(color);
};

const generateRandomToken = (prefix: string) =>
  `${prefix}-${Date.now().toString(36)}-${Math.random()
    .toString(36)
    .slice(2, 10)}`;

export const generateFillStrokeKey = () => generateRandomToken('fill');

export const generateClearStrokeKey = () => generateRandomToken('clear');

const buildEyedropperLayerOrder = (
  layerOrder: string[] | null,
  referenceParts: Record<string, string[][]> | null,
  layerPartsWithDrafts: Record<string, string[][]> | null,
  layerParts: Record<string, string[][]> | null
): string[] => {
  const order: string[] = [];
  const seen: Record<string, boolean> = {};
  const push = (key?: string | null) => {
    if (!key || seen[key]) {
      return;
    }
    seen[key] = true;
    order.push(key);
  };
  push(GENERIC_PART_KEY);
  if (Array.isArray(layerOrder)) {
    for (const key of layerOrder) {
      push(key);
    }
  }
  if (referenceParts) {
    for (const key of Object.keys(referenceParts)) {
      push(key);
    }
  }
  if (layerPartsWithDrafts) {
    for (const key of Object.keys(layerPartsWithDrafts)) {
      push(key);
    }
  } else if (layerParts) {
    for (const key of Object.keys(layerParts)) {
      push(key);
    }
  }
  return order;
};

export const createCanvasSamplingHelpers = (
  options: CanvasSamplingOptions
): CanvasSamplingHelpers => {
  const sampleCurrentPixelColor = (x: number, y: number): string | null => {
    if (
      options.draftPixelLookup &&
      Object.prototype.hasOwnProperty.call(
        options.draftPixelLookup,
        getDraftPixelKey(x, y)
      )
    ) {
      const pending = options.draftPixelLookup[getDraftPixelKey(x, y)];
      return pending || null;
    }
    return sampleGridColorAt(options.uiCanvasGrid, x, y);
  };

  const sampleReferencePixelColor = (x: number, y: number): string | null =>
    resolveReferencePixelColor(
      options.referenceParts,
      options.activePartKey,
      GENERIC_PART_KEY,
      options.referenceGrid,
      x,
      y
    );

  const sampleActiveLayerPixelColor = (x: number, y: number): string | null => {
    const activeLayerGrid =
      (options.layerPartsWithDrafts &&
        options.layerPartsWithDrafts[options.activePartKey]) ||
      (options.layerParts && options.layerParts[options.activePartKey]);
    if (!activeLayerGrid) {
      return null;
    }
    return sampleGridColorAt(activeLayerGrid, x, y);
  };

  const sampleOverlayPixelColor = (x: number, y: number): string | null => {
    const orderedLayers = buildEyedropperLayerOrder(
      options.layerOrder,
      options.referenceParts,
      options.layerPartsWithDrafts,
      options.layerParts
    );
    for (const partId of orderedLayers) {
      if (!partId || partId === options.activePartKey) {
        continue;
      }
      if (partId === GENERIC_PART_KEY) {
        const genericReference =
          (options.referenceParts &&
            options.referenceParts[GENERIC_PART_KEY]) ||
          options.referenceGrid;
        const genericColor = sampleGridColorAt(genericReference, x, y);
        if (genericColor) {
          return genericColor;
        }
        const genericLayer =
          (options.layerPartsWithDrafts &&
            options.layerPartsWithDrafts[GENERIC_PART_KEY]) ||
          (options.layerParts && options.layerParts[GENERIC_PART_KEY]);
        if (genericLayer) {
          const layerColor = sampleGridColorAt(genericLayer, x, y);
          if (layerColor) {
            return layerColor;
          }
        }
        continue;
      }
      const referenceColor = sampleGridColorAt(
        options.referenceParts && options.referenceParts[partId],
        x,
        y
      );
      if (referenceColor) {
        return referenceColor;
      }
      const layerMap =
        (options.layerPartsWithDrafts &&
          options.layerPartsWithDrafts[partId]) ||
        (options.layerParts && options.layerParts[partId]);
      if (layerMap) {
        const layerColor = sampleGridColorAt(layerMap, x, y);
        if (layerColor) {
          return layerColor;
        }
      }
    }
    return null;
  };

  const sampleEyedropperPixelColor = (x: number, y: number): string | null =>
    sampleCurrentPixelColor(x, y) ||
    sampleReferencePixelColor(x, y) ||
    sampleActiveLayerPixelColor(x, y) ||
    sampleOverlayPixelColor(x, y);

  const decoratePreviewPixels = (pixels: DiffEntry[]) =>
    resolvePreviewStrokePixels({
      pixels,
      brushHex: options.brushColor,
      blendMode: options.currentBlendMode,
      strength: options.analogStrength,
      grid: options.uiCanvasGrid,
      referenceParts: options.referenceParts,
      referenceGrid: options.referenceGrid,
      activePartKey: options.activePartKey,
      genericPartKey: GENERIC_PART_KEY,
      pendingPixelLookup: options.draftPixelLookup || undefined,
    });

  const buildFillPreviewDiff = (
    startX: number,
    startY: number
  ): DiffEntry[] => {
    if (
      !isValidCanvasPoint(
        startX,
        startY,
        options.canvasWidth,
        options.canvasHeight
      )
    ) {
      return [];
    }
    const startColor = sampleCurrentPixelColor(startX, startY);
    const queue: Array<[number, number]> = [[startX, startY]];
    const visited = new Set<string>();
    const rawPixels: DiffEntry[] = [];
    while (queue.length) {
      const [cx, cy] = queue.shift() as [number, number];
      const key = getDraftPixelKey(cx, cy);
      if (visited.has(key)) {
        continue;
      }
      visited.add(key);
      const currentColor = sampleCurrentPixelColor(cx, cy);
      if (currentColor !== startColor) {
        continue;
      }
      rawPixels.push({
        x: cx,
        y: cy,
        color: options.brushColor,
      });
      const neighbors: Array<[number, number]> = [
        [cx - 1, cy],
        [cx + 1, cy],
        [cx, cy - 1],
        [cx, cy + 1],
      ];
      for (const [nx, ny] of neighbors) {
        if (
          !isValidCanvasPoint(nx, ny, options.canvasWidth, options.canvasHeight)
        ) {
          continue;
        }
        queue.push([nx, ny]);
      }
    }
    if (!rawPixels.length) {
      return [];
    }
    const resolvedPixels = decoratePreviewPixels(rawPixels);
    if (!resolvedPixels.length) {
      return [];
    }
    const startResolved =
      resolvedPixels.find(
        (entry) => entry.x === startX && entry.y === startY
      ) || resolvedPixels[0];
    const nextStartColor = normalizeDiffColor(startResolved?.color);
    if (nextStartColor === startColor) {
      return [];
    }
    const changedPixels = resolvedPixels.filter((entry) => {
      const prevColor = sampleCurrentPixelColor(entry.x, entry.y);
      const nextColor = normalizeDiffColor(entry.color);
      return nextColor !== prevColor;
    });
    return changedPixels;
  };

  const buildClearPreviewDiff = (): DiffEntry[] => {
    const diff: DiffEntry[] = [];
    for (let x = 1; x <= options.canvasWidth; x += 1) {
      for (let y = 1; y <= options.canvasHeight; y += 1) {
        const current = sampleCurrentPixelColor(x, y);
        if (!current) {
          continue;
        }
        diff.push({
          x,
          y,
          color: TRANSPARENT_HEX,
        });
      }
    }
    return diff;
  };

  return {
    decoratePreviewPixels,
    buildFillPreviewDiff,
    buildClearPreviewDiff,
    sampleEyedropperPixelColor,
    sampleCurrentPixelColor,
  };
};
