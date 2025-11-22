// ///////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Paint handler builders for custom marking designer //
// ///////////////////////////////////////////////////////////////////////////////////////////////////

import { buildBrushPixels, buildLinePixels, isValidCanvasPoint, normalizeStrokeKey } from './index';
import type { DiffEntry } from '../../../utils/character-preview';

type PaintHandlerOptions = {
  canvasWidth: number;
  canvasHeight: number;
  size: number;
  previewColorForBlend: string;
  isBrushTool: boolean;
  appendStrokePreviewPixels: (stroke: unknown, pixels: DiffEntry[]) => void;
  decoratePreviewPixels: (pixels: DiffEntry[]) => DiffEntry[];
  buildFillPreviewDiff: (x: number, y: number) => DiffEntry[];
  buildClearPreviewDiff: () => DiffEntry[];
  sampleEyedropperPixelColor: (x: number, y: number) => string | null;
  applyBrushColorChange: (hex: string) => Promise<void>;
  generateFillStrokeKey: () => string;
  generateClearStrokeKey: () => string;
};

export type PaintHandlers = {
  onPaint: ({
    x,
    y,
    stroke,
    brushSize,
  }: {
    x: number;
    y: number;
    stroke: unknown;
    brushSize: number;
  }) => void;
  onLine: ({
    x1,
    y1,
    x2,
    y2,
    stroke,
    brushSize,
  }: {
    x1: number;
    y1: number;
    x2: number;
    y2: number;
    stroke: unknown;
    brushSize: number;
  }) => void;
  onFill: ({ x, y }: { x: number; y: number }) => void;
  onEyedropper: ({ x, y }: { x: number; y: number }) => Promise<void>;
  queueCanvasClearPreview: () => boolean;
};

export const createPaintHandlers = (
  options: PaintHandlerOptions
): PaintHandlers => {
  const queueBrushStampPreview = (
    stroke: unknown,
    x: number,
    y: number,
    brushSize?: number
  ) => {
    if (!options.isBrushTool) {
      return;
    }
    const strokeKey = normalizeStrokeKey(stroke);
    if (!strokeKey) {
      return;
    }
    const pixels = buildBrushPixels(
      x,
      y,
      brushSize || options.size,
      options.previewColorForBlend,
      options.canvasWidth,
      options.canvasHeight
    );
    const resolvedPixels = options.decoratePreviewPixels(pixels);
    if (!resolvedPixels.length) {
      return;
    }
    options.appendStrokePreviewPixels(strokeKey, resolvedPixels);
  };

  const queueBrushLinePreview = (
    stroke: unknown,
    x1: number,
    y1: number,
    x2: number,
    y2: number,
    brushSize?: number
  ) => {
    if (!options.isBrushTool) {
      return;
    }
    const strokeKey = normalizeStrokeKey(stroke);
    if (!strokeKey) {
      return;
    }
    const pixels = buildLinePixels(
      x1,
      y1,
      x2,
      y2,
      brushSize || options.size,
      options.previewColorForBlend,
      options.canvasWidth,
      options.canvasHeight
    );
    const resolvedPixels = options.decoratePreviewPixels(pixels);
    if (!resolvedPixels.length) {
      return;
    }
    options.appendStrokePreviewPixels(strokeKey, resolvedPixels);
  };

  const onPaint = ({ x, y, stroke, brushSize }) => {
    const brushFootprint = Math.max(
      1,
      Math.floor(brushSize || options.size || 1)
    );
    if (
      !isValidCanvasPoint(x, y, options.canvasWidth, options.canvasHeight) ||
      brushFootprint <= 0
    ) {
      return;
    }
    queueBrushStampPreview(stroke, x, y, brushFootprint);
  };

  const onLine = ({ x1, y1, x2, y2, stroke, brushSize }) => {
    if (stroke !== undefined && stroke !== null) {
      queueBrushLinePreview(stroke, x1, y1, x2, y2, brushSize);
    }
  };

  const onFill = ({ x, y }: { x: number; y: number }) => {
    if (!isValidCanvasPoint(x, y, options.canvasWidth, options.canvasHeight)) {
      return;
    }
    const diff = options.buildFillPreviewDiff(x, y);
    if (!diff.length) {
      return;
    }
    const strokeKey = options.generateFillStrokeKey();
    options.appendStrokePreviewPixels(strokeKey, diff);
  };

  const onEyedropper = async ({ x, y }: { x: number; y: number }) => {
    if (!isValidCanvasPoint(x, y, options.canvasWidth, options.canvasHeight)) {
      return;
    }
    const sampled = options.sampleEyedropperPixelColor(x, y);
    if (!sampled) {
      return;
    }
    await options.applyBrushColorChange(sampled);
  };

  const queueCanvasClearPreview = () => {
    const diff = options.buildClearPreviewDiff();
    if (!diff.length) {
      return false;
    }
    const strokeKey = options.generateClearStrokeKey();
    options.appendStrokePreviewPixels(strokeKey, diff);
    return true;
  };

  return {
    onPaint,
    onLine,
    onFill,
    onEyedropper,
    queueCanvasClearPreview,
  };
};
