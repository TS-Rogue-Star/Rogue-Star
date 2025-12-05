// /////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Direction preview canvas for custom marking designer //
// /////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Updated to support 64x64 markings /////////////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support loaout and job gear ////////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////////

import { Component, createRef } from 'inferno';
import { Box } from '../../../components';
import type { PreviewLayerEntry } from '../../../utils/character-preview';
import { CANVAS_FIT_TARGET } from '../constants';

const FULL_GRID_FIT_TARGET = CANVAS_FIT_TARGET * 2;

export type DirectionPreviewCanvasProps = {
  readonly layers?: PreviewLayerEntry[];
  readonly pixelSize: number;
  readonly width: number;
  readonly height: number;
  readonly fitToFrame?: boolean;
  readonly backgroundImage?: string | null;
  readonly backgroundColor?: string;
  readonly backgroundScale?: number;
  readonly backgroundTileWidth?: number;
  readonly backgroundTileHeight?: number;
};

export class DirectionPreviewCanvas extends Component<DirectionPreviewCanvasProps> {
  private canvasRef = createRef<HTMLCanvasElement>();
  private bgCache: {
    src: string;
    scale: number;
    color: string;
    width: number;
    height: number;
    canvas: HTMLCanvasElement;
    image?: HTMLImageElement;
  } | null = null;

  componentDidMount() {
    this.draw();
  }

  componentDidUpdate(prevProps: DirectionPreviewCanvasProps) {
    if (
      prevProps.layers !== this.props.layers ||
      prevProps.pixelSize !== this.props.pixelSize ||
      prevProps.width !== this.props.width ||
      prevProps.height !== this.props.height ||
      prevProps.fitToFrame !== this.props.fitToFrame ||
      prevProps.backgroundImage !== this.props.backgroundImage ||
      prevProps.backgroundColor !== this.props.backgroundColor ||
      prevProps.backgroundScale !== this.props.backgroundScale ||
      prevProps.backgroundTileWidth !== this.props.backgroundTileWidth ||
      prevProps.backgroundTileHeight !== this.props.backgroundTileHeight
    ) {
      this.draw();
    }
  }

  draw() {
    const canvas = this.canvasRef.current;
    if (!canvas) {
      return;
    }
    const ctx = canvas.getContext('2d');
    if (!ctx) {
      return;
    }
    const pixelSize = Math.max(1, this.props.pixelSize || 1);
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.imageSmoothingEnabled = false;
    const layers = Array.isArray(this.props.layers) ? this.props.layers : [];
    this.drawBackground(ctx, layers, pixelSize, canvas);
  }

  drawLayers(
    ctx: CanvasRenderingContext2D,
    layers: PreviewLayerEntry[],
    pixelSize: number
  ) {
    for (const layer of layers) {
      const opacity =
        typeof layer?.opacity === 'number'
          ? Math.max(0, Math.min(1, layer.opacity))
          : 1;
      this.drawLayer(ctx, layer?.grid, pixelSize, opacity);
    }
  }

  drawLayer(
    ctx: CanvasRenderingContext2D,
    grid?: string[][],
    pixelSize?: number,
    opacity?: number
  ) {
    if (!Array.isArray(grid) || !pixelSize) {
      return;
    }
    const alpha = typeof opacity === 'number' ? opacity : 1;
    const restoreAlpha = ctx.globalAlpha;
    ctx.globalAlpha = alpha;
    for (let x = 0; x < grid.length; x++) {
      const column = grid[x];
      if (!Array.isArray(column)) {
        continue;
      }
      for (let y = 0; y < column.length; y++) {
        const color = column[y];
        if (!color || color === '#00000000') {
          continue;
        }
        ctx.fillStyle = color;
        ctx.fillRect(x * pixelSize, y * pixelSize, pixelSize, pixelSize);
      }
    }
    ctx.globalAlpha = restoreAlpha;
  }

