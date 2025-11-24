// ////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Grid export helpers for custom marking designer //
// ////////////////////////////////////////////////////////////////////////////////////////////////

import { TRANSPARENT_HEX } from '../../../utils/color';
import {
  GENERIC_PART_KEY,
  createBlankGrid,
} from '../../../utils/character-preview';
import type {
  DiffEntry,
  PreviewDirState,
} from '../../../utils/character-preview';
import { resolveExportGridForDirPart } from './previewState';

export type GridExportResult = {
  blob: Blob;
  hasPixels: boolean;
};

export type RenderedGridCanvas = {
  canvas: HTMLCanvasElement;
  hasPixels: boolean;
};

export const renderGridToCanvas = (
  grid: string[][],
  width: number,
  height: number
): RenderedGridCanvas | null => {
  if (
    typeof document === 'undefined' ||
    !Number.isFinite(width) ||
    !Number.isFinite(height)
  ) {
    return null;
  }
  const targetWidth = Math.max(1, Math.floor(width));
  const targetHeight = Math.max(1, Math.floor(height));
  const canvas = document.createElement('canvas');
  if (!canvas) {
    return null;
  }
  canvas.width = targetWidth;
  canvas.height = targetHeight;
  const ctx = canvas.getContext('2d');
  if (!ctx) {
    return null;
  }
  ctx.clearRect(0, 0, targetWidth, targetHeight);
  ctx.imageSmoothingEnabled = false;
  let hasPixels = false;
  const xLimit = Math.max(targetWidth, grid.length);
  for (let x = 0; x < xLimit; x += 1) {
    const sourceColumn = grid[x];
    const column = Array.isArray(sourceColumn) ? sourceColumn : [];
    const yLimit = Math.max(targetHeight, column.length);
    for (let y = 0; y < yLimit; y += 1) {
      const color = column[y];
      if (!color || color === TRANSPARENT_HEX) {
        continue;
      }
      ctx.fillStyle = color;
      ctx.fillRect(x, y, 1, 1);
      hasPixels = true;
    }
  }
  return { canvas, hasPixels };
};

export const buildPngBlobFromGrid = async (
  grid: string[][],
  width: number,
  height: number
): Promise<GridExportResult | null> => {
  const rendered = renderGridToCanvas(grid, width, height);
  if (!rendered) {
    return null;
  }
  const blob = await new Promise<Blob | null>((resolve) => {
    rendered.canvas.toBlob((result) => resolve(result), 'image/png');
  });
  if (!blob) {
    return null;
  }
  return { blob, hasPixels: rendered.hasPixels };
};

export const sanitizeFileToken = (
  value?: string | null,
  fallback = 'custom_marking'
): string => {
  if (!value || typeof value !== 'string') {
    return fallback;
  }
  const normalized = value
    .toLowerCase()
    .replace(/\s+/g, '_')
    .replace(/[^a-z0-9_-]/g, '')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '');
  return normalized.length ? normalized : fallback;
};

export const saveBlob = (
  blob: Blob,
  fileName: string,
  extension = '.png'
): boolean => {
  const byond = (globalThis as any)?.Byond;
  if (byond && typeof byond.saveBlob === 'function') {
    byond.saveBlob(blob, fileName, extension);
    return true;
  }
  if (typeof window === 'undefined' || typeof document === 'undefined') {
    return false;
  }
  try {
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = fileName;
    document.body.appendChild(anchor);
    anchor.click();
    document.body.removeChild(anchor);
    URL.revokeObjectURL(url);
    return true;
  } catch {
    return false;
  }
};

export type BuildDmiExportOptions = {
  dirStates: Record<number, PreviewDirState>;
  canvasWidth: number;
  canvasHeight: number;
  partIds: string[];
  draftDiffIndex?: Record<number, Record<string, DiffEntry[]>> | null;
  activeDirKey: number;
  activePartKey: string;
  activeDraftDiff?: DiffEntry[] | null;
};

export type DmiStatePayload = {
  name: string;
  dirs: number;
  frames: RenderedGridCanvas[];
};

export const CARDINAL_DIRECTION_ORDER = [2, 1, 4, 8];
export const DMI_VERSION = '4.0';

