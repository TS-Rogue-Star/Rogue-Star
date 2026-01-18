// ///////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Paint handler builders for custom marking designer //
// ///////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Updated to support 64x64 markings ///////////////////
// ///////////////////////////////////////////////////////////////////////////////////////////////////

import {
  buildBrushPixels,
  buildLinePixels,
  isValidCanvasPoint,
  mirrorStrokePixelsHorizontally,
  normalizeStrokeKey,
} from './index';
import type { DiffEntry } from '../../../utils/character-preview';

type PaintToolContext = {
  previewColorForBlend: string;
  isBrushTool: boolean;
  mirrorBrush: boolean;
  blendMode: string;
};

type PaintHandlerOptions = {
  canvasWidth: number;
  canvasHeight: number;
  size: number;
  resolveToolContext: (tool: string) => PaintToolContext;
  appendStrokePreviewPixels: (stroke: unknown, pixels: DiffEntry[]) => void;
  decoratePreviewPixels: (
    pixels: DiffEntry[],
    blendModeOverride?: string
  ) => DiffEntry[];
  buildFillPreviewDiff: (
    x: number,
    y: number,
    blendModeOverride?: string
  ) => DiffEntry[];
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
    tool,
  }: {
    x: number;
    y: number;
    stroke: unknown;
    brushSize: number;
    tool?: string;
  }) => void;
  onLine: ({
    x1,
    y1,
    x2,
    y2,
    stroke,
    brushSize,
    tool,
  }: {
    x1: number;
    y1: number;
    x2: number;
    y2: number;
    stroke: unknown;
    brushSize: number;
    tool?: string;
  }) => void;
  onFill: ({ x, y, tool }: { x: number; y: number; tool?: string }) => void;
  onEyedropper: ({
    x,
    y,
    tool,
  }: {
    x: number;
    y: number;
    tool?: string;
  }) => Promise<void>;
  queueCanvasClearPreview: () => boolean;
};

export const createPaintHandlers = (
  options: PaintHandlerOptions
): PaintHandlers => {
  const queueBrushStampPreview = (
    tool: string,
    stroke: unknown,
    x: number,
    y: number,
    brushSize?: number
  ) => {
    const toolContext = options.resolveToolContext(tool);
    if (!toolContext.isBrushTool) {
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
      toolContext.previewColorForBlend,
      options.canvasWidth,
      options.canvasHeight
    );
    const withMirror = toolContext.mirrorBrush
      ? mirrorStrokePixelsHorizontally(pixels, options.canvasWidth)
      : pixels;
    const resolvedPixels = options.decoratePreviewPixels(
      withMirror,
      toolContext.blendMode
    );
    if (!resolvedPixels.length) {
      return;
    }
    options.appendStrokePreviewPixels(strokeKey, resolvedPixels);
  };

  const queueBrushLinePreview = (
    tool: string,
    stroke: unknown,
    x1: number,
    y1: number,
    x2: number,
    y2: number,
    brushSize?: number
  ) => {
    const toolContext = options.resolveToolContext(tool);
    if (!toolContext.isBrushTool) {
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
      toolContext.previewColorForBlend,
      options.canvasWidth,
      options.canvasHeight
    );
    const withMirror = toolContext.mirrorBrush
      ? mirrorStrokePixelsHorizontally(pixels, options.canvasWidth)
      : pixels;
    const resolvedPixels = options.decoratePreviewPixels(
      withMirror,
      toolContext.blendMode
    );
    if (!resolvedPixels.length) {
      return;
    }
    options.appendStrokePreviewPixels(strokeKey, resolvedPixels);
  };

  const onPaint = ({ x, y, stroke, brushSize, tool }) => {
    const resolvedTool = tool || 'brush';
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
    queueBrushStampPreview(resolvedTool, stroke, x, y, brushFootprint);
  };

  const onLine = ({ x1, y1, x2, y2, stroke, brushSize, tool }) => {
    const resolvedTool = tool || 'brush';
    if (stroke !== undefined && stroke !== null) {
      queueBrushLinePreview(resolvedTool, stroke, x1, y1, x2, y2, brushSize);
    }
  };

  const onFill = ({ x, y, tool }: { x: number; y: number; tool?: string }) => {
    if (!isValidCanvasPoint(x, y, options.canvasWidth, options.canvasHeight)) {
      return;
    }
    const toolContext = options.resolveToolContext(tool || 'brush');
    const diff = options.buildFillPreviewDiff(x, y, toolContext.blendMode);
    if (!diff.length) {
      return;
    }
    const strokeKey = options.generateFillStrokeKey();
    options.appendStrokePreviewPixels(strokeKey, diff);
  };

  const onEyedropper = async ({
    x,
    y,
  }: {
    x: number;
    y: number;
    tool?: string;
  }) => {
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
