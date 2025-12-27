// /////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: New body marking selection tab added //
// /////////////////////////////////////////////////////////////////////////////////////

import { Component } from 'inferno';
import {
  backendSetSharedState,
  selectBackend,
  useBackend,
  useLocalState,
} from '../../backend';
import {
  Box,
  Button,
  ColorBox,
  Flex,
  Input,
  LabeledList,
  NoticeBox,
  Section,
  Tabs,
  RogueStarColorPicker,
} from '../../components';
import { normalizeHex, TRANSPARENT_HEX } from '../../utils/color';
import {
  applyBodyColorToPreview,
  buildPartPaintPresenceMap,
  buildRenderedPreviewDirs as buildDesignerPreviewDirs,
  buildBasicStateFromPayload,
  clampChannel,
  ICON_BLEND_MODE,
  parseHex,
  recolorGrid,
  resolveBlendMode,
  tintGrid,
  toHex,
  updatePreviewStateFromPayload,
} from './utils';
import {
  buildRenderedPreviewDirs as buildBasePreviewDirs,
  cloneGridData,
  createBlankGrid,
  getPreviewGridFromAsset,
  getPreviewPartMapFromAssets,
  gridHasPixels,
  type GearOverlayAsset,
  type IconAssetPayload,
  PreviewDirectionEntry,
  type PreviewLayerEntry,
  type PreviewDirState,
} from '../../utils/character-preview';
import { DirectionPreviewCanvas, LoadingOverlay } from './components';
import { CHIP_BUTTON_CLASS, PREVIEW_PIXEL_SIZE } from './constants';
import type {
  BasicAppearanceAccessoryDefinition,
  BasicAppearanceGradientDefinition,
  BasicAppearancePayload,
  BasicAppearanceState,
  BodyMarkingColorTarget,
  BodyMarkingDefinition,
  BodyMarkingEntry,
  BodyMarkingsPayload,
  BodyMarkingPartState,
  BodyMarkingsSavedState,
  CanvasBackgroundOption,
  CustomMarkingDesignerData,
} from './types';
import {
  buildBodyMarkingDefinitions,
  buildBodyMarkingSavePayload,
  buildBodyMarkingChunkPlan,
  buildBodyPayloadSignature,
  buildBodySavedStateFromPayload,
  cloneEntry,
  deepCopyMarkings,
  isBodyMarkingPartEnabled,
  resolveBodyMarkingColorTarget,
} from './utils/bodyMarkings';

type BodyMarkingsTabProps = Readonly<{
  data: CustomMarkingDesignerData;
  setPendingClose: (state: boolean) => void;
  setPendingSave: (state: boolean) => void;
  canvasBackgroundOptions: CanvasBackgroundOption[];
  resolvedCanvasBackground: CanvasBackgroundOption | null;
  backgroundFallbackColor: string;
  cycleCanvasBackground: () => void;
  canvasBackgroundScale: number;
  resolvedPartPriorityMap: Record<string, boolean>;
  resolvedPartReplacementMap: Record<string, boolean>;
  showJobGear: boolean;
  onToggleJobGear: () => void;
  showLoadoutGear: boolean;
  onToggleLoadout: () => void;
}>;

type MarkingLayer = {
  label: string;
  grid: string[][];
};

type PartMarkingLayers = {
  normal: MarkingLayer[];
  priority: MarkingLayer[];
};

type OrderedOverlayLayer = {
  grid: string[][];
  layer: number | null;
  slot?: string | null;
  source: 'base' | 'job' | 'loadout';
  order: number;
};

type MarkingLayersCacheEntry = {
  entry: BodyMarkingEntry;
  defId: string;
  doColouration: boolean;
  blendMode: number;
  renderAboveBody: boolean;
  renderAboveBodyPartsSig: string;
  digitigrade: boolean;
  canvasWidth: number;
  canvasHeight: number;
  offsetX: number;
  assetRevision: number;
  built: Record<string, PartMarkingLayers>;
};

type SelectMarkingOptions = Readonly<{
  setColorTarget?: boolean;
}>;

const MARKING_TILE_PIXEL_SIZE = 2;
const BODY_MARKING_SELECTION_LIMIT = 40;

const CATEGORY_LABELS: Record<string, string> = {
  all: 'All',
  heads: 'Head',
  bodies: 'Body',
  limbs: 'Limbs',
  addons: 'Tats/Scars',
  skintone: 'Skintone',
  teshari: 'Teshari',
  vox: 'Vox',
  augment: 'Augment',
};

const OVERLAY_SLOT_PRIORITY_MAP: Record<string, number> = {
  tail_lower: 7,
  wing_lower: 8,
  shoes: 9,
  uniform: 10,
  id: 11,
  gloves: 13,
  belt: 14,
  suit: 15,
  tail_upper: 16,
  glasses: 17,
  suit_store: 19,
  back: 20,
  hair: 21,
  hair_accessory: 22,
  ears: 23,
  eyes: 24,
  mask: 25,
  head: 27,
  wing_upper: 32,
  tail_upper_alt: 33,
  modifier: 34,
  vore_belly: 38,
  vore_tail: 39,
  custom_marking: 40,
};

const HIDDEN_LEG_PARTS = new Set(['l_leg', 'r_leg', 'l_foot', 'r_foot']);
const TAUR_CLOTHING_SLOTS = new Set(['uniform', 'belt', 'suit', 'back']);
const APPEARANCE_OVERLAY_SLOTS = new Set([
  'hair',
  'hair_accessory',
  'ears',
  'tail_lower',
  'tail_upper',
  'tail_upper_alt',
  'wing_lower',
  'wing_upper',
]);

let assetUpdateScheduled = false;

const BODY_MARKINGS_PREVIEW_TIMEOUT_MS = 5000;

const collectBodyColorExcludedParts = (
  dirStates: Record<number, PreviewDirState> | null | undefined
): Set<string> | null => {
  if (!dirStates) {
    return null;
  }
  const excluded = new Set<string>();
  for (const dirState of Object.values(dirStates)) {
    const parts = dirState?.bodyColorExcludedParts;
    if (!Array.isArray(parts)) {
      continue;
    }
    for (const partId of parts) {
      if (typeof partId === 'string' && partId.length) {
        excluded.add(partId);
      }
    }
  }
  return excluded.size ? excluded : null;
};

const colorDistance = (
  r: number,
  g: number,
  b: number,
  target: [number, number, number]
) =>
  Math.abs(r - target[0]) + Math.abs(g - target[1]) + Math.abs(b - target[2]);

const EYE_COLOR_MATCH_THRESHOLD = 90;
const EYE_COLOR_BODY_MARGIN = 12;

const shiftEyeColorGrid = (
  grid: string[][],
  baseHex: string,
  targetHex: string,
  bodyHex?: string | null
): string[][] => {
  const [br, bg, bb] = parseHex(baseHex);
  const [tr, tg, tb] = parseHex(targetHex);
  if (br === tr && bg === tg && bb === tb) {
    return grid;
  }
  const hasBody = typeof bodyHex === 'string' && normalizeHex(bodyHex) !== null;
  const [bodyR, bodyG, bodyB] = hasBody
    ? parseHex(bodyHex as string)
    : ([0, 0, 0] as [number, number, number]);
  const deltaR = tr - br;
  const deltaG = tg - bg;
  const deltaB = tb - bb;
  const recolored: string[][] = [];
  for (let x = 0; x < grid.length; x += 1) {
    const column = grid[x];
    if (!Array.isArray(column)) {
      recolored[x] = [];
      continue;
    }
    recolored[x] = [];
    for (let y = 0; y < column.length; y += 1) {
      const px = column[y];
      if (typeof px !== 'string' || px === TRANSPARENT_HEX) {
        recolored[x][y] = TRANSPARENT_HEX;
        continue;
      }
      const [r, g, b, a] = parseHex(px);
      const eyeDist = colorDistance(r, g, b, [br, bg, bb]);
      const bodyDist = hasBody
        ? colorDistance(r, g, b, [bodyR, bodyG, bodyB])
        : Number.POSITIVE_INFINITY;
      const matchesEye =
        eyeDist <= EYE_COLOR_MATCH_THRESHOLD ||
        eyeDist + EYE_COLOR_BODY_MARGIN <= bodyDist;
      if (!matchesEye) {
        recolored[x][y] = px;
        continue;
      }
      recolored[x][y] = toHex(
        clampChannel(r + deltaR),
        clampChannel(g + deltaG),
        clampChannel(b + deltaB),
        a
      );
    }
  }
  return recolored;
};

export const applyEyeColorToPreview = (
  preview: PreviewDirectionEntry[],
  baseHex: string | null,
  targetHex: string | null,
  bodyHex?: string | null
): PreviewDirectionEntry[] => {
  const base = normalizeHex(baseHex);
  const target = normalizeHex(targetHex);
  if (!base || !target || base === target) {
    return preview;
  }
  let changed = false;
  const next = preview.map((entry) => {
    let layersChanged = false;
    const layers = (entry.layers || []).map((layer) => {
      if (!layer?.grid || layer.type !== 'reference_part') {
        return layer;
      }
      if (
        typeof layer.key !== 'string' ||
        !layer.key.startsWith('ref_') ||
        layer.key.endsWith('_markings')
      ) {
        return layer;
      }
      const partId = layer.key.slice(4).toLowerCase();
      if (partId !== 'head' && partId !== 'face' && partId !== 'eyes') {
        return layer;
      }
      const shifted = shiftEyeColorGrid(layer.grid, base, target, bodyHex);
      if (shifted === layer.grid) {
        return layer;
      }
      layersChanged = true;
      return {
        ...layer,
        grid: shifted,
      };
    });
    if (!layersChanged) {
      return entry;
    }
    changed = true;
    return {
      ...entry,
      layers,
    };
  });
  return changed ? next : preview;
};

const pixelHasColor = (value?: string): boolean =>
  typeof value === 'string' && value.length > 0 && value !== TRANSPARENT_HEX;

const compositePixel = (base: string | undefined, overlay: string): string => {
  if (!pixelHasColor(overlay)) {
    return base || TRANSPARENT_HEX;
  }
  if (!pixelHasColor(base)) {
    return overlay;
  }
  const [sr, sg, sb, sa] = parseHex(overlay);
  if (sa >= 255) {
    return overlay;
  }
  if (sa <= 0) {
    return base || TRANSPARENT_HEX;
  }
  const [dr, dg, db, da] = parseHex(base);
  const srcA = sa / 255;
  const dstA = da / 255;
  const outA = srcA + dstA * (1 - srcA);
  if (outA <= 0) {
    return TRANSPARENT_HEX;
  }
  const outR = Math.round((sr * srcA + dr * dstA * (1 - srcA)) / outA);
  const outG = Math.round((sg * srcA + dg * dstA * (1 - srcA)) / outA);
  const outB = Math.round((sb * srcA + db * dstA * (1 - srcA)) / outA);
  const outAlpha = Math.round(outA * 255);
  if (outAlpha <= 0) {
    return TRANSPARENT_HEX;
  }
  return toHex(outR, outG, outB, outAlpha);
};

const addPixel = (base: string | undefined, overlay: string): string => {
  if (!pixelHasColor(overlay)) {
    return base || TRANSPARENT_HEX;
  }
  const [sr, sg, sb, sa] = parseHex(overlay);
  if (sa <= 0) {
    return base || TRANSPARENT_HEX;
  }
  const [dr, dg, db, da] = pixelHasColor(base) ? parseHex(base) : [0, 0, 0, 0];
  const alphaFactor = sa / 255;
  const outR = clampChannel(dr + Math.round(sr * alphaFactor));
  const outG = clampChannel(dg + Math.round(sg * alphaFactor));
  const outB = clampChannel(db + Math.round(sb * alphaFactor));
  const outA = clampChannel(Math.max(da, sa));
  if (outA <= 0) {
    return TRANSPARENT_HEX;
  }
  return toHex(outR, outG, outB, outA);
};

const mergeGrid = (target: string[][], source?: string[][] | null) => {
  if (!Array.isArray(target) || !Array.isArray(source)) {
    return;
  }
  for (let x = 0; x < source.length; x += 1) {
    const srcCol = source[x];
    if (!Array.isArray(srcCol)) {
      continue;
    }
    if (!Array.isArray(target[x])) {
      target[x] = [];
    }
    for (let y = 0; y < srcCol.length; y += 1) {
      const val = srcCol[y];
      if (typeof val !== 'string' || val === TRANSPARENT_HEX) {
        continue;
      }
      target[x][y] = compositePixel(target[x][y], val);
    }
  }
};

const mergeGridAdd = (target: string[][], source?: string[][] | null) => {
  if (!Array.isArray(target) || !Array.isArray(source)) {
    return;
  }
  for (let x = 0; x < source.length; x += 1) {
    const srcCol = source[x];
    if (!Array.isArray(srcCol)) {
      continue;
    }
    if (!Array.isArray(target[x])) {
      target[x] = [];
    }
    for (let y = 0; y < srcCol.length; y += 1) {
      const val = srcCol[y];
      if (typeof val !== 'string' || val === TRANSPARENT_HEX) {
        continue;
      }
      target[x][y] = addPixel(target[x][y], val);
    }
  }
};

const applyMaskToGrid = (target: string[][], mask: string[][]) => {
  if (!Array.isArray(target) || !Array.isArray(mask)) {
    return;
  }
  const width = Math.min(target.length, mask.length);
  for (let x = 0; x < width; x += 1) {
    const targetColumn = target[x];
    const maskColumn = mask[x];
    if (!Array.isArray(targetColumn) || !Array.isArray(maskColumn)) {
      continue;
    }
    const height = Math.min(targetColumn.length, maskColumn.length);
    for (let y = 0; y < height; y += 1) {
      if (!pixelHasColor(maskColumn[y]) || !pixelHasColor(targetColumn[y])) {
        continue;
      }
      targetColumn[y] = TRANSPARENT_HEX;
    }
  }
};

const applyClipMaskToGrid = (target: string[][], mask: string[][]) => {
  if (!Array.isArray(target) || !Array.isArray(mask)) {
    return;
  }
  const width = Math.min(target.length, mask.length);
  for (let x = 0; x < width; x += 1) {
    const targetColumn = target[x];
    const maskColumn = mask[x];
    if (!Array.isArray(targetColumn) || !Array.isArray(maskColumn)) {
      continue;
    }
    const height = Math.min(targetColumn.length, maskColumn.length);
    for (let y = 0; y < height; y += 1) {
      if (!pixelHasColor(targetColumn[y])) {
        continue;
      }
      if (pixelHasColor(maskColumn[y])) {
        targetColumn[y] = TRANSPARENT_HEX;
      }
    }
  }
};

const collectHiddenLegParts = (hiddenBodyParts?: string[] | null): string[] => {
  if (!Array.isArray(hiddenBodyParts)) {
    return [];
  }
  const parts: string[] = [];
  for (const partId of hiddenBodyParts) {
    if (typeof partId === 'string' && HIDDEN_LEG_PARTS.has(partId)) {
      parts.push(partId);
    }
  }
  return parts;
};

const buildHiddenBodyPartsByDir = (
  previewDirStates: Record<number, PreviewDirState>
): Record<number, Record<string, boolean>> => {
  const result: Record<number, Record<string, boolean>> = {};
  for (const dirState of Object.values(previewDirStates)) {
    const hiddenParts = dirState?.hiddenBodyParts;
    if (!dirState || !Array.isArray(hiddenParts) || !hiddenParts.length) {
      continue;
    }
    const hiddenMap: Record<string, boolean> = {};
    for (const partId of hiddenParts) {
      if (typeof partId === 'string' && partId.length) {
        hiddenMap[partId] = true;
      }
    }
    if (Object.keys(hiddenMap).length) {
      result[dirState.dir] = hiddenMap;
    }
  }
  return result;
};

const maskGridForHiddenLegParts = (
  grid: string[][],
  referenceParts: Record<string, string[][]>,
  hiddenLegParts: string[]
) => {
  if (!hiddenLegParts.length) {
    return;
  }
  for (const partId of hiddenLegParts) {
    const maskGrid = referenceParts[partId];
    if (!maskGrid) {
      continue;
    }
    applyClipMaskToGrid(grid, maskGrid);
  }
};