export const buildDmiExportBlob = async (
  options: BuildDmiExportOptions
): Promise<Blob | null> => {
  if (typeof document === 'undefined') {
    return null;
  }
  const {
    dirStates,
    canvasWidth,
    canvasHeight,
    partIds,
    draftDiffIndex,
    activeDirKey,
    activePartKey,
    activeDraftDiff,
  } = options;
  const exportParts = partIds && partIds.length ? partIds : [GENERIC_PART_KEY];
  const states: DmiStatePayload[] = [];
  const blankGrid = createBlankGrid(canvasWidth, canvasHeight);
  for (const rawPart of exportParts) {
    const partId = rawPart || GENERIC_PART_KEY;
    if (!partId) {
      continue;
    }
    const frames: RenderedGridCanvas[] = [];
    let hasAnyPixels = false;
    for (const dirKey of CARDINAL_DIRECTION_ORDER) {
      const dirState = dirStates[dirKey];
      const dirDrafts = draftDiffIndex?.[dirKey] || null;
      const exportGrid = resolveExportGridForDirPart({
        dirState,
        dirKey,
        partKey: partId,
        canvasWidth,
        canvasHeight,
        dirDrafts,
        activeDirKey,
        activePartKey,
        activeDraftDiff,
      });
      const targetGrid =
        exportGrid && exportGrid.length ? exportGrid : blankGrid;
      const rendered = renderGridToCanvas(
        targetGrid,
        canvasWidth,
        canvasHeight
      );
      if (!rendered) {
        return null;
      }
      frames.push(rendered);
      if (rendered.hasPixels) {
        hasAnyPixels = true;
      }
    }
    if (!hasAnyPixels) {
      continue;
    }
    states.push({
      name: `export-${partId}`,
      dirs: CARDINAL_DIRECTION_ORDER.length,
      frames,
    });
  }
  if (!states.length) {
    return null;
  }
  const totalFrames = states.reduce(
    (sum, state) => sum + state.frames.length,
    0
  );
  const columns = Math.max(1, Math.ceil(Math.sqrt(totalFrames)));
  const rows = Math.max(1, Math.ceil(totalFrames / columns));
  const sheetCanvas = document.createElement('canvas');
  if (!sheetCanvas) {
    return null;
  }
  sheetCanvas.width = columns * canvasWidth;
  sheetCanvas.height = rows * canvasHeight;
  const sheetCtx = sheetCanvas.getContext('2d');
  if (!sheetCtx) {
    return null;
  }
  sheetCtx.clearRect(0, 0, sheetCanvas.width, sheetCanvas.height);
  sheetCtx.imageSmoothingEnabled = false;
  let frameIndex = 0;
  for (const state of states) {
    for (const frame of state.frames) {
      const targetX = (frameIndex % columns) * canvasWidth;
      const targetY = Math.floor(frameIndex / columns) * canvasHeight;
      sheetCtx.drawImage(frame.canvas, targetX, targetY);
      frameIndex += 1;
    }
  }
  const baseBlob = await new Promise<Blob | null>((resolve) => {
    sheetCanvas.toBlob((result) => resolve(result), 'image/png');
  });
  if (!baseBlob) {
    return null;
  }
  const metadata = buildDmiMetadata(states, canvasWidth, canvasHeight);
  const finalBlob = await insertPngTextChunk(baseBlob, 'Description', metadata);
  if (!finalBlob) {
    return null;
  }
  return finalBlob;
};

export const buildDmiMetadata = (
  states: DmiStatePayload[],
  width: number,
  height: number
): string => {
  const lines = [
    '# BEGIN DMI',
    `version = ${DMI_VERSION}`,
    `\twidth = ${width}`,
    `\theight = ${height}`,
  ];
  for (const state of states) {
    lines.push(`state = ${escapeDmiStateName(state.name)}`);
    lines.push(`\tdirs = ${state.dirs}`);
    lines.push('\tframes = 1');
  }
  lines.push('# END DMI');
  return lines.join('\n');
};

export const escapeDmiStateName = (value: string): string => {
  const escaped = value.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
  return `"${escaped}"`;
};

export const insertPngTextChunk = async (
  pngBlob: Blob,
  keyword: string,
  text: string
): Promise<Blob | null> => {
  const buffer = await pngBlob.arrayBuffer();
  const bytes = new Uint8Array(buffer);
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  for (let i = 0; i < signature.length; i += 1) {
    if (bytes[i] !== signature[i]) {
      return null;
    }
  }
  let offset = 8;
  let insertPos = bytes.length;
  while (offset < bytes.length) {
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
    const chunkEnd = typeStart + 4 + length + 4;
    offset = chunkEnd;
    if (type === 'IHDR') {
      insertPos = chunkEnd;
      break;
    }
  }
  const chunkBytes = createTextChunkBytes(keyword, text);
  if (!chunkBytes) {
    return null;
  }
  const output = new Uint8Array(bytes.length + chunkBytes.length);
  output.set(bytes.slice(0, insertPos), 0);
  output.set(chunkBytes, insertPos);
  output.set(bytes.slice(insertPos), insertPos + chunkBytes.length);
  return new Blob([output], { type: 'image/png' });
};

export const createTextChunkBytes = (
  keyword: string,
  text: string
): Uint8Array => {
  const encoder = new TextEncoder();
  const keywordBytes = encoder.encode(keyword);
  const textBytes = encoder.encode(text);
  const dataLength = keywordBytes.length + 1 + textBytes.length;
  const chunk = new Uint8Array(4 + 4 + dataLength + 4);
  const view = new DataView(chunk.buffer);
  view.setUint32(0, dataLength);
  chunk.set([0x74, 0x45, 0x58, 0x74], 4);
  chunk.set(keywordBytes, 8);
  chunk[8 + keywordBytes.length] = 0;
  chunk.set(textBytes, 9 + keywordBytes.length);
  const crc = crc32(chunk, 4, 8 + dataLength);
  view.setUint32(8 + dataLength, crc >>> 0);
  return chunk;
};

export const CRC32_TABLE = (() => {
  const table = new Uint32Array(256);
  for (let i = 0; i < 256; i += 1) {
    let c = i;
    for (let j = 0; j < 8; j += 1) {
      if (c & 1) {
        c = 0xedb88320 ^ (c >>> 1);
      } else {
        c >>>= 1;
      }
    }
    table[i] = c >>> 0;
  }
  return table;
})();

export const crc32 = (
  bytes: Uint8Array,
  start: number,
  end: number
): number => {
  let crc = 0xffffffff;
  for (let i = start; i < end; i += 1) {
    const byte = bytes[i];
    crc = (crc >>> 8) ^ CRC32_TABLE[(crc ^ byte) & 0xff];
  }
  return (crc ^ 0xffffffff) >>> 0;
};
