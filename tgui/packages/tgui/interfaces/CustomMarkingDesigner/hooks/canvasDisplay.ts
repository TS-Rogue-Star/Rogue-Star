// //////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Canvas display sizing helpers for custom marking designer //
// //////////////////////////////////////////////////////////////////////////////////////////////////////////

import { useLocalState } from '../../../backend';
import { CANVAS_FIT_TARGET, DOT_SIZE } from '../constants';
import type { CustomMarkingDesignerData } from '../types';

export type CanvasDisplayState = Readonly<{
  canvasWidth: number;
  canvasHeight: number;
  canvasPixelSize: number;
  canvasDisplayWidthPx: number;
  canvasDisplayHeightPx: number;
  canvasTransform: string;
  canvasFitToFrame: boolean;
  previewFitToFrame: boolean;
  toggleCanvasFit: () => void;
}>;

export const useCanvasDisplayState = (
  context: any,
  stateToken: string,
  data: CustomMarkingDesignerData
): CanvasDisplayState => {
  const maxCanvasWidth = Math.max(1, data.max_width || 64);
  const maxCanvasHeight = Math.max(1, data.max_height || 64);
  const defaultCanvasWidth = Math.max(1, data.default_width || 32);
  const defaultCanvasHeight = Math.max(1, data.default_height || 32);
  const canvasWidth = maxCanvasWidth;
  const canvasHeight = maxCanvasHeight;
  const activeCanvasWidth = Math.min(
    maxCanvasWidth,
    Math.max(1, data.active_canvas_width || data.width || defaultCanvasWidth)
  );
  const activeCanvasHeight = Math.min(
    maxCanvasHeight,
    Math.max(1, data.active_canvas_height || data.height || defaultCanvasHeight)
  );
  const baseDisplayUnits = defaultCanvasWidth || CANVAS_FIT_TARGET;
  const canvasTargetDisplayPx = baseDisplayUnits * DOT_SIZE;
  const canvasFitDefault = false;
  const [canvasFitToFrame, setCanvasFitToFrame] = useLocalState(
    context,
    `canvasFitToFrame-${stateToken}`,
    canvasFitDefault
  );
  const previewFitDefault = false;
  const [previewFitToFrame, setPreviewFitToFrame] = useLocalState(
    context,
    `previewFitToFrame-${stateToken}`,
    previewFitDefault
  );
  const largestCanvasDimension = Math.max(
    canvasWidth,
    canvasHeight,
    activeCanvasWidth,
    activeCanvasHeight
  );
  const canvasPixelSize = Math.max(
    1,
    Math.floor(canvasTargetDisplayPx / Math.max(largestCanvasDimension, 1))
  );
  const canvasDisplayWidthPx = Math.max(
    1,
    Math.round(canvasPixelSize * canvasWidth)
  );
  const canvasDisplayHeightPx = Math.max(
    1,
    Math.round(canvasPixelSize * canvasHeight)
  );
  const canvasZoomScale =
    canvasFitToFrame || canvasWidth <= baseDisplayUnits
      ? 1
      : Math.max(
          canvasWidth / baseDisplayUnits,
          canvasHeight / baseDisplayUnits
        );
  const canvasOffsetY =
    canvasFitToFrame || canvasZoomScale === 1
      ? 0
      : -1 * ((canvasZoomScale - 1) / canvasZoomScale) * canvasDisplayHeightPx +
        1;
  const canvasOffsetX =
    canvasFitToFrame || canvasZoomScale === 1
      ? 0
      : ((1 - canvasZoomScale) * canvasDisplayWidthPx) / (2 * canvasZoomScale) +
        191;
  const canvasTransform = `translate(${canvasOffsetX}px, ${canvasOffsetY}px) scale(${canvasZoomScale})`;
  const toggleCanvasFit = () => {
    const next = !canvasFitToFrame;
    setCanvasFitToFrame(next);
    setPreviewFitToFrame(next);
  };
  return {
    canvasWidth,
    canvasHeight,
    canvasPixelSize,
    canvasDisplayWidthPx,
    canvasDisplayHeightPx,
    canvasTransform,
    canvasFitToFrame,
    previewFitToFrame,
    toggleCanvasFit,
  };
};