const buildHairGradientOverlayGrid = (options: {
  hairTexture: string[][] | null;
  gradientMask: string[][] | null;
  gradientColor: string | null;
}): string[][] | null => {
  const { hairTexture, gradientMask, gradientColor } = options;
  const normalizedGradientColor = normalizeHex(gradientColor);
  if (!normalizedGradientColor || !hairTexture || !gradientMask) {
    return null;
  }
  const [tr, tg, tb] = parseHex(normalizedGradientColor);
  const width = hairTexture.length;
  if (!width) {
    return null;
  }
  const height = Array.isArray(hairTexture[0]) ? hairTexture[0].length : 0;
  if (!height) {
    return null;
  }
  const overlay = createBlankGrid(width, height);
  let hasPixels = false;
  for (let x = 0; x < hairTexture.length; x += 1) {
    const hairColumn = hairTexture[x];
    if (!Array.isArray(hairColumn)) {
      continue;
    }
    const maskColumn = gradientMask[x];
    const overlayColumn = overlay[x];
    for (let y = 0; y < hairColumn.length; y += 1) {
      const hairPixel = hairColumn[y];
      if (
        typeof hairPixel !== 'string' ||
        hairPixel.length === 0 ||
        hairPixel === TRANSPARENT_HEX
      ) {
        continue;
      }
      const [hr, hg, hb, ha] = parseHex(hairPixel);
      if (ha <= 0) {
        continue;
      }
      const maskPixel = Array.isArray(maskColumn) ? maskColumn[y] : null;
      if (typeof maskPixel !== 'string' || maskPixel.length === 0) {
        continue;
      }
      const maskAlpha = parseHex(maskPixel)[3];
      if (maskAlpha <= 0) {
        continue;
      }
      const outAlpha = clampChannel(Math.round((ha * maskAlpha) / 255));
      if (outAlpha <= 0) {
        continue;
      }
      const outR = clampChannel(Math.round((hr * tr) / 255));
      const outG = clampChannel(Math.round((hg * tg) / 255));
      const outB = clampChannel(Math.round((hb * tb) / 255));
      overlayColumn[y] = toHex(outR, outG, outB, outAlpha);
      hasPixels = true;
    }
  }
  if (!hasPixels) {
    return null;
  }
  return overlay;
};

const shiftGrid = (
  source: string[][],
  offsetX: number,
  offsetY: number,
  width: number,
  height: number
): string[][] => {
  const target = createBlankGrid(width, height);
  for (let x = 0; x < source.length; x += 1) {
    const col = source[x];
    if (!Array.isArray(col)) {
      continue;
    }
    for (let y = 0; y < col.length; y += 1) {
      const val = col[y];
      if (typeof val !== 'string') {
        continue;
      }
      const nx = x + offsetX;
      const ny = y + offsetY;
      if (nx < 0 || ny < 0 || nx >= width || ny >= height) {
        continue;
      }
      target[nx][ny] = val;
    }
  }
  return target;
};

const buildAccessoryGrid = (options: {
  def: BasicAppearanceAccessoryDefinition;
  dir: number;
  canvasWidth: number;
  canvasHeight: number;
  colors: (string | null)[];
  signalAssetUpdate: () => void;
  extraOffsetX?: number;
}): string[][] | null => {
  const {
    def,
    dir,
    canvasWidth,
    canvasHeight,
    colors,
    signalAssetUpdate,
    extraOffsetX,
  } = options;
  const assetsForDir = def.assets?.[dir];
  if (!assetsForDir || !assetsForDir.length) {
    return null;
  }
  let combined: string[][] | null = null;
  for (let channel = 0; channel < assetsForDir.length; channel += 1) {
    const payload = assetsForDir[channel];
    if (!payload) {
      continue;
    }
    const grid = getPreviewGridFromAsset(
      payload,
      canvasWidth,
      canvasHeight,
      signalAssetUpdate
    );
    if (!grid) {
      continue;
    }
    let working = grid as string[][];
    const color = colors[channel];
    if (def.do_colouration && typeof color === 'string' && color.length) {
      working = tintGrid(
        working,
        color,
        typeof def.color_blend_mode === 'number'
          ? def.color_blend_mode
          : ICON_BLEND_MODE.MULTIPLY
      );
    }
    if (typeof extraOffsetX === 'number' && extraOffsetX) {
      working = shiftGrid(
        working,
        extraOffsetX,
        0,
        Math.max(canvasWidth, working.length),
        canvasHeight
      );
    }
    if (!combined) {
      combined = cloneGridData(working);
      continue;
    }
    mergeGrid(combined, working);
  }
  if (combined && gridHasPixels(combined)) {
    return combined;
  }
  return null;
};

const buildHairGridWithGradient = (options: {
  hairDef: BasicAppearanceAccessoryDefinition;
  gradientDef: BasicAppearanceGradientDefinition | null;
  dir: number;
  canvasWidth: number;
  canvasHeight: number;
  hairColor: string | null;
  gradientColor: string | null;
  signalAssetUpdate: () => void;
}): string[][] | null => {
  const {
    hairDef,
    gradientDef,
    dir,
    canvasWidth,
    canvasHeight,
    hairColor,
    gradientColor,
    signalAssetUpdate,
  } = options;
  const assetsForDir = hairDef.assets?.[dir];
  if (!assetsForDir || !assetsForDir.length) {
    return null;
  }
  const basePayload = assetsForDir[0];
  if (!basePayload) {
    return null;
  }
  const baseGrid = getPreviewGridFromAsset(
    basePayload,
    canvasWidth,
    canvasHeight,
    signalAssetUpdate
  ) as string[][] | null;
  if (!baseGrid) {
    return null;
  }
  if (!hairDef?.do_colouration) {
    return baseGrid;
  }

  const resolvedHairColor = normalizeHex(hairColor) || '#ffffff';
  const base = tintGrid(baseGrid, resolvedHairColor, ICON_BLEND_MODE.MULTIPLY);
  const addPayload = assetsForDir.length > 1 ? assetsForDir[1] : null;
  if (addPayload) {
    const addGrid = getPreviewGridFromAsset(
      addPayload,
      canvasWidth,
      canvasHeight,
      signalAssetUpdate
    ) as string[][] | null;
    if (addGrid) {
      mergeGridAdd(base, addGrid);
    }
  }

  if (!gradientDef) {
    return base;
  }
  const gradPayload = gradientDef.assets?.[dir];
  if (!gradPayload) {
    return base;
  }
  const gradGrid = getPreviewGridFromAsset(
    gradPayload,
    canvasWidth,
    canvasHeight,
    signalAssetUpdate
  );
  if (!gradGrid) {
    return base;
  }
  const overlay = buildHairGradientOverlayGrid({
    hairTexture: baseGrid,
    gradientMask: gradGrid as string[][],
    gradientColor,
  });
  if (!overlay) {
    return base;
  }
  mergeGrid(base, overlay);
  return base;
};

const buildOrderedOverlayLayers = (
  assets: (GearOverlayAsset | IconAssetPayload)[],
  canvasWidth: number,
  canvasHeight: number,
  source: OrderedOverlayLayer['source'],
  signalAssetUpdate?: () => void,
  orderOffset = 0
): OrderedOverlayLayer[] => {
  const layers: OrderedOverlayLayer[] = [];
  const updateSignal = signalAssetUpdate || (() => undefined);
  for (let i = 0; i < assets.length; i += 1) {
    const entry = assets[i] as GearOverlayAsset | IconAssetPayload;
    const payload =
      (entry as GearOverlayAsset)?.asset ||
      ((entry as IconAssetPayload)?.token ? (entry as IconAssetPayload) : null);
    if (!payload) {
      continue;
    }
    const grid = getPreviewGridFromAsset(
      payload,
      canvasWidth,
      canvasHeight,
      updateSignal
    );
    if (!grid) {
      continue;
    }
    const slot =
      (entry as GearOverlayAsset)?.slot !== undefined
        ? ((entry as GearOverlayAsset).slot as string | null)
        : null;
    const hasSlotPriority =
      !!slot &&
      Object.prototype.hasOwnProperty.call(OVERLAY_SLOT_PRIORITY_MAP, slot);
    const fallbackLayer = hasSlotPriority
      ? OVERLAY_SLOT_PRIORITY_MAP[slot as string]
      : null;
    const rawLayer = (entry as GearOverlayAsset)?.layer;
    let layerValue: number | null = null;
    if (typeof rawLayer === 'number') {
      layerValue = rawLayer;
    } else if (hasSlotPriority && fallbackLayer !== null) {
      layerValue = fallbackLayer;
    } else {
      layerValue = orderOffset + i;
    }
    layers.push({
      grid: grid as string[][],
      layer: layerValue,
      slot,
      source,
      order: orderOffset + i,
    });
  }
  return layers;
};

const mergeOverlayLayerLists = (
  baseLayers: OrderedOverlayLayer[],
  jobLayers: OrderedOverlayLayer[],
  loadoutLayers: OrderedOverlayLayer[]
): OrderedOverlayLayer[] =>
  [...baseLayers, ...jobLayers, ...loadoutLayers].sort((a, b) => {
    const layerA = Number.isFinite(a.layer)
      ? (a.layer as number)
      : Number.MAX_SAFE_INTEGER;
    const layerB = Number.isFinite(b.layer)
      ? (b.layer as number)
      : Number.MAX_SAFE_INTEGER;
    if (layerA !== layerB) {
      return layerA - layerB;
    }
    return a.order - b.order;
  });

const resolveSelectedDef = <T extends { id: string }>(
  defs: T[] | undefined,
  id: string | null
): T | null => {
  if (!id || !Array.isArray(defs)) {
    return null;
  }
  return defs.find((entry) => entry.id === id) || null;
};

const buildReferencePartMaskMap = (
  layers: Array<{ key?: string; type?: string; grid?: string[][] }>
): Record<string, string[][]> => {
  const map: Record<string, string[][]> = {};
  if (!Array.isArray(layers)) {
    return map;
  }
  layers.forEach((layer) => {
    if (layer?.type !== 'reference_part') {
      return;
    }
    const key = layer?.key;
    if (typeof key !== 'string' || !key.startsWith('ref_')) {
      return;
    }
    const partId = key.slice('ref_'.length);
    if (!partId || partId.endsWith('_markings')) {
      return;
    }
    if (!map[partId] && Array.isArray(layer.grid)) {
      map[partId] = layer.grid as string[][];
    }
  });
  return map;
};

const buildMaskedGenericGrid = (
  genericGrid: string[][],
  referenceMasks: Record<string, string[][]>,
  hiddenPartsMap: Record<string, boolean>
): string[][] => {
  const cloned = cloneGridData(genericGrid);
  Object.keys(hiddenPartsMap).forEach((partId) => {
    if (!hiddenPartsMap[partId]) {
      return;
    }
    const maskGrid = referenceMasks[partId];
    if (!maskGrid) {
      return;
    }
    applyMaskToGrid(cloned, maskGrid);
  });
  return cloned;
};

const buildHiddenBodyPartsMapForSingleMarking = (
  def: BodyMarkingDefinition,
  entry: BodyMarkingEntry
): Record<string, boolean> => {
  const hidden: Record<string, boolean> = {};
  const hideList = def?.hide_body_parts;
  if (!Array.isArray(hideList) || !hideList.length) {
    return hidden;
  }
  for (const partId of def.body_parts || []) {
    if (!partId || hideList.indexOf(partId) === -1) {
      continue;
    }
    const partState = entry?.[partId] as BodyMarkingPartState;
    if (!isBodyMarkingPartEnabled(partState?.on)) {
      continue;
    }
    hidden[partId] = true;
  }
  return hidden;
};

const buildHiddenBodyPartsMapForMarkings = (
  defs: Record<string, BodyMarkingDefinition>,
  entries: Record<string, BodyMarkingEntry>,
  orderedIds: string[]
): Record<string, boolean> => {
  const hidden: Record<string, boolean> = {};
  for (const markId of orderedIds || []) {
    const def = defs[markId];
    const entry = entries[markId];
    if (!def || !entry) {
      continue;
    }
    const hideList = def.hide_body_parts;
    if (!Array.isArray(hideList) || !hideList.length) {
      continue;
    }
    for (const partId of def.body_parts || []) {
      if (!partId || hideList.indexOf(partId) === -1) {
        continue;
      }
      const partState = entry?.[partId] as BodyMarkingPartState;
      if (!isBodyMarkingPartEnabled(partState?.on)) {
        continue;
      }
      hidden[partId] = true;
    }
  }
  return hidden;
};

const applyGridOffset = (
  source: string[][],
  offsetX: number,
  offsetY: number,
  width: number,
  height: number
): string[][] => {
  if (!offsetX && !offsetY && source.length === width) {
    let matchesTargetSize = true;
    for (let x = 0; x < source.length; x += 1) {
      const col = source[x];
      if (!Array.isArray(col) || col.length !== height) {
        matchesTargetSize = false;
        break;
      }
    }
    if (matchesTargetSize) {
      return source;
    }
  }
  const target = createBlankGrid(width, height);
  for (let x = 0; x < source.length; x += 1) {
    const col = source[x];
    if (!Array.isArray(col)) {
      continue;
    }
    for (let y = 0; y < col.length; y += 1) {
      const val = col[y];
      if (typeof val !== 'string') {
        continue;
      }
      const nx = x + offsetX;
      const ny = y + offsetY;
      if (nx < 0 || ny < 0 || nx >= width || ny >= height) {
        continue;
      }
      if (!Array.isArray(target[nx])) {
        target[nx] = [];
      }
      target[nx][ny] = val;
    }
  }
  return target;
};

const buildMarkingLayersForDir = (
  def: BodyMarkingDefinition,
  entry: BodyMarkingEntry,
  dir: number,
  digitigrade: boolean,
  canvasWidth: number,
  canvasHeight: number,
  offsetX = 0,
  signalAssetUpdate?: () => void
): Record<string, PartMarkingLayers> => {
  const assetsByDir =
    (digitigrade && def.digitigrade_assets?.[dir]) || def.assets?.[dir];
  if (!assetsByDir) {
    return {};
  }
  const defaultColor = entry?.color || def.default_color || '#000000';
  const result: Record<string, PartMarkingLayers> = {};
  for (const [partId, asset] of Object.entries(assetsByDir)) {
    const partState = entry?.[partId] as BodyMarkingPartState;
    if (!isBodyMarkingPartEnabled(partState?.on)) {
      continue;
    }
    const partColor =
      typeof partState?.color === 'string' ? partState.color : defaultColor;
    const baseGrid = getPreviewGridFromAsset(
      asset,
      canvasWidth,
      canvasHeight,
      signalAssetUpdate || (() => undefined)
    );
    if (!baseGrid || !gridHasPixels(baseGrid)) {
      continue;
    }
    const tinted = def.do_colouration
      ? tintGrid(baseGrid, partColor, def.color_blend_mode)
      : baseGrid;
    const shifted = applyGridOffset(
      tinted,
      offsetX,
      0,
      canvasWidth,
      canvasHeight
    );
    const isPriority =
      def.render_above_body || !!def.render_above_body_parts?.[partId];
    if (!result[partId]) {
      result[partId] = { normal: [], priority: [] };
    }
    const target = isPriority ? result[partId].priority : result[partId].normal;
    target.push({
      label: def.name,
      grid: shifted,
    });
  }
  return result;
};

const resolveLayerPartId = (layer: { key?: string; type?: string }) => {
  if (typeof layer?.key === 'string' && layer.key.startsWith('ref_')) {
    const raw = layer.key.slice('ref_'.length);
    if (!raw) {
      return null;
    }
    if (raw.endsWith('_markings')) {
      const trimmed = raw.slice(0, -'_markings'.length);
      return trimmed || null;
    }
    return raw;
  }
  if (
    layer?.type === 'custom' &&
    typeof layer?.key === 'string' &&
    layer.key.startsWith('custom_')
  ) {
    const raw = layer.key.slice('custom_'.length);
    return raw || null;
  }
  if (layer?.key === 'body' || layer?.type === 'body') {
    return 'generic';
  }
  return null;
};

