// ////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Export handlers for custom marking designer //
// ////////////////////////////////////////////////////////////////////////////////////////////

import {
  applyDiffToGrid,
  cloneGridData,
  createBlankGrid,
  GENERIC_PART_KEY,
} from '../../../utils/character-preview';
import type { DiffEntry, PreviewState } from '../../../utils/character-preview';
import { rgbToHex, TRANSPARENT_HEX } from '../../../utils/color';
import { CARDINAL_DIRECTION_ORDER, buildLocalSessionKey } from '../utils';
import {
  buildDmiExportBlob,
  buildPngBlobFromGrid,
  buildSessionDraftDiff,
  sanitizeFileToken,
  saveBlob,
} from '../utils';
import type {
  CustomMarkingDesignerData,
  StrokeDraftEntry,
  StrokeDraftState,
} from '../types';

type ExportControllerOptions = {
  data: CustomMarkingDesignerData;
  uiCanvasGrid: string[][] | null;
  strokeDraftState: StrokeDraftState;
  localSessionKey: string;
  canvasWidth: number;
  canvasHeight: number;
  activePartKey: string;
  currentDirectionKey: number;
  derivedPreviewState: PreviewState;
  draftDiffIndex: Record<number, Record<string, DiffEntry[]>>;
  activeDraftDiff: DiffEntry[];
  updateStrokeDrafts: (
    updater: (prev: StrokeDraftState) => StrokeDraftState
  ) => void;
  clearSessionDrafts: (sessionKey?: string) => void;
  allocateDraftSequence: () => number;
  sendActionAfterSync: (
    actionName: string,
    payload?: Record<string, unknown>
  ) => Promise<void>;
};

export type ExportController = {
  handleViewRawPayload: () => Promise<void>;
  handleImport: (type: 'png' | 'dmi') => Promise<void>;
  handleExport: (type: 'png' | 'dmi') => Promise<void>;
};

const pickLocalFile = async (accept: string): Promise<File | null> => {
  if (typeof document === 'undefined') {
    return null;
  }
  return await new Promise((resolve) => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = accept;
    input.style.display = 'none';
    input.onchange = () => {
      const file = input.files?.[0] || null;
      input.remove();
      resolve(file);
    };
    document.body.appendChild(input);
    input.click();
  });
};

type ImageSource = ImageBitmap | HTMLImageElement;

const loadImageFromBlob = async (blob: Blob): Promise<ImageSource | null> => {
  if (typeof window === 'undefined') {
    return null;
  }
  if (typeof createImageBitmap === 'function') {
    try {
      // RS Edit - Sonar
      return await createImageBitmap(blob);
    } catch {}
  }
  return await new Promise((resolve) => {
    const url = URL.createObjectURL(blob);
    const img = new Image();
    img.onload = () => {
      URL.revokeObjectURL(url);
      resolve(img);
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      resolve(null);
    };
    img.src = url;
  });
};

const getImageDimensions = (
  source: ImageSource
): { width: number; height: number } => {
  if ('naturalWidth' in source) {
    return {
      width: source.naturalWidth,
      height: source.naturalHeight,
    };
  }
  return {
    width: source.width,
    height: source.height,
  };
};

const extractImageData = (
  source: ImageSource,
  targetWidth: number,
  targetHeight: number,
  region?: { x: number; y: number; width: number; height: number }
): ImageData | null => {
  if (typeof document === 'undefined') {
    return null;
  }
  const canvas = document.createElement('canvas');
  canvas.width = targetWidth;
  canvas.height = targetHeight;
  const ctx = canvas.getContext('2d');
  if (!ctx) {
    return null;
  }
  if (region) {
    ctx.drawImage(
      source,
      region.x,
      region.y,
      region.width,
      region.height,
      0,
      0,
      targetWidth,
      targetHeight
    );
  } else {
    ctx.drawImage(source, 0, 0, targetWidth, targetHeight);
  }
  try {
    return ctx.getImageData(0, 0, targetWidth, targetHeight);
  } catch {
    return null;
  }
};

