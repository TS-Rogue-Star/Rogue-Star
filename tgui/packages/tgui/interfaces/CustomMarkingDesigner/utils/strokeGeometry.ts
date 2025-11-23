// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Stroke geometry helpers for custom marking designer //
// ////////////////////////////////////////////////////////////////////////////////////////////////////

import type { DiffEntry } from '../../../utils/character-preview';

export const normalizeStrokeKey = (stroke: unknown): string | null => {
  if (stroke === null || stroke === undefined) {
    return null;
  }
  const value = String(stroke).trim();
  return value.length ? value : null;
};

export const mergeStrokePixels = (
  existing: DiffEntry[] | undefined,
  additions: DiffEntry[]
): DiffEntry[] => {
  const map = new Map<string, DiffEntry>();
  if (Array.isArray(existing)) {
    for (const pixel of existing) {
      if (!pixel) {
        continue;
      }
      const key = `${pixel.x}-${pixel.y}`;
      map.set(key, pixel);
    }
  }
  for (const pixel of additions) {
    if (!pixel) {
      continue;
    }
    const key = `${pixel.x}-${pixel.y}`;
    map.set(key, pixel);
  }
  return Array.from(map.values());
};

export const arePixelListsEqual = (
  a?: DiffEntry[],
  b?: DiffEntry[]
): boolean => {
  if (!a && !b) {
    return true;
  }
  if (!a || !b) {
    return false;
  }
  if (a.length !== b.length) {
    return false;
  }
  for (let i = 0; i < a.length; i += 1) {
    const left = a[i];
    const right = b[i];
    if (!left || !right) {
      return false;
    }
    if (
      left.x !== right.x ||
      left.y !== right.y ||
      left.color !== right.color
    ) {
      return false;
    }
  }
  return true;
};

export const uiToServerY = (uiY: number, height: number): number =>
  height - uiY + 1;

export const serverToUiY = (serverY: number, height: number): number =>
  height - serverY + 1;

export const buildBrushPixels = (
  x: number,
  y: number,
  size: number,
  color: string,
  width: number,
  height: number
): DiffEntry[] => {
  const clampedSize = Math.max(1, Math.floor(size || 1));
  const offset = Math.floor((clampedSize - 1) / 2);
  const startX = x - offset;
  let startYServer = uiToServerY(y, height) - offset;
  if (clampedSize % 2 === 0) {
    startYServer -= 1;
  }
  const pixels: DiffEntry[] = [];
  for (let dx = 0; dx < clampedSize; dx += 1) {
    const px = startX + dx;
    if (px < 1 || px > width) {
      continue;
    }
    for (let dy = 0; dy < clampedSize; dy += 1) {
      const serverY = startYServer + dy;
      const py = serverToUiY(serverY, height);
      if (py < 1 || py > height) {
        continue;
      }
      pixels.push({ x: px, y: py, color });
    }
  }
  if (!pixels.length && x >= 1 && x <= width && y >= 1 && y <= height) {
    pixels.push({ x, y, color });
  }
  return pixels;
};

export const buildLinePixels = (
  x1: number,
  y1: number,
  x2: number,
  y2: number,
  size: number,
  color: string,
  width: number,
  height: number
): DiffEntry[] => {
  const pixels: DiffEntry[] = [];
  forEachLinePoint(x1, y1, x2, y2, (px, py) => {
    pixels.push(...buildBrushPixels(px, py, size, color, width, height));
  });
  return pixels;
};

export const forEachLinePoint = (
  x1: number,
  y1: number,
  x2: number,
  y2: number,
  plot: (x: number, y: number) => void
) => {
  let dx = Math.abs(x2 - x1);
  let dy = Math.abs(y2 - y1);
  const sx = x1 < x2 ? 1 : -1;
  const sy = y1 < y2 ? 1 : -1;
  let err = dx - dy;
  let cx = x1;
  let cy = y1;
  while (true) {
    plot(cx, cy);
    if (cx === x2 && cy === y2) {
      break;
    }
    const e2 = err * 2;
    if (e2 > -dy) {
      err -= dy;
      cx += sx;
    }
    if (e2 < dx) {
      err += dx;
      cy += sy;
    }
  }
};

export const isValidCanvasPoint = (
  x: number,
  y: number,
  width: number,
  height: number
): boolean =>
  Number.isFinite(x) &&
  Number.isFinite(y) &&
  x >= 1 &&
  x <= width &&
  y >= 1 &&
  y <= height;
