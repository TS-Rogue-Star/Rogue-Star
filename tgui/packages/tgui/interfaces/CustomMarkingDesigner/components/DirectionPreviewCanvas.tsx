// /////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Direction preview canvas for custom marking designer //
// /////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Updated to support 64x64 markings /////////////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support loaout and job gear ////////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star August 2026: Character Designer - Species and Prosthetics ////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star August 2026: Character Designer - Traits Tab /////////////////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////////

import { Component, createRef } from 'inferno';
import { Box } from '../../../components';
import {
  applyPreviewLayerColorTransformToRgba,
  type PreviewLayerEntry,
  type PreviewLayerGroup,
} from '../../../utils/character-preview';
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

type SharedRenderedCanvasCacheEntry = {
  canvas: HTMLCanvasElement;
};

const MAX_SHARED_RENDERED_CANVASES = 400;
const MAX_SHARED_BASE_RENDERED_CANVASES = 64;
export const MAX_SHARED_LAYER_RASTERS = 192;
const sharedBackgroundCache = new Map<string, SharedBackgroundCacheEntry>();
const sharedRenderedCanvasCache = new Map<
  string,
  SharedRenderedCanvasCacheEntry
>();
const sharedBaseRenderedCanvasCache = new Map<
  string,
  SharedRenderedCanvasCacheEntry
>();
const sharedLayerRasterCache = new Map<
  string,
  SharedRenderedCanvasCacheEntry
>();

const isPreviewOverlayLayer = (layer?: PreviewLayerEntry) =>
  layer?.type === 'overlay' ||
  (layer?.type === 'custom' && layer.source === 'render_priority');

const buildBackgroundCacheKey = (
  src: string | null,
  scale: number,
  color: string,
  width: number,
  height: number
) => `${src || 'none'}|${scale}|${color}|${width}x${height}`;

const getSharedRenderedCanvas = (key: string) => {
  const cached = sharedRenderedCanvasCache.get(key);
  if (!cached) {
    return null;
  }
  sharedRenderedCanvasCache.delete(key);
  sharedRenderedCanvasCache.set(key, cached);
  return cached.canvas;
};

const retainSharedRenderedCanvas = (key: string, canvas: HTMLCanvasElement) => {
  sharedRenderedCanvasCache.delete(key);
  sharedRenderedCanvasCache.set(key, { canvas });
  while (sharedRenderedCanvasCache.size > MAX_SHARED_RENDERED_CANVASES) {
    const oldestKey = sharedRenderedCanvasCache.keys().next().value as
      | string
      | undefined;
    if (!oldestKey) {
      break;
    }
    sharedRenderedCanvasCache.delete(oldestKey);
  }
};

const storeSharedRenderedCanvas = (key: string, source: HTMLCanvasElement) => {
  const canvas = document.createElement('canvas');
  canvas.width = source.width;
  canvas.height = source.height;
  const ctx = canvas.getContext('2d');
  if (!ctx) {
    return;
  }
  ctx.imageSmoothingEnabled = false;
  ctx.drawImage(source, 0, 0);
  retainSharedRenderedCanvas(key, canvas);
};

const getSharedBaseRenderedCanvas = (key: string) => {
  const cached = sharedBaseRenderedCanvasCache.get(key);
  if (!cached) {
    return null;
  }
  sharedBaseRenderedCanvasCache.delete(key);
  sharedBaseRenderedCanvasCache.set(key, cached);
  return cached.canvas;
};

const storeSharedBaseRenderedCanvas = (
  key: string,
  canvas: HTMLCanvasElement
) => {
  sharedBaseRenderedCanvasCache.delete(key);
  sharedBaseRenderedCanvasCache.set(key, { canvas });
  while (
    sharedBaseRenderedCanvasCache.size > MAX_SHARED_BASE_RENDERED_CANVASES
  ) {
    const oldestKey = sharedBaseRenderedCanvasCache.keys().next().value as
      | string
      | undefined;
    if (!oldestKey) {
      break;
    }
    sharedBaseRenderedCanvasCache.delete(oldestKey);
  }
};