const splitOverlayLayers = <T extends { type?: string }>(layers: T[]) => {
  const firstOverlayIndex = layers.findIndex(
    (layer) => layer?.type === 'overlay'
  );
  if (firstOverlayIndex === -1) {
    return { before: layers, overlay: [], after: [] };
  }
  let lastOverlayIndex = firstOverlayIndex;
  for (let idx = layers.length - 1; idx >= 0; idx -= 1) {
    if (layers[idx]?.type === 'overlay') {
      lastOverlayIndex = idx;
      break;
    }
  }
  return {
    before: layers.slice(0, firstOverlayIndex),
    overlay: layers.slice(firstOverlayIndex, lastOverlayIndex + 1),
    after: layers.slice(lastOverlayIndex + 1),
  };
};

export type AppearancePreviewContext = Readonly<{
  canApplyAppearance: boolean;
  appearanceState: BasicAppearanceState;
  hairDef: BasicAppearanceAccessoryDefinition | null;
  gradientDef: BasicAppearanceGradientDefinition | null;
  facialHairDef: BasicAppearanceAccessoryDefinition | null;
  earDef: BasicAppearanceAccessoryDefinition | null;
  hornDef: BasicAppearanceAccessoryDefinition | null;
  tailDef: BasicAppearanceAccessoryDefinition | null;
  wingDef: BasicAppearanceAccessoryDefinition | null;
  previewBaseBodyColor: string | null;
  previewTargetBodyColor: string;
  previewBaseEyeColor: string | null;
  previewTargetEyeColor: string;
  appearanceSignature: string;
  digitigrade: boolean;
  previewDirStatesForLive: Record<number, PreviewDirState>;
  bodyColorExcludedParts: Set<string> | null;
}>;

type BodyMarkingsPreviewBaseResult = Readonly<{
  basePreview: PreviewDirectionEntry[];
  liveBasePreview: PreviewDirectionEntry[];
  appearanceContext: AppearancePreviewContext;
}>;

export const resolveAppearanceContext = (options: {
  previewDirStates: Record<number, PreviewDirState>;
  basicPayload: BasicAppearancePayload | null;
  basicAppearanceState: BasicAppearanceState;
  fallbackDigitigrade: boolean;
}): AppearancePreviewContext => {
  const {
    previewDirStates,
    basicPayload,
    basicAppearanceState,
    fallbackDigitigrade,
  } = options;
  const canApplyAppearance = !!basicPayload;
  const appearanceState = basicAppearanceState;
  const hair_styles = basicPayload?.hair_styles;
  const gradient_styles = basicPayload?.gradient_styles;
  const facial_hair_styles = basicPayload?.facial_hair_styles;
  const ear_styles = basicPayload?.ear_styles;
  const tail_styles = basicPayload?.tail_styles;
  const wing_styles = basicPayload?.wing_styles;
  const hairDef = canApplyAppearance
    ? resolveSelectedDef(hair_styles, appearanceState.hair_style)
    : null;
  const gradientDef = canApplyAppearance
    ? resolveSelectedDef(gradient_styles, appearanceState.hair_gradient_style)
    : null;
  const facialHairDef = canApplyAppearance
    ? resolveSelectedDef(facial_hair_styles, appearanceState.facial_hair_style)
    : null;
  const earDef = canApplyAppearance
    ? resolveSelectedDef(ear_styles, appearanceState.ear_style)
    : null;
  const hornDef = canApplyAppearance
    ? resolveSelectedDef(ear_styles, appearanceState.horn_style)
    : null;
  const tailDef = canApplyAppearance
    ? resolveSelectedDef(tail_styles, appearanceState.tail_style)
    : null;
  const wingDef = canApplyAppearance
    ? resolveSelectedDef(wing_styles, appearanceState.wing_style)
    : null;
  const previewBaseBodyColor = normalizeHex(basicPayload?.body_color);
  const previewTargetBodyColor =
    normalizeHex(appearanceState.body_color) || '#ffffff';
  const previewBaseEyeColor = normalizeHex(basicPayload?.eye_color);
  const previewTargetEyeColor =
    normalizeHex(appearanceState.eye_color) || '#ffffff';
  const appearanceSignature = canApplyAppearance
    ? [
        appearanceState.digitigrade ? 'd' : 'p',
        appearanceState.body_color || 'bc',
        appearanceState.eye_color || 'ec',
        appearanceState.hair_style || 'hs',
        appearanceState.hair_color || 'hc',
        appearanceState.hair_gradient_style || 'gs',
        appearanceState.hair_gradient_color || 'gc',
        appearanceState.facial_hair_style || 'fs',
        appearanceState.facial_hair_color || 'fc',
        appearanceState.ear_style || 'es',
        appearanceState.horn_style || 'hos',
        appearanceState.tail_style || 'ts',
        appearanceState.wing_style || 'ws',
        (appearanceState.ear_colors || []).join('|'),
        (appearanceState.horn_colors || []).join('|'),
        (appearanceState.tail_colors || []).join('|'),
        (appearanceState.wing_colors || []).join('|'),
      ].join('::')
    : 'no-appearance';
  const digitigrade = canApplyAppearance
    ? !!appearanceState.digitigrade
    : fallbackDigitigrade;
  const tailHideParts = tailDef?.hide_body_parts;
  const tailHiddenBodyParts = Array.isArray(tailHideParts)
    ? tailHideParts.filter(
        (part): part is string => typeof part === 'string' && part.length > 0
      )
    : [];
  const previewDirStatesForLive =
    tailHiddenBodyParts.length > 0
      ? Object.values(previewDirStates).reduce(
          (acc, dirState) => {
            if (!dirState) {
              return acc;
            }
            const currentHidden = Array.isArray(dirState.hiddenBodyParts)
              ? dirState.hiddenBodyParts
              : [];
            const mergedHidden = Array.from(
              new Set([...currentHidden, ...tailHiddenBodyParts])
            );
            if (mergedHidden.length === currentHidden.length) {
              acc[dirState.dir] = dirState;
              return acc;
            }
            acc[dirState.dir] = {
              ...dirState,
              hiddenBodyParts: mergedHidden,
            };
            return acc;
          },
          {} as Record<number, PreviewDirState>
        )
      : previewDirStates;
  const bodyColorExcludedParts = collectBodyColorExcludedParts(
    previewDirStatesForLive
  );
  return {
    canApplyAppearance,
    appearanceState,
    hairDef,
    gradientDef,
    facialHairDef,
    earDef,
    hornDef,
    tailDef,
    wingDef,
    previewBaseBodyColor,
    previewTargetBodyColor,
    previewBaseEyeColor,
    previewTargetEyeColor,
    appearanceSignature,
    digitigrade,
    previewDirStatesForLive,
    bodyColorExcludedParts,
  };
};

const buildAppearanceOverlayEntriesForDir = (options: {
  dir: number;
  dirState?: PreviewDirState;
  appearanceState: BasicAppearanceState;
  hairDef: BasicAppearanceAccessoryDefinition | null;
  gradientDef: BasicAppearanceGradientDefinition | null;
  facialHairDef: BasicAppearanceAccessoryDefinition | null;
  earDef: BasicAppearanceAccessoryDefinition | null;
  hornDef: BasicAppearanceAccessoryDefinition | null;
  tailDef: BasicAppearanceAccessoryDefinition | null;
  wingDef: BasicAppearanceAccessoryDefinition | null;
  previewBaseEyeColor: string | null;
  previewTargetEyeColor: string | null;
  canvasWidth: number;
  canvasHeight: number;
  showJobGear: boolean;
  showLoadoutGear: boolean;
  signalAssetUpdate: () => void;
}): PreviewLayerEntry[] => {
  const {
    dir,
    dirState,
    appearanceState,
    hairDef,
    gradientDef,
    facialHairDef,
    earDef,
    hornDef,
    tailDef,
    wingDef,
    previewBaseEyeColor,
    previewTargetEyeColor,
    canvasWidth,
    canvasHeight,
    showJobGear,
    showLoadoutGear,
    signalAssetUpdate,
  } = options;
  if (!dirState) {
    return [];
  }
  const hiddenLegParts = collectHiddenLegParts(dirState.hiddenBodyParts);
  const hideShoes =
    hiddenLegParts.includes('l_foot') || hiddenLegParts.includes('r_foot');
  const referenceParts =
    hiddenLegParts.length > 0
      ? getPreviewPartMapFromAssets(
          dirState.referencePartAssets,
          canvasWidth,
          canvasHeight,
          signalAssetUpdate
        )
      : null;
  const overlayAssetsRaw = Array.isArray(dirState.overlayAssets)
    ? (dirState.overlayAssets as Array<GearOverlayAsset | IconAssetPayload>)
    : [];
  const overlayAssets = overlayAssetsRaw.filter((entry) => {
    const slot = (entry as GearOverlayAsset)?.slot;
    return !slot || !APPEARANCE_OVERLAY_SLOTS.has(String(slot));
  });
  const baseOverlayLayers = buildOrderedOverlayLayers(
    overlayAssets,
    canvasWidth,
    canvasHeight,
    'base',
    signalAssetUpdate
  );
  const loadoutLayers = showLoadoutGear
    ? buildOrderedOverlayLayers(
        (dirState.gearLoadoutOverlayAssets as (
          | GearOverlayAsset
          | IconAssetPayload
        )[]) || [],
        canvasWidth,
        canvasHeight,
        'loadout',
        signalAssetUpdate,
        baseOverlayLayers.length
      )
    : [];
  const loadoutSlots = new Set(
    loadoutLayers
      .map((entry) => entry.slot)
      .filter((slot): slot is string => !!slot)
  );
  const jobLayersUnfiltered = showJobGear
    ? buildOrderedOverlayLayers(
        (dirState.gearJobOverlayAssets as (
          | GearOverlayAsset
          | IconAssetPayload
        )[]) || [],
        canvasWidth,
        canvasHeight,
        'job',
        signalAssetUpdate,
        baseOverlayLayers.length + loadoutLayers.length
      )
    : [];
  const jobLayers =
    showLoadoutGear && showJobGear
      ? jobLayersUnfiltered.filter(
          (entry) => !entry.slot || !loadoutSlots.has(entry.slot)
        )
      : jobLayersUnfiltered;

  const appearanceLayers: OrderedOverlayLayer[] = [];

  let hairCompositeGrid: string[][] | null = null;
  if (facialHairDef) {
    hairCompositeGrid = buildAccessoryGrid({
      def: facialHairDef,
      dir,
      canvasWidth,
      canvasHeight,
      colors: [appearanceState.facial_hair_color],
      signalAssetUpdate,
    });
  }
  if (hairDef) {
    const hairGrid = buildHairGridWithGradient({
      hairDef,
      gradientDef,
      dir,
      canvasWidth,
      canvasHeight,
      hairColor: appearanceState.hair_color,
      gradientColor: appearanceState.hair_gradient_color,
      signalAssetUpdate,
    });
    if (hairGrid) {
      if (!hairCompositeGrid) {
        hairCompositeGrid = cloneGridData(hairGrid);
      } else {
        mergeGrid(hairCompositeGrid, hairGrid);
      }
    }
  }
  if (earDef) {
    const earsGrid = buildAccessoryGrid({
      def: earDef,
      dir,
      canvasWidth,
      canvasHeight,
      colors: appearanceState.ear_colors,
      signalAssetUpdate,
    });
    if (earsGrid) {
      if (!hairCompositeGrid) {
        hairCompositeGrid = cloneGridData(earsGrid);
      } else {
        mergeGrid(hairCompositeGrid, earsGrid);
      }
    }
  }
  if (hornDef) {
    const hornsGrid = buildAccessoryGrid({
      def: hornDef,
      dir,
      canvasWidth,
      canvasHeight,
      colors: appearanceState.horn_colors,
      signalAssetUpdate,
    });
    if (hornsGrid) {
      if (!hairCompositeGrid) {
        hairCompositeGrid = cloneGridData(hornsGrid);
      } else {
        mergeGrid(hairCompositeGrid, hornsGrid);
      }
    }
  }
  if (hairCompositeGrid && gridHasPixels(hairCompositeGrid)) {
    appearanceLayers.push({
      grid: hairCompositeGrid,
      layer: OVERLAY_SLOT_PRIORITY_MAP.hair,
      slot: 'hair',
      source: 'base',
      order: 1000,
    });
  }

  if (tailDef) {
    const tailGrid = buildAccessoryGrid({
      def: tailDef,
      dir,
      canvasWidth,
      canvasHeight,
      colors: appearanceState.tail_colors,
      signalAssetUpdate,
    });
    if (tailGrid) {
      const lowerDirs = Array.isArray(tailDef.lower_layer_dirs)
        ? tailDef.lower_layer_dirs
        : [2];
      const isLower = lowerDirs.includes(dir);
      const slot = isLower ? 'tail_lower' : 'tail_upper';
      appearanceLayers.push({
        grid: tailGrid,
        layer: OVERLAY_SLOT_PRIORITY_MAP[slot],
        slot,
        source: 'base',
        order: 1030,
      });
    }
  }

  if (wingDef) {
    const frontGrid = buildAccessoryGrid({
      def: wingDef,
      dir,
      canvasWidth,
      canvasHeight,
      colors: appearanceState.wing_colors,
      signalAssetUpdate,
    });
    if (frontGrid) {
      appearanceLayers.push({
        grid: frontGrid,
        layer: OVERLAY_SLOT_PRIORITY_MAP.wing_upper,
        slot: 'wing_upper',
        source: 'base',
        order: 1040,
      });
    }
    if (wingDef.multi_dir && wingDef.back_assets) {
      const backAssets = wingDef.back_assets?.[dir];
      if (backAssets && backAssets.length) {
        const backDef: BasicAppearanceAccessoryDefinition = {
          ...wingDef,
          assets: { [dir]: backAssets } as any,
        };
        const backGrid = buildAccessoryGrid({
          def: backDef,
          dir,
          canvasWidth,
          canvasHeight,
          colors: appearanceState.wing_colors,
          signalAssetUpdate,
        });
        if (backGrid) {
          appearanceLayers.push({
            grid: backGrid,
            layer: OVERLAY_SLOT_PRIORITY_MAP.wing_lower,
            slot: 'wing_lower',
            source: 'base',
            order: 1035,
          });
        }
      }
    }
  }

  const merged = mergeOverlayLayerLists(
    [...baseOverlayLayers, ...appearanceLayers],
    jobLayers,
    loadoutLayers
  );
  const overlayEntries: PreviewLayerEntry[] = [];
  merged.forEach((entry, index) => {
    if (hideShoes && entry.slot === 'shoes') {
      return;
    }
    let grid = cloneGridData(entry.grid);
    if (entry.slot === 'eyes' && previewBaseEyeColor && previewTargetEyeColor) {
      grid = recolorGrid(grid, previewBaseEyeColor, previewTargetEyeColor);
    }
    if (referenceParts && entry.slot && TAUR_CLOTHING_SLOTS.has(entry.slot)) {
      maskGridForHiddenLegParts(grid, referenceParts, hiddenLegParts);
    }
    if (!gridHasPixels(grid)) {
      return;
    }
    overlayEntries.push({
      type: 'overlay',
      key: `overlay_body_${dir}_${entry.source}_${entry.slot || index}_${index}`,
      label:
        entry.source === 'job'
          ? 'Job Gear'
          : entry.source === 'loadout'
            ? 'Loadout Gear'
            : 'Overlay',
      source: entry.source,
      grid,
      opacity: 1,
    });
  });
  return overlayEntries;
};