  drawBackground(
    ctx: CanvasRenderingContext2D,
    layers: PreviewLayerEntry[],
    pixelSize: number,
    canvas: HTMLCanvasElement
  ) {
    const bgImage = this.props.backgroundImage || null;
    const bgColor = this.props.backgroundColor || 'rgba(0,0,0,0)';
    const bgScale =
      Number.isFinite(this.props.backgroundScale || 0) &&
      (this.props.backgroundScale as number) > 0
        ? (this.props.backgroundScale as number)
        : 1;
    const cacheKeyMatch =
      this.bgCache &&
      this.bgCache.src === (bgImage || '') &&
      this.bgCache.scale === bgScale &&
      this.bgCache.color === bgColor &&
      this.bgCache.width === canvas.width &&
      this.bgCache.height === canvas.height;

    if (cacheKeyMatch && this.bgCache?.canvas) {
      ctx.drawImage(this.bgCache.canvas, 0, 0);
      this.drawLayers(ctx, layers, pixelSize);
      return;
    }

    const buffer = document.createElement('canvas');
    buffer.width = canvas.width;
    buffer.height = canvas.height;
    const bctx = buffer.getContext('2d');
    if (!bctx) {
      this.drawLayers(ctx, layers, pixelSize);
      return;
    }
    bctx.fillStyle = bgColor;
    bctx.fillRect(0, 0, buffer.width, buffer.height);

    const drawAndCache = (bgImg?: HTMLImageElement) => {
      ctx.drawImage(buffer, 0, 0);
      this.drawLayers(ctx, layers, pixelSize);
      this.bgCache = {
        src: bgImage || '',
        scale: bgScale,
        color: bgColor,
        width: canvas.width,
        height: canvas.height,
        canvas: buffer,
        image: bgImg,
      };
    };

    if (bgImage) {
      const bgImageElement = new Image();
      bgImageElement.onload = () => {
        const pattern = bctx.createPattern(bgImageElement, 'repeat');
        if (pattern) {
          bctx.save();
          if (bgScale !== 1) {
            bctx.scale(bgScale, bgScale);
          }
          bctx.fillStyle = pattern;
          bctx.fillRect(0, 0, buffer.width / bgScale, buffer.height / bgScale);
          bctx.restore();
        }
        drawAndCache(bgImageElement);
      };
      bgImageElement.onerror = () => {
        drawAndCache();
      };
      bgImageElement.crossOrigin = 'anonymous';
      bgImageElement.src = bgImage;
      return;
    }

    drawAndCache();
  }

  render() {
    const {
      layers,
      pixelSize,
      width,
      height,
      fitToFrame,
      backgroundImage,
      backgroundColor,
      backgroundScale,
      backgroundTileWidth,
      backgroundTileHeight,
    } = this.props;
    const fallbackWidth = Math.max(1, width || 1);
    const fallbackHeight = Math.max(1, height || 1);
    const layerWidths = Array.isArray(layers)
      ? layers
          .map((layer) => (Array.isArray(layer?.grid) ? layer.grid.length : 0))
          .filter((value) => typeof value === 'number' && value > 0)
      : [];
    const layerHeights = Array.isArray(layers)
      ? layers
          .map((layer) => {
            const grid = layer?.grid;
            if (!Array.isArray(grid)) {
              return 0;
            }
            let maxHeight = 0;
            for (const column of grid) {
              if (Array.isArray(column) && column.length > maxHeight) {
                maxHeight = column.length;
              }
            }
            return maxHeight;
          })
          .filter((value) => typeof value === 'number' && value > 0)
      : [];
    const gridWidth = layerWidths.length
      ? Math.max(fallbackWidth, ...layerWidths)
      : fallbackWidth;
    const gridHeight = layerHeights.length
      ? Math.max(fallbackHeight, ...layerHeights)
      : fallbackHeight;
    const size = Math.max(1, pixelSize);
    const canvasWidth = gridWidth * size;
    const canvasHeight = gridHeight * size;
    const clampedFitWidth = fitToFrame
      ? Math.min(canvasWidth, FULL_GRID_FIT_TARGET * size)
      : canvasWidth;
    const clampedFitHeight = fitToFrame
      ? Math.min(canvasHeight, FULL_GRID_FIT_TARGET * size)
      : canvasHeight;
    const cropWidthUnits = Math.min(CANVAS_FIT_TARGET, gridWidth);
    const cropHeightUnits = Math.min(CANVAS_FIT_TARGET, gridHeight);
    const cropWidth = cropWidthUnits * size;
    const cropHeight = cropHeightUnits * size;
    const displayScale =
      fitToFrame && canvasWidth > 0 && canvasHeight > 0
        ? Math.min(
            cropWidth / clampedFitWidth,
            cropHeight / clampedFitHeight,
            1
          )
        : 1;
    const scaledCanvasWidth = canvasWidth * displayScale;
    const scaledCanvasHeight = canvasHeight * displayScale;
    const offsetLeft = (cropWidth - scaledCanvasWidth) / 2;
    const offsetTop = cropHeight - scaledCanvasHeight;
    return (
      <Box textAlign="center" className="RogueStar__previewCanvas">
        <Box
          className="RogueStar__previewCanvasFrame"
          style={{
            width: `${cropWidth}px`,
            height: `${cropHeight}px`,
            margin: '0 auto',
            position: 'relative',
            backgroundColor: backgroundColor || 'rgba(18, 10, 32, 0.6)',
            backgroundImage: backgroundImage
              ? `url(${backgroundImage})`
              : undefined,
            backgroundRepeat: backgroundImage ? 'repeat' : undefined,
            backgroundPosition: 'center center',
            backgroundSize:
              backgroundImage && backgroundTileWidth && backgroundTileHeight
                ? `${Math.max(1, backgroundTileWidth * (backgroundScale || 1))}px ${Math.max(1, backgroundTileHeight * (backgroundScale || 1))}px`
                : undefined,
          }}>
          <canvas
            ref={this.canvasRef}
            width={canvasWidth}
            height={canvasHeight}
            style={{
              imageRendering: 'pixelated',
              position: 'absolute',
              left: `${offsetLeft}px`,
              top: `${offsetTop}px`,
              width: `${scaledCanvasWidth}px`,
              height: `${scaledCanvasHeight}px`,
            }}
          />
        </Box>
      </Box>
    );
  }
}