const getSharedLayerRaster = (key: string) => {
  const cached = sharedLayerRasterCache.get(key);
  if (!cached) {
    return null;
  }
  sharedLayerRasterCache.delete(key);
  sharedLayerRasterCache.set(key, cached);
  return cached.canvas;
};

const storeSharedLayerRaster = (key: string, canvas: HTMLCanvasElement) => {
  sharedLayerRasterCache.delete(key);
  sharedLayerRasterCache.set(key, { canvas });
  while (sharedLayerRasterCache.size > MAX_SHARED_LAYER_RASTERS) {
    const oldestKey = sharedLayerRasterCache.keys().next().value as
      | string
      | undefined;
    if (!oldestKey) {
      break;
    }
    sharedLayerRasterCache.delete(oldestKey);
  }
};

export const buildSharedLayerRasterKey = (options: {
  signature: string;
  targetWidth: number;
  targetHeight: number;
  opacitySignature: string;
}) => {
  const { signature, targetWidth, targetHeight, opacitySignature } = options;
  return [
    'native-layer-v1',
    signature,
    `target:${targetWidth}x${targetHeight}`,
    `opacity:${opacitySignature}`,
  ].join('|');
};

export const getSharedLayerRasterCacheSize = () => sharedLayerRasterCache.size;

export const getSharedLayerRasterCacheStats = () => ({
  entries: sharedLayerRasterCache.size,
  maxEntries: MAX_SHARED_LAYER_RASTERS,
  estimatedBytes: Array.from(sharedLayerRasterCache.values()).reduce(
    (total, entry) => total + entry.canvas.width * entry.canvas.height * 4,
    0
  ),
});

export const clearSharedLayerRasterCache = () => {
  sharedLayerRasterCache.clear();
};

export const buildSharedBaseRenderedCanvasKey = (options: {
  signature: string;
  pixelSize: number;
  canvasWidth: number;
  canvasHeight: number;
  targetWidth: number;
  targetHeight: number;
  bodyAlpha: number | null;
}) => {
  const {
    signature,
    pixelSize,
    canvasWidth,
    canvasHeight,
    targetWidth,
    targetHeight,
    bodyAlpha,
  } = options;
  return [
    'base-v1',
    signature,
    `pixel:${pixelSize}`,
    `canvas:${canvasWidth}x${canvasHeight}`,
    `target:${targetWidth}x${targetHeight}`,
    `alpha:${bodyAlpha ?? 'full'}`,
  ].join('|');
};

export type DirectionPreviewCanvasProps = {
  readonly layers?: PreviewLayerEntry[];
  readonly layerGroups?: PreviewLayerGroup[];
  readonly baseLayers?: PreviewLayerEntry[];
  readonly underlayLayers?: PreviewLayerEntry[];
  readonly overlayLayers?: PreviewLayerEntry[];
  readonly baseSignature?: string;
  readonly renderSignature?: string;
  readonly retainRenderedCanvasOnUnmount?: boolean;
  readonly pixelSize: number;
  readonly width: number;
  readonly height: number;
  readonly fitToFrame?: boolean;
  readonly backgroundImage?: string | null;
  readonly backgroundColor?: string;
  readonly backgroundScale?: number;
  readonly backgroundTileWidth?: number;
  readonly backgroundTileHeight?: number;
  readonly bodyAlpha?: number | null;
  readonly iconScaleX?: number;
  readonly iconScaleY?: number;
};

