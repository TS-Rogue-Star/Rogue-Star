// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Grid conversion helpers for custom marking designer //
// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Updated to support 64x64 markings ////////////////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////

import { TRANSPARENT_HEX } from '../../../utils/color';

export const convertCompositeGridToUi = (
  grid?: (string | null)[][] | null,
  width?: number,
  height?: number
): string[][] | null => {
  if (!Array.isArray(grid) || !grid.length) {
    return null;
  }
  const sourceWidth = grid.length;
  const resolvedWidth = Math.max(1, Number(width) || grid.length);
  let resolvedHeight = Number(height) || 0;
  if (!resolvedHeight) {
    for (const column of grid) {
      if (Array.isArray(column) && column.length > resolvedHeight) {
        resolvedHeight = column.length;
      }
    }
  }
  resolvedHeight = Math.max(1, resolvedHeight);
  const xOffset = Math.max(0, Math.round((resolvedWidth - sourceWidth) / 2));
  const result: string[][] = Array.from({ length: resolvedWidth }, () =>
    Array.from({ length: resolvedHeight }, () => TRANSPARENT_HEX)
  );
  for (let x = 1; x <= resolvedWidth; x += 1) {
    const targetColumn = result[x - 1];
    const sourceX = x - xOffset;
    const sourceColumn =
      sourceX >= 1 && sourceX <= sourceWidth && Array.isArray(grid[sourceX - 1])
        ? grid[sourceX - 1]
        : [];
    for (let y = 1; y <= resolvedHeight; y += 1) {
      const rawColor = sourceColumn[y - 1];
      const normalized =
        typeof rawColor === 'string' && rawColor.length
          ? rawColor
          : TRANSPARENT_HEX;
      const uiY = resolvedHeight - y;
      if (uiY < 0 || uiY >= resolvedHeight) {
        continue;
      }
      targetColumn[uiY] = normalized;
    }
  }
  return result;
};

export const convertCompositeLayerMap = (
  source?: Record<string, (string | null)[][] | null>,
  width?: number,
  height?: number
): Record<string, string[][]> | null => {
  if (!source) {
    return null;
  }
  const entries = Object.entries(source);
  if (!entries.length) {
    return null;
  }
  const result: Record<string, string[][]> = {};
  let hasEntry = false;
  for (const [key, grid] of entries) {
    const converted = convertCompositeGridToUi(grid, width, height);
    if (!converted) {
      continue;
    }
    result[key] = converted;
    hasEntry = true;
  }
  return hasEntry ? result : null;
};
