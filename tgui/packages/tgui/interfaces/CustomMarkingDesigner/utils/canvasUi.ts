// //////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Canvas UI helpers for custom marking designer //
// //////////////////////////////////////////////////////////////////////////////////////////////

import type { CanvasBackgroundOption } from '../types';

export const getCanvasFrameStyle = (
  resolvedCanvasBackground: CanvasBackgroundOption | null,
  backgroundFallbackColor: string,
  canvasDisplayWidthPx: number,
  canvasDisplayHeightPx: number
) => ({
  position: 'relative',
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