export const applyAppearanceOverlaysToPreview = (options: {
  preview: PreviewDirectionEntry[];
  previewDirStatesForLive: Record<number, PreviewDirState>;
  appearanceContext: AppearancePreviewContext;
  canvasWidth: number;
  canvasHeight: number;
  showJobGear: boolean;
  showLoadoutGear: boolean;
  signalAssetUpdate: () => void;
}): PreviewDirectionEntry[] => {
  const {
    preview,
    previewDirStatesForLive,
    appearanceContext,
    canvasWidth,
    canvasHeight,
    showJobGear,
    showLoadoutGear,
    signalAssetUpdate,
  } = options;
  if (!appearanceContext.canApplyAppearance) {
    return preview;
  }
  return preview.map((dirEntry) => {
    const layers = dirEntry.layers || [];
    const { before, after } = splitOverlayLayers(layers);
    const overlayEntries = buildAppearanceOverlayEntriesForDir({
      dir: dirEntry.dir,
      dirState: previewDirStatesForLive[dirEntry.dir],
      appearanceState: appearanceContext.appearanceState,
      hairDef: appearanceContext.hairDef,
      gradientDef: appearanceContext.gradientDef,
      facialHairDef: appearanceContext.facialHairDef,
      earDef: appearanceContext.earDef,
      hornDef: appearanceContext.hornDef,
      tailDef: appearanceContext.tailDef,
      wingDef: appearanceContext.wingDef,
      previewBaseEyeColor: appearanceContext.previewBaseEyeColor,
      previewTargetEyeColor: appearanceContext.previewTargetEyeColor,
      canvasWidth,
      canvasHeight,
      showJobGear,
      showLoadoutGear,
      signalAssetUpdate,
    });
    return {
      ...dirEntry,
      layers: [...before, ...overlayEntries, ...after],
    };
  });
};

const buildBodyMarkingsPreviewBases = (options: {
  previewDirStates: Record<number, PreviewDirState>;
  bodyPayload: BodyMarkingsPayload | null;
  basicPayload: BasicAppearancePayload | null;
  basicAppearanceState: BasicAppearanceState;
  data: CustomMarkingDesignerData;
  bodyPartLabels: Record<string, string>;
  canvasWidth: number;
  canvasHeight: number;
  resolvedPartPriorityMap: Record<string, boolean>;
  resolvedPartReplacementMap: Record<string, boolean>;
  showJobGear: boolean;
  showLoadoutGear: boolean;
  signalAssetUpdate: () => void;
}): BodyMarkingsPreviewBaseResult => {
  const {
    previewDirStates,
    bodyPayload,
    basicPayload,
    basicAppearanceState,
    data,
    bodyPartLabels,
    canvasWidth,
    canvasHeight,
    resolvedPartPriorityMap,
    resolvedPartReplacementMap,
    showJobGear,
    showLoadoutGear,
    signalAssetUpdate,
  } = options;
  const appearanceContext = resolveAppearanceContext({
    previewDirStates,
    basicPayload,
    basicAppearanceState,
    fallbackDigitigrade: !!bodyPayload?.digitigrade,
  });
  const hasReplacementFlags = Object.values(
    resolvedPartReplacementMap || {}
  ).some(Boolean);
  const partPaintPresenceMap =
    bodyPayload?.preview_sources && hasReplacementFlags
      ? buildPartPaintPresenceMap({
          dirStates: appearanceContext.previewDirStatesForLive,
          activeDirKey: data.active_dir_key,
          activePartKey: data.active_body_part || 'generic',
          canvasWidth,
          canvasHeight,
          replacementDependents: data.replacement_dependents,
        })
      : undefined;
  const basePreviewRaw = bodyPayload?.preview_sources
    ? buildBasePreviewDirs(
        appearanceContext.previewDirStatesForLive,
        data.directions,
        bodyPartLabels,
        canvasWidth,
        canvasHeight,
        signalAssetUpdate
      )
    : [];
  const liveBasePreviewRaw = bodyPayload?.preview_sources
    ? buildDesignerPreviewDirs(
        appearanceContext.previewDirStatesForLive,
        data.directions,
        bodyPartLabels,
        canvasWidth,
        canvasHeight,
        data.active_dir_key,
        'generic',
        null,
        null,
        resolvedPartPriorityMap,
        resolvedPartReplacementMap,
        partPaintPresenceMap,
        showJobGear,
        showLoadoutGear,
        signalAssetUpdate
      )
    : [];
  const basePreviewColored = applyEyeColorToPreview(
    applyBodyColorToPreview(
      basePreviewRaw,
      appearanceContext.previewBaseBodyColor,
      appearanceContext.previewTargetBodyColor,
      appearanceContext.bodyColorExcludedParts
    ),
    appearanceContext.previewBaseEyeColor,
    appearanceContext.previewTargetEyeColor,
    appearanceContext.previewTargetBodyColor
  );
  const liveBasePreviewColored = applyEyeColorToPreview(
    applyBodyColorToPreview(
      liveBasePreviewRaw,
      appearanceContext.previewBaseBodyColor,
      appearanceContext.previewTargetBodyColor,
      appearanceContext.bodyColorExcludedParts
    ),
    appearanceContext.previewBaseEyeColor,
    appearanceContext.previewTargetEyeColor,
    appearanceContext.previewTargetBodyColor
  );
  const basePreview = applyAppearanceOverlaysToPreview({
    preview: basePreviewColored,
    previewDirStatesForLive: appearanceContext.previewDirStatesForLive,
    appearanceContext,
    canvasWidth,
    canvasHeight,
    showJobGear,
    showLoadoutGear,
    signalAssetUpdate,
  });
  const liveBasePreview = applyAppearanceOverlaysToPreview({
    preview: liveBasePreviewColored,
    previewDirStatesForLive: appearanceContext.previewDirStatesForLive,
    appearanceContext,
    canvasWidth,
    canvasHeight,
    showJobGear,
    showLoadoutGear,
    signalAssetUpdate,
  });
  return {
    basePreview,
    liveBasePreview,
    appearanceContext,
  };
};

type BodyMarkingsInitializerProps = Readonly<{
  bodyPayload: BodyMarkingsPayload | null;
  dataPayload?: BodyMarkingsPayload | null;
  payloadSignature: string | null;
  setPayloadSignature: (signature: string | null) => void;
  requestPayload: () => void;
  syncPayload: (payload: BodyMarkingsPayload) => void;
  syncPreviewPayload: (payload: BodyMarkingsPayload) => void;
  loadInProgress: boolean;
  setLoadInProgress: (value: boolean) => void;
}>;

class BodyMarkingsInitializer extends Component<BodyMarkingsInitializerProps> {
  private hasRequested = false;
  private lastPayloadSignature: string | null = null;
  private lastDataPayload: BodyMarkingsPayload | null = null;

  componentDidMount() {
    this.requestIfNeeded();
    this.syncIfNeeded();
  }

  componentDidUpdate(prevProps: BodyMarkingsInitializerProps) {
    if (
      prevProps.bodyPayload !== this.props.bodyPayload ||
      prevProps.dataPayload !== this.props.dataPayload
    ) {
      this.requestIfNeeded();
      this.syncIfNeeded();
    }
  }

  requestIfNeeded() {
    const {
      bodyPayload,
      dataPayload,
      requestPayload,
      loadInProgress,
      setLoadInProgress,
    } = this.props;
    if (!bodyPayload && !dataPayload && !this.hasRequested && !loadInProgress) {
      this.hasRequested = true;
      setLoadInProgress(true);
      requestPayload();
    }
  }

  syncIfNeeded() {
    const {
      dataPayload,
      bodyPayload,
      payloadSignature,
      setPayloadSignature,
      syncPayload,
      syncPreviewPayload,
      loadInProgress,
      setLoadInProgress,
    } = this.props;
    if (!dataPayload) {
      if (bodyPayload) {
        const bodySignature = buildBodyPayloadSignature(bodyPayload);
        if (bodySignature !== payloadSignature) {
          setPayloadSignature(bodySignature);
        }
      }
      this.lastPayloadSignature = null;
      this.lastDataPayload = null;
      return;
    }
    const isPreviewOnly = !!dataPayload.preview_only;
    if (bodyPayload && !loadInProgress && !isPreviewOnly) {
      const bodySignature = buildBodyPayloadSignature(bodyPayload);
      if (bodySignature !== payloadSignature) {
        setPayloadSignature(bodySignature);
      }
      return;
    }
    const nextSignature = buildBodyPayloadSignature(dataPayload);
    if (isPreviewOnly && bodyPayload) {
      const localRevision = bodyPayload.preview_revision || 0;
      const incomingRevision = dataPayload.preview_revision || 0;
      if (localRevision > incomingRevision) {
        this.lastDataPayload = dataPayload;
        this.lastPayloadSignature = nextSignature;
        if (loadInProgress) {
          setLoadInProgress(false);
        }
        return;
      }
    }
    const signatureChanged = nextSignature !== this.lastPayloadSignature;
    const hadLastDataPayload = this.lastDataPayload !== null;
    const dataRefChanged = dataPayload !== this.lastDataPayload;
    if (!dataRefChanged && !signatureChanged) {
      return;
    }
    if (dataPayload.preview_only) {
      this.lastDataPayload = dataPayload;
      this.lastPayloadSignature = nextSignature;
      setPayloadSignature(nextSignature);
      syncPreviewPayload(dataPayload);
      if (loadInProgress) {
        setLoadInProgress(false);
      }
      return;
    }
    this.lastDataPayload = dataPayload;
    this.lastPayloadSignature = nextSignature;

    const signatureMatches = nextSignature === payloadSignature;
    const waitingForReload = loadInProgress && !bodyPayload;
    if (signatureMatches) {
      if (waitingForReload) {
        if (!hadLastDataPayload) {
          return;
        }
        if (dataRefChanged) {
          setPayloadSignature(nextSignature);
          syncPayload(dataPayload);
          setLoadInProgress(false);
        }
        return;
      }

      if (bodyPayload) {
        if (loadInProgress) {
          setLoadInProgress(false);
        }
        return;
      }

      if (!loadInProgress) {
        setPayloadSignature(nextSignature);
        syncPayload(dataPayload);
      }
      return;
    }

    setPayloadSignature(nextSignature);
    syncPayload(dataPayload);
    if (loadInProgress) {
      setLoadInProgress(false);
    }
  }

  render() {
    return null;
  }
}

type BodyMarkingsPreviewLoadCoordinatorProps = Readonly<{
  bodyPayload: BodyMarkingsPayload | null;
  payloadSignature: string | null;
  referenceBuildInProgress: boolean;
  previewReady: boolean;
  timedOut: boolean;
  setTimedOut: (value: boolean) => void;
  timeoutMs: number;
}>;

class BodyMarkingsPreviewLoadCoordinator extends Component<BodyMarkingsPreviewLoadCoordinatorProps> {
  private timeoutHandle: ReturnType<typeof setTimeout> | null = null;
  private lastPayloadSignature: string | null = null;

  componentDidMount() {
    this.sync();
  }

  componentDidUpdate(prevProps: BodyMarkingsPreviewLoadCoordinatorProps) {
    if (
      prevProps.bodyPayload !== this.props.bodyPayload ||
      prevProps.payloadSignature !== this.props.payloadSignature ||
      prevProps.referenceBuildInProgress !==
        this.props.referenceBuildInProgress ||
      prevProps.previewReady !== this.props.previewReady ||
      prevProps.timedOut !== this.props.timedOut ||
      prevProps.timeoutMs !== this.props.timeoutMs
    ) {
      this.sync();
    }
  }

  componentWillUnmount() {
    this.clear();
  }

  clear() {
    if (this.timeoutHandle) {
      clearTimeout(this.timeoutHandle);
      this.timeoutHandle = null;
    }
  }

  sync() {
    const {
      bodyPayload,
      payloadSignature,
      referenceBuildInProgress,
      previewReady,
      timedOut,
      setTimedOut,
      timeoutMs,
    } = this.props;

    if (payloadSignature !== this.lastPayloadSignature) {
      this.lastPayloadSignature = payloadSignature;
      this.clear();
      if (timedOut) {
        setTimedOut(false);
        return;
      }
    }

    const shouldReset =
      !bodyPayload || referenceBuildInProgress || previewReady;
    if (shouldReset) {
      this.clear();
      if (timedOut) {
        setTimedOut(false);
      }
      return;
    }

    if (timedOut) {
      this.clear();
      return;
    }

    if (this.timeoutHandle) {
      return;
    }

    this.timeoutHandle = setTimeout(
      () => {
        this.timeoutHandle = null;
        setTimedOut(true);
      },
      Math.max(0, timeoutMs)
    );
  }

  render() {
    return null;
  }
}

type MarkingTileProps = Readonly<{
  def: BodyMarkingDefinition;
  selected: boolean;
  previews: PreviewDirectionEntry[];
  onToggle: () => void;
  canvasWidth: number;
  canvasHeight: number;
  backgroundImage: string | null;
  backgroundColor: string;
  backgroundScale: number;
  backgroundTileWidth?: number;
  backgroundTileHeight?: number;
}>;

class MarkingTile extends Component<MarkingTileProps> {
  shouldComponentUpdate(next: MarkingTileProps) {
    return (
      next.selected !== this.props.selected ||
      next.previews !== this.props.previews ||
      next.def.id !== this.props.def.id ||
      next.def.name !== this.props.def.name ||
      next.backgroundImage !== this.props.backgroundImage ||
      next.backgroundColor !== this.props.backgroundColor ||
      next.backgroundScale !== this.props.backgroundScale ||
      next.backgroundTileWidth !== this.props.backgroundTileWidth ||
      next.backgroundTileHeight !== this.props.backgroundTileHeight
    );
  }

  render() {
    const {
      def,
      selected,
      previews,
      onToggle,
      canvasWidth,
      canvasHeight,
      backgroundImage,
      backgroundColor,
      backgroundScale,
      backgroundTileWidth,
      backgroundTileHeight,
    } = this.props;
    return (
      <Box
        className={`RogueStar__markingTile${
          selected ? ' RogueStar__markingTile--selected' : ''
        }`}
        onClick={onToggle}>
        <Box className="RogueStar__markingTilePreviewGrid">
          {previews.map((preview) => (
            <Box
              key={`${def.id}-${preview.dir}`}
              className="RogueStar__markingTilePreview">
              <DirectionPreviewCanvas
                layers={preview.layers}
                pixelSize={MARKING_TILE_PIXEL_SIZE}
                width={canvasWidth}
                height={canvasHeight}
                backgroundImage={backgroundImage}
                backgroundColor={backgroundColor}
                backgroundScale={backgroundScale}
                backgroundTileWidth={backgroundTileWidth}
                backgroundTileHeight={backgroundTileHeight}
              />
            </Box>
          ))}
        </Box>
        <Box className="RogueStar__markingTileLabel" title={def.name}>
          {def.name}
        </Box>
      </Box>
    );
  }
}

type MarkingTileSectionProps = Readonly<{
  definitions: BodyMarkingDefinition[];
  canvasWidth: number;
  canvasHeight: number;
  category: string;
  search: string;
  page: number;
  onPageChange: (page: number) => void;
  tileDirectionsSignature: string;
  previewColorSignature: string;
  assetRevision: number;
  backgroundImage: string | null;
  backgroundColor: string;
  backgroundScale: number;
  backgroundTileWidth?: number;
  backgroundTileHeight?: number;
  markings: Record<string, BodyMarkingEntry>;
  markingKeysSignature: string;
  getTilePreviewEntries: (
    def: BodyMarkingDefinition
  ) => PreviewDirectionEntry[];
  applyAdd: (id: string) => void;
  applyRemove: (id: string) => void;
}>;

const compareDefinitionsByName = (
  a: BodyMarkingDefinition,
  b: BodyMarkingDefinition
) =>
  a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }) ||
  a.id.localeCompare(b.id, undefined, { sensitivity: 'base' });

class MarkingTileSection extends Component<MarkingTileSectionProps> {
  shouldComponentUpdate(next: MarkingTileSectionProps) {
    return (
      next.category !== this.props.category ||
      next.search !== this.props.search ||
      next.page !== this.props.page ||
      next.canvasWidth !== this.props.canvasWidth ||
      next.canvasHeight !== this.props.canvasHeight ||
      next.markingKeysSignature !== this.props.markingKeysSignature ||
      next.tileDirectionsSignature !== this.props.tileDirectionsSignature ||
      next.previewColorSignature !== this.props.previewColorSignature ||
      next.assetRevision !== this.props.assetRevision ||
      next.definitions !== this.props.definitions ||
      next.backgroundImage !== this.props.backgroundImage ||
      next.backgroundColor !== this.props.backgroundColor ||
      next.backgroundScale !== this.props.backgroundScale ||
      next.backgroundTileWidth !== this.props.backgroundTileWidth ||
      next.backgroundTileHeight !== this.props.backgroundTileHeight
    );
  }

