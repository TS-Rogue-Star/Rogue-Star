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

type SharedBackgroundCacheEntry = {
  key: string;
  src: string;
  scale: number;
  color: string;
  width: number;
  height: number;
  canvas: HTMLCanvasElement;
  image?: HTMLImageElement;
  ready: boolean;
  listeners: Set<() => void>;
};

const sharedBackgroundCache = new Map<string, SharedBackgroundCacheEntry>();

const buildBackgroundCacheKey = (
  src: string | null,
  scale: number,
  color: string,
  width: number,
  height: number
) => `${src || 'none'}|${scale}|${color}|${width}x${height}`;

export type DirectionPreviewCanvasProps = {
  readonly layers?: PreviewLayerEntry[];
  readonly baseLayers?: PreviewLayerEntry[];
  readonly underlayLayers?: PreviewLayerEntry[];
  readonly overlayLayers?: PreviewLayerEntry[];
  readonly baseSignature?: string;
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
  private baseCache: {
    signature: string;
    layersRef: PreviewLayerEntry[] | null;
    width: number;
    height: number;
    pixelSize: number;
    targetWidth: number;
    targetHeight: number;
    canvas: HTMLCanvasElement;
  } | null = null;
  private handleBackgroundReady = () => {
    this.draw();
  };

  componentDidMount() {
    this.draw();
  }

  componentDidUpdate(prevProps: DirectionPreviewCanvasProps) {
    if (
      prevProps.layers !== this.props.layers ||
      prevProps.baseLayers !== this.props.baseLayers ||
      prevProps.underlayLayers !== this.props.underlayLayers ||
      prevProps.overlayLayers !== this.props.overlayLayers ||
      prevProps.baseSignature !== this.props.baseSignature ||
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
    const targetWidth = Math.max(1, Math.floor(canvas.width / pixelSize));
    const targetHeight = Math.max(1, Math.floor(canvas.height / pixelSize));
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.imageSmoothingEnabled = false;
    const baseLayers = Array.isArray(this.props.baseLayers)
      ? this.props.baseLayers
      : null;
    const underlayLayers = Array.isArray(this.props.underlayLayers)
      ? this.props.underlayLayers
      : [];
    const overlayLayers = Array.isArray(this.props.overlayLayers)
      ? this.props.overlayLayers
      : [];
    const layers = Array.isArray(this.props.layers) ? this.props.layers : [];
    const useLayerGroups =
      baseLayers !== null ||
      underlayLayers.length > 0 ||
      overlayLayers.length > 0;
    if (!useLayerGroups) {
      this.drawBackground(
        ctx,
        layers,
        pixelSize,
        canvas,
        targetWidth,
        targetHeight
      );
      return;
    }
    this.drawBackground(
      ctx,
      [],
      pixelSize,
      canvas,
      targetWidth,
      targetHeight,
      () => {
        if (underlayLayers.length) {
          this.drawLayers(
            ctx,
            underlayLayers,
            pixelSize,
            targetWidth,
            targetHeight
          );
        }
        if (baseLayers && baseLayers.length) {
          this.drawBaseLayers(
            ctx,
            baseLayers,
            pixelSize,
            canvas,
            targetWidth,
            targetHeight,
            this.props.baseSignature
          );
        }
        if (overlayLayers.length) {
          this.drawLayers(
            ctx,
            overlayLayers,
            pixelSize,
            targetWidth,
            targetHeight
          );
        }
      }
    );
  }

  drawLayers(
    ctx: CanvasRenderingContext2D,
    layers: PreviewLayerEntry[],
    pixelSize: number,
    targetWidth: number,
    targetHeight: number
  ) {
    for (const layer of layers) {
      const opacity =
        typeof layer?.opacity === 'number'
          ? Math.max(0, Math.min(1, layer.opacity))
          : 1;
      this.drawLayer(
        ctx,
        layer?.grid,
        pixelSize,
        opacity,
        targetWidth,
        targetHeight
      );
    }
  }

  drawBaseLayers(
    ctx: CanvasRenderingContext2D,
    layers: PreviewLayerEntry[],
    pixelSize: number,
    canvas: HTMLCanvasElement,
    targetWidth: number,
    targetHeight: number,
    signature?: string
  ) {
    if (!layers.length) {
      return;
    }
    const resolvedSignature =
      typeof signature === 'string' && signature.length ? signature : '';
    const useSignature = resolvedSignature.length > 0;
    const shouldRebuild =
      !this.baseCache ||
      this.baseCache.width !== canvas.width ||
      this.baseCache.height !== canvas.height ||
      this.baseCache.pixelSize !== pixelSize ||
      this.baseCache.targetWidth !== targetWidth ||
      this.baseCache.targetHeight !== targetHeight ||
      (useSignature
        ? this.baseCache.signature !== resolvedSignature
        : this.baseCache.layersRef !== layers);
    if (shouldRebuild) {
      const buffer = document.createElement('canvas');
      buffer.width = canvas.width;
      buffer.height = canvas.height;
      const bctx = buffer.getContext('2d');
      if (bctx) {
        bctx.clearRect(0, 0, buffer.width, buffer.height);
        bctx.imageSmoothingEnabled = false;
        this.drawLayers(bctx, layers, pixelSize, targetWidth, targetHeight);
      }
      this.baseCache = {
        signature: resolvedSignature,
        layersRef: useSignature ? null : layers,
        width: canvas.width,
        height: canvas.height,
        pixelSize,
        targetWidth,
        targetHeight,
        canvas: buffer,
      };
    }
    if (this.baseCache?.canvas) {
      ctx.drawImage(this.baseCache.canvas, 0, 0);
    }
  }

  drawLayer(
    ctx: CanvasRenderingContext2D,
    grid?: string[][],
    pixelSize?: number,
    opacity?: number,
    targetWidth?: number,
    targetHeight?: number
  ) {
    if (!Array.isArray(grid) || !pixelSize) {
      return;
    }
    const resolvedTargetWidth =
      typeof targetWidth === 'number' &&
      Number.isFinite(targetWidth) &&
      targetWidth > 0
        ? Math.floor(targetWidth)
        : grid.length;
    const resolvedTargetHeight =
      typeof targetHeight === 'number' &&
      Number.isFinite(targetHeight) &&
      targetHeight > 0
        ? Math.floor(targetHeight)
        : 0;
    let gridHeight = 0;
    for (const column of grid) {
      if (Array.isArray(column) && column.length > gridHeight) {
        gridHeight = column.length;
      }
    }
    const offsetX =
      resolvedTargetWidth > grid.length
        ? Math.round((resolvedTargetWidth - grid.length) / 2)
        : 0;
    const offsetY =
      resolvedTargetHeight > gridHeight ? resolvedTargetHeight - gridHeight : 0;
    const alpha = typeof opacity === 'number' ? opacity : 1;
    const restoreAlpha = ctx.globalAlpha;
    ctx.globalAlpha = alpha;
    for (let x = 0; x < grid.length; x++) {
      const column = grid[x];
      if (!Array.isArray(column)) {
        continue;
      }
      const destX = x + offsetX;
      if (destX < 0 || destX >= resolvedTargetWidth) {
        continue;
      }
      for (let y = 0; y < column.length; y++) {
        const color = column[y];
        if (!color || color === '#00000000') {
          continue;
        }
        const destY = y + offsetY;
        if (
          resolvedTargetHeight &&
          (destY < 0 || destY >= resolvedTargetHeight)
        ) {
          continue;
        }
        ctx.fillStyle = color;
        ctx.fillRect(
          destX * pixelSize,
          destY * pixelSize,
          pixelSize,
          pixelSize
        );
      }
    }
    ctx.globalAlpha = restoreAlpha;
  }

  drawBackground(
    ctx: CanvasRenderingContext2D,
    layers: PreviewLayerEntry[],
    pixelSize: number,
    canvas: HTMLCanvasElement,
    targetWidth: number,
    targetHeight: number,
    drawLayerGroups?: () => void
  ) {
    const bgImage = this.props.backgroundImage || null;
    const bgColor = this.props.backgroundColor || 'rgba(0,0,0,0)';
    const bgScale =
      Number.isFinite(this.props.backgroundScale || 0) &&
      (this.props.backgroundScale as number) > 0
        ? (this.props.backgroundScale as number)
        : 1;
    const cacheKey = buildBackgroundCacheKey(
      bgImage,
      bgScale,
      bgColor,
      canvas.width,
      canvas.height
    );
    const cacheEntry = sharedBackgroundCache.get(cacheKey);

    const drawLayers = () => {
      if (typeof drawLayerGroups === 'function') {
        drawLayerGroups();
        return;
      }
      this.drawLayers(ctx, layers, pixelSize, targetWidth, targetHeight);
    };

    if (cacheEntry?.ready && cacheEntry.canvas) {
      ctx.drawImage(cacheEntry.canvas, 0, 0);
      drawLayers();
      return;
    }

    if (cacheEntry && !cacheEntry.ready) {
      cacheEntry.listeners.add(this.handleBackgroundReady);
      return;
    }

    const buffer = document.createElement('canvas');
    buffer.width = canvas.width;
    buffer.height = canvas.height;
    const bctx = buffer.getContext('2d');
    if (!bctx) {
      drawLayers();
      return;
    }
    bctx.fillStyle = bgColor;
    bctx.fillRect(0, 0, buffer.width, buffer.height);

    const entry: SharedBackgroundCacheEntry = {
      key: cacheKey,
      src: bgImage || '',
      scale: bgScale,
      color: bgColor,
      width: canvas.width,
      height: canvas.height,
      canvas: buffer,
      ready: false,
      listeners: new Set(),
    };
    sharedBackgroundCache.set(cacheKey, entry);

    if (bgImage) {
      entry.listeners.add(this.handleBackgroundReady);
      const bgImageElement = new Image();
      entry.image = bgImageElement;
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
        entry.ready = true;
        const listeners = Array.from(entry.listeners);
        entry.listeners.clear();
        for (const listener of listeners) {
          listener();
        }
      };
      bgImageElement.onerror = () => {
        entry.ready = true;
        const listeners = Array.from(entry.listeners);
        entry.listeners.clear();
        for (const listener of listeners) {
          listener();
        }
      };
      bgImageElement.crossOrigin = 'anonymous';
      bgImageElement.src = bgImage;
      return;
    }

    entry.ready = true;
    ctx.drawImage(buffer, 0, 0);
    drawLayers();
  }

  render() {
    const {
      layers,
      baseLayers,
      underlayLayers,
      overlayLayers,
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
    const useLayerGroups =
      Array.isArray(baseLayers) ||
      (Array.isArray(underlayLayers) && underlayLayers.length > 0) ||
      (Array.isArray(overlayLayers) && overlayLayers.length > 0);
    const resolvedLayers = useLayerGroups
      ? [
          ...(Array.isArray(underlayLayers) ? underlayLayers : []),
          ...(Array.isArray(baseLayers) ? baseLayers : []),
          ...(Array.isArray(overlayLayers) ? overlayLayers : []),
        ]
      : Array.isArray(layers)
        ? layers
        : [];
    const fallbackWidth = Math.max(1, width || 1);
    const fallbackHeight = Math.max(1, height || 1);
    const useFixedSize =
      useLayerGroups &&
      Number.isFinite(width) &&
      Number.isFinite(height) &&
      (width || 0) > 0 &&
      (height || 0) > 0;
    const layerWidths = useFixedSize
      ? []
      : resolvedLayers
          .map((layer) => (Array.isArray(layer?.grid) ? layer.grid.length : 0))
          .filter((value) => typeof value === 'number' && value > 0);
    const layerHeights = useFixedSize
      ? []
      : resolvedLayers
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
          .filter((value) => typeof value === 'number' && value > 0);
    const gridWidth = useFixedSize
      ? fallbackWidth
      : layerWidths.length
        ? Math.max(fallbackWidth, ...layerWidths)
        : fallbackWidth;
    const gridHeight = useFixedSize
      ? fallbackHeight
      : layerHeights.length
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
