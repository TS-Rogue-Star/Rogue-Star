// /////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Canvas section component for custom marking designer //
// /////////////////////////////////////////////////////////////////////////////////////////////////////

import { Box, Flex, Section } from '../../../components';
import { PaintCanvas } from '../../Canvas';
import { CANVAS_FIT_TARGET, PLACEHOLDER_TOOL } from '../constants';
import type { StrokeDraftState } from '../types';
import { CanvasToolbar, type CanvasToolbarProps } from './CanvasToolbar';

export type CanvasHandlers = Readonly<{
  onFill: (payload: any) => void;
  onEyedropper: (payload: any) => void;
  onPaint: (payload: any) => void;
  onLine: (payload: any) => void;
  resolveCanvasTool: (toolUsed: string | null, button: number) => any;
  handleUndo: () => void;
  handleDiffApplied: (stroke?: unknown) => void;
}>;

export type CanvasSectionProps = Readonly<{
  title: string;
  canvasFrameStyle: Record<string, any>;
  canvasBackgroundStyle?: Record<string, any> | null;
  canvasTransform: string;
  canvasKey: string;
  backgroundImage: string | null;
  backgroundFallbackColor: string;
  canvasDisplayWidthPx: number;
  canvasDisplayHeightPx: number;
  canvasPixelSize: number;
  canvasToolbarProps: CanvasToolbarProps;
  referenceGrid: any;
  referenceParts: any;
  currentReferenceOpacity: number;
  resolvedReferenceOpacityMap: Record<string, number>;
  referenceSignature?: string;
  overlayLayerParts: any;
  overlayLayerOrder: any;
  layerRevision: number;
  uiCanvasGrid: any;
  serverDiffPayload: any;
  serverDiffSeq?: number;
  serverDiffStroke: unknown;
  activePartKey: string;
  genericReferenceOpacity: number;
  activePrimaryTool: string | null;
  activeSecondaryTool: string | null;
  size: number;
  brushColor: string;
  strokeDraftState: StrokeDraftState;
  strokeDraftSession: string;
  canvasFlushToken: number;
  canvasHandlers: CanvasHandlers;
  resolveToolForButton: (button: number) => string | null;
}>;