  render() {
    const {
      definitions,
      canvasWidth,
      canvasHeight,
      category,
      search,
      page,
      onPageChange,
      tileDirectionsSignature: _,
      previewColorSignature: __,
      markings,
      backgroundImage,
      backgroundColor,
      backgroundScale,
      backgroundTileWidth,
      backgroundTileHeight,
      getTilePreviewEntries,
      applyAdd,
      applyRemove,
    } = this.props;
    const searchNeedle = search.trim().toLowerCase();
    const filteredDefinitions = definitions.filter((def) => {
      if (def.hide_from_gallery && !markings[def.id]) {
        return false;
      }
      if (category !== 'all' && def.category !== category) {
        return false;
      }
      if (!searchNeedle) {
        return true;
      }
      return (
        def.id.toLowerCase().includes(searchNeedle) ||
        def.name.toLowerCase().includes(searchNeedle)
      );
    });
    filteredDefinitions.sort(compareDefinitionsByName);

    const PAGE_SIZE = 20;
    const totalPages = Math.max(
      1,
      Math.ceil(filteredDefinitions.length / PAGE_SIZE)
    );
    const currentPage = Math.min(
      Math.max(0, page),
      Math.max(0, totalPages - 1)
    );
    const startIdx = currentPage * PAGE_SIZE;
    const endIdx = startIdx + PAGE_SIZE;
    const pagedDefinitions = filteredDefinitions.slice(startIdx, endIdx);
    const showStart = filteredDefinitions.length ? startIdx + 1 : 0;
    const showEnd = Math.min(endIdx, filteredDefinitions.length);

    return (
      <>
        <Box className="RogueStar__markingGrid">
          {pagedDefinitions.map((def) => {
            const selected = !!markings[def.id];
            const tilePreviews = getTilePreviewEntries(def);
            const canToggle = !(selected && def.hide_from_gallery);
            return (
              <MarkingTile
                key={def.id}
                def={def}
                selected={selected}
                previews={tilePreviews}
                canvasWidth={canvasWidth}
                canvasHeight={canvasHeight}
                backgroundImage={backgroundImage}
                backgroundColor={backgroundColor}
                backgroundScale={backgroundScale}
                backgroundTileWidth={backgroundTileWidth}
                backgroundTileHeight={backgroundTileHeight}
                onToggle={() => {
                  if (!canToggle) {
                    return;
                  }
                  return selected ? applyRemove(def.id) : applyAdd(def.id);
                }}
              />
            );
          })}
          {!filteredDefinitions.length && (
            <NoticeBox>No markings found for this filter.</NoticeBox>
          )}
        </Box>
        {filteredDefinitions.length > PAGE_SIZE && (
          <Flex
            mt={1}
            align="center"
            justify="space-between"
            wrap="nowrap"
            style={{ gap: '0.75rem' }}>
            <Flex.Item shrink={0}>
              <Button
                className={CHIP_BUTTON_CLASS}
                icon="chevron-left"
                disabled={currentPage <= 0}
                onClick={() => onPageChange(Math.max(0, currentPage - 1))}>
                Prev
              </Button>
            </Flex.Item>
            <Flex.Item grow>
              <Box nowrap textAlign="center">
                Page {currentPage + 1} / {totalPages} · Showing {showStart}-
                {showEnd} of {filteredDefinitions.length}
              </Box>
            </Flex.Item>
            <Flex.Item shrink={0}>
              <Button
                className={CHIP_BUTTON_CLASS}
                icon="chevron-right"
                disabled={currentPage >= totalPages - 1}
                onClick={() =>
                  onPageChange(Math.min(totalPages - 1, currentPage + 1))
                }>
                Next
              </Button>
            </Flex.Item>
          </Flex>
        )}
      </>
    );
  }
}

type BodyMarkingsGallerySectionProps = Readonly<{
  bodyPayload: BodyMarkingsPayload;
  category: string;
  setCategory: (category: string) => void;
  search: string;
  setSearch: (search: string) => void;
  tilePage: number;
  setTilePage: (page: number) => void;
  activeColorTarget: BodyMarkingColorTarget | null;
  previewTint: string | null;
  setColorTarget: (target: BodyMarkingColorTarget | null) => void;
  atSelectionLimit: boolean;
  canvasWidth: number;
  canvasHeight: number;
  tileDirectionsSignature: string;
  assetRevision: number;
  markings: Record<string, BodyMarkingEntry>;
  markingKeysSignature: string;
  getTilePreviewEntries: (
    def: BodyMarkingDefinition
  ) => PreviewDirectionEntry[];
  backgroundImage: string | null;
  backgroundColor: string;
  backgroundScale: number;
  backgroundTileWidth?: number;
  backgroundTileHeight?: number;
  applyAdd: (id: string) => void;
  applyRemove: (id: string) => void;
}>;

const BodyMarkingsGallerySection = ({
  bodyPayload,
  category,
  setCategory,
  search,
  setSearch,
  tilePage,
  setTilePage,
  activeColorTarget,
  previewTint,
  setColorTarget,
  atSelectionLimit,
  canvasWidth,
  canvasHeight,
  tileDirectionsSignature,
  assetRevision,
  markings,
  markingKeysSignature,
  getTilePreviewEntries,
  backgroundImage,
  backgroundColor,
  backgroundScale,
  backgroundTileWidth,
  backgroundTileHeight,
  applyAdd,
  applyRemove,
}: BodyMarkingsGallerySectionProps) => (
  <Section
    title="Body Markings Gallery"
    buttons={
      <Flex align="center" gap={0.5} wrap="wrap">
        <Flex.Item grow>
          <Tabs>
            {Object.entries(CATEGORY_LABELS).map(([cat, label]) => (
              <Tabs.Tab
                key={cat}
                selected={category === cat}
                onClick={() => {
                  setCategory(cat);
                  setTilePage(0);
                }}>
                {label}
              </Tabs.Tab>
            ))}
          </Tabs>
        </Flex.Item>
        <Flex.Item>
          <Button
            className={CHIP_BUTTON_CLASS}
            icon="palette"
            selected={activeColorTarget?.type === 'galleryPreview'}
            onClick={() => setColorTarget({ type: 'galleryPreview' })}>
            <ColorBox mr={0.5} color={previewTint || '#888888'} />
            Preview Color
          </Button>
        </Flex.Item>
      </Flex>
    }>
    <Box mb={1}>
      <Input
        fluid
        value={search}
        placeholder="Search markings…"
        onInput={(e, value) => {
          setSearch(value);
          setTilePage(0);
        }}
      />
    </Box>
    {atSelectionLimit && (
      <NoticeBox danger mb={1}>
        Marking limit reached ({BODY_MARKING_SELECTION_LIMIT}). Remove a marking
        to add another.
      </NoticeBox>
    )}
    <MarkingTileSection
      definitions={bodyPayload.body_marking_definitions || []}
      tileDirectionsSignature={tileDirectionsSignature}
      assetRevision={assetRevision}
      canvasWidth={canvasWidth}
      canvasHeight={canvasHeight}
      category={category}
      search={search}
      page={tilePage}
      onPageChange={setTilePage}
      markings={markings}
      markingKeysSignature={markingKeysSignature}
      previewColorSignature={previewTint || 'default'}
      getTilePreviewEntries={getTilePreviewEntries}
      backgroundImage={backgroundImage}
      backgroundColor={backgroundColor}
      backgroundScale={backgroundScale}
      backgroundTileWidth={backgroundTileWidth}
      backgroundTileHeight={backgroundTileHeight}
      applyAdd={applyAdd}
      applyRemove={applyRemove}
    />
  </Section>
);

type BodyMarkingsSaveSectionProps = Readonly<{
  pendingSave: boolean;
  pendingClose: boolean;
  uiLocked: boolean;
  dirty: boolean;
  onSave: () => void;
  onSaveAndClose: () => void;
  onDiscardAndClose: () => void;
}>;