const imageDataToDiffEntries = (imageData: ImageData): DiffEntry[] => {
  const { data, width, height } = imageData;
  const pixels: DiffEntry[] = [];
  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      const idx = (y * width + x) * 4;
      const r = data[idx];
      const g = data[idx + 1];
      const b = data[idx + 2];
      const a = data[idx + 3];
      const color = a > 0 ? rgbToHex(r, g, b) : TRANSPARENT_HEX;
      pixels.push({
        x: x + 1,
        y: y + 1,
        color,
      });
    }
  }
  return pixels;
};

const applyImportedDiff = (
  options: ExportControllerOptions,
  sessionKey: string,
  dirKey: number,
  partKey: string,
  pixels: DiffEntry[]
): boolean => {
  if (!sessionKey || !pixels.length) {
    return false;
  }
  options.clearSessionDrafts(sessionKey);
  const strokeId = `import-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
  const sequence = options.allocateDraftSequence();
  options.updateStrokeDrafts((prev) => {
    const next: StrokeDraftState = { ...prev };
    const storageKey = `${sessionKey}::${strokeId}`;
    const entry: StrokeDraftEntry = {
      stroke: strokeId,
      session: sessionKey,
      dirKey,
      part: partKey || GENERIC_PART_KEY,
      sequence,
      pixels,
    };
    next[storageKey] = entry;
    return next;
  });
  return true;
};

const extractPngTextChunk = (
  buffer: ArrayBuffer,
  keyword: string
): string | null => {
  const bytes = new Uint8Array(buffer);
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  for (let i = 0; i < signature.length; i += 1) {
    if (bytes[i] !== signature[i]) {
      return null;
    }
  }
  let offset = 8;
  const decoder = new TextDecoder('latin1');
  while (offset + 8 < bytes.length) {
    const length =
      ((bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3]) >>>
      0;
    const typeStart = offset + 4;
    const type = String.fromCharCode(
      bytes[typeStart],
      bytes[typeStart + 1],
      bytes[typeStart + 2],
      bytes[typeStart + 3]
    );
    const dataStart = typeStart + 4;
    const dataEnd = dataStart + length;
    if (type === 'tEXt') {
      const chunk = bytes.slice(dataStart, dataEnd);
      const nullIndex = chunk.indexOf(0);
      if (nullIndex > 0) {
        const foundKeyword = decoder.decode(chunk.slice(0, nullIndex));
        if (foundKeyword === keyword) {
          return decoder.decode(chunk.slice(nullIndex + 1));
        }
      }
    }
    offset = dataEnd + 4; // Skip CRC
  }
  return null;
};

type DmiStateMeta = {
  name: string;
  dirs: number;
  frames: number;
};

type DmiMetadata = {
  width: number;
  height: number;
  states: DmiStateMeta[];
};

const unescapeDmiStateName = (raw: string): string => {
  let value = raw.trim();
  if (value.startsWith('"') && value.endsWith('"')) {
    value = value.slice(1, -1);
  }
  return value.replace(/\\\\/g, '\\').replace(/\\"/g, '"');
};

const parseDmiMetadata = (text: string | null): DmiMetadata | null => {
  if (!text) {
    return null;
  }
  const lines = text
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line.length);
  let width: number | null = null;
  let height: number | null = null;
  const states: DmiStateMeta[] = [];
  let current: DmiStateMeta | null = null;
  const flushState = () => {
    if (current && current.name) {
      states.push(current);
    }
    current = null;
  };
  for (const line of lines) {
    if (line.startsWith('#')) {
      continue;
    }
    const [rawKey, rawValue] = line.split('=');
    if (!rawKey || rawValue === undefined) {
      continue;
    }
    const key = rawKey.trim().toLowerCase();
    const value = rawValue.trim();
    switch (key) {
      case 'width': {
        const parsed = Number(value);
        if (Number.isFinite(parsed)) {
          width = parsed;
        }
        break;
      }
      case 'height': {
        const parsed = Number(value);
        if (Number.isFinite(parsed)) {
          height = parsed;
        }
        break;
      }
      case 'state': {
        flushState();
        current = {
          name: unescapeDmiStateName(value),
          dirs: 1,
          frames: 1,
        };
        break;
      }
      case 'dirs': {
        if (current) {
          const parsed = Number(value);
          if (Number.isFinite(parsed)) {
            current.dirs = parsed;
          }
        }
        break;
      }
      case 'frames': {
        if (current) {
          const parsed = Number(value);
          if (Number.isFinite(parsed)) {
            current.frames = parsed;
          }
        }
        break;
      }
      default:
        break;
    }
  }
  flushState();
  if (!Number.isFinite(width) || !Number.isFinite(height) || !states.length) {
    return null;
  }
  return {
    width: width as number,
    height: height as number,
    states,
  };
};

export const createExportController = (
  options: ExportControllerOptions
): ExportController => {
  const handleViewRawPayload = async () => {
    await options.sendActionAfterSync('view_raw_payload');
  };

  const handlePngImport = async () => {
    const file = await pickLocalFile('.png,image/png');
    if (!file) {
      return;
    }
    const imageSource = await loadImageFromBlob(file);
    if (!imageSource) {
      window?.alert?.('Could not read that PNG file.');
      return;
    }
    const imageData = extractImageData(
      imageSource,
      options.canvasWidth,
      options.canvasHeight
    );
    if (!imageData) {
      window?.alert?.('Unable to read pixels from that PNG.');
      return;
    }
    const pixels = imageDataToDiffEntries(imageData);
    const sessionKey = options.localSessionKey;
    const success = applyImportedDiff(
      options,
      sessionKey,
      options.currentDirectionKey,
      options.activePartKey || GENERIC_PART_KEY,
      pixels
    );
    if (success && typeof window !== 'undefined') {
      window.alert(
        'PNG imported into the current direction and body part. Save to upload it to the server.'
      );
    }
  };

  const handleDmiImport = async () => {
    const file = await pickLocalFile('.dmi,image/png');
    if (!file) {
      return;
    }
    const buffer = await file.arrayBuffer();
    const metadataText = extractPngTextChunk(buffer, 'Description');
    const metadata = parseDmiMetadata(metadataText);
    if (
      !metadata ||
      !Number.isFinite(metadata.width) ||
      !Number.isFinite(metadata.height)
    ) {
      window?.alert?.('Could not read DMI metadata from that file.');
      return;
    }
    if (
      metadata.width !== options.canvasWidth ||
      metadata.height !== options.canvasHeight
    ) {
      window?.alert?.(
        'Imported DMI icon size does not match this marking canvas.'
      );
      return;
    }
    const imageSource = await loadImageFromBlob(
      new Blob([buffer], { type: file.type || 'image/png' })
    );
    if (!imageSource) {
      window?.alert?.('Could not read that DMI file.');
      return;
    }
    const { width: sheetWidth, height: sheetHeight } =
      getImageDimensions(imageSource);
    if (
      sheetWidth % metadata.width !== 0 ||
      sheetHeight % metadata.height !== 0
    ) {
      window?.alert?.('The DMI sprite sheet dimensions look invalid.');
      return;
    }
    const columns = Math.floor(sheetWidth / metadata.width);
    const rows = Math.floor(sheetHeight / metadata.height);
    const totalFrames = columns * rows;
    const directionOrder = CARDINAL_DIRECTION_ORDER;
    let frameCursor = 0;
    const targets: {
      dirKey: number;
      partKey: string;
      pixels: DiffEntry[];
    }[] = [];
    for (const state of metadata.states) {
      const frameCount =
        Math.max(1, state.frames || 1) * Math.max(1, state.dirs || 1);
      if (frameCursor + frameCount > totalFrames) {
        break;
      }
      const shouldImport = state.name?.toLowerCase().startsWith('export-');
      if (shouldImport) {
        const partSuffix = state.name.slice('export-'.length);
        const partKey =
          partSuffix && partSuffix.length
            ? partSuffix.toLowerCase()
            : GENERIC_PART_KEY;
        const dirLimit = Math.min(state.dirs || 1, directionOrder.length);
        for (let dirIndex = 0; dirIndex < dirLimit; dirIndex += 1) {
          const frameIndex = frameCursor + dirIndex;
          const col = frameIndex % columns;
          const row = Math.floor(frameIndex / columns);
          const region = {
            x: col * metadata.width,
            y: row * metadata.height,
            width: metadata.width,
            height: metadata.height,
          };
          const imageData = extractImageData(
            imageSource,
            metadata.width,
            metadata.height,
            region
          );
          if (!imageData) {
            continue;
          }
          const pixels = imageDataToDiffEntries(imageData);
          targets.push({
            dirKey: directionOrder[dirIndex],
            partKey,
            pixels,
          });
        }
      }
      frameCursor += frameCount;
    }
    if (!targets.length) {
      window?.alert?.("No 'export-' states were found in that DMI.");
      return;
    }
    for (const target of targets) {
      const sessionKey = buildLocalSessionKey(target.dirKey, target.partKey);
      applyImportedDiff(
        options,
        sessionKey,
        target.dirKey,
        target.partKey,
        target.pixels
      );
    }
    if (typeof window !== 'undefined') {
      window.alert(
        'DMI imported. Review the preview and save if you want to keep these changes.'
      );
    }
  };

  const handleImport = async (type: 'png' | 'dmi') => {
    if (type === 'png') {
      await handlePngImport();
      return;
    }
    await handleDmiImport();
  };

  const handlePngExport = async () => {
    let exportGrid = options.uiCanvasGrid
      ? cloneGridData(options.uiCanvasGrid)
      : createBlankGrid(options.canvasWidth, options.canvasHeight);
    const pendingDiff = buildSessionDraftDiff(
      options.strokeDraftState,
      options.localSessionKey,
      options.canvasWidth,
      options.canvasHeight
    );
    if (pendingDiff.length) {
      exportGrid = applyDiffToGrid(
        exportGrid,
        pendingDiff,
        options.canvasWidth,
        options.canvasHeight
      );
    }
    const exportResult = await buildPngBlobFromGrid(
      exportGrid,
      options.canvasWidth,
      options.canvasHeight
    );
    if (!exportResult) {
      if (typeof window !== 'undefined') {
        window.alert('Could not export PNG; missing browser canvas support.');
      }
      return;
    }
    const { blob, hasPixels } = exportResult;
    const baseName = sanitizeFileToken(
      options.data.mark_name,
      'custom_marking'
    );
    const partToken = sanitizeFileToken(
      options.activePartKey && options.activePartKey.length
        ? options.activePartKey
        : 'generic',
      'generic'
    );
    const directionToken = sanitizeFileToken(
      options.data.directions.find(
        (dir) => dir.dir === options.currentDirectionKey
      )?.label ||
        options.data.active_dir ||
        'direction',
      'direction'
    );
    const fileName = `${baseName}_${partToken}_${directionToken}.png`;
    if (!saveBlob(blob, fileName, '.png')) {
      if (typeof window !== 'undefined') {
        window.alert('Could not start download; client environment missing.');
      }
      return;
    }
    if (!hasPixels && typeof window !== 'undefined') {
      window.alert('No painted pixels found; exported image will be blank.');
    }
  };

  const handleDmiExport = async () => {
    const partOrder: string[] = [];
    const ensurePart = (value?: string | null) => {
      if (!value || partOrder.includes(value)) {
        return;
      }
      partOrder.push(value);
    };
    ensurePart(options.activePartKey);
    (options.data.selected_body_parts || []).forEach((part) =>
      ensurePart(part)
    );
    ensurePart(GENERIC_PART_KEY);
    const exportBlob = await buildDmiExportBlob({
      dirStates: options.derivedPreviewState.dirs,
      canvasWidth: options.canvasWidth,
      canvasHeight: options.canvasHeight,
      partIds: partOrder,
      draftDiffIndex: options.draftDiffIndex,
      activeDirKey: options.currentDirectionKey,
      activePartKey: options.activePartKey,
      activeDraftDiff: options.activeDraftDiff,
    });
    if (!exportBlob) {
      if (typeof window !== 'undefined') {
        window.alert('No custom marking states found to export.');
      }
      return;
    }
    const baseName = sanitizeFileToken(
      options.data.mark_name,
      'custom_marking'
    );
    const fileName = `${baseName}_full.dmi`;
    if (!saveBlob(exportBlob, fileName, '.dmi') && typeof window !== 'undefined') {
      window.alert('Could not start download; client environment missing.');
    }
  };

  const handleExport = async (type: 'png' | 'dmi') => {
    if (type === 'png') {
      await handlePngExport();
      return;
    }
    await handleDmiExport();
  };

  return {
    handleViewRawPayload,
    handleImport,
    handleExport,
  };
};
