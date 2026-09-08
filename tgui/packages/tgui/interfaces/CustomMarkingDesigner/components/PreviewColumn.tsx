// /////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Preview column component for custom marking designer //
// /////////////////////////////////////////////////////////////////////////////////////////////////////

import { Box, Flex } from '../../../components';
import { PREVIEW_PIXEL_SIZE } from '../constants';
import type { CanvasBackgroundOption } from '../types';
import { DirectionPreviewCanvas } from './DirectionPreviewCanvas';

type PreviewColumnProps = Readonly<{
  renderedPreviewDirs: ReadonlyArray<any>;
  previewRevision: number;
  previewFitToFrame: boolean;
  canvasWidth: number;
  canvasHeight: number;
  resolvedCanvasBackground: CanvasBackgroundOption | null;
  backgroundFallbackColor: string;
  canvasBackgroundScale: number;
}>;

export const PreviewColumn = ({
  renderedPreviewDirs,
  previewRevision: _previewRevision,
  previewFitToFrame,
  canvasWidth,
  canvasHeight,
  resolvedCanvasBackground,
  backgroundFallbackColor,
  canvasBackgroundScale,
}: PreviewColumnProps) => {
  if (!renderedPreviewDirs.length) {
    return null;
  }
  return (
    <Flex.Item basis="280px" grow={0} shrink={0}>
      <Box className="RogueStar__previewCard" height="100%">
        <Box
          color="label"
          fontWeight="bold"
          mb={1}
          className="RogueStar__previewTitle RogueStar__previewTitle--center">
          Live Preview
        </Box>
        <Box className="RogueStar__previewList">
          {renderedPreviewDirs.map((entry) => (
            <Box
              key={`${entry.dir}-${previewFitToFrame ? 'fit' : 'crop'}`}
              className="RogueStar__previewItem">
              <DirectionPreviewCanvas
                layers={entry.layers}
                pixelSize={Math.max(1, PREVIEW_PIXEL_SIZE)}
                width={canvasWidth}
                height={canvasHeight}
                fitToFrame={previewFitToFrame}
                backgroundImage={
                  resolvedCanvasBackground?.asset?.png
                    ? `data:image/png;base64,${resolvedCanvasBackground.asset.png}`
                    : null
                }
                backgroundColor={backgroundFallbackColor}
                backgroundScale={canvasBackgroundScale}
                backgroundTileWidth={
                  resolvedCanvasBackground?.asset?.width
                    ? resolvedCanvasBackground.asset.width *
                      canvasBackgroundScale
                    : undefined
                }
                backgroundTileHeight={
                  resolvedCanvasBackground?.asset?.height
                    ? resolvedCanvasBackground.asset.height *
                      canvasBackgroundScale
                    : undefined
                }
              />
            </Box>
          ))}
        </Box>
      </Box>
    </Flex.Item>
  );
};