const BodyMarkingsSaveSection = ({
  pendingSave,
  pendingClose,
  uiLocked,
  dirty,
  onSave,
  onSaveAndClose,
  onDiscardAndClose,
}: BodyMarkingsSaveSectionProps) => (
  <Section title="Save">
    <Flex justify="space-between" wrap className="RogueStar__sessionButtons">
      <Flex.Item>
        <Button
          className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--positive`}
          icon={pendingSave ? 'spinner-third' : 'save'}
          iconSpin={pendingSave}
          disabled={pendingClose || pendingSave || uiLocked || !dirty}
          onClick={onSave}>
          Save
        </Button>
      </Flex.Item>
      <Flex.Item>
        <Button
          className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--positive`}
          icon={pendingClose ? 'spinner-third' : 'floppy-disk'}
          iconSpin={pendingClose}
          disabled={pendingClose || pendingSave || uiLocked}
          onClick={onSaveAndClose}>
          Save &amp; Close
        </Button>
      </Flex.Item>
      <Flex.Item>
        <Button.Confirm
          className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--negative`}
          icon="door-open"
          confirmIcon="triangle-exclamation"
          content="Close Without Saving"
          confirmContent="Confirm Close"
          color="transparent"
          confirmColor="bad"
          disabled={pendingClose || pendingSave || uiLocked}
          onClick={onDiscardAndClose}
        />
      </Flex.Item>
    </Flex>
  </Section>
);

type BodyMarkingsActiveSectionProps = Readonly<{
  order: string[];
  visibleOrder: string[];
  totalSelected: number;
  selectedId: string | null;
  definitions: Record<string, BodyMarkingDefinition>;
  markings: Record<string, BodyMarkingEntry>;
  selectMarking: (id: string | null) => void;
  reorder: (id: string, direction: 'up' | 'down') => void;
  applyRemove: (id: string) => void;
  selectedDef: BodyMarkingDefinition | null;
  selectedEntry: BodyMarkingEntry | null;
  toggleAll: (markId: string, value: boolean) => void;
  togglePart: (markId: string, partId: string) => void;
  bodyPartLabels: Record<string, string>;
  activeColorTarget: BodyMarkingColorTarget | null;
  setColorTarget: (target: BodyMarkingColorTarget | null) => void;
}>;

const BodyMarkingsActiveSection = ({
  order,
  visibleOrder,
  totalSelected,
  selectedId,
  definitions,
  markings,
  selectMarking,
  reorder,
  applyRemove,
  selectedDef,
  selectedEntry,
  toggleAll,
  togglePart,
  bodyPartLabels,
  activeColorTarget,
  setColorTarget,
}: BodyMarkingsActiveSectionProps) => (
  <Section
    title={`Active Markings (${totalSelected}/${BODY_MARKING_SELECTION_LIMIT})`}
    fill>
    <Flex direction="column" gap={1}>
      {!visibleOrder.length && (
        <NoticeBox>
          {order.length
            ? 'Only hidden markings are active.'
            : 'Nothing selected yet.'}
        </NoticeBox>
      )}
      <Box className="RogueStar__activeList">
        {visibleOrder.map((markId) => {
          const def = definitions[markId];
          const allowColor = def?.do_colouration;
          const colorSample =
            allowColor && markings[markId]?.color
              ? (markings[markId].color as string)
              : def?.default_color || '#000000';
          return (
            <Box key={markId} mb={0.25}>
              <Flex align="center" justify="space-between" mb={0.25} gap={0.5}>
                <Flex.Item grow>
                  <Button
                    className={CHIP_BUTTON_CLASS}
                    fluid
                    selected={selectedId === markId}
                    onClick={() => selectMarking(markId)}>
                    {def?.name || markId}
                  </Button>
                </Flex.Item>
                <Flex.Item>
                  <ColorBox color={colorSample} />
                </Flex.Item>
                <Flex.Item>
                  <Button
                    className={CHIP_BUTTON_CLASS}
                    icon="arrow-up"
                    onClick={() => reorder(markId, 'up')}
                  />
                </Flex.Item>
                <Flex.Item>
                  <Button
                    className={CHIP_BUTTON_CLASS}
                    icon="arrow-down"
                    onClick={() => reorder(markId, 'down')}
                  />
                </Flex.Item>
                <Flex.Item>
                  <Button
                    className={CHIP_BUTTON_CLASS}
                    icon="times"
                    disabled={!!def?.hide_from_gallery}
                    onClick={() => applyRemove(markId)}
                  />
                </Flex.Item>
              </Flex>
            </Box>
          );
        })}
      </Box>
      {selectedDef && selectedEntry ? (
        <Section title={`Customize: ${selectedDef.name}`} fill>
          <Flex justify="space-between" wrap gap={0.5} mb={1}>
            <Flex.Item>
              <Button
                className={CHIP_BUTTON_CLASS}
                icon="check-square"
                onClick={() => toggleAll(selectedDef.id, true)}>
                Enable All
              </Button>
            </Flex.Item>
            <Flex.Item>
              <Button
                className={CHIP_BUTTON_CLASS}
                icon="ban"
                onClick={() => toggleAll(selectedDef.id, false)}>
                Disable All
              </Button>
            </Flex.Item>
            {selectedDef.do_colouration ? (
              <Flex.Item>
                <Button
                  className={CHIP_BUTTON_CLASS}
                  icon="tint"
                  selected={
                    !!activeColorTarget &&
                    activeColorTarget.type === 'mark' &&
                    activeColorTarget.markId === selectedDef.id &&
                    !activeColorTarget.partId
                  }
                  onClick={() =>
                    setColorTarget({
                      type: 'mark',
                      markId: selectedDef.id,
                    })
                  }>
                  Color All
                </Button>
              </Flex.Item>
            ) : null}
          </Flex>
          <LabeledList>
            {selectedDef.body_parts.map((partId) => {
              const partState = selectedEntry[partId] as BodyMarkingPartState;
              const allowColor = selectedDef.do_colouration;
              const partColor =
                (partState?.color as string) ||
                (selectedEntry.color as string) ||
                selectedDef.default_color ||
                '#000000';
              return (
                <LabeledList.Item
                  key={partId}
                  label={bodyPartLabels[partId] || partId}>
                  <Button.Checkbox
                    className={CHIP_BUTTON_CLASS}
                    checked={isBodyMarkingPartEnabled(partState?.on)}
                    onClick={() => togglePart(selectedDef.id, partId)}>
                    Enabled
                  </Button.Checkbox>
                  {allowColor ? (
                    <Button
                      className={CHIP_BUTTON_CLASS}
                      ml={1}
                      icon="tint"
                      selected={
                        !!activeColorTarget &&
                        activeColorTarget.type === 'mark' &&
                        activeColorTarget.markId === selectedDef.id &&
                        activeColorTarget.partId === partId
                      }
                      onClick={() =>
                        setColorTarget({
                          type: 'mark',
                          markId: selectedDef.id,
                          partId,
                        })
                      }>
                      <ColorBox mr={0.5} color={partColor} />
                      Color
                    </Button>
                  ) : (
                    <ColorBox ml={1} color={partColor} />
                  )}
                </LabeledList.Item>
              );
            })}
          </LabeledList>
        </Section>
      ) : (
        <NoticeBox>Select a marking to customize.</NoticeBox>
      )}
    </Flex>
  </Section>
);

type BodyMarkingsPreviewColumnProps = Readonly<{
  markedPreview: PreviewDirectionEntry[];
  canvasWidth: number;
  canvasHeight: number;
  previewFitToFrame: boolean;
  onTogglePreviewFit: () => void;
  previewBackgroundImage: string | null;
  backgroundFallbackColor: string;
  canvasBackgroundScale: number;
  previewBackgroundTileWidth?: number;
  previewBackgroundTileHeight?: number;
  showJobGear: boolean;
  onToggleJobGear: () => void;
  showLoadoutGear: boolean;
  onToggleLoadout: () => void;
  canvasBackgroundOptions: CanvasBackgroundOption[];
  resolvedCanvasBackground: CanvasBackgroundOption | null;
  cycleCanvasBackground: () => void;
  colorPickerValue: string;
  applyColorTarget: (hex: string) => void;
}>;

const BodyMarkingsPreviewColumn = ({
  markedPreview,
  canvasWidth,
  canvasHeight,
  previewFitToFrame,
  onTogglePreviewFit,
  previewBackgroundImage,
  backgroundFallbackColor,
  canvasBackgroundScale,
  previewBackgroundTileWidth,
  previewBackgroundTileHeight,
  showJobGear,
  onToggleJobGear,
  showLoadoutGear,
  onToggleLoadout,
  canvasBackgroundOptions,
  resolvedCanvasBackground,
  cycleCanvasBackground,
  colorPickerValue,
  applyColorTarget,
}: BodyMarkingsPreviewColumnProps) => (
  <Flex direction="column" gap={1}>
    <Section
      fill
      noTopPadding
      className="RogueStar__previewCard RogueStar__previewCard--flush">
      <Flex align="center" wrap gap={0.5} mb={1} ml={0.5}>
        <Box
          color="label"
          fontWeight="bold"
          className="RogueStar__previewTitle"
          mr={0.5}>
          Live Preview
        </Box>
        <Button
          className={CHIP_BUTTON_CLASS}
          icon={previewFitToFrame ? 'compress-arrows-alt' : 'expand-arrows-alt'}
          selected={previewFitToFrame}
          tooltip="Shrink to show the full 64x64 grid"
          onClick={onTogglePreviewFit}
        />
        <Button
          className={CHIP_BUTTON_CLASS}
          icon="id-card"
          selected={showJobGear}
          tooltip="Show or hide job gear overlays."
          onClick={onToggleJobGear}>
          Job gear
        </Button>
        <Button
          className={CHIP_BUTTON_CLASS}
          icon="toolbox"
          selected={showLoadoutGear}
          tooltip="Show or hide loadout overlays."
          onClick={onToggleLoadout}>
          Loadout
        </Button>
        {canvasBackgroundOptions.length ? (
          <Button
            className={CHIP_BUTTON_CLASS}
            icon="image"
            tooltip={`Change preview background (current: ${resolvedCanvasBackground?.label || 'Default'})`}
            onClick={cycleCanvasBackground}>
            {resolvedCanvasBackground?.label || 'Background'}
          </Button>
        ) : null}
      </Flex>
      <Flex wrap gap={1}>
        {markedPreview.map((entry) => (
          <Flex.Item
            key={entry.dir}
            basis="45%"
            className="RogueStar__previewItem">
            <DirectionPreviewCanvas
              layers={entry.layers}
              pixelSize={Math.max(1, PREVIEW_PIXEL_SIZE)}
              width={canvasWidth}
              height={canvasHeight}
              fitToFrame={previewFitToFrame}
              backgroundImage={previewBackgroundImage}
              backgroundColor={backgroundFallbackColor}
              backgroundScale={canvasBackgroundScale}
              backgroundTileWidth={previewBackgroundTileWidth}
              backgroundTileHeight={previewBackgroundTileHeight}
            />
          </Flex.Item>
        ))}
      </Flex>
    </Section>
    <Section title="Color Picker">
      <Box className="RogueStar__inlineColorPicker">
        <RogueStarColorPicker
          color={colorPickerValue}
          currentColor={colorPickerValue}
          onChange={applyColorTarget}
          onCommit={applyColorTarget}
          showPreview={false}
          showCustomColors={false}
        />
      </Box>
    </Section>
  </Flex>
);

export const BodyMarkingsTab = (props: BodyMarkingsTabProps, context) => {
  const {
    data,
    setPendingClose,
    setPendingSave,
    canvasBackgroundOptions,
    resolvedCanvasBackground,
    backgroundFallbackColor,
    cycleCanvasBackground,
    canvasBackgroundScale,
    resolvedPartPriorityMap,
    resolvedPartReplacementMap,
    showJobGear,
    onToggleJobGear,
    showLoadoutGear,
    onToggleLoadout,
  } = props;
  const { act } = useBackend<CustomMarkingDesignerData>(context);
  const uiLocked = data.ui_locked ?? false;
  const stateToken = data.state_token || 'session';
  const [, setCanvasFitToFrame] = useLocalState<boolean>(
    context,
    `canvasFitToFrame-${stateToken}`,
    false
  );
  const [previewFitToFrame, setPreviewFitToFrame] = useLocalState<boolean>(
    context,
    `previewFitToFrame-${stateToken}`,
    false
  );
  const [, setReloadPending] = useLocalState<boolean>(
    context,
    `customMarkingDesignerReloadPending-${stateToken}`,
    false
  );
  const [, setReloadTargetRevision] = useLocalState<number>(
    context,
    `customMarkingDesignerReloadTargetRevision-${stateToken}`,
    0
  );
  const [previewRefreshSkips, setPreviewRefreshSkips] = useLocalState<number>(
    context,
    `customMarkingDesignerPreviewRefreshSkips-${stateToken}`,
    0
  );
  const [loadInProgress, setLoadInProgress] = useLocalState<boolean>(
    context,
    `bodyMarkingsLoadInProgress-${stateToken}`,
    false
  );
  const [bodyPayload, setBodyPayload] =
    useLocalState<BodyMarkingsPayload | null>(
      context,
      'bodyPayload',
      data.body_markings_payload || null
    );
  const [basicPayload] = useLocalState<BasicAppearancePayload | null>(
    context,
    'basicPayload',
    data.basic_appearance_payload || null
  );
  const [basicAppearanceState] = useLocalState<BasicAppearanceState>(
    context,
    'basicAppearanceState',
    buildBasicStateFromPayload(data.basic_appearance_payload)
  );
  const [markings, setMarkings] = useLocalState<
    Record<string, BodyMarkingEntry>
  >(
    context,
    'bodyMarkingsState',
    deepCopyMarkings(data.body_markings_payload?.body_markings)
  );
  const [order, setOrder] = useLocalState<string[]>(
    context,
    'bodyMarkingsOrder',
    (data.body_markings_payload?.order as string[]) || []
  );
  const [selectedId, setSelectedId] = useLocalState<string | null>(
    context,
    'bodyMarkingsSelected',
    (data.body_markings_payload?.order?.[0] as string) || null
  );
  const [, setSavedState] = useLocalState<BodyMarkingsSavedState>(
    context,
    'bodyMarkingsSavedState',
    buildBodySavedStateFromPayload(data.body_markings_payload)
  );
  const [category, setCategory] = useLocalState<string>(
    context,
    'bodyMarkingsCategory',
    'all'
  );
  const [search, setSearch] = useLocalState<string>(
    context,
    'bodyMarkingsSearch',
    ''
  );
  const [dirty, setDirty] = useLocalState(context, 'bodyMarkingsDirty', false);
  const [payloadSignature, setPayloadSignature] = useLocalState<string | null>(
    context,
    'bodyMarkingsPayloadSignature',
    buildBodyPayloadSignature(bodyPayload)
  );
  const [tilePage, setTilePage] = useLocalState<number>(
    context,
    'bodyMarkingsTilePage',
    0
  );
  const [colorTarget, setColorTarget] =
    useLocalState<BodyMarkingColorTarget | null>(
      context,
      'bodyMarkingsColorTarget',
      { type: 'galleryPreview' }
    );
  const [previewColor, setPreviewColor] = useLocalState<string | null>(
    context,
    'bodyMarkingsPreviewColor',
    null
  );
  const [pendingSave, setPendingSaveLocal] = useLocalState<boolean>(
    context,
    'bodyMarkingsPendingSave',
    false
  );
  const [pendingClose, setPendingCloseLocal] = useLocalState<boolean>(
    context,
    'bodyMarkingsPendingClose',
    false
  );
  const [tilePreviewCache] = useLocalState<
    Record<string, { sig: string; previews: PreviewDirectionEntry[] }>
  >(context, 'bodyMarkingsTilePreviewCache', {});
  const [markingLayersCache] = useLocalState<
    Record<string, MarkingLayersCacheEntry>
  >(context, 'bodyMarkingsMarkingLayersCache', {});
  const [assetRevision] = useLocalState<number>(
    context,
    'bodyMarkingsAssetRevision',
    0
  );
  const [previewTimedOut, setPreviewTimedOut] = useLocalState<boolean>(
    context,
    `bodyMarkingsPreviewTimedOut-${stateToken}`,
    false
  );
  const togglePreviewFit = () => {
    const next = !previewFitToFrame;
    setPreviewFitToFrame(next);
    setCanvasFitToFrame(next);
  };

  const updateSharedState = function <T>(opts: {
    key: string;
    fallback: T;
    updater: (prev: T) => T;
  }) {
    const { key, fallback, updater } = opts;
    const backendState = selectBackend(context.store.getState()) as {
      shared?: Record<string, unknown>;
    };
    const shared = backendState?.shared || {};
    const prev = (shared[key] as T) ?? fallback;
    const next = updater(prev);
    context.store.dispatch(
      backendSetSharedState({
        key,
        nextState: next,
      })
    );
  };

  const updateMarkingsState = (
    updater: (
      prev: Record<string, BodyMarkingEntry>
    ) => Record<string, BodyMarkingEntry>
  ) =>
    updateSharedState({
      key: 'bodyMarkingsState',
      fallback: markings,
      updater,
    });
  const updateOrderState = (updater: (prev: string[]) => string[]) =>
    updateSharedState({
      key: 'bodyMarkingsOrder',
      fallback: order,
      updater,
    });
  const updateColorTargetState = (
    updater: (
      prev: BodyMarkingColorTarget | null
    ) => BodyMarkingColorTarget | null
  ) =>
    updateSharedState({
      key: 'bodyMarkingsColorTarget',
      fallback: colorTarget,
      updater,
    });
  const updateSelectedIdState = (
    updater: (prev: string | null) => string | null
  ) =>
    updateSharedState({
      key: 'bodyMarkingsSelected',
      fallback: selectedId,
      updater,
    });
  const resolveLatestBodyState = () => {
    const backendState = selectBackend(context.store.getState()) as {
      shared?: Record<string, unknown>;
    };
    const shared = backendState?.shared || {};
    return {
      latestMarkings:
        (shared.bodyMarkingsState as Record<string, BodyMarkingEntry>) ||
        markings,
      latestOrder: (shared.bodyMarkingsOrder as string[]) || order,
      latestPayload:
        (shared.bodyPayload as BodyMarkingsPayload | null) || bodyPayload,
    };
  };
  const signalAssetUpdate = () => {
    if (assetUpdateScheduled) {
      return;
    }
    assetUpdateScheduled = true;
    setTimeout(() => {
      assetUpdateScheduled = false;
      updateSharedState({
        key: 'bodyMarkingsAssetRevision',
        fallback: assetRevision,
        updater: (prev) => ((prev || 0) + 1) % 1000000,
      });
    }, 0);
  };

  const canvasWidth = bodyPayload?.preview_width || 64;
  const canvasHeight = bodyPayload?.preview_height || 64;
  const resolveMaxAssetSize = () => {
    let maxW = 0;
    let maxH = 0;
    const consider = (asset?: { width?: number; height?: number } | null) => {
      if (!asset) return;
      maxW = Math.max(maxW, asset.width || 0);
      maxH = Math.max(maxH, asset.height || 0);
    };
    const considerMap = (
      assets?: Record<string, { width?: number; height?: number }> | null
    ) => {
      if (!assets) return;
      for (const asset of Object.values(assets)) {
        consider(asset);
      }
    };
    for (const entry of bodyPayload?.preview_sources || []) {
      consider(entry?.body_asset);
      consider(entry?.composite_asset);
      considerMap(entry?.reference_part_assets);
      considerMap(entry?.reference_part_marking_assets);
    }
    return { maxW, maxH };
  };
  const { maxW: maxAssetWidth, maxH: maxAssetHeight } = resolveMaxAssetSize();
  const usesLargeSprites = maxAssetWidth > 32 || maxAssetHeight > 32;
  const markingOffsetX = usesLargeSprites ? 12 : 0;
  const bodyPartLabels = (data.body_parts || []).reduce(
    (acc, entry) => {
      acc[entry.id] = entry.label;
      return acc;
    },
    {} as Record<string, string>
  );

  const definitions = buildBodyMarkingDefinitions(bodyPayload);
  const previewTint = normalizeHex(previewColor || undefined);
  const isImplicitCustomMarkingId = (markId: string) =>
    /\(custom [0-9a-f]{6}-\d+\)$/i.test(markId);
  const isHiddenMarking = (
    markId: string,
    defs: Record<string, BodyMarkingDefinition> = definitions
  ) => !!defs[markId]?.hide_from_gallery || isImplicitCustomMarkingId(markId);

  const selectMarking = (
    id: string | null,
    defs: Record<string, BodyMarkingDefinition> = definitions,
    markEntries: Record<string, BodyMarkingEntry> = markings,
    options: SelectMarkingOptions = {}
  ) => {
    updateSelectedIdState(() => id);
    if (options.setColorTarget === false) {
      return;
    }
    updateColorTargetState(() => {
      if (id && defs[id] && markEntries[id] && defs[id].do_colouration) {
        return { type: 'mark', markId: id };
      }
      return null;
    });
  };

  const activeColorTarget = resolveBodyMarkingColorTarget(
    colorTarget,
    definitions,
    markings
  );

  const resolveColorTargetHex = (
    target: NonNullable<typeof activeColorTarget>
  ): string => {
    if (target.type === 'galleryPreview') {
      return previewTint || '#ffffff';
    }
    const def = definitions[target.markId];
    const entry = markings[target.markId];
    if (!def || !entry) {
      return '#ffffff';
    }
    if (target.partId) {
      const partState = entry[target.partId] as BodyMarkingPartState;
      const partColor =
        partState?.color ||
        (entry.color as string) ||
        def.default_color ||
        '#ffffff';
      return normalizeHex(partColor) || '#ffffff';
    }
    const markColor = (entry.color as string) || def.default_color || '#ffffff';
    return normalizeHex(markColor) || '#ffffff';
  };

  const applyColorTarget = (hex: string) => {
    if (!activeColorTarget) {
      return;
    }
    const normalized = normalizeHex(hex) || '#ffffff';
    if (activeColorTarget.type === 'galleryPreview') {
      const current = previewTint || '#ffffff';
      if (current === normalized) {
        return;
      }
      setPreviewColor(normalized);
      return;
    }
    if (activeColorTarget.type === 'mark' && activeColorTarget.partId) {
      setPartColor(
        activeColorTarget.markId,
        activeColorTarget.partId,
        normalized
      );
    } else {
      setMarkColor(activeColorTarget.markId, normalized);
    }
  };

  const colorPickerValue = activeColorTarget
    ? resolveColorTargetHex(activeColorTarget)
    : '#ffffff';

  const requestPayload = () => {
    act('load_body_markings');
  };

  const syncPayload = (payload: BodyMarkingsPayload) => {
    setBodyPayload(payload);
    const nextMarkings = deepCopyMarkings(payload.body_markings);
    const nextOrder =
      (payload.order as string[]) || Object.keys(payload.body_markings || {});
    setMarkings(nextMarkings);
    setOrder(nextOrder);
    const nextSelectedId =
      typeof nextOrder[0] === 'string' ? nextOrder[0] : null;
    const nextDefinitions = buildBodyMarkingDefinitions(payload);
    selectMarking(nextSelectedId, nextDefinitions, payload.body_markings, {
      setColorTarget: false,
    });
    setSavedState({
      order: [...nextOrder],
      markings: deepCopyMarkings(nextMarkings),
      selectedId: nextSelectedId,
    });
    setTilePage(0);
    setDirty(false);
  };

  const syncPreviewPayload = (payload: BodyMarkingsPayload) => {
    setBodyPayload(payload);
  };

  const applyAdd = (id: string) => {
    if (
      !markings[id] &&
      Object.keys(markings || {}).length >= BODY_MARKING_SELECTION_LIMIT
    ) {
      return;
    }
    const def = definitions[id];
    if (!def) {
      return;
    }
    const entry = cloneEntry<BodyMarkingEntry>(
      def.default_entry || ({} as BodyMarkingEntry)
    );
    if (def.do_colouration && previewTint) {
      entry.color = previewTint;
      if (def.body_parts) {
        for (const partId of def.body_parts) {
          const partState =
            cloneEntry<BodyMarkingPartState>(
              (entry[partId] as BodyMarkingPartState) ||
                ({} as BodyMarkingPartState)
            ) || ({} as BodyMarkingPartState);
          partState.color = previewTint;
          entry[partId] = partState;
        }
      }
    }
    let added = false;
    updateMarkingsState((prev) => {
      if (prev[id]) {
        return prev;
      }
      added = true;
      return {
        ...prev,
        [id]: entry,
      };
    });
    updateOrderState((prev) => {
      if (prev.includes(id)) {
        return prev;
      }
      return [...prev, id];
    });
    if (def.do_colouration) {
      updateColorTargetState(() => ({ type: 'mark', markId: id }));
    } else {
      updateColorTargetState(() => null);
    }
    updateSelectedIdState(() => id);
    if (!added) {
      return;
    }
    setDirty(true);
  };

  const applyRemove = (id: string) => {
    let removed = false;
    let nextOrder: string[] = [];
    updateMarkingsState((prev) => {
      if (!prev[id]) {
        return prev;
      }
      removed = true;
      const next = { ...prev };
      delete next[id];
      return next;
    });
    updateOrderState((prev) => {
      nextOrder = prev.filter((item) => item !== id);
      if (nextOrder.length !== prev.length) {
        removed = true;
      }
      return nextOrder;
    });
    updateColorTargetState((prev) =>
      prev?.type === 'mark' && prev.markId === id ? null : prev
    );
    updateSelectedIdState((prev) => {
      if (prev && prev !== id) {
        return prev;
      }
      return nextOrder[0] || null;
    });
    if (!removed) {
      return;
    }
    setDirty(true);
  };

  const reorder = (id: string, direction: 'up' | 'down') => {
    updateOrderState((prev) => {
      const visible = prev.filter((markId) => !isHiddenMarking(markId));
      const visibleIdx = visible.indexOf(id);
      if (visibleIdx === -1 || visible.length <= 1) {
        return prev;
      }
      const targetVisibleIdx =
        direction === 'up'
          ? visibleIdx === 0
            ? visible.length - 1
            : visibleIdx - 1
          : visibleIdx === visible.length - 1
            ? 0
            : visibleIdx + 1;
      const targetId = visible[targetVisibleIdx];
      const idx = prev.indexOf(id);
      const targetIdx = prev.indexOf(targetId);
      if (idx === -1 || targetIdx === -1) {
        return prev;
      }
      const next = [...prev];
      next[idx] = targetId;
      next[targetIdx] = id;
      return next;
    });
    setDirty(true);
  };

  const togglePart = (markId: string, partId: string) => {
    updateMarkingsState((prev) => {
      const current = cloneEntry<BodyMarkingEntry>(
        prev[markId] || ({} as BodyMarkingEntry)
      );
      const part =
        cloneEntry<BodyMarkingPartState>(
          (current[partId] as BodyMarkingPartState) ||
            ({} as BodyMarkingPartState)
        ) || ({} as BodyMarkingPartState);
      part.on = !isBodyMarkingPartEnabled(part.on);
      current[partId] = part;
      return {
        ...prev,
        [markId]: current,
      };
    });
    setDirty(true);
  };

  const setPartColor = (markId: string, partId: string, color: string) => {
    const normalized = normalizeHex(color) || '#ffffff';
    const { latestMarkings } = resolveLatestBodyState();
    const existingEntry = latestMarkings[markId];
    const existingPartState = existingEntry?.[partId] as
      | BodyMarkingPartState
      | undefined;
    const existingColor = normalizeHex(existingPartState?.color) || null;
    if (existingEntry?.color === null && existingColor === normalized) {
      return;
    }
    updateMarkingsState((prev) => {
      const current = cloneEntry<BodyMarkingEntry>(
        prev[markId] || ({} as BodyMarkingEntry)
      );
      const part =
        cloneEntry<BodyMarkingPartState>(
          (current[partId] as BodyMarkingPartState) ||
            ({} as BodyMarkingPartState)
        ) || ({} as BodyMarkingPartState);
      part.color = normalized;
      current[partId] = part;
      current.color = null;
      return {
        ...prev,
        [markId]: current,
      };
    });
    if (!dirty) {
      setDirty(true);
    }
  };

  const setMarkColor = (markId: string, color: string) => {
    const def = definitions[markId];
    const normalized = normalizeHex(color) || '#ffffff';
    const { latestMarkings } = resolveLatestBodyState();
    const existingEntry = latestMarkings[markId];
    const existingEntryColor = normalizeHex(existingEntry?.color) || null;
    if (existingEntryColor === normalized) {
      const parts = def?.body_parts || [];
      const matches = parts.every((partId) => {
        const partState = existingEntry?.[partId] as BodyMarkingPartState;
        const partColor = normalizeHex(partState?.color) || null;
        return (
          isBodyMarkingPartEnabled(partState?.on) && partColor === normalized
        );
      });
      if (matches) {
        return;
      }
    }
    updateMarkingsState((prev) => {
      const current = cloneEntry<BodyMarkingEntry>(
        prev[markId] || ({} as BodyMarkingEntry)
      );
      current.color = normalized;
      if (def?.body_parts) {
        for (const partId of def.body_parts) {
          const part =
            cloneEntry<BodyMarkingPartState>(
              (current[partId] as BodyMarkingPartState) ||
                ({} as BodyMarkingPartState)
            ) || ({} as BodyMarkingPartState);
          part.color = normalized;
          part.on = isBodyMarkingPartEnabled(part.on);
          current[partId] = part;
        }
      }
      return {
        ...prev,
        [markId]: current,
      };
    });
    if (!dirty) {
      setDirty(true);
    }
  };

  const normalizeEntryPartState = (
    entry: BodyMarkingEntry,
    def: BodyMarkingDefinition
  ): BodyMarkingEntry => {
    if (!def?.body_parts || !def.body_parts.length) {
      return entry;
    }
    const normalized = cloneEntry<BodyMarkingEntry>(entry);
    for (const partId of def.body_parts) {
      const raw = normalized[partId] as BodyMarkingPartState;
      if (!raw || typeof raw !== 'object') {
        normalized[partId] = { on: true } as BodyMarkingPartState;
        continue;
      }
      normalized[partId] = {
        on: isBodyMarkingPartEnabled(raw.on),
        color: raw.color ? normalizeHex(raw.color) : raw.color,
      } as BodyMarkingPartState;
    }
    return normalized;
  };

  const toggleAll = (markId: string, value: boolean) => {
    const def = definitions[markId];
    updateMarkingsState((prev) => {
      const current = cloneEntry<BodyMarkingEntry>(
        prev[markId] || ({} as BodyMarkingEntry)
      );
      if (def?.body_parts) {
        for (const partId of def.body_parts) {
          const part =
            cloneEntry<BodyMarkingPartState>(
              (current[partId] as BodyMarkingPartState) ||
                ({} as BodyMarkingPartState)
            ) || ({} as BodyMarkingPartState);
          part.on = value;
          current[partId] = part;
        }
      }
      return {
        ...prev,
        [markId]: current,
      };
    });
    setDirty(true);
  };

  const handleSave = async (close = false) => {
    const wasDirty = dirty;
    const startingPreviewRevision =
      typeof data.preview_revision === 'number' ? data.preview_revision : 0;
    const { latestMarkings, latestOrder, latestPayload } =
      resolveLatestBodyState();
    const nextOrder = latestOrder || [];
    const nextMarkings = latestMarkings || {};
    if (!nextOrder.length) {
      setDirty(false);
    }
    setPendingSave(true);
    setPendingSaveLocal(true);
    if (close) {
      setPendingClose(true);
      setPendingCloseLocal(true);
    }
    try {
      if (wasDirty) {
        setPreviewRefreshSkips((previewRefreshSkips || 0) + 1);
      }
      const { body_markings: outgoing, order: outgoingOrder } =
        buildBodyMarkingSavePayload({
          order: nextOrder,
          markings: nextMarkings,
          definitions,
        });
      if (!outgoingOrder.length) {
        await act('save_body_markings', {
          body_markings: outgoing,
          order: outgoingOrder,
          close,
        });
      } else {
        const { chunkId, chunks } = buildBodyMarkingChunkPlan({
          order: outgoingOrder,
          markings: outgoing,
          maxEntriesPerChunk: 1,
        });
        const totalChunks = Math.max(chunks.length, 1);
        for (let idx = 0; idx < totalChunks; idx += 1) {
          const payload: Record<string, unknown> = {
            chunk_id: chunkId,
            chunk_index: idx,
            chunk_total: totalChunks,
            body_markings: chunks[idx] || {},
          };
          if (idx === 0) {
            payload.order = outgoingOrder;
          }
          if (close && idx === totalChunks - 1) {
            payload.close = true;
          }
          await act('save_body_markings', payload);
        }
      }
      if (!close) {
        if (wasDirty) {
          setReloadTargetRevision(startingPreviewRevision + 1);
          setReloadPending(true);
        }
        const nextSelected = selectedId || outgoingOrder[0] || null;
        setDirty(false);
        setSavedState({
          order: [...outgoingOrder],
          markings: deepCopyMarkings(outgoing),
          selectedId: nextSelected,
        });
        if (latestPayload) {
          const updatedPayload: BodyMarkingsPayload = {
            ...latestPayload,
            body_markings: outgoing,
            order: outgoingOrder,
          };
          setBodyPayload(updatedPayload);
          setPayloadSignature(buildBodyPayloadSignature(updatedPayload));
        }
      }
    } finally {
      setPendingSave(false);
      setPendingSaveLocal(false);
      setPendingClose(false);
      setPendingCloseLocal(false);
    }
  };

  const handleDiscard = async () => {
    setPendingClose(true);
    setPendingCloseLocal(true);
    try {
      await act('close_body_markings');
    } finally {
      setPendingClose(false);
      setPendingCloseLocal(false);
    }
  };

  const {
    basePreviewReady,
    tileDirectionsSignature,
    getTilePreviewEntries,
    markedPreview,
  } = (() => {
    const previewDirStates = bodyPayload?.preview_sources
      ? updatePreviewStateFromPayload(
          { revision: 0, lastDiffSeq: 0, dirs: {} },
          {
            data: {
              preview_sources: bodyPayload.preview_sources,
              preview_revision: bodyPayload.preview_revision || 0,
              active_dir_key: data.active_dir_key,
              active_dir: data.active_dir,
              grid: [],
            } as any,
            sessionKey: 'body-markings',
            activePartKey: 'generic',
            canvasWidth,
            canvasHeight,
            canvasGrid: null,
          }
        ).dirs
      : ({} as Record<number, PreviewDirState>);
    const { basePreview, liveBasePreview, appearanceContext } =
      buildBodyMarkingsPreviewBases({
        previewDirStates,
        bodyPayload,
        basicPayload,
        basicAppearanceState,
        data,
        bodyPartLabels,
        canvasWidth,
        canvasHeight,
        resolvedPartPriorityMap,
        resolvedPartReplacementMap,
        showJobGear,
        showLoadoutGear,
        signalAssetUpdate,
      });
    const hiddenPartsByDir = buildHiddenBodyPartsByDir(
      appearanceContext.previewDirStatesForLive
    );
    const { appearanceSignature, digitigrade } = appearanceContext;
    const basePreviewByDir = basePreview.reduce(
      (acc, entry) => {
        acc[entry.dir] = entry;
        return acc;
      },
      {} as Record<number, PreviewDirectionEntry>
    );
    const tileDirections =
      (data.directions && data.directions.length
        ? data.directions
        : basePreview.map((entry) => ({ dir: entry.dir, label: entry.label }))
      ).slice(0, 4) || [];
    const tileDirectionsSignature = tileDirections
      .map((entry) => entry.dir)
      .join('|');

    const expectedPreviewDirs = (() => {
      const previewSources = bodyPayload?.preview_sources;
      const payloadDirs = Array.isArray(previewSources)
        ? previewSources
            .map((entry) => entry?.dir)
            .filter((dir): dir is number => typeof dir === 'number')
        : [];
      if (payloadDirs.length) {
        return payloadDirs;
      }
      if (tileDirections.length) {
        return tileDirections.map((entry) => entry.dir);
      }
      return [];
    })();

    const basePreviewReady =
      !!bodyPayload &&
      (expectedPreviewDirs.length
        ? expectedPreviewDirs.every((dir) => !!basePreviewByDir[dir])
        : basePreview.length > 0);

    const buildTilePreviewEntries = (
      def: BodyMarkingDefinition
    ): PreviewDirectionEntry[] => {
      if (!tileDirections.length || !Object.keys(basePreviewByDir).length) {
        return [];
      }
      const defaultEntry = cloneEntry<BodyMarkingEntry>(
        def.default_entry || ({} as BodyMarkingEntry)
      );
      if (!defaultEntry.color && def.default_color) {
        defaultEntry.color = def.default_color;
      }
      if (previewTint && def.do_colouration) {
        defaultEntry.color = previewTint;
        if (def.body_parts) {
          for (const partId of def.body_parts) {
            const partState =
              cloneEntry<BodyMarkingPartState>(
                (defaultEntry[partId] as BodyMarkingPartState) ||
                  ({} as BodyMarkingPartState)
              ) || ({} as BodyMarkingPartState);
            partState.color = previewTint;
            defaultEntry[partId] = partState;
          }
        }
      }
      const hiddenPartsMap = buildHiddenBodyPartsMapForSingleMarking(
        def,
        defaultEntry
      );
      const hasHiddenParts = Object.keys(hiddenPartsMap).length > 0;
      return tileDirections
        .map((dir) => {
          const baseDir = basePreviewByDir[dir.dir];
          if (!baseDir) {
            return null;
          }
          const layersForDir = buildMarkingLayersForDir(
            def,
            defaultEntry,
            dir.dir,
            digitigrade,
            canvasWidth,
            canvasHeight,
            markingOffsetX,
            signalAssetUpdate
          );
          const baseLayers = baseDir.layers || [];
          const overlayLayers = baseLayers.filter(
            (layer) =>
              layer.type === 'overlay' &&
              layer.source !== 'job' &&
              layer.source !== 'loadout'
          );
          const nonOverlayLayers = baseLayers.filter(
            (layer) => layer.type !== 'overlay'
          );
          const suppressedPartsMap = hiddenPartsByDir[dir.dir];
          const hasSuppressedParts =
            !!suppressedPartsMap && Object.keys(suppressedPartsMap).length > 0;
          const combinedHiddenPartsMap = hasSuppressedParts
            ? { ...hiddenPartsMap, ...suppressedPartsMap }
            : hiddenPartsMap;
          const referenceMasks =
            hasHiddenParts || hasSuppressedParts
              ? buildReferencePartMaskMap(
                  nonOverlayLayers as Array<{
                    key?: string;
                    type?: string;
                    grid?: string[][];
                  }>
                )
              : {};
          const canMaskGeneric = Object.keys(referenceMasks).length > 0;
          const normalStack: typeof baseLayers = [];
          const priorityStack: typeof baseLayers = [];
          const handledParts = new Set<string>();
          const appendPartLayers = (partId: string) => {
            const partLayers = layersForDir[partId];
            if (!partLayers) {
              return;
            }
            const isSuppressedPart =
              !!suppressedPartsMap && !!suppressedPartsMap[partId];
            const shouldMaskGeneric =
              partId === 'generic' && hasSuppressedParts && canMaskGeneric;
            if (isSuppressedPart && partId !== 'generic') {
              return;
            }
            partLayers.normal.forEach((markLayer, idx) => {
              normalStack.push({
                type: 'custom',
                key: `tile-${def.id}-${dir.dir}-${partId}-n-${idx}`,
                label: markLayer.label,
                grid:
                  shouldMaskGeneric && Array.isArray(markLayer.grid)
                    ? buildMaskedGenericGrid(
                        markLayer.grid,
                        referenceMasks,
                        suppressedPartsMap || {}
                      )
                    : markLayer.grid,
              });
            });
            partLayers.priority.forEach((markLayer, idx) => {
              priorityStack.push({
                type: 'overlay',
                key: `tile-${def.id}-${dir.dir}-${partId}-p-${idx}`,
                label: markLayer.label,
                grid:
                  shouldMaskGeneric && Array.isArray(markLayer.grid)
                    ? buildMaskedGenericGrid(
                        markLayer.grid,
                        referenceMasks,
                        suppressedPartsMap || {}
                      )
                    : markLayer.grid,
              });
            });
          };
          nonOverlayLayers.forEach((layer) => {
            const partId = resolveLayerPartId(layer);
            const isHiddenPart = !!(partId && hiddenPartsMap[partId]);
            const isSuppressedPart = !!(partId && suppressedPartsMap?.[partId]);
            let resolvedLayer = layer;
            if (
              partId === 'generic' &&
              (hasHiddenParts || hasSuppressedParts) &&
              Array.isArray(layer.grid)
            ) {
              resolvedLayer = {
                ...layer,
                grid: buildMaskedGenericGrid(
                  layer.grid as string[][],
                  referenceMasks,
                  combinedHiddenPartsMap
                ),
              };
            }
            if (
              !isSuppressedPart &&
              (!isHiddenPart || layer?.type === 'custom')
            ) {
              normalStack.push(resolvedLayer);
            }
            if (!partId || !layersForDir[partId] || handledParts.has(partId)) {
              return;
            }
            handledParts.add(partId);
            appendPartLayers(partId);
          });
          Object.keys(layersForDir || {}).forEach((partId) => {
            if (handledParts.has(partId)) {
              return;
            }
            if (suppressedPartsMap?.[partId] && partId !== 'generic') {
              return;
            }
            handledParts.add(partId);
            appendPartLayers(partId);
          });
          return {
            dir: dir.dir,
            label: baseDir.label || dir.label,
            layers: [...normalStack, ...priorityStack, ...overlayLayers],
          };
        })
        .filter(Boolean) as PreviewDirectionEntry[];
    };

    const resolveTilePreviewSignature = (def: BodyMarkingDefinition) =>
      [
        def.id,
        def.default_color || '',
        def.do_colouration ? 'c' : 'n',
        def.render_above_body ? 'p' : 'n',
        def.color_blend_mode,
        digitigrade ? 'd' : 'p',
        canvasWidth,
        canvasHeight,
        markingOffsetX,
        bodyPayload?.preview_revision || 0,
        appearanceSignature,
        assetRevision,
        tileDirections.map((entry) => entry.dir).join(','),
        previewTint || 'default',
      ].join('|');

    const getTilePreviewEntries = (def: BodyMarkingDefinition) => {
      const sig = resolveTilePreviewSignature(def);
      const cached = tilePreviewCache[def.id];
      if (cached && cached.sig === sig) {
        return cached.previews;
      }
      const previews = buildTilePreviewEntries(def);
      tilePreviewCache[def.id] = { sig, previews };
      return previews;
    };

    const layersByDir: Record<number, Record<string, PartMarkingLayers>> = {};
    for (const dir of data.directions || []) {
      layersByDir[dir.dir] = {};
      for (const markId of order) {
        const def = definitions[markId];
        const entry = markings[markId];
        if (!def || !entry) {
          continue;
        }
        const cacheKey = `${markId}:${dir.dir}`;
        const blendMode = resolveBlendMode(def.color_blend_mode);
        const renderAboveBodyPartsSig = def.render_above_body_parts
          ? Object.keys(def.render_above_body_parts).sort().join(',')
          : '';
        const cached = markingLayersCache[cacheKey];
        const built =
          cached &&
          cached.entry === entry &&
          cached.defId === def.id &&
          cached.doColouration === !!def.do_colouration &&
          cached.blendMode === blendMode &&
          cached.renderAboveBody === !!def.render_above_body &&
          cached.renderAboveBodyPartsSig === renderAboveBodyPartsSig &&
          cached.digitigrade === digitigrade &&
          cached.canvasWidth === canvasWidth &&
          cached.canvasHeight === canvasHeight &&
          cached.offsetX === markingOffsetX &&
          cached.assetRevision === assetRevision
            ? cached.built
            : buildMarkingLayersForDir(
                def,
                entry,
                dir.dir,
                digitigrade,
                canvasWidth,
                canvasHeight,
                markingOffsetX,
                signalAssetUpdate
              );
        if (cached?.built !== built) {
          markingLayersCache[cacheKey] = {
            entry,
            defId: def.id,
            doColouration: !!def.do_colouration,
            blendMode,
            renderAboveBody: !!def.render_above_body,
            renderAboveBodyPartsSig,
            digitigrade,
            canvasWidth,
            canvasHeight,
            offsetX: markingOffsetX,
            assetRevision,
            built,
          };
        }
        for (const [partId, partLayers] of Object.entries(built)) {
          if (!layersByDir[dir.dir][partId]) {
            layersByDir[dir.dir][partId] = { normal: [], priority: [] };
          }
          layersByDir[dir.dir][partId].normal.push(...partLayers.normal);
          layersByDir[dir.dir][partId].priority.push(...partLayers.priority);
        }
      }
    }
    const hiddenPartsMap = buildHiddenBodyPartsMapForMarkings(
      definitions,
      markings,
      order
    );
    const hasHiddenParts = Object.keys(hiddenPartsMap).length > 0;
    const previewBase = liveBasePreview.length ? liveBasePreview : basePreview;
    const markedPreview = previewBase.map((dirEntry) => {
      const layerGroup = layersByDir[dirEntry.dir] || {};
      const baseLayers = dirEntry.layers || [];
      const {
        before: nonOverlayLayers,
        overlay: overlayLayers,
        after,
      } = splitOverlayLayers(baseLayers);
      const suppressedPartsMap = hiddenPartsByDir[dirEntry.dir];
      const hasSuppressedParts =
        !!suppressedPartsMap && Object.keys(suppressedPartsMap).length > 0;
      const combinedHiddenPartsMap = hasSuppressedParts
        ? { ...hiddenPartsMap, ...suppressedPartsMap }
        : hiddenPartsMap;
      const referenceMasks =
        hasHiddenParts || hasSuppressedParts
          ? buildReferencePartMaskMap(
              nonOverlayLayers as Array<{
                key?: string;
                type?: string;
                grid?: string[][];
              }>
            )
          : {};
      const canMaskGeneric = Object.keys(referenceMasks).length > 0;
      const normalLayers: typeof baseLayers = [];
      const priorityLayers: typeof baseLayers = [];
      const handledParts = new Set<string>();
      const appendPartLayers = (partId: string) => {
        const partLayers = layerGroup[partId];
        if (!partLayers) {
          return;
        }
        const isSuppressedPart =
          !!suppressedPartsMap && !!suppressedPartsMap[partId];
        const shouldMaskGeneric =
          partId === 'generic' && hasSuppressedParts && canMaskGeneric;
        if (isSuppressedPart && partId !== 'generic') {
          return;
        }
        partLayers.normal.forEach((markLayer, idx) => {
          normalLayers.push({
            type: 'custom',
            key: `mark-${dirEntry.dir}-${partId}-n-${idx}`,
            label: markLayer.label,
            grid:
              shouldMaskGeneric && Array.isArray(markLayer.grid)
                ? buildMaskedGenericGrid(
                    markLayer.grid,
                    referenceMasks,
                    suppressedPartsMap || {}
                  )
                : markLayer.grid,
          });
        });
        partLayers.priority.forEach((markLayer, idx) => {
          priorityLayers.push({
            type: 'overlay',
            key: `mark-priority-${dirEntry.dir}-${partId}-p-${idx}`,
            label: markLayer.label,
            grid:
              shouldMaskGeneric && Array.isArray(markLayer.grid)
                ? buildMaskedGenericGrid(
                    markLayer.grid,
                    referenceMasks,
                    suppressedPartsMap || {}
                  )
                : markLayer.grid,
          });
        });
      };
      nonOverlayLayers.forEach((layer) => {
        const partId = resolveLayerPartId(layer);
        const isHiddenPart = !!(partId && hiddenPartsMap[partId]);
        const isSuppressedPart = !!(partId && suppressedPartsMap?.[partId]);
        let resolvedLayer = layer;
        if (
          partId === 'generic' &&
          (hasHiddenParts || hasSuppressedParts) &&
          Array.isArray(layer.grid)
        ) {
          resolvedLayer = {
            ...layer,
            grid: buildMaskedGenericGrid(
              layer.grid as string[][],
              referenceMasks,
              combinedHiddenPartsMap
            ),
          };
        }
        if (!isSuppressedPart && (!isHiddenPart || layer?.type === 'custom')) {
          normalLayers.push(resolvedLayer);
        }
        if (!partId || !layerGroup[partId] || handledParts.has(partId)) {
          return;
        }
        handledParts.add(partId);
        appendPartLayers(partId);
      });
      Object.keys(layerGroup).forEach((partId) => {
        if (handledParts.has(partId)) {
          return;
        }
        if (suppressedPartsMap?.[partId] && partId !== 'generic') {
          return;
        }
        handledParts.add(partId);
        appendPartLayers(partId);
      });
      return {
        ...dirEntry,
        layers: [
          ...normalLayers,
          ...priorityLayers,
          ...overlayLayers,
          ...after,
        ],
      };
    });

    return {
      basePreviewReady,
      tileDirectionsSignature,
      getTilePreviewEntries,
      markedPreview,
    };
  })();

  const visibleOrder = order.filter((markId) => !isHiddenMarking(markId));
  const totalSelected = Object.keys(markings || {}).length;
  const previewBackgroundImage = resolvedCanvasBackground?.asset?.png
    ? `data:image/png;base64,${resolvedCanvasBackground.asset.png}`
    : null;
  const previewBackgroundTileWidth = resolvedCanvasBackground?.asset?.width
    ? resolvedCanvasBackground.asset.width * canvasBackgroundScale
    : undefined;
  const previewBackgroundTileHeight = resolvedCanvasBackground?.asset?.height
    ? resolvedCanvasBackground.asset.height * canvasBackgroundScale
    : undefined;
  const atSelectionLimit = totalSelected >= BODY_MARKING_SELECTION_LIMIT;
  const effectiveSelectedId =
    selectedId && !isHiddenMarking(selectedId)
      ? selectedId
      : visibleOrder[0] || null;
  const selectedDef =
    effectiveSelectedId && definitions[effectiveSelectedId]
      ? definitions[effectiveSelectedId]
      : null;
  const selectedEntry =
    effectiveSelectedId && markings[effectiveSelectedId] && selectedDef
      ? normalizeEntryPartState(markings[effectiveSelectedId], selectedDef)
      : null;
  const markingKeysSignature = Object.keys(markings || {})
    .sort()
    .join('|');
  const referenceBuildInProgress = !!data.reference_build_in_progress;
  if (
    !bodyPayload ||
    referenceBuildInProgress ||
    (!basePreviewReady && !previewTimedOut)
  ) {
    return (
      <Box className="RogueStar" position="relative" minHeight="100%">
        <BodyMarkingsInitializer
          bodyPayload={bodyPayload}
          dataPayload={data.body_markings_payload}
          payloadSignature={payloadSignature}
          setPayloadSignature={setPayloadSignature}
          loadInProgress={loadInProgress}
          setLoadInProgress={setLoadInProgress}
          requestPayload={requestPayload}
          syncPayload={(payload) => {
            setPayloadSignature(buildBodyPayloadSignature(payload));
            syncPayload(payload);
          }}
          syncPreviewPayload={(payload) => {
            setPayloadSignature(buildBodyPayloadSignature(payload));
            syncPreviewPayload(payload);
          }}
        />
        <BodyMarkingsPreviewLoadCoordinator
          bodyPayload={bodyPayload}
          payloadSignature={payloadSignature}
          referenceBuildInProgress={referenceBuildInProgress}
          previewReady={basePreviewReady}
          timedOut={previewTimedOut}
          setTimedOut={setPreviewTimedOut}
          timeoutMs={BODY_MARKINGS_PREVIEW_TIMEOUT_MS}
        />
        <LoadingOverlay
          title="Loading body markings…"
          subtitle="Fetching your available markings and previews. This should only take a moment."
        />
      </Box>
    );
  }

  return (
    <Box className="RogueStar" position="relative" minHeight="100%">
      <BodyMarkingsInitializer
        bodyPayload={bodyPayload}
        dataPayload={data.body_markings_payload}
        payloadSignature={payloadSignature}
        setPayloadSignature={setPayloadSignature}
        loadInProgress={loadInProgress}
        setLoadInProgress={setLoadInProgress}
        requestPayload={requestPayload}
        syncPayload={(payload) => {
          setPayloadSignature(buildBodyPayloadSignature(payload));
          syncPayload(payload);
        }}
        syncPreviewPayload={(payload) => {
          setPayloadSignature(buildBodyPayloadSignature(payload));
          syncPreviewPayload(payload);
        }}
      />
      <BodyMarkingsPreviewLoadCoordinator
        bodyPayload={bodyPayload}
        payloadSignature={payloadSignature}
        referenceBuildInProgress={referenceBuildInProgress}
        previewReady={basePreviewReady}
        timedOut={previewTimedOut}
        setTimedOut={setPreviewTimedOut}
        timeoutMs={BODY_MARKINGS_PREVIEW_TIMEOUT_MS}
      />
      <Flex direction="row" gap={1} wrap={false} height="100%">
        <Flex.Item basis="840px" shrink={0}>
          <Flex direction="column" gap={1}>
            <BodyMarkingsGallerySection
              bodyPayload={bodyPayload}
              category={category}
              setCategory={setCategory}
              search={search}
              setSearch={setSearch}
              tilePage={tilePage}
              setTilePage={setTilePage}
              activeColorTarget={activeColorTarget}
              previewTint={previewTint}
              setColorTarget={setColorTarget}
              atSelectionLimit={atSelectionLimit}
              canvasWidth={canvasWidth}
              canvasHeight={canvasHeight}
              tileDirectionsSignature={tileDirectionsSignature}
              assetRevision={assetRevision}
              markings={markings}
              markingKeysSignature={markingKeysSignature}
              getTilePreviewEntries={getTilePreviewEntries}
              applyAdd={applyAdd}
              applyRemove={applyRemove}
              backgroundImage={previewBackgroundImage}
              backgroundColor={backgroundFallbackColor}
              backgroundScale={canvasBackgroundScale}
              backgroundTileWidth={previewBackgroundTileWidth}
              backgroundTileHeight={previewBackgroundTileHeight}
            />
          </Flex>
        </Flex.Item>
        <Flex.Item basis="418px" shrink={0}>
          <Flex direction="column" gap={1}>
            <BodyMarkingsSaveSection
              pendingSave={pendingSave}
              pendingClose={pendingClose}
              uiLocked={uiLocked}
              dirty={dirty}
              onSave={() => handleSave(false)}
              onSaveAndClose={() => handleSave(true)}
              onDiscardAndClose={handleDiscard}
            />
            <BodyMarkingsActiveSection
              order={order}
              visibleOrder={visibleOrder}
              totalSelected={totalSelected}
              selectedId={selectedId}
              definitions={definitions}
              markings={markings}
              selectMarking={selectMarking}
              reorder={reorder}
              applyRemove={applyRemove}
              selectedDef={selectedDef}
              selectedEntry={selectedEntry}
              toggleAll={toggleAll}
              togglePart={togglePart}
              bodyPartLabels={bodyPartLabels}
              activeColorTarget={activeColorTarget}
              setColorTarget={setColorTarget}
            />
          </Flex>
        </Flex.Item>
        <Flex.Item grow>
          <BodyMarkingsPreviewColumn
            markedPreview={markedPreview}
            canvasWidth={canvasWidth}
            canvasHeight={canvasHeight}
            previewFitToFrame={previewFitToFrame}
            onTogglePreviewFit={togglePreviewFit}
            previewBackgroundImage={previewBackgroundImage}
            backgroundFallbackColor={backgroundFallbackColor}
            canvasBackgroundScale={canvasBackgroundScale}
            previewBackgroundTileWidth={previewBackgroundTileWidth}
            previewBackgroundTileHeight={previewBackgroundTileHeight}
            showJobGear={showJobGear}
            onToggleJobGear={onToggleJobGear}
            showLoadoutGear={showLoadoutGear}
            onToggleLoadout={onToggleLoadout}
            canvasBackgroundOptions={canvasBackgroundOptions}
            resolvedCanvasBackground={resolvedCanvasBackground}
            cycleCanvasBackground={cycleCanvasBackground}
            colorPickerValue={colorPickerValue}
            applyColorTarget={applyColorTarget}
          />
        </Flex.Item>
      </Flex>
    </Box>
  );
};