export class DirectionPreviewCanvas extends Component<DirectionPreviewCanvasProps> {
  private canvasRef = createRef<HTMLCanvasElement>();
  private characterCompositeCanvas: HTMLCanvasElement | null = null;
  private completedRenderCache: {
    key: string;
    canvas: HTMLCanvasElement;
  } | null = null;
  private layerGroupCache = new Map<
    string,
    {
      signature: string;
      width: number;
      height: number;
      pixelSize: number;
      targetWidth: number;
      targetHeight: number;
      canvas: HTMLCanvasElement;
    }
  >();
  private colorLayerGroupCache = new Map<
    string,
    {
      signature: string;
      width: number;
      height: number;
      sourceData: Uint8ClampedArray;
      activeOffsets: number[];
      imageData: ImageData;
      canvas: HTMLCanvasElement;
      context: CanvasRenderingContext2D;
      colorSignature: string;
    }
  >();
  private baseCache: {
    signature: string;
    layersRef: PreviewLayerEntry[] | null;
    width: number;
    height: number;
    pixelSize: number;
    targetWidth: number;
    targetHeight: number;
    bodyAlpha: number | null;
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
      prevProps.layerGroups !== this.props.layerGroups ||
      prevProps.baseLayers !== this.props.baseLayers ||
      prevProps.underlayLayers !== this.props.underlayLayers ||
      prevProps.overlayLayers !== this.props.overlayLayers ||
      prevProps.baseSignature !== this.props.baseSignature ||
      prevProps.renderSignature !== this.props.renderSignature ||
      prevProps.pixelSize !== this.props.pixelSize ||
      prevProps.width !== this.props.width ||
      prevProps.height !== this.props.height ||
      prevProps.fitToFrame !== this.props.fitToFrame ||
      prevProps.backgroundImage !== this.props.backgroundImage ||
      prevProps.backgroundColor !== this.props.backgroundColor ||
      prevProps.backgroundScale !== this.props.backgroundScale ||
      prevProps.backgroundTileWidth !== this.props.backgroundTileWidth ||
      prevProps.backgroundTileHeight !== this.props.backgroundTileHeight ||
      prevProps.bodyAlpha !== this.props.bodyAlpha ||
      prevProps.iconScaleX !== this.props.iconScaleX ||
      prevProps.iconScaleY !== this.props.iconScaleY
    ) {
      this.draw();
    }
  }

  componentWillUnmount() {
    if (this.props.retainRenderedCanvasOnUnmount && this.completedRenderCache) {
      retainSharedRenderedCanvas(
        this.completedRenderCache.key,
        this.completedRenderCache.canvas
      );
    }
    for (const entry of Array.from(sharedBackgroundCache.values())) {
      entry.listeners.delete(this.handleBackgroundReady);
    }
    this.layerGroupCache.clear();
    this.colorLayerGroupCache.clear();
    this.characterCompositeCanvas = null;
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
    const iconScaleX = this.resolveIconScale(this.props.iconScaleX);
    const iconScaleY = this.resolveIconScale(this.props.iconScaleY);
    this.completedRenderCache = null;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.imageSmoothingEnabled = false;
    const renderSignature = this.props.renderSignature || '';
    const sharedRenderKey = renderSignature
      ? [
          renderSignature,
          pixelSize,
          canvas.width,
          canvas.height,
          this.props.backgroundImage || '',
          this.props.backgroundColor || '',
          this.props.backgroundScale || 1,
          this.props.bodyAlpha ?? '',
          iconScaleX,
          iconScaleY,
        ].join('|')
      : null;
    if (sharedRenderKey) {
      const sharedCanvas = getSharedRenderedCanvas(sharedRenderKey);
      if (sharedCanvas) {
        ctx.drawImage(sharedCanvas, 0, 0);
        this.completedRenderCache = { key: sharedRenderKey, canvas };
        return;
      }
    }
    const baseLayers = Array.isArray(this.props.baseLayers)
      ? this.props.baseLayers
      : null;
    const underlayLayers = Array.isArray(this.props.underlayLayers)
      ? this.props.underlayLayers
      : [];
    const overlayLayers = Array.isArray(this.props.overlayLayers)
      ? this.props.overlayLayers
      : [];
    const layerGroups = Array.isArray(this.props.layerGroups)
      ? this.props.layerGroups
      : [];
    const layers = Array.isArray(this.props.layers) ? this.props.layers : [];
    if (layerGroups.length) {
      const rendered = this.drawBackground(
        ctx,
        [],
        pixelSize,
        canvas,
        targetWidth,
        targetHeight,
        () => {
          this.drawCharacterLayers(
            ctx,
            canvas,
            iconScaleX,
            iconScaleY,
            (characterCtx) => {
              this.drawOrderedLayerGroups(
                characterCtx,
                layerGroups,
                pixelSize,
                canvas,
                targetWidth,
                targetHeight,
                this.props.bodyAlpha
              );
            }
          );
        }
      );
      if (rendered && sharedRenderKey) {
        this.completeRenderedCanvasCache(sharedRenderKey, canvas);
      }
      return;
    }
    const useLayerGroups =
      baseLayers !== null ||
      underlayLayers.length > 0 ||
      overlayLayers.length > 0;
    if (!useLayerGroups) {
      const rendered = this.drawBackground(
        ctx,
        [],
        pixelSize,
        canvas,
        targetWidth,
        targetHeight,
        () => {
          this.drawCharacterLayers(
            ctx,
            canvas,
            iconScaleX,
            iconScaleY,
            (characterCtx) => {
              this.drawLayers(
                characterCtx,
                layers,
                pixelSize,
                targetWidth,
                targetHeight,
                this.props.bodyAlpha
              );
            }
          );
        }
      );
      if (rendered && sharedRenderKey) {
        this.completeRenderedCanvasCache(sharedRenderKey, canvas);
      }
      return;
    }
    const rendered = this.drawBackground(
      ctx,
      [],
      pixelSize,
      canvas,
      targetWidth,
      targetHeight,
      () => {
        this.drawCharacterLayers(
          ctx,
          canvas,
          iconScaleX,
          iconScaleY,
          (characterCtx) => {
            if (underlayLayers.length) {
              this.drawLayers(
                characterCtx,
                underlayLayers,
                pixelSize,
                targetWidth,
                targetHeight
              );
            }
            if (baseLayers && baseLayers.length) {
              this.drawBaseLayers(
                characterCtx,
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
                characterCtx,
                overlayLayers,
                pixelSize,
                targetWidth,
                targetHeight
              );
            }
          }
        );
      }
    );
    if (rendered && sharedRenderKey) {
      this.completeRenderedCanvasCache(sharedRenderKey, canvas);
    }
  }

  private completeRenderedCanvasCache(key: string, canvas: HTMLCanvasElement) {
    this.completedRenderCache = { key, canvas };
    if (!this.props.retainRenderedCanvasOnUnmount) {
      storeSharedRenderedCanvas(key, canvas);
    }
  }

  private resolveIconScale(value?: number) {
    return typeof value === 'number' && Number.isFinite(value) && value > 0
      ? value
      : 1;
  }

  private drawCharacterLayers(
    ctx: CanvasRenderingContext2D,
    canvas: HTMLCanvasElement,
    iconScaleX: number,
    iconScaleY: number,
    drawLayers: (ctx: CanvasRenderingContext2D) => void
  ) {
    if (iconScaleX === 1 && iconScaleY === 1) {
      drawLayers(ctx);
      return;
    }

    const compositeCanvas =
      this.characterCompositeCanvas || document.createElement('canvas');
    this.characterCompositeCanvas = compositeCanvas;
    if (
      compositeCanvas.width !== canvas.width ||
      compositeCanvas.height !== canvas.height
    ) {
      compositeCanvas.width = canvas.width;
      compositeCanvas.height = canvas.height;
    }
    const compositeCtx = compositeCanvas.getContext('2d');
    if (!compositeCtx) {
      drawLayers(ctx);
      return;
    }
    compositeCtx.setTransform(1, 0, 0, 1, 0, 0);
    compositeCtx.globalAlpha = 1;
    compositeCtx.globalCompositeOperation = 'source-over';
    compositeCtx.clearRect(0, 0, compositeCanvas.width, compositeCanvas.height);
    compositeCtx.imageSmoothingEnabled = false;
    drawLayers(compositeCtx);

    const scaledWidth = Math.max(
      1,
      Math.round(compositeCanvas.width * iconScaleX)
    );
    const scaledHeight = Math.max(
      1,
      Math.round(compositeCanvas.height * iconScaleY)
    );
    const offsetX = Math.round((canvas.width - scaledWidth) / 2);
    const offsetY = canvas.height - scaledHeight;
    ctx.save();
    ctx.imageSmoothingEnabled = false;
    ctx.drawImage(
      compositeCanvas,
      0,
      0,
      compositeCanvas.width,
      compositeCanvas.height,
      offsetX,
      offsetY,
      scaledWidth,
      scaledHeight
    );
    ctx.restore();
  }

  drawOrderedLayerGroups(
    ctx: CanvasRenderingContext2D,
    groups: PreviewLayerGroup[],
    pixelSize: number,
    canvas: HTMLCanvasElement,
    targetWidth: number,
    targetHeight: number,
    bodyAlpha?: number | null
  ) {
    const resolvedBodyAlpha =
      typeof bodyAlpha === 'number'
        ? Math.max(0, Math.min(255, bodyAlpha))
        : 255;
    if (resolvedBodyAlpha >= 255) {
      this.drawLayerGroupSequence(
        ctx,
        groups,
        pixelSize,
        canvas,
        targetWidth,
        targetHeight
      );
      return;
    }

    const bodyGroups: PreviewLayerGroup[] = [];
    const overlayGroups: PreviewLayerGroup[] = [];
    let reachedOverlays = false;
    for (const group of groups) {
      if (reachedOverlays) {
        overlayGroups.push(group);
        continue;
      }
      const firstOverlayIndex = group.layers.findIndex(isPreviewOverlayLayer);
      if (firstOverlayIndex === -1) {
        bodyGroups.push(group);
        continue;
      }
      if (firstOverlayIndex > 0) {
        bodyGroups.push({
          ...group,
          key: `${group.key}:body`,
          layers: group.layers.slice(0, firstOverlayIndex),
          cacheSignature: group.cacheSignature
            ? `${group.cacheSignature}:body:${firstOverlayIndex}`
            : undefined,
        });
      }
      overlayGroups.push({
        ...group,
        key: `${group.key}:overlay`,
        layers: group.layers.slice(firstOverlayIndex),
        cacheSignature: group.cacheSignature
          ? `${group.cacheSignature}:overlay:${firstOverlayIndex}`
          : undefined,
      });
      reachedOverlays = true;
    }

    if (bodyGroups.length && resolvedBodyAlpha > 0) {
      const buffer = document.createElement('canvas');
      buffer.width = canvas.width;
      buffer.height = canvas.height;
      const bctx = buffer.getContext('2d');
      if (bctx) {
        bctx.imageSmoothingEnabled = false;
        this.drawLayerGroupSequence(
          bctx,
          bodyGroups,
          pixelSize,
          buffer,
          targetWidth,
          targetHeight
        );
        const restoreAlpha = ctx.globalAlpha;
        ctx.globalAlpha = restoreAlpha * (resolvedBodyAlpha / 255);
        ctx.drawImage(buffer, 0, 0);
        ctx.globalAlpha = restoreAlpha;
      }
    }
    this.drawLayerGroupSequence(
      ctx,
      overlayGroups,
      pixelSize,
      canvas,
      targetWidth,
      targetHeight
    );
  }

  drawLayerGroupSequence(
    ctx: CanvasRenderingContext2D,
    groups: PreviewLayerGroup[],
    pixelSize: number,
    canvas: HTMLCanvasElement,
    targetWidth: number,
    targetHeight: number
  ) {
    for (const group of groups) {
      if (!group.layers.length) {
        continue;
      }
      if (group.colorTransform) {
        this.drawColorizedLayerGroup(
          ctx,
          group,
          pixelSize,
          targetWidth,
          targetHeight
        );
        continue;
      }
      if (group.sharedRasterSignature) {
        this.drawSharedLayerRaster(
          ctx,
          group,
          pixelSize,
          targetWidth,
          targetHeight
        );
        continue;
      }
      if (group.cacheSignature) {
        this.drawCachedLayerGroup(
          ctx,
          group,
          pixelSize,
          canvas,
          targetWidth,
          targetHeight
        );
        continue;
      }
      this.drawLayers(ctx, group.layers, pixelSize, targetWidth, targetHeight);
    }
  }

  drawSharedLayerRaster(
    ctx: CanvasRenderingContext2D,
    group: PreviewLayerGroup,
    pixelSize: number,
    targetWidth: number,
    targetHeight: number
  ) {
    const opacitySignature = group.layers
      .map((layer) =>
        typeof layer.opacity === 'number'
          ? Math.max(0, Math.min(1, layer.opacity))
          : 1
      )
      .join(',');
    const key = buildSharedLayerRasterKey({
      signature: group.sharedRasterSignature || '',
      targetWidth,
      targetHeight,
      opacitySignature,
    });
    let buffer = getSharedLayerRaster(key);
    if (!buffer) {
      buffer = document.createElement('canvas');
      buffer.width = targetWidth;
      buffer.height = targetHeight;
      const bctx = buffer.getContext('2d');
      if (!bctx) {
        this.drawLayers(
          ctx,
          group.layers,
          pixelSize,
          targetWidth,
          targetHeight
        );
        return;
      }
      bctx.imageSmoothingEnabled = false;
      this.drawLayers(bctx, group.layers, 1, targetWidth, targetHeight);
      storeSharedLayerRaster(key, buffer);
    }
    ctx.drawImage(
      buffer,
      0,
      0,
      targetWidth * pixelSize,
      targetHeight * pixelSize
    );
  }

  drawColorizedLayerGroup(
    ctx: CanvasRenderingContext2D,
    group: PreviewLayerGroup,
    pixelSize: number,
    targetWidth: number,
    targetHeight: number
  ) {
    const transform = group.colorTransform;
    if (!transform) {
      return;
    }
    const signature = group.cacheSignature || '';
    let cached = this.colorLayerGroupCache.get(group.key);
    const shouldRebuild =
      !cached ||
      cached.signature !== signature ||
      cached.width !== targetWidth ||
      cached.height !== targetHeight;
    if (shouldRebuild) {
      const sourceCanvas = document.createElement('canvas');
      sourceCanvas.width = targetWidth;
      sourceCanvas.height = targetHeight;
      const sourceCtx = sourceCanvas.getContext('2d');
      const colorCanvas = document.createElement('canvas');
      colorCanvas.width = targetWidth;
      colorCanvas.height = targetHeight;
      const colorCtx = colorCanvas.getContext('2d');
      if (!sourceCtx || !colorCtx) {
        this.drawLayers(
          ctx,
          group.layers,
          pixelSize,
          targetWidth,
          targetHeight
        );
        return;
      }
      sourceCtx.imageSmoothingEnabled = false;
      this.drawLayers(sourceCtx, group.layers, 1, targetWidth, targetHeight);
      const sourceImageData = sourceCtx.getImageData(
        0,
        0,
        targetWidth,
        targetHeight
      );
      const activeOffsets: number[] = [];
      for (let offset = 3; offset < sourceImageData.data.length; offset += 4) {
        if (sourceImageData.data[offset] > 0) {
          activeOffsets.push(offset - 3);
        }
      }
      cached = {
        signature,
        width: targetWidth,
        height: targetHeight,
        sourceData: sourceImageData.data,
        activeOffsets,
        imageData: colorCtx.createImageData(targetWidth, targetHeight),
        canvas: colorCanvas,
        context: colorCtx,
        colorSignature: '',
      };
      this.colorLayerGroupCache.set(group.key, cached);
    }
    if (!cached) {
      return;
    }

    const colorSignature = [
      transform.color,
      transform.multiply ? 'multiply' : 'add',
      transform.passes,
    ].join(':');
    if (cached.colorSignature !== colorSignature) {
      applyPreviewLayerColorTransformToRgba(
        cached.sourceData,
        cached.imageData.data,
        cached.activeOffsets,
        transform
      );
      cached.context.putImageData(cached.imageData, 0, 0);
      cached.colorSignature = colorSignature;
    }
    ctx.drawImage(
      cached.canvas,
      0,
      0,
      targetWidth * pixelSize,
      targetHeight * pixelSize
    );
  }

  drawCachedLayerGroup(
    ctx: CanvasRenderingContext2D,
    group: PreviewLayerGroup,
    pixelSize: number,
    canvas: HTMLCanvasElement,
    targetWidth: number,
    targetHeight: number
  ) {
    const signature = group.cacheSignature || '';
    const cached = this.layerGroupCache.get(group.key);
    const shouldRebuild =
      !cached ||
      cached.signature !== signature ||
      cached.width !== canvas.width ||
      cached.height !== canvas.height ||
      cached.pixelSize !== pixelSize ||
      cached.targetWidth !== targetWidth ||
      cached.targetHeight !== targetHeight;
    let resolved = cached;
    if (shouldRebuild) {
      const buffer = document.createElement('canvas');
      buffer.width = canvas.width;
      buffer.height = canvas.height;
      const bctx = buffer.getContext('2d');
      if (bctx) {
        bctx.imageSmoothingEnabled = false;
        this.drawLayers(
          bctx,
          group.layers,
          pixelSize,
          targetWidth,
          targetHeight
        );
      }
      resolved = {
        signature,
        width: canvas.width,
        height: canvas.height,
        pixelSize,
        targetWidth,
        targetHeight,
        canvas: buffer,
      };
      this.layerGroupCache.set(group.key, resolved);
    }
    if (resolved?.canvas) {
      ctx.drawImage(resolved.canvas, 0, 0);
    }
  }

  drawLayers(
    ctx: CanvasRenderingContext2D,
    layers: PreviewLayerEntry[],
    pixelSize: number,
    targetWidth: number,
    targetHeight: number,
    bodyAlpha?: number | null
  ) {
    const resolvedBodyAlpha =
      typeof bodyAlpha === 'number'
        ? Math.max(0, Math.min(255, bodyAlpha))
        : 255;
    let remainingLayers = layers;
    if (resolvedBodyAlpha < 255 && layers.length) {
      const firstOverlayIndex = layers.findIndex(isPreviewOverlayLayer);
      const bodyLayerCount =
        firstOverlayIndex === -1 ? layers.length : firstOverlayIndex;
      if (bodyLayerCount > 0) {
        const buffer = document.createElement('canvas');
        buffer.width = ctx.canvas.width;
        buffer.height = ctx.canvas.height;
        const bctx = buffer.getContext('2d');
        if (bctx) {
          bctx.imageSmoothingEnabled = false;
          this.drawLayers(
            bctx,
            layers.slice(0, bodyLayerCount),
            pixelSize,
            targetWidth,
            targetHeight
          );
          const restoreAlpha = ctx.globalAlpha;
          ctx.globalAlpha = restoreAlpha * (resolvedBodyAlpha / 255);
          ctx.drawImage(buffer, 0, 0);
          ctx.globalAlpha = restoreAlpha;
          remainingLayers = layers.slice(bodyLayerCount);
        }
      }
    }
    for (const layer of remainingLayers) {
      const opacity =
        typeof layer?.opacity === 'number'
          ? Math.max(0, Math.min(1, layer.opacity))
          : 1;
      this.drawLayer(ctx, layer, pixelSize, opacity, targetWidth, targetHeight);
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
    const bodyAlpha =
      typeof this.props.bodyAlpha === 'number' ? this.props.bodyAlpha : null;
    const shouldRebuild =
      !this.baseCache ||
      this.baseCache.width !== canvas.width ||
      this.baseCache.height !== canvas.height ||
      this.baseCache.pixelSize !== pixelSize ||
      this.baseCache.targetWidth !== targetWidth ||
      this.baseCache.targetHeight !== targetHeight ||
      this.baseCache.bodyAlpha !== bodyAlpha ||
      (useSignature
        ? this.baseCache.signature !== resolvedSignature
        : this.baseCache.layersRef !== layers);
    if (shouldRebuild) {
      const sharedCacheKey = useSignature
        ? buildSharedBaseRenderedCanvasKey({
            signature: resolvedSignature,
            pixelSize,
            canvasWidth: canvas.width,
            canvasHeight: canvas.height,
            targetWidth,
            targetHeight,
            bodyAlpha,
          })
        : null;
      let buffer = sharedCacheKey
        ? getSharedBaseRenderedCanvas(sharedCacheKey)
        : null;
      if (!buffer) {
        buffer = document.createElement('canvas');
        buffer.width = canvas.width;
        buffer.height = canvas.height;
        const bctx = buffer.getContext('2d');
        if (bctx) {
          bctx.clearRect(0, 0, buffer.width, buffer.height);
          bctx.imageSmoothingEnabled = false;
          this.drawLayers(
            bctx,
            layers,
            pixelSize,
            targetWidth,
            targetHeight,
            bodyAlpha
          );
        }
        if (sharedCacheKey) {
          storeSharedBaseRenderedCanvas(sharedCacheKey, buffer);
        }
      }
      this.baseCache = {
        signature: resolvedSignature,
        layersRef: useSignature ? null : layers,
        width: canvas.width,
        height: canvas.height,
        pixelSize,
        targetWidth,
        targetHeight,
        bodyAlpha,
        canvas: buffer,
      };
    }
    if (this.baseCache?.canvas) {
      ctx.drawImage(this.baseCache.canvas, 0, 0);
    }
  }

  drawLayer(
    ctx: CanvasRenderingContext2D,
    layer?: PreviewLayerEntry,
    pixelSize?: number,
    opacity?: number,
    targetWidth?: number,
    targetHeight?: number
  ) {
    if (!Array.isArray(layer?.grid) || !pixelSize) {
      return;
    }
    const grid = layer.grid;
    const alpha = typeof opacity === 'number' ? opacity : 1;
    const restoreAlpha = ctx.globalAlpha;
    ctx.globalAlpha = alpha;
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
  ): boolean {
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
      this.drawLayers(
        ctx,
        layers,
        pixelSize,
        targetWidth,
        targetHeight,
        this.props.bodyAlpha
      );
    };

    if (cacheEntry?.ready && cacheEntry.canvas) {
      ctx.drawImage(cacheEntry.canvas, 0, 0);
      drawLayers();
      return true;
    }

    if (cacheEntry && !cacheEntry.ready) {
      cacheEntry.listeners.add(this.handleBackgroundReady);
      return false;
    }

    const buffer = document.createElement('canvas');
    buffer.width = canvas.width;
    buffer.height = canvas.height;
    const bctx = buffer.getContext('2d');
    if (!bctx) {
      drawLayers();
      return true;
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
      return false;
    }

    entry.ready = true;
    ctx.drawImage(buffer, 0, 0);
    drawLayers();
    return true;
  }

  render() {
    const {
      layers,
      layerGroups,
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
    const hasOrderedLayerGroups =
      Array.isArray(layerGroups) && layerGroups.length > 0;
    const useLayerGroups =
      hasOrderedLayerGroups ||
      Array.isArray(baseLayers) ||
      (Array.isArray(underlayLayers) && underlayLayers.length > 0) ||
      (Array.isArray(overlayLayers) && overlayLayers.length > 0);
    const resolvedLayers = hasOrderedLayerGroups
      ? layerGroups.flatMap((group) => group.layers)
      : useLayerGroups
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
              'image-rendering': 'pixelated', // RS Edit: Inferno 7 to 9 (Lira, January 2026)
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