export const CanvasSection = ({
  title,
  canvasFrameStyle,
  canvasBackgroundStyle,
  canvasTransform,
  canvasKey,
  backgroundImage,
  backgroundFallbackColor,
  canvasDisplayWidthPx,
  canvasDisplayHeightPx,
  canvasPixelSize,
  canvasToolbarProps,
  referenceGrid,
  referenceParts,
  currentReferenceOpacity,
  resolvedReferenceOpacityMap,
  referenceSignature,
  overlayLayerParts,
  overlayLayerOrder,
  layerRevision,
  uiCanvasGrid,
  serverDiffPayload,
  serverDiffSeq,
  serverDiffStroke,
  activePartKey,
  genericReferenceOpacity,
  activePrimaryTool,
  activeSecondaryTool,
  size,
  brushColor,
  strokeDraftState,
  strokeDraftSession,
  canvasFlushToken,
  canvasHandlers,
  resolveToolForButton,
}: CanvasSectionProps) => {
  const {
    onFill,
    onEyedropper,
    onPaint,
    onLine,
    resolveCanvasTool,
    handleUndo,
    handleDiffApplied,
  } = canvasHandlers;

  const resolveInteractionTool = (toolUsed: string | null, button: number) =>
    resolveCanvasTool(toolUsed, button);

  const handleCanvasClick = (
    x: number,
    y: number,
    brushSize: number,
    stroke: unknown,
    toolUsed: string | null,
    button: number
  ) => {
    const resolvedTool = resolveInteractionTool(toolUsed, button);
    if (resolvedTool === 'fill') {
      return onFill({ x, y, tool: resolvedTool });
    }
    if (resolvedTool === 'eyedropper') {
      return onEyedropper({ x, y, tool: resolvedTool });
    }
    return onPaint({
      x,
      y,
      brushSize,
      stroke,
      tool: resolvedTool,
    });
  };

  const handleCanvasLine = (
    x1: number,
    y1: number,
    x2: number,
    y2: number,
    brushSize: number,
    stroke: unknown,
    toolUsed: string | null,
    button: number
  ) =>
    onLine({
      x1,
      y1,
      x2,
      y2,
      brushSize,
      stroke,
      tool: resolveInteractionTool(toolUsed, button),
    });

  const handleCanvasFill = (
    x: number,
    y: number,
    toolUsed: string | null,
    button: number
  ) =>
    onFill({
      x,
      y,
      tool: resolveInteractionTool(toolUsed, button),
    });

  const handleEyedropper = (
    x: number,
    y: number,
    toolUsed: string | null,
    button: number
  ) =>
    onEyedropper({
      x,
      y,
      tool: resolveInteractionTool(toolUsed, button),
    });

  return (
    <Flex.Item grow basis="0">
      <Section title={title} fill>
        <Box className="RogueStar__canvasScroll" height="100%">
          <CanvasToolbar {...canvasToolbarProps} />
          <Box className="RogueStar__canvasFrame" style={canvasFrameStyle}>
            <Box
              style={{
                position: 'absolute',
                inset: 0,
                zIndex: 0,
                ...(canvasBackgroundStyle || {}),
              }}
            />
            <PaintCanvas
              key={canvasKey}
              value={uiCanvasGrid || []}
              reference={referenceGrid}
              referenceParts={referenceParts}
              referenceSignature={referenceSignature}
              referenceOpacity={
                referenceGrid ? currentReferenceOpacity : undefined
              }
              referenceOpacityMap={resolvedReferenceOpacityMap}
              layerParts={overlayLayerParts}
              layerOrder={overlayLayerOrder}
              layerRevision={layerRevision}
              backgroundImage={backgroundImage}
              backgroundColor={backgroundFallbackColor}
              diff={serverDiffPayload}
              diffSeq={serverDiffSeq}
              diffStroke={serverDiffStroke}
              activeLayerKey={activePartKey}
              otherLayerOpacity={genericReferenceOpacity}
              dotsize={canvasPixelSize}
              legacyGridGuideSize={CANVAS_FIT_TARGET}
              tool={activePrimaryTool ? activePrimaryTool : PLACEHOLDER_TOOL}
              secondaryTool={activeSecondaryTool || undefined}
              resolveToolForButton={(button) => resolveToolForButton(button)}
              size={size}
              previewColor={brushColor}
              finalized={false}
              allowUndoShortcut
              style={{
                position: 'relative',
                zIndex: 1,
                width: `${canvasDisplayWidthPx}px`,
                height: `${canvasDisplayHeightPx}px`,
                transform: canvasTransform,
                transformOrigin: 'top left',
                backgroundColor: 'transparent',
              }}
              onUndo={() => handleUndo()}
              onCanvasClick={(x, y, brushSize, stroke, toolUsed, button) =>
                handleCanvasClick(x, y, brushSize, stroke, toolUsed, button)
              }
              onCanvasLine={(
                x1,
                y1,
                x2,
                y2,
                brushSize,
                stroke,
                toolUsed,
                button
              ) =>
                handleCanvasLine(
                  x1,
                  y1,
                  x2,
                  y2,
                  brushSize,
                  stroke,
                  toolUsed,
                  button
                )
              }
              onCanvasFill={(x, y, toolUsed, button) =>
                handleCanvasFill(x, y, toolUsed, button)
              }
              onEyedropper={(x, y, toolUsed, button) =>
                handleEyedropper(x, y, toolUsed, button)
              }
              strokeDrafts={strokeDraftState}
              strokeDraftSession={strokeDraftSession}
              onDiffApplied={handleDiffApplied}
              flushToken={canvasFlushToken}
            />
          </Box>
        </Box>
      </Section>
    </Flex.Item>
  );
};
