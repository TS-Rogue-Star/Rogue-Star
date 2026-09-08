// /////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Basic appearance selection tab added //
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
  buildRenderedPreviewDirs as buildBasePreviewDirs,
  cloneGridData,
  createBlankGrid,
  getPreviewGridFromAsset,
  getPreviewPartMapFromAssets,
  gridHasPixels,
  type GearOverlayAsset,
  type IconAssetPayload,
  type PreviewDirState,
  type PreviewDirectionEntry,
  type PreviewLayerEntry,
} from '../../utils/character-preview';
import { DirectionPreviewCanvas, LoadingOverlay } from './components';
import { CHIP_BUTTON_CLASS, PREVIEW_PIXEL_SIZE } from './constants';
import {
  applyBodyColorToPreview,
  buildBasicStateFromPayload,
  buildPartPaintPresenceMap,
  buildRenderedPreviewDirs as buildDesignerPreviewDirs,
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
  buildBodyMarkingDefinitions,
  buildBodyPayloadSignature,
  buildBodySavedStateFromPayload,
  deepCopyMarkings,
  isBodyMarkingPartEnabled,
} from './utils/bodyMarkings';
import type {
  BasicAppearanceAccessoryDefinition,
  BasicAppearanceGradientDefinition,
  BasicAppearancePayload,
  BasicAppearanceState,
  BodyMarkingDefinition,
  BodyMarkingEntry,
  BodyMarkingPartState,
  BodyMarkingsPayload,
  BodyMarkingsSavedState,
  CanvasBackgroundOption,
  CustomMarkingDesignerData,
  DirectionEntry,
} from './types';

type BasicAppearanceTabProps = Readonly<{
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

type BasicAppearanceType =
  | 'hair'
  | 'gradient'
  | 'facial_hair'
  | 'ears'
  | 'horns'
  | 'tail'
  | 'wings'
  | 'eyes'
  | 'body';

type BasicAppearanceColorTarget =
  | { type: 'hair' }
  | { type: 'gradient' }
  | { type: 'facial_hair' }
  | { type: 'eyes' }
  | { type: 'body' }
  | { type: 'ears'; channel: number }
  | { type: 'horns'; channel: number }
  | { type: 'tail'; channel: number }
  | { type: 'wings'; channel: number };

type BasicAppearanceAccessoryChannelCaps = Readonly<{
  ears: number;
  horns: number;
  tail: number;
  wings: number;
}>;

type OrderedOverlayLayer = {
  grid: string[][];
  layer: number | null;
  slot?: string | null;
  source: 'base' | 'job' | 'loadout';
  order: number;
};

const MARKING_TILE_PIXEL_SIZE = 2;

const TYPE_LABELS: Record<BasicAppearanceType, string> = {
  hair: 'Hair',
  gradient: 'Hair Gradient',
  facial_hair: 'Facial Hair',
  ears: 'Ears',
  horns: 'Horns',
  tail: 'Tail',
  wings: 'Wings',
  eyes: 'Eyes',
  body: 'Body',
};

const GALLERY_TYPES: BasicAppearanceType[] = [
  'hair',
  'gradient',
  'facial_hair',
  'ears',
  'horns',
  'tail',
  'wings',
];

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

let assetUpdateScheduled = false;

const compareByName = (
  a: { id: string; name: string },
  b: { id: string; name: string }
) =>
  a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }) ||
  a.id.localeCompare(b.id, undefined, { sensitivity: 'base' });

const buildBooleanMapSignature = (
  map?: Record<string, boolean> | null
): string => {
  if (!map) {
    return '';
  }
  return Object.keys(map)
    .filter((key) => map[key])
    .sort()
    .join('|');
};

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

const applyEyeColorToPreview = (
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

const applyBodyAndEyeColorToPreview = (
  preview: PreviewDirectionEntry[],
  bodyBaseHex: string | null,
  bodyTargetHex: string | null,
  bodyExcludedParts: Set<string> | null,
  eyeBaseHex: string | null,
  eyeTargetHex: string | null,
  bodyHex?: string | null
): PreviewDirectionEntry[] =>
  applyEyeColorToPreview(
    applyBodyColorToPreview(
      preview,
      bodyBaseHex,
      bodyTargetHex,
      bodyExcludedParts,
      3
    ),
    eyeBaseHex,
    eyeTargetHex,
    bodyHex
  );

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
      if (!pixelHasColor(targetColumn[y])) {
        continue;
      }
      if (!pixelHasColor(maskColumn[y])) {
        targetColumn[y] = TRANSPARENT_HEX;
      }
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

const mergeHiddenBodyPartsInPreviewStates = (
  previewDirStates: Record<number, PreviewDirState>,
  hiddenBodyParts: string[]
): Record<number, PreviewDirState> => {
  if (!hiddenBodyParts.length) {
    return previewDirStates;
  }
  return Object.values(previewDirStates).reduce(
    (acc, dirState) => {
      if (!dirState) {
        return acc;
      }
      const currentHidden = Array.isArray(dirState.hiddenBodyParts)
        ? dirState.hiddenBodyParts
        : [];
      const mergedHidden = Array.from(
        new Set([...currentHidden, ...hiddenBodyParts])
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
  );
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

const buildBasicPayloadSignature = (
  payload?: BasicAppearancePayload | null
) => {
  if (!payload) {
    return null;
  }
  const revision = payload.preview_revision || 0;
  const altRevision = payload.preview_revision_alt || 0;
  const size = `${payload.preview_width || 0}x${payload.preview_height || 0}`;
  const digitigrade = payload.digitigrade ? 'd' : 'p';
  const digitigradeAllowed = payload.digitigrade_allowed === false ? '0' : '1';
  const defsSignature = [
    (payload.hair_styles || []).map((def) => def.id).join('|'),
    (payload.gradient_styles || []).map((def) => def.id).join('|'),
    (payload.facial_hair_styles || []).map((def) => def.id).join('|'),
    (payload.ear_styles || []).map((def) => def.id).join('|'),
    (payload.tail_styles || []).map((def) => def.id).join('|'),
    (payload.wing_styles || []).map((def) => def.id).join('|'),
  ].join('::');
  return `${revision}:${altRevision}:${size}:${digitigrade}:${digitigradeAllowed}:${defsSignature}`;
};

const resolveSelectedDef = <T extends { id: string }>(
  defs: T[] | undefined,
  id: string | null
): T | null => {
  if (!id || !Array.isArray(defs)) {
    return null;
  }
  return defs.find((entry) => entry.id === id) || null;
};

const resolveAccessoryMaxChannels = (
  defs: BasicAppearanceAccessoryDefinition[] | undefined
): number => {
  if (!Array.isArray(defs) || !defs.length) {
    return 0;
  }
  let max = 0;
  for (const def of defs) {
    const count =
      typeof def.channel_count === 'number'
        ? Math.max(0, def.channel_count)
        : 0;
    max = Math.max(max, count);
  }
  return max;
};

const resolveDefaultColorTarget = (
  type: BasicAppearanceType
): BasicAppearanceColorTarget => {
  switch (type) {
    case 'gradient':
      return { type: 'gradient' };
    case 'facial_hair':
      return { type: 'facial_hair' };
    case 'ears':
      return { type: 'ears', channel: 0 };
    case 'horns':
      return { type: 'horns', channel: 0 };
    case 'tail':
      return { type: 'tail', channel: 0 };
    case 'wings':
      return { type: 'wings', channel: 0 };
    case 'eyes':
      return { type: 'eyes' };
    case 'body':
      return { type: 'body' };
    default:
      return { type: 'hair' };
  }
};

const clampChannelIndex = (value: number, maxChannels: number) =>
  Math.max(0, Math.min(maxChannels - 1, Math.floor(value)));

const resolveBasicColorTarget = (options: {
  target: BasicAppearanceColorTarget | null;
  activeType: BasicAppearanceType;
  maxAccessoryChannels: BasicAppearanceAccessoryChannelCaps;
}): BasicAppearanceColorTarget | null => {
  const { target, activeType, maxAccessoryChannels } = options;
  if (!target) {
    return resolveDefaultColorTarget(activeType);
  }

  switch (target.type) {
    case 'hair':
      return { type: 'hair' };
    case 'gradient':
      return { type: 'gradient' };
    case 'facial_hair':
      return { type: 'facial_hair' };
    case 'eyes':
      return { type: 'eyes' };
    case 'body':
      return { type: 'body' };
    case 'ears': {
      const maxChannels = Math.max(0, maxAccessoryChannels.ears);
      if (maxChannels <= 0) {
        return resolveDefaultColorTarget(activeType);
      }
      return {
        ...target,
        channel: clampChannelIndex(target.channel, maxChannels),
      };
    }
    case 'horns': {
      const maxChannels = Math.max(0, maxAccessoryChannels.horns);
      if (maxChannels <= 0) {
        return resolveDefaultColorTarget(activeType);
      }
      return {
        ...target,
        channel: clampChannelIndex(target.channel, maxChannels),
      };
    }
    case 'tail': {
      const maxChannels = Math.max(0, maxAccessoryChannels.tail);
      if (maxChannels <= 0) {
        return resolveDefaultColorTarget(activeType);
      }
      return {
        ...target,
        channel: clampChannelIndex(target.channel, maxChannels),
      };
    }
    case 'wings': {
      const maxChannels = Math.max(0, maxAccessoryChannels.wings);
      if (maxChannels <= 0) {
        return resolveDefaultColorTarget(activeType);
      }
      return {
        ...target,
        channel: clampChannelIndex(target.channel, maxChannels),
      };
    }
    default:
      return resolveDefaultColorTarget(activeType);
  }
};

type BasicTilePreviewEntry = PreviewDirectionEntry & {
  baseLayers?: PreviewLayerEntry[];
  underlayLayers?: PreviewLayerEntry[];
  overlayLayers?: PreviewLayerEntry[];
  baseSignature?: string;
};

type BasicTileProps = Readonly<{
  def: { id: string; name: string };
  selected: boolean;
  previews: BasicTilePreviewEntry[];
  onToggle: () => void;
  canvasWidth: number;
  canvasHeight: number;
  backgroundImage: string | null;
  backgroundColor: string;
  backgroundScale: number;
  backgroundTileWidth?: number;
  backgroundTileHeight?: number;
}>;

class BasicTile extends Component<BasicTileProps> {
  shouldComponentUpdate(next: BasicTileProps) {
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
                layers={
                  preview.baseLayers ||
                  preview.underlayLayers ||
                  preview.overlayLayers
                    ? undefined
                    : preview.layers
                }
                baseLayers={preview.baseLayers}
                underlayLayers={preview.underlayLayers}
                overlayLayers={preview.overlayLayers}
                baseSignature={preview.baseSignature}
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

type BasicTileSectionProps = Readonly<{
  definitions: Array<{ id: string; name: string }>;
  canvasWidth: number;
  canvasHeight: number;
  search: string;
  page: number;
  onPageChange: (page: number) => void;
  tileDirectionsSignature: string;
  assetRevision: number;
  selectedId: string | null;
  backgroundImage: string | null;
  backgroundColor: string;
  backgroundScale: number;
  backgroundTileWidth?: number;
  backgroundTileHeight?: number;
  getTilePreviewEntries: (def: {
    id: string;
    name: string;
  }) => BasicTilePreviewEntry[];
  onSelect: (id: string | null) => void;
  emptyMessage?: string;
}>;

class BasicTileSection extends Component<BasicTileSectionProps> {
  shouldComponentUpdate(next: BasicTileSectionProps) {
    return (
      next.search !== this.props.search ||
      next.page !== this.props.page ||
      next.canvasWidth !== this.props.canvasWidth ||
      next.canvasHeight !== this.props.canvasHeight ||
      next.tileDirectionsSignature !== this.props.tileDirectionsSignature ||
      next.assetRevision !== this.props.assetRevision ||
      next.selectedId !== this.props.selectedId ||
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
      search,
      page,
      onPageChange,
      tileDirectionsSignature: _,
      assetRevision: __,
      selectedId,
      backgroundImage,
      backgroundColor,
      backgroundScale,
      backgroundTileWidth,
      backgroundTileHeight,
      getTilePreviewEntries,
      onSelect,
      emptyMessage,
    } = this.props;
    const searchNeedle = search.trim().toLowerCase();
    const filtered = definitions.filter((def) => {
      if (!searchNeedle) {
        return true;
      }
      return (
        def.id.toLowerCase().includes(searchNeedle) ||
        def.name.toLowerCase().includes(searchNeedle)
      );
    });
    filtered.sort(compareByName);

    const PAGE_SIZE = 20;
    const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
    const currentPage = Math.min(
      Math.max(0, page),
      Math.max(0, totalPages - 1)
    );
    const startIdx = currentPage * PAGE_SIZE;
    const endIdx = startIdx + PAGE_SIZE;
    const paged = filtered.slice(startIdx, endIdx);
    const showStart = filtered.length ? startIdx + 1 : 0;
    const showEnd = Math.min(endIdx, filtered.length);

    return (
      <>
        <Box className="RogueStar__markingGrid">
          {paged.map((def) => {
            const selected = !!selectedId && selectedId === def.id;
            const tilePreviews = getTilePreviewEntries(def);
            return (
              <BasicTile
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
                onToggle={() => onSelect(selected ? null : def.id)}
              />
            );
          })}
          {!filtered.length && (
            <NoticeBox>
              {emptyMessage || 'No entries found for this filter.'}
            </NoticeBox>
          )}
        </Box>
        {filtered.length > PAGE_SIZE && (
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
                {showEnd} of {filtered.length}
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

type BasicAppearanceGallerySectionProps = Readonly<{
  type: BasicAppearanceType;
  setType: (type: BasicAppearanceType) => void;
  search: string;
  setSearch: (search: string) => void;
  tilePage: number;
  setTilePage: (page: number) => void;
  definitions: Array<{ id: string; name: string }>;
  selectedId: string | null;
  canvasWidth: number;
  canvasHeight: number;
  tileDirectionsSignature: string;
  assetRevision: number;
  getTilePreviewEntries: (def: {
    id: string;
    name: string;
  }) => BasicTilePreviewEntry[];
  backgroundImage: string | null;
  backgroundColor: string;
  backgroundScale: number;
  backgroundTileWidth?: number;
  backgroundTileHeight?: number;
  onSelect: (id: string | null) => void;
}>;

const BasicAppearanceGallerySection = ({
  type,
  setType,
  search,
  setSearch,
  tilePage,
  setTilePage,
  definitions,
  selectedId,
  canvasWidth,
  canvasHeight,
  tileDirectionsSignature,
  assetRevision,
  getTilePreviewEntries,
  backgroundImage,
  backgroundColor,
  backgroundScale,
  backgroundTileWidth,
  backgroundTileHeight,
  onSelect,
}: BasicAppearanceGallerySectionProps) => (
  <Section
    title="Basic Appearance Gallery"
    buttons={
      <Flex align="center" gap={0.5} wrap="wrap">
        <Flex.Item grow>
          <Tabs>
            {GALLERY_TYPES.map((key) => (
              <Tabs.Tab
                key={key}
                selected={type === key}
                onClick={() => {
                  setType(key);
                  setTilePage(0);
                }}>
                {TYPE_LABELS[key]}
              </Tabs.Tab>
            ))}
          </Tabs>
        </Flex.Item>
      </Flex>
    }>
    <Box mb={1}>
      <Input
        fluid
        value={search}
        placeholder={`Search ${TYPE_LABELS[type].toLowerCase()}…`}
        onInput={(e, value) => {
          setSearch(value);
          setTilePage(0);
        }}
      />
    </Box>
    <BasicTileSection
      definitions={definitions}
      canvasWidth={canvasWidth}
      canvasHeight={canvasHeight}
      search={search}
      page={tilePage}
      onPageChange={setTilePage}
      tileDirectionsSignature={tileDirectionsSignature}
      assetRevision={assetRevision}
      selectedId={selectedId}
      backgroundImage={backgroundImage}
      backgroundColor={backgroundColor}
      backgroundScale={backgroundScale}
      backgroundTileWidth={backgroundTileWidth}
      backgroundTileHeight={backgroundTileHeight}
      getTilePreviewEntries={getTilePreviewEntries}
      onSelect={onSelect}
    />
  </Section>
);

type BasicAppearanceSaveSectionProps = Readonly<{
  pendingSave: boolean;
  pendingClose: boolean;
  uiLocked: boolean;
  dirty: boolean;
  onSave: () => void;
  onSaveAndClose: () => void;
  onDiscardAndClose: () => void;
}>;

const BasicAppearanceSaveSection = ({
  pendingSave,
  pendingClose,
  uiLocked,
  dirty,
  onSave,
  onSaveAndClose,
  onDiscardAndClose,
}: BasicAppearanceSaveSectionProps) => (
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

type BasicAppearanceSettingsSectionProps = Readonly<{
  state: BasicAppearanceState;
  uiLocked: boolean;
  digitigradeAllowed: boolean;
  hairDef: BasicAppearanceAccessoryDefinition | null;
  facialHairDef: BasicAppearanceAccessoryDefinition | null;
  maxAccessoryChannels: BasicAppearanceAccessoryChannelCaps;
  activeColorTarget: BasicAppearanceColorTarget | null;
  setColorTarget: (target: BasicAppearanceColorTarget | null) => void;
  setStyle: (type: BasicAppearanceType, styleId: string | null) => void;
  setDigitigrade: (value: boolean) => void;
}>;

const buildChannelButtons = (options: {
  label: string;
  type:
    | { type: 'ears'; max: number; colors: (string | null)[] }
    | { type: 'horns'; max: number; colors: (string | null)[] }
    | { type: 'tail'; max: number; colors: (string | null)[] }
    | { type: 'wings'; max: number; colors: (string | null)[] };
  activeColorTarget: BasicAppearanceColorTarget | null;
  setColorTarget: (target: BasicAppearanceColorTarget | null) => void;
  disabled?: boolean;
}) => {
  const { label, type, activeColorTarget, setColorTarget, disabled } = options;
  const max = Math.max(0, type.max || 0);
  const colors = Array.isArray(type.colors) ? type.colors : [];
  if (max <= 0) {
    return (
      <NoticeBox>
        {label} has no color channels for the selected style.
      </NoticeBox>
    );
  }
  return (
    <Flex wrap gap={0.5}>
      {Array.from({ length: max }, (_, index) => {
        const color = normalizeHex(colors[index]) || '#ffffff';
        const target: BasicAppearanceColorTarget = {
          type: type.type,
          channel: index,
        } as BasicAppearanceColorTarget;
        const selected =
          activeColorTarget?.type === type.type &&
          (activeColorTarget as any).channel === index;
        return (
          <Button
            key={`${type.type}-${index}`}
            className={CHIP_BUTTON_CLASS}
            icon="tint"
            disabled={disabled}
            selected={selected}
            onClick={() => setColorTarget(target)}>
            <ColorBox mr={0.5} color={color} />
            Color {index + 1}
          </Button>
        );
      })}
    </Flex>
  );
};

const BasicAppearanceSettingsSection = ({
  state,
  uiLocked,
  digitigradeAllowed,
  hairDef,
  facialHairDef,
  maxAccessoryChannels,
  activeColorTarget,
  setColorTarget,
  setStyle,
  setDigitigrade,
}: BasicAppearanceSettingsSectionProps) => {
  type BasicAppearanceStyleType =
    | 'hair'
    | 'gradient'
    | 'facial_hair'
    | 'ears'
    | 'horns'
    | 'tail'
    | 'wings';

  const digitigradeTooltip = !digitigradeAllowed
    ? 'Not available for the selected species.'
    : undefined;

  const StyleRow = (
    props: Readonly<{
      label: string;
      value: string | null;
      type: BasicAppearanceStyleType;
    }>
  ) => {
    const { label, value, type } = props;
    return (
      <LabeledList.Item label={label}>
        <Flex align="center" gap={0.5} wrap>
          <Flex.Item grow>
            <Box nowrap title={value || 'None'}>
              {value || 'None'}
            </Box>
          </Flex.Item>
          <Flex.Item>
            <Button
              className={CHIP_BUTTON_CLASS}
              icon="eraser"
              disabled={uiLocked || !value}
              onClick={() => setStyle(type, null)}>
              Clear
            </Button>
          </Flex.Item>
        </Flex>
      </LabeledList.Item>
    );
  };

  const hairColor = normalizeHex(state.hair_color) || '#ffffff';
  const gradientColor = normalizeHex(state.hair_gradient_color) || '#ffffff';
  const facialHairColor = normalizeHex(state.facial_hair_color) || '#ffffff';
  const eyesColor = normalizeHex(state.eye_color) || '#ffffff';
  const bodyColor = normalizeHex(state.body_color) || '#ffffff';

  const hairColorable = !!hairDef?.do_colouration;
  const facialHairColorable = !!facialHairDef?.do_colouration;
  const earChannels = Math.max(0, maxAccessoryChannels.ears);
  const hornChannels = Math.max(
    0,
    maxAccessoryChannels.horns,
    state.horn_colors.length || 0
  );
  const tailChannels = Math.max(0, maxAccessoryChannels.tail);
  const wingChannels = Math.max(0, maxAccessoryChannels.wings);

  return (
    <Section title="Settings" fill>
      <Flex direction="column" gap={1}>
        <LabeledList>
          <StyleRow type="hair" label="Hair Style" value={state.hair_style} />
          <LabeledList.Item label="Hair Color">
            <Button
              className={CHIP_BUTTON_CLASS}
              icon="tint"
              disabled={uiLocked || !hairColorable}
              selected={activeColorTarget?.type === 'hair'}
              onClick={() => setColorTarget({ type: 'hair' })}>
              <ColorBox mr={0.5} color={hairColor} />
              Color
            </Button>
          </LabeledList.Item>
          <StyleRow
            type="gradient"
            label="Gradient Style"
            value={state.hair_gradient_style}
          />
          <LabeledList.Item label="Gradient Color">
            <Button
              className={CHIP_BUTTON_CLASS}
              icon="tint"
              disabled={uiLocked || !state.hair_gradient_style}
              selected={activeColorTarget?.type === 'gradient'}
              onClick={() => setColorTarget({ type: 'gradient' })}>
              <ColorBox mr={0.5} color={gradientColor} />
              Color
            </Button>
          </LabeledList.Item>
          <StyleRow
            type="facial_hair"
            label="Facial Hair Style"
            value={state.facial_hair_style}
          />
          <LabeledList.Item label="Facial Hair Color">
            <Button
              className={CHIP_BUTTON_CLASS}
              icon="tint"
              disabled={uiLocked || !facialHairColorable}
              selected={activeColorTarget?.type === 'facial_hair'}
              onClick={() => setColorTarget({ type: 'facial_hair' })}>
              <ColorBox mr={0.5} color={facialHairColor} />
              Color
            </Button>
          </LabeledList.Item>
          <StyleRow type="ears" label="Ear Style" value={state.ear_style} />
          <LabeledList.Item label="Ear Colors">
            {buildChannelButtons({
              label: 'Ears',
              type: {
                type: 'ears',
                max: earChannels,
                colors: state.ear_colors,
              },
              activeColorTarget,
              setColorTarget,
              disabled: uiLocked,
            })}
          </LabeledList.Item>
          <StyleRow type="horns" label="Horn Style" value={state.horn_style} />
          <LabeledList.Item label="Horn Colors">
            {buildChannelButtons({
              label: 'Horns',
              type: {
                type: 'horns',
                max: hornChannels,
                colors: state.horn_colors,
              },
              activeColorTarget,
              setColorTarget,
              disabled: uiLocked,
            })}
          </LabeledList.Item>
          <StyleRow type="tail" label="Tail Style" value={state.tail_style} />
          <LabeledList.Item label="Tail Colors">
            {buildChannelButtons({
              label: 'Tail',
              type: {
                type: 'tail',
                max: tailChannels,
                colors: state.tail_colors,
              },
              activeColorTarget,
              setColorTarget,
              disabled: uiLocked,
            })}
          </LabeledList.Item>
          <StyleRow type="wings" label="Wing Style" value={state.wing_style} />
          <LabeledList.Item label="Wing Colors">
            {buildChannelButtons({
              label: 'Wings',
              type: {
                type: 'wings',
                max: wingChannels,
                colors: state.wing_colors,
              },
              activeColorTarget,
              setColorTarget,
              disabled: uiLocked,
            })}
          </LabeledList.Item>
          <LabeledList.Item label="Eye Color">
            <Button
              className={CHIP_BUTTON_CLASS}
              icon="tint"
              disabled={uiLocked}
              selected={activeColorTarget?.type === 'eyes'}
              onClick={() => setColorTarget({ type: 'eyes' })}>
              <ColorBox mr={0.5} color={eyesColor} />
              Color
            </Button>
          </LabeledList.Item>
          <LabeledList.Item label="Body Color">
            <Button
              className={CHIP_BUTTON_CLASS}
              icon="tint"
              disabled={uiLocked}
              selected={activeColorTarget?.type === 'body'}
              onClick={() => setColorTarget({ type: 'body' })}>
              <ColorBox mr={0.5} color={bodyColor} />
              Color
            </Button>
          </LabeledList.Item>
          <LabeledList.Item label="Digitigrade">
            <Button.Checkbox
              className={CHIP_BUTTON_CLASS}
              checked={digitigradeAllowed && !!state.digitigrade}
              disabled={uiLocked || !digitigradeAllowed}
              tooltip={digitigradeTooltip}
              onClick={() => setDigitigrade(!state.digitigrade)}>
              Enabled
            </Button.Checkbox>
          </LabeledList.Item>
        </LabeledList>
      </Flex>
    </Section>
  );
};

type BasicAppearancePreviewColumnProps = Readonly<{
  preview: PreviewDirectionEntry[];
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

const BasicAppearancePreviewColumn = ({
  preview,
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
}: BasicAppearancePreviewColumnProps) => (
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
        {preview.map((entry) => (
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

type BasicAppearanceInitializerProps = Readonly<{
  basicPayload: BasicAppearancePayload | null;
  dataPayload?: BasicAppearancePayload | null;
  payloadSignature: string | null;
  setPayloadSignature: (signature: string | null) => void;
  requestPayload: () => void;
  syncPayload: (payload: BasicAppearancePayload) => void;
  syncPreviewPayload: (payload: BasicAppearancePayload) => void;
  loadInProgress: boolean;
  setLoadInProgress: (value: boolean) => void;
}>;

class BasicAppearanceInitializer extends Component<BasicAppearanceInitializerProps> {
  private hasRequested = false;
  private lastPayloadSignature: string | null = null;
  private lastDataPayload: BasicAppearancePayload | null = null;

  componentDidMount() {
    this.requestIfNeeded();
    this.syncIfNeeded();
  }

  componentDidUpdate(prevProps: BasicAppearanceInitializerProps) {
    if (
      prevProps.basicPayload !== this.props.basicPayload ||
      prevProps.dataPayload !== this.props.dataPayload
    ) {
      this.requestIfNeeded();
      this.syncIfNeeded();
    }
  }

  requestIfNeeded() {
    const {
      basicPayload,
      dataPayload,
      requestPayload,
      loadInProgress,
      setLoadInProgress,
    } = this.props;
    if (
      !basicPayload &&
      !dataPayload &&
      !this.hasRequested &&
      !loadInProgress
    ) {
      this.hasRequested = true;
      setLoadInProgress(true);
      requestPayload();
    }
  }

  syncIfNeeded() {
    const {
      dataPayload,
      basicPayload,
      payloadSignature,
      setPayloadSignature,
      syncPayload,
      syncPreviewPayload,
      loadInProgress,
      setLoadInProgress,
    } = this.props;
    if (!dataPayload) {
      if (basicPayload) {
        const basicSignature = buildBasicPayloadSignature(basicPayload);
        if (basicSignature !== payloadSignature) {
          setPayloadSignature(basicSignature);
        }
      }
      this.lastPayloadSignature = null;
      this.lastDataPayload = null;
      return;
    }
    const nextSignature = buildBasicPayloadSignature(dataPayload);
    if (!dataPayload.preview_only && basicPayload) {
      const localRevision = Math.max(
        basicPayload.preview_revision || 0,
        basicPayload.preview_revision_alt || 0
      );
      const incomingRevision = Math.max(
        dataPayload.preview_revision || 0,
        dataPayload.preview_revision_alt || 0
      );
      if (localRevision > incomingRevision) {
        const basicSignature = buildBasicPayloadSignature(basicPayload);
        if (basicSignature !== payloadSignature) {
          setPayloadSignature(basicSignature);
        }
        this.lastDataPayload = dataPayload;
        this.lastPayloadSignature = nextSignature;
        if (loadInProgress) {
          setLoadInProgress(false);
        }
        return;
      }
    }
    const dataRefChanged = dataPayload !== this.lastDataPayload;
    const signatureChanged = nextSignature !== this.lastPayloadSignature;
    if (dataPayload.preview_only) {
      if (!dataRefChanged && !signatureChanged) {
        return;
      }
      this.lastDataPayload = dataPayload;
      this.lastPayloadSignature = nextSignature;
      setPayloadSignature(nextSignature);
      syncPreviewPayload(dataPayload);
      if (loadInProgress) {
        setLoadInProgress(false);
      }
      return;
    }
    const hadLastDataPayload = this.lastDataPayload !== null;
    if (!dataRefChanged && !signatureChanged) {
      return;
    }
    this.lastDataPayload = dataPayload;
    this.lastPayloadSignature = nextSignature;

    const signatureMatches = nextSignature === payloadSignature;
    const waitingForReload = loadInProgress && !basicPayload;
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

      if (basicPayload) {
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

type BodyMarkingsPreviewInitializerProps = Readonly<{
  bodyPayload: BodyMarkingsPayload | null;
  dataPayload?: BodyMarkingsPayload | null;
  requestAllowed: boolean;
  requestPayload: () => void;
  syncPayload: (payload: BodyMarkingsPayload) => void;
  loadInProgress: boolean;
  setLoadInProgress: (value: boolean) => void;
  reloadPending: boolean;
  setReloadPending: (value: boolean) => void;
}>;

class BodyMarkingsPreviewInitializer extends Component<BodyMarkingsPreviewInitializerProps> {
  private lastPayloadSignature: string | null = null;
  private lastDataPayload: BodyMarkingsPayload | null = null;

  componentDidMount() {
    this.requestIfNeeded();
    this.syncIfNeeded();
  }

  componentDidUpdate(prevProps: BodyMarkingsPreviewInitializerProps) {
    if (
      prevProps.bodyPayload !== this.props.bodyPayload ||
      prevProps.dataPayload !== this.props.dataPayload ||
      prevProps.requestAllowed !== this.props.requestAllowed ||
      prevProps.reloadPending !== this.props.reloadPending ||
      prevProps.loadInProgress !== this.props.loadInProgress
    ) {
      this.requestIfNeeded();
      this.syncIfNeeded();
    }
  }

  requestIfNeeded() {
    const {
      dataPayload,
      requestAllowed,
      requestPayload,
      loadInProgress,
      setLoadInProgress,
      reloadPending,
      setReloadPending,
    } = this.props;
    if (!requestAllowed) {
      return;
    }
    if (reloadPending && !loadInProgress) {
      setLoadInProgress(true);
      requestPayload();
      setReloadPending(false);
      return;
    }
    if (!dataPayload && !loadInProgress) {
      setLoadInProgress(true);
      requestPayload();
    }
  }

  syncIfNeeded() {
    const {
      dataPayload,
      bodyPayload,
      syncPayload,
      loadInProgress,
      setLoadInProgress,
    } = this.props;
    if (!dataPayload) {
      this.lastPayloadSignature = null;
      this.lastDataPayload = null;
      return;
    }
    const nextSignature = buildBodyPayloadSignature(dataPayload);
    if (bodyPayload) {
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
    const dataRefChanged = dataPayload !== this.lastDataPayload;
    const signatureChanged = nextSignature !== this.lastPayloadSignature;
    if (!dataRefChanged && !signatureChanged) {
      return;
    }
    this.lastDataPayload = dataPayload;
    this.lastPayloadSignature = nextSignature;
    syncPayload(dataPayload);
    if (loadInProgress) {
      setLoadInProgress(false);
    }
  }

  render() {
    return null;
  }
}

const buildOrderedOverlayLayers = (
  assets: (GearOverlayAsset | IconAssetPayload)[] | undefined,
  canvasWidth: number,
  canvasHeight: number,
  source: OrderedOverlayLayer['source'],
  signalAssetUpdate: () => void,
  orderOffset = 0
): OrderedOverlayLayer[] => {
  if (!Array.isArray(assets) || !assets.length) {
    return [];
  }
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

const splitOverlayGroup = (
  layers: PreviewLayerEntry[]
): {
  before: PreviewLayerEntry[];
  after: PreviewLayerEntry[];
} => {
  const firstOverlayIndex = layers.findIndex(
    (layer) => layer?.type === 'overlay'
  );
  if (firstOverlayIndex === -1) {
    return { before: layers, after: [] };
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
    after: layers.slice(lastOverlayIndex + 1),
  };
};

export type MarkingLayerEntry = {
  label: string;
  grid: string[][];
};

export type PartMarkingLayers = {
  normal: MarkingLayerEntry[];
  priority: MarkingLayerEntry[];
};

export type MarkingLayersCacheEntry = {
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

export type BodyMarkingsPreviewContext = {
  layersByDir: Record<number, Record<string, PartMarkingLayers>>;
  hiddenPartsMap: Record<string, boolean>;
  hasHiddenParts: boolean;
};

export type BodyMarkingsPreviewCache = {
  signature: string;
  context: BodyMarkingsPreviewContext | null;
};

export type BodyMarkingDefinitionCache = {
  payloadRef: BodyMarkingsPayload | null | undefined;
  definitions: Record<string, BodyMarkingDefinition>;
  offsetX: number;
};

export type BodyMarkingsSignatureCache = {
  markingsRef: Record<string, BodyMarkingEntry> | null;
  orderRef: string[] | null;
  definitionsRef: Record<string, BodyMarkingDefinition> | null;
  signature: string;
};

type MarkedBasePreviewCache = {
  signature: string;
  previewByDir: Record<number, PreviewDirectionEntry>;
  afterByDir: Record<number, PreviewLayerEntry[]>;
};

type GalleryBasePreviewCache = {
  signature: string;
  preview: PreviewDirectionEntry[];
  previewByDir: Record<number, PreviewDirectionEntry>;
};

type TileBasePreviewCacheEntry = {
  sig: string;
  preview: PreviewDirectionEntry[];
  previewByDir: Record<number, PreviewDirectionEntry>;
};

type TileBasePreviewCache = Record<string, TileBasePreviewCacheEntry>;

const resolveBodyMarkingOffsetX = (
  payload?: BodyMarkingsPayload | null
): number => {
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
  for (const entry of payload?.preview_sources || []) {
    consider(entry?.body_asset);
    consider(entry?.composite_asset);
    considerMap(entry?.reference_part_assets);
    considerMap(entry?.reference_part_marking_assets);
  }
  const usesLargeSprites = maxW > 32 || maxH > 32;
  return usesLargeSprites ? 12 : 0;
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
  offsetX: number,
  signalAssetUpdate: () => void
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
      signalAssetUpdate
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

const isReferenceMarkingLayer = (layer: PreviewLayerEntry) => {
  if (!layer || layer.type !== 'reference_part') {
    return false;
  }
  if (typeof layer.key !== 'string' || !layer.key.startsWith('ref_')) {
    return false;
  }
  return layer.key.endsWith('_markings');
};

const stripReferenceMarkingsFromPreview = (
  preview: PreviewDirectionEntry[]
): PreviewDirectionEntry[] => {
  let changed = false;
  const next = preview.map((entry) => {
    const layers = entry.layers || [];
    const filtered = layers.filter((layer) => !isReferenceMarkingLayer(layer));
    if (filtered.length === layers.length) {
      return entry;
    }
    changed = true;
    return {
      ...entry,
      layers: filtered,
    };
  });
  return changed ? next : preview;
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

const buildBodyMarkingLayersByDir = (options: {
  directions: { dir: number }[];
  order: string[];
  definitions: Record<string, BodyMarkingDefinition>;
  markings: Record<string, BodyMarkingEntry>;
  digitigrade: boolean;
  canvasWidth: number;
  canvasHeight: number;
  offsetX: number;
  assetRevision: number;
  signalAssetUpdate: () => void;
  markingLayersCache: Record<string, MarkingLayersCacheEntry>;
}): Record<number, Record<string, PartMarkingLayers>> => {
  const {
    directions,
    order,
    definitions,
    markings,
    digitigrade,
    canvasWidth,
    canvasHeight,
    offsetX,
    assetRevision,
    signalAssetUpdate,
    markingLayersCache,
  } = options;
  const layersByDir: Record<number, Record<string, PartMarkingLayers>> = {};
  for (const dir of directions || []) {
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
        cached.offsetX === offsetX &&
        cached.assetRevision === assetRevision
          ? cached.built
          : buildMarkingLayersForDir(
              def,
              entry,
              dir.dir,
              digitigrade,
              canvasWidth,
              canvasHeight,
              offsetX,
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
          offsetX,
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
  return layersByDir;
};

const buildBodyMarkingsPreviewContext = (options: {
  definitions: Record<string, BodyMarkingDefinition>;
  order: string[];
  markings: Record<string, BodyMarkingEntry>;
  digitigrade: boolean;
  canvasWidth: number;
  canvasHeight: number;
  offsetX: number;
  assetRevision: number;
  signalAssetUpdate: () => void;
  directions: { dir: number }[];
  markingLayersCache: Record<string, MarkingLayersCacheEntry>;
}): BodyMarkingsPreviewContext | null => {
  const {
    definitions,
    order,
    markings,
    digitigrade,
    canvasWidth,
    canvasHeight,
    offsetX,
    assetRevision,
    signalAssetUpdate,
    directions,
    markingLayersCache,
  } = options;
  if (!order.length) {
    return null;
  }
  const hasDefinitions = Object.keys(definitions || {}).length > 0;
  if (!hasDefinitions) {
    return null;
  }
  const layersByDir = buildBodyMarkingLayersByDir({
    directions,
    order,
    definitions,
    markings,
    digitigrade,
    canvasWidth,
    canvasHeight,
    offsetX,
    assetRevision,
    signalAssetUpdate,
    markingLayersCache,
  });
  const hiddenPartsMap = buildHiddenBodyPartsMapForMarkings(
    definitions,
    markings,
    order
  );
  const hasHiddenParts = Object.keys(hiddenPartsMap).length > 0;
  if (!hasHiddenParts && !Object.keys(layersByDir).length) {
    return null;
  }
  return {
    layersByDir,
    hiddenPartsMap,
    hasHiddenParts,
  };
};

export const applyBodyMarkingsToPreview = (options: {
  preview: PreviewDirectionEntry[];
  context: BodyMarkingsPreviewContext | null;
  stripReferenceMarkings?: boolean;
  suppressedPartsByDir?: Record<number, Record<string, boolean>>;
}): PreviewDirectionEntry[] => {
  const { preview, context, stripReferenceMarkings, suppressedPartsByDir } =
    options;
  if (!preview.length) {
    return preview;
  }
  const basePreview = stripReferenceMarkings
    ? stripReferenceMarkingsFromPreview(preview)
    : preview;
  if (!context) {
    return basePreview;
  }
  const { layersByDir, hiddenPartsMap, hasHiddenParts } = context;
  return basePreview.map((dirEntry) => {
    const layerGroup = layersByDir[dirEntry.dir] || {};
    const baseLayers = dirEntry.layers || [];
    const {
      before: nonOverlayLayers,
      overlay: overlayLayers,
      after,
    } = splitOverlayLayers(baseLayers);
    const suppressedPartsMap = suppressedPartsByDir?.[dirEntry.dir];
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
      layers: [...normalLayers, ...priorityLayers, ...overlayLayers, ...after],
    };
  });
};

const buildBodyMarkingsSignature = (options: {
  order: string[];
  definitions: Record<string, BodyMarkingDefinition>;
  markings: Record<string, BodyMarkingEntry>;
}): string => {
  const { order, definitions, markings } = options;
  if (!order.length) {
    return 'none';
  }
  const segments: string[] = [];
  for (const markId of order) {
    const def = definitions[markId];
    const entry = markings[markId];
    if (!entry) {
      continue;
    }
    const baseColor = normalizeHex(entry.color as string) || '';
    const defSig = def
      ? [
          def.do_colouration ? 'c1' : 'c0',
          resolveBlendMode(def.color_blend_mode),
          def.render_above_body ? 'p1' : 'p0',
          def.render_above_body_parts
            ? Object.keys(def.render_above_body_parts).sort().join(',')
            : '',
          Array.isArray(def.hide_body_parts)
            ? [...def.hide_body_parts].sort().join(',')
            : '',
        ].join('|')
      : 'missing';
    const partKeys =
      def?.body_parts && def.body_parts.length
        ? def.body_parts
        : Object.keys(entry)
            .filter((key) => key !== 'color')
            .sort();
    const partSig = partKeys
      .map((partId) => {
        const state = entry[partId] as BodyMarkingPartState;
        if (!state || typeof state !== 'object') {
          return `${partId}:0:`;
        }
        const on = isBodyMarkingPartEnabled(state.on) ? '1' : '0';
        const color = normalizeHex(state.color as string) || '';
        return `${partId}:${on}:${color}`;
      })
      .join(',');
    segments.push(`${markId}:${baseColor}:${partSig}:${defSig}`);
  }
  return segments.length ? segments.join('|') : 'none';
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

const applyStyleChange = (options: {
  targetType: BasicAppearanceType;
  styleId: string | null;
  updateAppearanceState: (
    updater: (prev: BasicAppearanceState) => BasicAppearanceState
  ) => void;
  setDirty: (value: boolean) => void;
  isDirty: boolean;
}) => {
  const { targetType, styleId, updateAppearanceState, setDirty, isDirty } =
    options;
  updateAppearanceState((prev) => {
    switch (targetType) {
      case 'hair':
        return { ...prev, hair_style: styleId };
      case 'gradient':
        return { ...prev, hair_gradient_style: styleId };
      case 'facial_hair':
        return { ...prev, facial_hair_style: styleId };
      case 'ears':
        return { ...prev, ear_style: styleId };
      case 'horns':
        return {
          ...prev,
          horn_style: styleId,
          horn_colors: prev.horn_colors || [],
        };
      case 'tail':
        return { ...prev, tail_style: styleId };
      case 'wings':
        return { ...prev, wing_style: styleId };
      default:
        return prev;
    }
  });
  if (!isDirty) {
    setDirty(true);
  }
};

const applyDigitigradeChange = (options: {
  value: boolean;
  allowed: boolean;
  updateAppearanceState: (
    updater: (prev: BasicAppearanceState) => BasicAppearanceState
  ) => void;
  setDirty: (value: boolean) => void;
  isDirty: boolean;
}) => {
  const { value, allowed, updateAppearanceState, setDirty, isDirty } = options;
  if (!allowed) {
    return;
  }
  updateAppearanceState((prev) => ({ ...prev, digitigrade: !!value }));
  if (!isDirty) {
    setDirty(true);
  }
};

const resolveColorTargetHexForState = (
  appearanceState: BasicAppearanceState,
  target: BasicAppearanceColorTarget | null
): string => {
  if (!target) {
    return '#ffffff';
  }
  switch (target.type) {
    case 'hair':
      return normalizeHex(appearanceState.hair_color) || '#ffffff';
    case 'gradient':
      return normalizeHex(appearanceState.hair_gradient_color) || '#ffffff';
    case 'facial_hair':
      return normalizeHex(appearanceState.facial_hair_color) || '#ffffff';
    case 'eyes':
      return normalizeHex(appearanceState.eye_color) || '#ffffff';
    case 'body':
      return normalizeHex(appearanceState.body_color) || '#ffffff';
    case 'ears':
      return (
        normalizeHex(appearanceState.ear_colors?.[target.channel]) || '#ffffff'
      );
    case 'horns':
      return (
        normalizeHex(appearanceState.horn_colors?.[target.channel]) || '#ffffff'
      );
    case 'tail':
      return (
        normalizeHex(appearanceState.tail_colors?.[target.channel]) || '#ffffff'
      );
    case 'wings':
      return (
        normalizeHex(appearanceState.wing_colors?.[target.channel]) || '#ffffff'
      );
    default:
      return '#ffffff';
  }
};

const applyBasicColorTarget = (options: {
  hex: string;
  colorTarget: BasicAppearanceColorTarget | null;
  activeType: BasicAppearanceType;
  maxAccessoryChannels: BasicAppearanceAccessoryChannelCaps;
  resolveLatestState: () => {
    latestState: BasicAppearanceState;
    latestDirty: boolean;
  };
  updateAppearanceState: (
    updater: (prev: BasicAppearanceState) => BasicAppearanceState
  ) => void;
  setDirty: (value: boolean) => void;
}) => {
  const {
    hex,
    colorTarget,
    activeType,
    maxAccessoryChannels,
    resolveLatestState,
    updateAppearanceState,
    setDirty,
  } = options;
  const resolved = resolveBasicColorTarget({
    target: colorTarget,
    activeType,
    maxAccessoryChannels,
  });
  if (!resolved) {
    return;
  }
  const normalized = normalizeHex(hex) || '#ffffff';
  const { latestState, latestDirty } = resolveLatestState();
  const current = resolveColorTargetHexForState(latestState, resolved);
  if (current === normalized) {
    return;
  }
  updateAppearanceState((prev) => {
    switch (resolved.type) {
      case 'hair':
        return { ...prev, hair_color: normalized };
      case 'gradient':
        return { ...prev, hair_gradient_color: normalized };
      case 'facial_hair':
        return { ...prev, facial_hair_color: normalized };
      case 'eyes':
        return { ...prev, eye_color: normalized };
      case 'body':
        return { ...prev, body_color: normalized };
      case 'ears': {
        const next = [...(prev.ear_colors || [])];
        next[resolved.channel] = normalized;
        return { ...prev, ear_colors: next };
      }
      case 'horns': {
        const next = [...(prev.horn_colors || [])];
        next[resolved.channel] = normalized;
        return { ...prev, horn_colors: next };
      }
      case 'tail': {
        const next = [...(prev.tail_colors || [])];
        next[resolved.channel] = normalized;
        return { ...prev, tail_colors: next };
      }
      case 'wings': {
        const next = [...(prev.wing_colors || [])];
        next[resolved.channel] = normalized;
        return { ...prev, wing_colors: next };
      }
      default:
        return prev;
    }
  });
  if (!latestDirty) {
    setDirty(true);
  }
};

const resolveGalleryDefinitionsForType = (
  galleryType: BasicAppearanceType,
  hairStyles?: BasicAppearanceAccessoryDefinition[],
  gradientStyles?: BasicAppearanceGradientDefinition[],
  facialHairStyles?: BasicAppearanceAccessoryDefinition[],
  earStyles?: BasicAppearanceAccessoryDefinition[],
  tailStyles?: BasicAppearanceAccessoryDefinition[],
  wingStyles?: BasicAppearanceAccessoryDefinition[]
): Array<{ id: string; name: string }> => {
  switch (galleryType) {
    case 'hair':
      return (hairStyles || []).map((def) => ({ id: def.id, name: def.name }));
    case 'gradient':
      return (gradientStyles || []).map((def) => ({
        id: def.id,
        name: def.name,
      }));
    case 'facial_hair':
      return (facialHairStyles || []).map((def) => ({
        id: def.id,
        name: def.name,
      }));
    case 'ears':
    case 'horns':
      return (earStyles || []).map((def) => ({ id: def.id, name: def.name }));
    case 'tail':
      return (tailStyles || []).map((def) => ({ id: def.id, name: def.name }));
    case 'wings':
      return (wingStyles || []).map((def) => ({ id: def.id, name: def.name }));
    default:
      return [];
  }
};

const resolveSelectedIdForGalleryType = (
  galleryType: BasicAppearanceType,
  appearanceState: BasicAppearanceState
): string | null => {
  switch (galleryType) {
    case 'hair':
      return appearanceState.hair_style;
    case 'gradient':
      return appearanceState.hair_gradient_style;
    case 'facial_hair':
      return appearanceState.facial_hair_style;
    case 'ears':
      return appearanceState.ear_style;
    case 'horns':
      return appearanceState.horn_style;
    case 'tail':
      return appearanceState.tail_style;
    case 'wings':
      return appearanceState.wing_style;
    default:
      return null;
  }
};

const applyGallerySelection = (options: {
  galleryType: BasicAppearanceType;
  id: string | null;
  setStyle: (targetType: BasicAppearanceType, styleId: string | null) => void;
  setColorTarget: (target: BasicAppearanceColorTarget | null) => void;
}) => {
  const { galleryType, id, setStyle, setColorTarget } = options;
  const normalized =
    id && (id === 'Normal' || id.toLowerCase() === 'none') ? null : id;
  switch (galleryType) {
    case 'hair':
      setStyle('hair', normalized);
      setColorTarget({ type: 'hair' });
      return;
    case 'gradient':
      setStyle('gradient', normalized);
      setColorTarget({ type: 'gradient' });
      return;
    case 'facial_hair':
      setStyle('facial_hair', normalized);
      setColorTarget({ type: 'facial_hair' });
      return;
    case 'ears':
      setStyle('ears', normalized);
      setColorTarget({ type: 'ears', channel: 0 });
      return;
    case 'horns':
      setStyle('horns', normalized);
      setColorTarget({ type: 'horns', channel: 0 });
      return;
    case 'tail':
      setStyle('tail', normalized);
      setColorTarget({ type: 'tail', channel: 0 });
      return;
    case 'wings':
      setStyle('wings', normalized);
      setColorTarget({ type: 'wings', channel: 0 });
      return;
    default:
      return;
  }
};

type TilePreviewOptions = {
  def: { id: string; name: string };
  galleryType: BasicAppearanceType;
  tileDirections: DirectionEntry[];
  tileDirectionsSignature: string;
  canvasWidth: number;
  canvasHeight: number;
  activePreviewRevision?: number | null;
  appearanceState: BasicAppearanceState;
  assetRevision: number;
  bodyMarkingsSignature: string;
  bodyMarkingsContextSignature: string;
  previewTargetBodyColor: string | null;
  previewTargetEyeColor: string | null;
  hairStyles?: BasicAppearanceAccessoryDefinition[];
  gradientStyles?: BasicAppearanceGradientDefinition[];
  facialHairStyles?: BasicAppearanceAccessoryDefinition[];
  earStyles?: BasicAppearanceAccessoryDefinition[];
  tailStyles?: BasicAppearanceAccessoryDefinition[];
  wingStyles?: BasicAppearanceAccessoryDefinition[];
  hairDef: BasicAppearanceAccessoryDefinition | null;
  gradientDef: BasicAppearanceGradientDefinition | null;
  previewDirStates: Record<number, PreviewDirState>;
  tilePreviewCache: Record<
    string,
    { sig: string; previews: BasicTilePreviewEntry[] }
  >;
  tileBasePreviewCache: TileBasePreviewCache;
  galleryMannequinPreviewByDir: Record<number, PreviewDirectionEntry>;
  previewBaseBodyColor: string | null;
  previewBaseEyeColor: string | null;
  bodyColorExcludedParts: Set<string> | null;
  applyBodyMarkings: (
    preview: PreviewDirectionEntry[],
    suppressedPartsByDir?: Record<number, Record<string, boolean>>
  ) => PreviewDirectionEntry[];
  signalAssetUpdate: () => void;
  stripReferenceMarkings?: boolean;
};

type TailTileInfo = {
  tailDef: BasicAppearanceAccessoryDefinition | null;
  hiddenParts: string[];
};

const resolveTailTileInfo = (
  galleryType: BasicAppearanceType,
  tailStyles: BasicAppearanceAccessoryDefinition[] | undefined,
  defId: string
): TailTileInfo => {
  if (galleryType !== 'tail') {
    return { tailDef: null, hiddenParts: [] };
  }
  const tailDef = resolveSelectedDef(tailStyles, defId);
  const hiddenParts =
    tailDef && Array.isArray(tailDef.hide_body_parts)
      ? tailDef.hide_body_parts.filter(
          (part): part is string => typeof part === 'string' && part.length > 0
        )
      : [];
  return {
    tailDef,
    hiddenParts: hiddenParts.sort(),
  };
};

type TilePreviewSignatureOptions = {
  tileDirectionsSignature: string;
  canvasWidth: number;
  canvasHeight: number;
  activePreviewRevision?: number | null;
  appearanceState: BasicAppearanceState;
  assetRevision: number;
  bodyMarkingsSignature: string;
  previewTargetBodyColor: string | null;
  previewTargetEyeColor: string | null;
  tailHiddenParts: string[];
  stripReferenceMarkings?: boolean;
};

const buildTilePreviewSignature = (
  options: TilePreviewSignatureOptions
): string => {
  const {
    tileDirectionsSignature,
    canvasWidth,
    canvasHeight,
    activePreviewRevision,
    appearanceState,
    assetRevision,
    bodyMarkingsSignature,
    previewTargetBodyColor,
    previewTargetEyeColor,
    tailHiddenParts,
    stripReferenceMarkings,
  } = options;
  const signatureParts: string[] = [
    tileDirectionsSignature,
    `${canvasWidth}x${canvasHeight}`,
    `${activePreviewRevision || 0}`,
    appearanceState.digitigrade ? 'd' : 'p',
    `${assetRevision}`,
    bodyMarkingsSignature,
    appearanceState.hair_style || 'none',
    previewTargetBodyColor || 'bc',
    previewTargetEyeColor || 'ec',
    appearanceState.hair_color || 'hc',
    appearanceState.hair_gradient_style || 'gs',
    appearanceState.hair_gradient_color || 'gc',
    appearanceState.facial_hair_style || 'fs',
    appearanceState.facial_hair_color || 'fc',
    (appearanceState.ear_colors || []).join('|'),
    (appearanceState.horn_colors || []).join('|'),
    (appearanceState.tail_colors || []).join('|'),
    (appearanceState.wing_colors || []).join('|'),
    tailHiddenParts.length ? tailHiddenParts.join('|') : 'no-hide',
    stripReferenceMarkings ? 's1' : 's0',
  ];
  return signatureParts.join('::');
};

type TileBasePreviewSignatureOptions = {
  tileDirectionsSignature: string;
  canvasWidth: number;
  canvasHeight: number;
  activePreviewRevision?: number | null;
  appearanceState: BasicAppearanceState;
  assetRevision: number;
  bodyMarkingsContextSignature: string;
  tailHiddenParts: string[];
  stripReferenceMarkings?: boolean;
};

const buildTileBasePreviewSignature = (
  options: TileBasePreviewSignatureOptions
): string => {
  const {
    tileDirectionsSignature,
    canvasWidth,
    canvasHeight,
    activePreviewRevision,
    appearanceState,
    assetRevision,
    bodyMarkingsContextSignature,
    tailHiddenParts,
    stripReferenceMarkings,
  } = options;
  return [
    tileDirectionsSignature,
    `${canvasWidth}x${canvasHeight}`,
    `${activePreviewRevision || 0}`,
    appearanceState.digitigrade ? 'd' : 'p',
    `${assetRevision}`,
    bodyMarkingsContextSignature,
    tailHiddenParts.length ? tailHiddenParts.join('|') : 'no-hide',
    stripReferenceMarkings ? 's1' : 's0',
  ].join('::');
};

type TileBasePreviewOptions = {
  cacheKey: string;
  galleryType: BasicAppearanceType;
  tailHiddenParts: string[];
  previewDirStates: Record<number, PreviewDirState>;
  tileDirections: DirectionEntry[];
  tileDirectionsSignature: string;
  canvasWidth: number;
  canvasHeight: number;
  activePreviewRevision?: number | null;
  appearanceState: BasicAppearanceState;
  assetRevision: number;
  bodyMarkingsContextSignature: string;
  previewBaseBodyColor: string | null;
  previewTargetBodyColor: string | null;
  previewBaseEyeColor: string | null;
  previewTargetEyeColor: string | null;
  bodyColorExcludedParts: Set<string> | null;
  applyBodyMarkings: (
    preview: PreviewDirectionEntry[],
    suppressedPartsByDir?: Record<number, Record<string, boolean>>
  ) => PreviewDirectionEntry[];
  signalAssetUpdate: () => void;
  galleryMannequinPreviewByDir: Record<number, PreviewDirectionEntry>;
  tileBasePreviewCache: TileBasePreviewCache;
  stripReferenceMarkings?: boolean;
};

const buildTileBasePreviewByDir = (
  options: TileBasePreviewOptions
): Record<number, PreviewDirectionEntry> => {
  const {
    cacheKey,
    galleryType,
    tailHiddenParts,
    previewDirStates,
    tileDirections,
    tileDirectionsSignature,
    canvasWidth,
    canvasHeight,
    activePreviewRevision,
    appearanceState,
    assetRevision,
    bodyMarkingsContextSignature,
    previewBaseBodyColor,
    previewTargetBodyColor,
    previewBaseEyeColor,
    previewTargetEyeColor,
    bodyColorExcludedParts,
    applyBodyMarkings,
    signalAssetUpdate,
    galleryMannequinPreviewByDir,
    tileBasePreviewCache,
    stripReferenceMarkings,
  } = options;
  if (galleryType !== 'tail' || !tailHiddenParts.length) {
    return galleryMannequinPreviewByDir;
  }
  const baseSignature = buildTileBasePreviewSignature({
    tileDirectionsSignature,
    canvasWidth,
    canvasHeight,
    activePreviewRevision,
    appearanceState,
    assetRevision,
    bodyMarkingsContextSignature,
    tailHiddenParts,
    stripReferenceMarkings,
  });
  const cachedBase = tileBasePreviewCache[cacheKey];
  let basePreview =
    cachedBase?.sig === baseSignature ? cachedBase.preview : null;
  if (!basePreview) {
    const previewDirStatesForTile = mergeHiddenBodyPartsInPreviewStates(
      previewDirStates,
      tailHiddenParts
    );
    const suppressedPartsByDir = buildHiddenBodyPartsByDir(
      previewDirStatesForTile
    );
    basePreview = applyBodyMarkings(
      buildBasePreviewDirs(
        previewDirStatesForTile,
        tileDirections,
        {},
        canvasWidth,
        canvasHeight,
        signalAssetUpdate,
        stripReferenceMarkings
      ),
      suppressedPartsByDir
    );
    tileBasePreviewCache[cacheKey] = {
      sig: baseSignature,
      preview: basePreview,
      previewByDir: basePreview.reduce(
        (acc, entry) => {
          acc[entry.dir] = entry;
          return acc;
        },
        {} as Record<number, PreviewDirectionEntry>
      ),
    };
  }
  const coloredPreview = applyBodyAndEyeColorToPreview(
    basePreview,
    previewBaseBodyColor,
    previewTargetBodyColor,
    bodyColorExcludedParts,
    previewBaseEyeColor,
    previewTargetEyeColor,
    previewTargetBodyColor
  );
  return coloredPreview.reduce(
    (acc, entry) => {
      acc[entry.dir] = entry;
      return acc;
    },
    {} as Record<number, PreviewDirectionEntry>
  );
};

type TileGridResult = {
  grid: string[][] | null;
  backGrid: string[][] | null;
};

type TileGridBuilderOptions = {
  defId: string;
  galleryType: BasicAppearanceType;
  dir: number;
  canvasWidth: number;
  canvasHeight: number;
  appearanceState: BasicAppearanceState;
  hairStyles?: BasicAppearanceAccessoryDefinition[];
  gradientStyles?: BasicAppearanceGradientDefinition[];
  facialHairStyles?: BasicAppearanceAccessoryDefinition[];
  earStyles?: BasicAppearanceAccessoryDefinition[];
  wingStyles?: BasicAppearanceAccessoryDefinition[];
  hairDef: BasicAppearanceAccessoryDefinition | null;
  gradientDef: BasicAppearanceGradientDefinition | null;
  tailDef: BasicAppearanceAccessoryDefinition | null;
  signalAssetUpdate: () => void;
};

const buildAccessoryTileGrid = (options: {
  def: BasicAppearanceAccessoryDefinition | null;
  dir: number;
  canvasWidth: number;
  canvasHeight: number;
  colors: (string | null)[] | null;
  signalAssetUpdate: () => void;
}): string[][] | null => {
  const { def, dir, canvasWidth, canvasHeight, colors, signalAssetUpdate } =
    options;
  if (!def) {
    return null;
  }
  return buildAccessoryGrid({
    def,
    dir,
    canvasWidth,
    canvasHeight,
    colors: colors || [],
    signalAssetUpdate,
  });
};

const buildHairTileGrid = (
  options: TileGridBuilderOptions
): string[][] | null => {
  const {
    defId,
    dir,
    canvasWidth,
    canvasHeight,
    appearanceState,
    hairStyles,
    gradientDef,
    signalAssetUpdate,
  } = options;
  const resolved = resolveSelectedDef(hairStyles, defId);
  if (!resolved) {
    return null;
  }
  return buildHairGridWithGradient({
    hairDef: resolved,
    gradientDef,
    dir,
    canvasWidth,
    canvasHeight,
    hairColor: appearanceState.hair_color,
    gradientColor: appearanceState.hair_gradient_color,
    signalAssetUpdate,
  });
};

const buildFacialHairTileGrid = (
  options: TileGridBuilderOptions
): string[][] | null => {
  const {
    defId,
    dir,
    canvasWidth,
    canvasHeight,
    appearanceState,
    facialHairStyles,
    signalAssetUpdate,
  } = options;
  const resolved = resolveSelectedDef(facialHairStyles, defId);
  return buildAccessoryTileGrid({
    def: resolved,
    dir,
    canvasWidth,
    canvasHeight,
    colors: [appearanceState.facial_hair_color],
    signalAssetUpdate,
  });
};

const buildGradientTileGrid = (
  options: TileGridBuilderOptions
): string[][] | null => {
  const {
    defId,
    dir,
    canvasWidth,
    canvasHeight,
    appearanceState,
    gradientStyles,
    hairDef,
    signalAssetUpdate,
  } = options;
  const resolved = resolveSelectedDef(gradientStyles, defId);
  if (!resolved) {
    return null;
  }
  if (hairDef) {
    return buildHairGridWithGradient({
      hairDef,
      gradientDef: resolved,
      dir,
      canvasWidth,
      canvasHeight,
      hairColor: appearanceState.hair_color,
      gradientColor: appearanceState.hair_gradient_color,
      signalAssetUpdate,
    });
  }
  const gradPayload = resolved.assets?.[dir];
  const rawGrad = gradPayload
    ? getPreviewGridFromAsset(
        gradPayload,
        canvasWidth,
        canvasHeight,
        signalAssetUpdate
      )
    : null;
  if (!rawGrad) {
    return null;
  }
  return appearanceState.hair_gradient_color
    ? tintGrid(
        rawGrad as string[][],
        appearanceState.hair_gradient_color,
        ICON_BLEND_MODE.OVERLAY
      )
    : (rawGrad as string[][]);
};

const buildEarTileGrid = (
  options: TileGridBuilderOptions
): string[][] | null => {
  const {
    defId,
    dir,
    canvasWidth,
    canvasHeight,
    appearanceState,
    earStyles,
    signalAssetUpdate,
  } = options;
  const resolved = resolveSelectedDef(earStyles, defId);
  return buildAccessoryTileGrid({
    def: resolved,
    dir,
    canvasWidth,
    canvasHeight,
    colors: appearanceState.ear_colors,
    signalAssetUpdate,
  });
};

const buildHornTileGrid = (
  options: TileGridBuilderOptions
): string[][] | null => {
  const {
    defId,
    dir,
    canvasWidth,
    canvasHeight,
    appearanceState,
    earStyles,
    signalAssetUpdate,
  } = options;
  const resolved = resolveSelectedDef(earStyles, defId);
  return buildAccessoryTileGrid({
    def: resolved,
    dir,
    canvasWidth,
    canvasHeight,
    colors: appearanceState.horn_colors,
    signalAssetUpdate,
  });
};

const buildTailTileGrid = (
  options: TileGridBuilderOptions
): string[][] | null => {
  const {
    dir,
    canvasWidth,
    canvasHeight,
    appearanceState,
    tailDef,
    signalAssetUpdate,
  } = options;
  return buildAccessoryTileGrid({
    def: tailDef,
    dir,
    canvasWidth,
    canvasHeight,
    colors: appearanceState.tail_colors,
    signalAssetUpdate,
  });
};

const buildWingTileGrids = (
  options: TileGridBuilderOptions
): TileGridResult => {
  const {
    defId,
    dir,
    canvasWidth,
    canvasHeight,
    appearanceState,
    wingStyles,
    signalAssetUpdate,
  } = options;
  const resolved = resolveSelectedDef(wingStyles, defId);
  if (!resolved) {
    return { grid: null, backGrid: null };
  }
  const grid = buildAccessoryTileGrid({
    def: resolved,
    dir,
    canvasWidth,
    canvasHeight,
    colors: appearanceState.wing_colors,
    signalAssetUpdate,
  });
  let backGrid: string[][] | null = null;
  if (resolved.multi_dir && resolved.back_assets) {
    const backAssets = resolved.back_assets?.[dir];
    if (backAssets && backAssets.length) {
      const backDef: BasicAppearanceAccessoryDefinition = {
        ...resolved,
        assets: { [dir]: backAssets } as any,
      };
      backGrid = buildAccessoryTileGrid({
        def: backDef,
        dir,
        canvasWidth,
        canvasHeight,
        colors: appearanceState.wing_colors,
        signalAssetUpdate,
      });
    }
  }
  return { grid, backGrid };
};

const buildTileGridForGallery = (
  options: TileGridBuilderOptions
): TileGridResult => {
  switch (options.galleryType) {
    case 'hair':
      return { grid: buildHairTileGrid(options), backGrid: null };
    case 'facial_hair':
      return { grid: buildFacialHairTileGrid(options), backGrid: null };
    case 'gradient':
      return { grid: buildGradientTileGrid(options), backGrid: null };
    case 'ears':
      return { grid: buildEarTileGrid(options), backGrid: null };
    case 'horns':
      return { grid: buildHornTileGrid(options), backGrid: null };
    case 'tail':
      return { grid: buildTailTileGrid(options), backGrid: null };
    case 'wings':
      return buildWingTileGrids(options);
    default:
      return { grid: null, backGrid: null };
  }
};

const buildTilePreviewEntries = (
  options: TilePreviewOptions
): BasicTilePreviewEntry[] => {
  const {
    def,
    galleryType,
    tileDirections,
    tileDirectionsSignature,
    canvasWidth,
    canvasHeight,
    activePreviewRevision,
    appearanceState,
    assetRevision,
    bodyMarkingsSignature,
    bodyMarkingsContextSignature,
    previewTargetBodyColor,
    previewTargetEyeColor,
    hairStyles,
    gradientStyles,
    facialHairStyles,
    earStyles,
    tailStyles,
    wingStyles,
    hairDef,
    gradientDef,
    previewDirStates,
    tilePreviewCache,
    tileBasePreviewCache,
    galleryMannequinPreviewByDir,
    previewBaseBodyColor,
    previewBaseEyeColor,
    bodyColorExcludedParts,
    applyBodyMarkings,
    signalAssetUpdate,
    stripReferenceMarkings,
  } = options;
  const tailInfo = resolveTailTileInfo(galleryType, tailStyles, def.id);
  const defKey = `${galleryType}:${def.id}`;
  const sig = buildTilePreviewSignature({
    tileDirectionsSignature,
    canvasWidth,
    canvasHeight,
    activePreviewRevision,
    appearanceState,
    assetRevision,
    bodyMarkingsSignature,
    previewTargetBodyColor,
    previewTargetEyeColor,
    tailHiddenParts: tailInfo.hiddenParts,
    stripReferenceMarkings,
  });
  const baseSignature = buildTileBasePreviewSignature({
    tileDirectionsSignature,
    canvasWidth,
    canvasHeight,
    activePreviewRevision,
    appearanceState,
    assetRevision,
    bodyMarkingsContextSignature,
    tailHiddenParts: tailInfo.hiddenParts,
    stripReferenceMarkings,
  });
  const baseColorSignature = [
    baseSignature,
    previewBaseBodyColor || '',
    previewTargetBodyColor || '',
    previewBaseEyeColor || '',
    previewTargetEyeColor || '',
  ].join('::');
  const cached = tilePreviewCache[defKey];
  if (cached && cached.sig === sig) {
    return cached.previews;
  }

  const tileBasePreviewByDir = buildTileBasePreviewByDir({
    cacheKey: defKey,
    galleryType,
    tailHiddenParts: tailInfo.hiddenParts,
    previewDirStates,
    tileDirections,
    tileDirectionsSignature,
    canvasWidth,
    canvasHeight,
    activePreviewRevision,
    appearanceState,
    assetRevision,
    bodyMarkingsContextSignature,
    previewBaseBodyColor,
    previewTargetBodyColor,
    previewBaseEyeColor,
    previewTargetEyeColor,
    bodyColorExcludedParts,
    applyBodyMarkings,
    signalAssetUpdate,
    galleryMannequinPreviewByDir,
    tileBasePreviewCache,
    stripReferenceMarkings,
  });

  const previews = tileDirections.map((entry) => {
    const tileGrids = buildTileGridForGallery({
      defId: def.id,
      galleryType,
      dir: entry.dir,
      canvasWidth,
      canvasHeight,
      appearanceState,
      hairStyles,
      gradientStyles,
      facialHairStyles,
      earStyles,
      wingStyles,
      hairDef,
      gradientDef,
      tailDef: tailInfo.tailDef,
      signalAssetUpdate,
    });
    const baseLayers = tileBasePreviewByDir[entry.dir]?.layers || [];
    const underlayLayers = tileGrids.backGrid
      ? [
          {
            type: 'overlay',
            key: `tile-${galleryType}-${def.id}-${entry.dir}-back`,
            grid: tileGrids.backGrid,
          },
        ]
      : [];
    const overlayLayers = tileGrids.grid
      ? [
          {
            type: 'overlay',
            key: `tile-${galleryType}-${def.id}-${entry.dir}`,
            grid: tileGrids.grid,
          },
        ]
      : [];
    return {
      dir: entry.dir,
      label: entry.label,
      layers: [],
      baseLayers,
      underlayLayers,
      overlayLayers,
      baseSignature: baseColorSignature,
    };
  });

  tilePreviewCache[defKey] = { sig, previews };
  return previews;
};

type OverlayEntriesOptions = {
  dir: number;
  dirState?: PreviewDirState;
  canvasWidth: number;
  canvasHeight: number;
  appearanceState: BasicAppearanceState;
  previewBaseEyeColor: string | null;
  previewTargetEyeColor: string | null;
  hairDef: BasicAppearanceAccessoryDefinition | null;
  gradientDef: BasicAppearanceGradientDefinition | null;
  facialHairDef: BasicAppearanceAccessoryDefinition | null;
  earDef: BasicAppearanceAccessoryDefinition | null;
  hornDef: BasicAppearanceAccessoryDefinition | null;
  tailDef: BasicAppearanceAccessoryDefinition | null;
  wingDef: BasicAppearanceAccessoryDefinition | null;
  showJobGear: boolean;
  showLoadoutGear: boolean;
  signalAssetUpdate: () => void;
};

type GearOverlayLayerOptions = {
  dirState: PreviewDirState;
  canvasWidth: number;
  canvasHeight: number;
  showJobGear: boolean;
  showLoadoutGear: boolean;
  signalAssetUpdate: () => void;
};

type GearOverlayLayerGroups = {
  baseOverlayLayers: OrderedOverlayLayer[];
  loadoutLayers: OrderedOverlayLayer[];
  jobLayers: OrderedOverlayLayer[];
};

const buildGearOverlayLayers = (
  options: GearOverlayLayerOptions
): GearOverlayLayerGroups => {
  const {
    dirState,
    canvasWidth,
    canvasHeight,
    showJobGear,
    showLoadoutGear,
    signalAssetUpdate,
  } = options;
  const baseOverlayLayers = buildOrderedOverlayLayers(
    (dirState.overlayAssets as (GearOverlayAsset | IconAssetPayload)[]) || [],
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
  return {
    baseOverlayLayers,
    loadoutLayers,
    jobLayers,
  };
};

type HairCompositeOptions = {
  dir: number;
  canvasWidth: number;
  canvasHeight: number;
  appearanceState: BasicAppearanceState;
  hairDef: BasicAppearanceAccessoryDefinition | null;
  gradientDef: BasicAppearanceGradientDefinition | null;
  facialHairDef: BasicAppearanceAccessoryDefinition | null;
  earDef: BasicAppearanceAccessoryDefinition | null;
  hornDef: BasicAppearanceAccessoryDefinition | null;
  signalAssetUpdate: () => void;
};

const mergeAccessoryGrid = (
  base: string[][] | null,
  next: string[][] | null
): string[][] | null => {
  if (!next) {
    return base;
  }
  if (!base) {
    return cloneGridData(next);
  }
  mergeGrid(base, next);
  return base;
};

const buildHairCompositeGrid = (
  options: HairCompositeOptions
): string[][] | null => {
  const {
    dir,
    canvasWidth,
    canvasHeight,
    appearanceState,
    hairDef,
    gradientDef,
    facialHairDef,
    earDef,
    hornDef,
    signalAssetUpdate,
  } = options;
  let composite: string[][] | null = null;
  if (facialHairDef) {
    composite = mergeAccessoryGrid(
      composite,
      buildAccessoryGrid({
        def: facialHairDef,
        dir,
        canvasWidth,
        canvasHeight,
        colors: [appearanceState.facial_hair_color],
        signalAssetUpdate,
      })
    );
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
    composite = mergeAccessoryGrid(composite, hairGrid);
  }
  if (earDef) {
    composite = mergeAccessoryGrid(
      composite,
      buildAccessoryGrid({
        def: earDef,
        dir,
        canvasWidth,
        canvasHeight,
        colors: appearanceState.ear_colors,
        signalAssetUpdate,
      })
    );
  }
  if (hornDef) {
    composite = mergeAccessoryGrid(
      composite,
      buildAccessoryGrid({
        def: hornDef,
        dir,
        canvasWidth,
        canvasHeight,
        colors: appearanceState.horn_colors,
        signalAssetUpdate,
      })
    );
  }
  return composite;
};

const buildHairAppearanceLayers = (
  options: HairCompositeOptions
): OrderedOverlayLayer[] => {
  const hairCompositeGrid = buildHairCompositeGrid(options);
  if (hairCompositeGrid && gridHasPixels(hairCompositeGrid)) {
    return [
      {
        grid: hairCompositeGrid,
        layer: OVERLAY_SLOT_PRIORITY_MAP.hair,
        slot: 'hair',
        source: 'base',
        order: 1000,
      },
    ];
  }
  return [];
};

type TailAppearanceOptions = {
  dir: number;
  canvasWidth: number;
  canvasHeight: number;
  appearanceState: BasicAppearanceState;
  tailDef: BasicAppearanceAccessoryDefinition | null;
  signalAssetUpdate: () => void;
};

const buildTailAppearanceLayers = (
  options: TailAppearanceOptions
): OrderedOverlayLayer[] => {
  const {
    dir,
    canvasWidth,
    canvasHeight,
    appearanceState,
    tailDef,
    signalAssetUpdate,
  } = options;
  if (!tailDef) {
    return [];
  }
  const tailGrid = buildAccessoryGrid({
    def: tailDef,
    dir,
    canvasWidth,
    canvasHeight,
    colors: appearanceState.tail_colors,
    signalAssetUpdate,
  });
  if (!tailGrid) {
    return [];
  }
  const lowerDirs = Array.isArray(tailDef.lower_layer_dirs)
    ? tailDef.lower_layer_dirs
    : [2];
  const slot = lowerDirs.includes(dir) ? 'tail_lower' : 'tail_upper';
  return [
    {
      grid: tailGrid,
      layer: OVERLAY_SLOT_PRIORITY_MAP[slot],
      slot,
      source: 'base',
      order: 1030,
    },
  ];
};

type WingAppearanceOptions = {
  dir: number;
  canvasWidth: number;
  canvasHeight: number;
  appearanceState: BasicAppearanceState;
  wingDef: BasicAppearanceAccessoryDefinition | null;
  signalAssetUpdate: () => void;
};

const buildWingAppearanceLayers = (
  options: WingAppearanceOptions
): OrderedOverlayLayer[] => {
  const {
    dir,
    canvasWidth,
    canvasHeight,
    appearanceState,
    wingDef,
    signalAssetUpdate,
  } = options;
  if (!wingDef) {
    return [];
  }
  const layers: OrderedOverlayLayer[] = [];
  const frontGrid = buildAccessoryGrid({
    def: wingDef,
    dir,
    canvasWidth,
    canvasHeight,
    colors: appearanceState.wing_colors,
    signalAssetUpdate,
  });
  if (frontGrid) {
    layers.push({
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
        layers.push({
          grid: backGrid,
          layer: OVERLAY_SLOT_PRIORITY_MAP.wing_lower,
          slot: 'wing_lower',
          source: 'base',
          order: 1035,
        });
      }
    }
  }
  return layers;
};

const buildOverlayEntriesFromMergedLayers = (options: {
  merged: OrderedOverlayLayer[];
  dir: number;
  hideShoes: boolean;
  previewBaseEyeColor: string | null;
  previewTargetEyeColor: string | null;
  referenceParts: Record<string, string[][]> | null;
  hiddenLegParts: string[];
}): PreviewLayerEntry[] => {
  const {
    merged,
    dir,
    hideShoes,
    previewBaseEyeColor,
    previewTargetEyeColor,
    referenceParts,
    hiddenLegParts,
  } = options;
  const overlayEntries: PreviewLayerEntry[] = [];
  merged.forEach((entry, index) => {
    if (hideShoes && entry.slot === 'shoes') {
      return;
    }
    let grid = cloneGridData(entry.grid);
    if (entry.slot === 'eyes' && previewBaseEyeColor && previewTargetEyeColor) {
      grid = recolorGrid(grid, previewBaseEyeColor, previewTargetEyeColor, 3);
    }
    if (referenceParts && entry.slot && TAUR_CLOTHING_SLOTS.has(entry.slot)) {
      maskGridForHiddenLegParts(grid, referenceParts, hiddenLegParts);
    }
    if (!gridHasPixels(grid)) {
      return;
    }
    overlayEntries.push({
      type: 'overlay',
      key: `overlay_basic_${dir}_${entry.source}_${entry.slot || index}_${index}`,
      label:
        entry.source === 'job'
          ? 'Job Gear'
          : entry.source === 'loadout'
            ? 'Loadout Gear'
            : 'Overlay',
      grid,
      opacity: 1,
    });
  });
  return overlayEntries;
};

const buildBasicAppearanceOverlayEntries = (
  options: OverlayEntriesOptions
): PreviewLayerEntry[] => {
  const {
    dir,
    dirState,
    canvasWidth,
    canvasHeight,
    appearanceState,
    previewBaseEyeColor,
    previewTargetEyeColor,
    hairDef,
    gradientDef,
    facialHairDef,
    earDef,
    hornDef,
    tailDef,
    wingDef,
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
  const { baseOverlayLayers, loadoutLayers, jobLayers } =
    buildGearOverlayLayers({
      dirState,
      canvasWidth,
      canvasHeight,
      showJobGear,
      showLoadoutGear,
      signalAssetUpdate,
    });
  const appearanceLayers: OrderedOverlayLayer[] = [
    ...buildHairAppearanceLayers({
      dir,
      canvasWidth,
      canvasHeight,
      appearanceState,
      hairDef,
      gradientDef,
      facialHairDef,
      earDef,
      hornDef,
      signalAssetUpdate,
    }),
    ...buildTailAppearanceLayers({
      dir,
      canvasWidth,
      canvasHeight,
      appearanceState,
      tailDef,
      signalAssetUpdate,
    }),
    ...buildWingAppearanceLayers({
      dir,
      canvasWidth,
      canvasHeight,
      appearanceState,
      wingDef,
      signalAssetUpdate,
    }),
  ];
  const merged = mergeOverlayLayerLists(
    [...baseOverlayLayers, ...appearanceLayers],
    jobLayers,
    loadoutLayers
  );
  return buildOverlayEntriesFromMergedLayers({
    merged,
    dir,
    hideShoes,
    previewBaseEyeColor,
    previewTargetEyeColor,
    referenceParts,
    hiddenLegParts,
  });
};

const resolveGalleryType = (type: BasicAppearanceType): BasicAppearanceType =>
  type === 'eyes' || type === 'body' ? 'hair' : type;

type PreviewSourceSelection = {
  previewUsesAltSources: boolean;
  activePreviewSources?: BasicAppearancePayload['preview_sources'];
  activePreviewRevision?: number | null;
};

const resolvePreviewSourceSelection = (
  basicPayload: BasicAppearancePayload | null | undefined,
  appearanceState: BasicAppearanceState
): PreviewSourceSelection => {
  const previewUsesAltSources =
    !!basicPayload?.preview_sources_alt &&
    appearanceState.digitigrade !== !!basicPayload?.digitigrade;
  return {
    previewUsesAltSources,
    activePreviewSources: previewUsesAltSources
      ? basicPayload?.preview_sources_alt
      : basicPayload?.preview_sources,
    activePreviewRevision: previewUsesAltSources
      ? (basicPayload?.preview_revision_alt ?? basicPayload?.preview_revision)
      : basicPayload?.preview_revision,
  };
};

type PreviewColorData = {
  previewBaseBodyColor: string | null;
  previewTargetBodyColor: string;
  previewBaseEyeColor: string | null;
  previewTargetEyeColor: string;
};

const resolvePreviewColors = (
  basicPayload: BasicAppearancePayload | null | undefined,
  appearanceState: BasicAppearanceState
): PreviewColorData => ({
  previewBaseBodyColor: normalizeHex(basicPayload?.body_color),
  previewTargetBodyColor: normalizeHex(appearanceState.body_color) || '#ffffff',
  previewBaseEyeColor: normalizeHex(basicPayload?.eye_color),
  previewTargetEyeColor: normalizeHex(appearanceState.eye_color) || '#ffffff',
});

type DirectionData = {
  tileDirections: DirectionEntry[];
  tileDirectionsSignature: string;
  directionSignature: string;
};

const resolveDirectionData = (
  directions?: DirectionEntry[] | null
): DirectionData => {
  const directionList = Array.isArray(directions) ? directions : [];
  const tileDirections = directionList.slice(0, 4);
  return {
    tileDirections,
    tileDirectionsSignature: tileDirections.map((entry) => entry.dir).join('|'),
    directionSignature: directionList.map((entry) => entry.dir).join('|'),
  };
};

const resolvePreviewDirStates = (options: {
  activePreviewSources?: BasicAppearancePayload['preview_sources'];
  activePreviewRevision?: number | null;
  data: CustomMarkingDesignerData;
  canvasWidth: number;
  canvasHeight: number;
}): Record<number, PreviewDirState> => {
  const {
    activePreviewSources,
    activePreviewRevision,
    data,
    canvasWidth,
    canvasHeight,
  } = options;
  if (!activePreviewSources) {
    return {} as Record<number, PreviewDirState>;
  }
  return updatePreviewStateFromPayload(
    { revision: 0, lastDiffSeq: 0, dirs: {} },
    {
      data: {
        preview_sources: activePreviewSources,
        preview_revision: activePreviewRevision || 0,
        active_dir_key: data.active_dir_key,
        active_dir: data.active_dir,
        grid: [],
      } as any,
      sessionKey: 'basic-appearance',
      activePartKey: 'generic',
      canvasWidth,
      canvasHeight,
      canvasGrid: null,
    }
  ).dirs;
};

const resolveHiddenBodyParts = (parts?: unknown): string[] => {
  if (!Array.isArray(parts)) {
    return [];
  }
  return parts.filter(
    (part): part is string => typeof part === 'string' && part.length > 0
  );
};

type BodyMarkingsContextResult = {
  definitions: Record<string, BodyMarkingDefinition>;
  offsetX: number;
  signature: string;
  contextSignature: string;
  context: BodyMarkingsPreviewContext | null;
};

export const resolveBodyMarkingsContext = (options: {
  bodyPayload: BodyMarkingsPayload | null;
  bodyMarkingsState: Record<string, BodyMarkingEntry>;
  bodyMarkingsOrder: string[];
  appearanceState: BasicAppearanceState;
  canvasWidth: number;
  canvasHeight: number;
  assetRevision: number;
  directionSignature: string;
  directions?: DirectionEntry[] | null;
  markingLayersCache: Record<string, MarkingLayersCacheEntry>;
  signalAssetUpdate: () => void;
  definitionCache: BodyMarkingDefinitionCache;
  signatureCache: BodyMarkingsSignatureCache;
  previewCache: BodyMarkingsPreviewCache;
}): BodyMarkingsContextResult => {
  const {
    bodyPayload,
    bodyMarkingsState,
    bodyMarkingsOrder,
    appearanceState,
    canvasWidth,
    canvasHeight,
    assetRevision,
    directionSignature,
    directions,
    markingLayersCache,
    signalAssetUpdate,
    definitionCache,
    signatureCache,
    previewCache,
  } = options;
  if (definitionCache.payloadRef !== bodyPayload) {
    definitionCache.payloadRef = bodyPayload;
    definitionCache.definitions = buildBodyMarkingDefinitions(bodyPayload);
    definitionCache.offsetX = resolveBodyMarkingOffsetX(bodyPayload);
  }
  const definitions = definitionCache.definitions;
  const offsetX = definitionCache.offsetX;
  if (
    signatureCache.markingsRef !== bodyMarkingsState ||
    signatureCache.orderRef !== bodyMarkingsOrder ||
    signatureCache.definitionsRef !== definitions
  ) {
    signatureCache.markingsRef = bodyMarkingsState;
    signatureCache.orderRef = bodyMarkingsOrder;
    signatureCache.definitionsRef = definitions;
    signatureCache.signature = buildBodyMarkingsSignature({
      order: bodyMarkingsOrder,
      definitions,
      markings: bodyMarkingsState,
    });
  }
  const signature = signatureCache.signature;
  const contextSignature = [
    signature,
    appearanceState.digitigrade ? 'd' : 'p',
    `${canvasWidth}x${canvasHeight}`,
    offsetX,
    assetRevision,
    directionSignature,
  ].join('::');
  let context = previewCache.context;
  if (previewCache.signature !== contextSignature) {
    context = buildBodyMarkingsPreviewContext({
      definitions,
      order: bodyMarkingsOrder,
      markings: bodyMarkingsState,
      digitigrade: appearanceState.digitigrade,
      canvasWidth,
      canvasHeight,
      offsetX,
      assetRevision,
      signalAssetUpdate,
      directions: Array.isArray(directions) ? directions : [],
      markingLayersCache,
    });
    previewCache.signature = contextSignature;
    previewCache.context = context;
  }
  return {
    definitions,
    offsetX,
    signature,
    contextSignature,
    context,
  };
};

const resolvePartPaintPresenceMap = (options: {
  activePreviewSources?: BasicAppearancePayload['preview_sources'];
  resolvedPartReplacementMap?: Record<string, boolean> | null;
  previewDirStates: Record<number, PreviewDirState>;
  activeDirKey: number;
  activePartKey?: string | null;
  canvasWidth: number;
  canvasHeight: number;
  replacementDependents?: Record<string, string[]>;
}): Record<string, boolean> | undefined => {
  const {
    activePreviewSources,
    resolvedPartReplacementMap,
    previewDirStates,
    activeDirKey,
    activePartKey,
    canvasWidth,
    canvasHeight,
    replacementDependents,
  } = options;
  if (!activePreviewSources) {
    return undefined;
  }
  const hasReplacementFlags = Object.values(
    resolvedPartReplacementMap || {}
  ).some(Boolean);
  if (!hasReplacementFlags) {
    return undefined;
  }
  return buildPartPaintPresenceMap({
    dirStates: previewDirStates,
    activeDirKey,
    activePartKey: activePartKey || 'generic',
    canvasWidth,
    canvasHeight,
    replacementDependents,
  });
};

const buildTailHiddenSignature = (tailHiddenBodyParts: string[]): string =>
  tailHiddenBodyParts.length ? tailHiddenBodyParts.join('|') : 'none';

type GalleryBasePreviewSignatureOptions = {
  payloadSignature: string | null;
  activePreviewRevision?: number | null;
  previewUsesAltSources: boolean;
  canvasWidth: number;
  canvasHeight: number;
  tileDirectionsSignature: string;
  directionSignature: string;
  bodyMarkingsContextSignature: string;
  stripReferenceMarkings?: boolean;
};

const buildGalleryBasePreviewSignature = (
  options: GalleryBasePreviewSignatureOptions
): string => {
  const {
    payloadSignature,
    activePreviewRevision,
    previewUsesAltSources,
    canvasWidth,
    canvasHeight,
    tileDirectionsSignature,
    directionSignature,
    bodyMarkingsContextSignature,
    stripReferenceMarkings,
  } = options;
  return [
    payloadSignature || 'base',
    activePreviewRevision || 0,
    previewUsesAltSources ? 'alt' : 'base',
    `${canvasWidth}x${canvasHeight}`,
    tileDirectionsSignature,
    directionSignature,
    bodyMarkingsContextSignature,
    stripReferenceMarkings ? 's1' : 's0',
  ].join('::');
};

type GalleryPreviewResult = {
  preview: PreviewDirectionEntry[];
  previewByDir: Record<number, PreviewDirectionEntry>;
};

const resolveGalleryBasePreview = (options: {
  cache: GalleryBasePreviewCache;
  signature: string;
  activePreviewSources?: BasicAppearancePayload['preview_sources'];
  previewDirStates: Record<number, PreviewDirState>;
  tileDirections: DirectionEntry[];
  canvasWidth: number;
  canvasHeight: number;
  applyBodyMarkings: (
    preview: PreviewDirectionEntry[],
    suppressedPartsByDir?: Record<number, Record<string, boolean>>
  ) => PreviewDirectionEntry[];
  suppressedPartsByDir?: Record<number, Record<string, boolean>>;
  signalAssetUpdate: () => void;
  stripReferenceMarkings?: boolean;
}): GalleryPreviewResult => {
  const {
    cache,
    signature,
    activePreviewSources,
    previewDirStates,
    tileDirections,
    canvasWidth,
    canvasHeight,
    applyBodyMarkings,
    suppressedPartsByDir,
    signalAssetUpdate,
    stripReferenceMarkings,
  } = options;
  let preview = cache.preview;
  let previewByDir = cache.previewByDir;
  if (cache.signature !== signature) {
    const galleryMannequinPreviewRaw = activePreviewSources
      ? buildBasePreviewDirs(
          previewDirStates,
          tileDirections,
          {},
          canvasWidth,
          canvasHeight,
          signalAssetUpdate,
          stripReferenceMarkings
        )
      : [];
    preview = applyBodyMarkings(
      galleryMannequinPreviewRaw,
      suppressedPartsByDir
    );
    previewByDir = preview.reduce(
      (acc, entry) => {
        acc[entry.dir] = entry;
        return acc;
      },
      {} as Record<number, PreviewDirectionEntry>
    );
    cache.signature = signature;
    cache.preview = preview;
    cache.previewByDir = previewByDir;
  }
  return { preview, previewByDir };
};

const buildBasePreviewRaw = (options: {
  activePreviewSources?: BasicAppearancePayload['preview_sources'];
  previewDirStates: Record<number, PreviewDirState>;
  directions?: DirectionEntry[] | null;
  canvasWidth: number;
  canvasHeight: number;
  activeDirKey: number;
  resolvedPartPriorityMap: Record<string, boolean>;
  resolvedPartReplacementMap: Record<string, boolean>;
  partPaintPresenceMap?: Record<string, boolean>;
  showJobGear: boolean;
  showLoadoutGear: boolean;
  signalAssetUpdate: () => void;
  stripReferenceMarkings?: boolean;
}): PreviewDirectionEntry[] => {
  const {
    activePreviewSources,
    previewDirStates,
    directions,
    canvasWidth,
    canvasHeight,
    activeDirKey,
    resolvedPartPriorityMap,
    resolvedPartReplacementMap,
    partPaintPresenceMap,
    showJobGear,
    showLoadoutGear,
    signalAssetUpdate,
    stripReferenceMarkings,
  } = options;
  if (!activePreviewSources) {
    return [];
  }
  return buildDesignerPreviewDirs(
    previewDirStates,
    Array.isArray(directions) ? directions : [],
    {},
    canvasWidth,
    canvasHeight,
    activeDirKey,
    'generic',
    null,
    null,
    resolvedPartPriorityMap,
    resolvedPartReplacementMap,
    partPaintPresenceMap,
    showJobGear,
    showLoadoutGear,
    signalAssetUpdate,
    stripReferenceMarkings
  );
};

type BasePreviewSignatureOptions = {
  payloadSignature: string | null;
  activePreviewRevision?: number | null;
  previewUsesAltSources: boolean;
  appearanceState: BasicAppearanceState;
  canvasWidth: number;
  canvasHeight: number;
  tailHiddenSignature: string;
  directionSignature: string;
  activeDirKey: number;
  activeDir: string;
  partPrioritySignature: string;
  partReplacementSignature: string;
  partPaintSignature: string;
  showJobGear: boolean;
  showLoadoutGear: boolean;
};

const buildBasePreviewSignature = (
  options: BasePreviewSignatureOptions
): string => {
  const {
    payloadSignature,
    activePreviewRevision,
    previewUsesAltSources,
    appearanceState,
    canvasWidth,
    canvasHeight,
    tailHiddenSignature,
    directionSignature,
    activeDirKey,
    activeDir,
    partPrioritySignature,
    partReplacementSignature,
    partPaintSignature,
    showJobGear,
    showLoadoutGear,
  } = options;
  return [
    payloadSignature || 'base',
    activePreviewRevision || 0,
    previewUsesAltSources ? 'alt' : 'base',
    appearanceState.digitigrade ? 'd' : 'p',
    `${canvasWidth}x${canvasHeight}`,
    tailHiddenSignature,
    directionSignature,
    activeDirKey,
    activeDir,
    partPrioritySignature,
    partReplacementSignature,
    partPaintSignature,
    showJobGear ? 'j1' : 'j0',
    showLoadoutGear ? 'l1' : 'l0',
  ].join('::');
};

type MarkedBasePreviewResult = {
  markedBasePreviewByDir: Record<number, PreviewDirectionEntry>;
  basePreviewAfterByDir: Record<number, PreviewLayerEntry[]>;
};

const resolveMarkedBasePreview = (options: {
  cache: MarkedBasePreviewCache;
  signature: string;
  basePreview: PreviewDirectionEntry[];
  applyBodyMarkings: (
    preview: PreviewDirectionEntry[],
    suppressedPartsByDir?: Record<number, Record<string, boolean>>
  ) => PreviewDirectionEntry[];
  suppressedPartsByDir?: Record<number, Record<string, boolean>>;
}): MarkedBasePreviewResult => {
  const {
    cache,
    signature,
    basePreview,
    applyBodyMarkings,
    suppressedPartsByDir,
  } = options;
  let markedBasePreviewByDir = cache.previewByDir;
  let basePreviewAfterByDir = cache.afterByDir;
  if (cache.signature !== signature) {
    const basePreviewSegments = basePreview.map((dirEntry) => {
      const { before, after } = splitOverlayGroup(dirEntry.layers || []);
      return {
        dir: dirEntry.dir,
        label: dirEntry.label,
        before,
        after,
      };
    });
    const basePreviewForMarkings = basePreviewSegments.map((entry) => ({
      dir: entry.dir,
      label: entry.label,
      layers: entry.before,
    }));
    const markedBasePreview = applyBodyMarkings(
      basePreviewForMarkings,
      suppressedPartsByDir
    );
    markedBasePreviewByDir = markedBasePreview.reduce(
      (acc, entry) => {
        acc[entry.dir] = entry;
        return acc;
      },
      {} as Record<number, PreviewDirectionEntry>
    );
    basePreviewAfterByDir = basePreviewSegments.reduce(
      (acc, entry) => {
        acc[entry.dir] = entry.after;
        return acc;
      },
      {} as Record<number, PreviewLayerEntry[]>
    );
    cache.signature = signature;
    cache.previewByDir = markedBasePreviewByDir;
    cache.afterByDir = basePreviewAfterByDir;
  }
  return { markedBasePreviewByDir, basePreviewAfterByDir };
};

type PreviewBackgroundData = {
  previewBackgroundImage: string | null;
  previewBackgroundTileWidth?: number;
  previewBackgroundTileHeight?: number;
};

const resolvePreviewBackgroundData = (
  resolvedCanvasBackground: CanvasBackgroundOption | null,
  canvasBackgroundScale: number
): PreviewBackgroundData => {
  const previewBackgroundImage = resolvedCanvasBackground?.asset?.png
    ? `data:image/png;base64,${resolvedCanvasBackground.asset.png}`
    : null;
  const previewBackgroundTileWidth = resolvedCanvasBackground?.asset?.width
    ? resolvedCanvasBackground.asset.width * canvasBackgroundScale
    : undefined;
  const previewBackgroundTileHeight = resolvedCanvasBackground?.asset?.height
    ? resolvedCanvasBackground.asset.height * canvasBackgroundScale
    : undefined;
  return {
    previewBackgroundImage,
    previewBackgroundTileWidth,
    previewBackgroundTileHeight,
  };
};

export const BasicAppearanceTab = (props: BasicAppearanceTabProps, context) => {
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
  const [, setBasicReloadPending] = useLocalState<boolean>(
    context,
    `basicAppearanceReloadPending-${stateToken}`,
    false
  );
  const [previewRefreshSkips, setPreviewRefreshSkips] = useLocalState<number>(
    context,
    `customMarkingDesignerPreviewRefreshSkips-${stateToken}`,
    0
  );
  const [loadInProgress, setLoadInProgress] = useLocalState<boolean>(
    context,
    `basicAppearanceLoadInProgress-${stateToken}`,
    false
  );
  const [bodyMarkingsLoadInProgress, setBodyMarkingsLoadInProgress] =
    useLocalState<boolean>(
      context,
      `bodyMarkingsLoadInProgress-${stateToken}`,
      false
    );
  const [bodyPayloadRequestPending, setBodyPayloadRequestPending] =
    useLocalState<boolean>(
      context,
      `basicAppearanceBodyPayloadRequestPending-${stateToken}`,
      false
    );
  const [bodyReloadPending, setBodyReloadPending] = useLocalState<boolean>(
    context,
    `bodyMarkingsReloadPending-${stateToken}`,
    false
  );
  const [basicPayload, setBasicPayload] =
    useLocalState<BasicAppearancePayload | null>(
      context,
      'basicPayload',
      data.basic_appearance_payload || null
    );
  const [bodyPayload, setBodyPayload] =
    useLocalState<BodyMarkingsPayload | null>(
      context,
      'bodyPayload',
      data.body_markings_payload || null
    );
  const [bodyMarkingsState, setBodyMarkingsState] = useLocalState<
    Record<string, BodyMarkingEntry>
  >(
    context,
    'bodyMarkingsState',
    deepCopyMarkings(data.body_markings_payload?.body_markings)
  );
  const [bodyMarkingsOrder, setBodyMarkingsOrder] = useLocalState<string[]>(
    context,
    'bodyMarkingsOrder',
    (data.body_markings_payload?.order as string[]) || []
  );
  const [bodyMarkingsSelected, setBodyMarkingsSelected] = useLocalState<
    string | null
  >(
    context,
    'bodyMarkingsSelected',
    (data.body_markings_payload?.order?.[0] as string) || null
  );
  const [, setBodySavedState] = useLocalState<BodyMarkingsSavedState>(
    context,
    'bodyMarkingsSavedState',
    buildBodySavedStateFromPayload(data.body_markings_payload)
  );
  const [bodyMarkingsDirty, setBodyMarkingsDirty] = useLocalState(
    context,
    'bodyMarkingsDirty',
    false
  );
  const [markingLayersCache] = useLocalState<
    Record<string, MarkingLayersCacheEntry>
  >(context, 'basicAppearanceBodyMarkingLayersCache', {});
  const [bodyMarkingsPreviewCache] = useLocalState<BodyMarkingsPreviewCache>(
    context,
    'basicAppearanceBodyMarkingPreviewCache',
    { signature: '', context: null }
  );
  const [bodyMarkingDefinitionCache] =
    useLocalState<BodyMarkingDefinitionCache>(
      context,
      'basicAppearanceBodyMarkingDefinitionCache',
      { payloadRef: null, definitions: {}, offsetX: 0 }
    );
  const [bodyMarkingsSignatureCache] =
    useLocalState<BodyMarkingsSignatureCache>(
      context,
      'basicAppearanceBodyMarkingsSignatureCache',
      {
        markingsRef: null,
        orderRef: null,
        definitionsRef: null,
        signature: 'none',
      }
    );
  const [markedBasePreviewCache] = useLocalState<MarkedBasePreviewCache>(
    context,
    'basicAppearanceMarkedBasePreviewCache',
    { signature: '', previewByDir: {}, afterByDir: {} }
  );
  const [galleryBasePreviewCache] = useLocalState<GalleryBasePreviewCache>(
    context,
    'basicAppearanceGalleryPreviewCache',
    { signature: '', preview: [], previewByDir: {} }
  );
  const digitigradeAllowed = basicPayload?.digitigrade_allowed ?? true;
  const [appearanceState, setAppearanceState] =
    useLocalState<BasicAppearanceState>(
      context,
      'basicAppearanceState',
      buildBasicStateFromPayload(data.basic_appearance_payload)
    );
  const [savedState, setSavedState] = useLocalState<BasicAppearanceState>(
    context,
    'basicAppearanceSavedState',
    buildBasicStateFromPayload(data.basic_appearance_payload)
  );
  const [type, setType] = useLocalState<BasicAppearanceType>(
    context,
    'basicAppearanceType',
    'hair'
  );
  const [search, setSearch] = useLocalState<string>(
    context,
    'basicAppearanceSearch',
    ''
  );
  const [tilePage, setTilePage] = useLocalState<number>(
    context,
    'basicAppearanceTilePage',
    0
  );
  const galleryType = resolveGalleryType(type);
  const [dirty, setDirty] = useLocalState(
    context,
    'basicAppearanceDirty',
    false
  );
  const [payloadSignature, setPayloadSignature] = useLocalState<string | null>(
    context,
    'basicAppearancePayloadSignature',
    buildBasicPayloadSignature(basicPayload)
  );
  const [colorTarget, setColorTarget] =
    useLocalState<BasicAppearanceColorTarget | null>(
      context,
      'basicAppearanceColorTarget',
      { type: 'hair' }
    );
  const [pendingSave, setPendingSaveLocal] = useLocalState<boolean>(
    context,
    'basicAppearancePendingSave',
    false
  );
  const [pendingClose, setPendingCloseLocal] = useLocalState<boolean>(
    context,
    'basicAppearancePendingClose',
    false
  );
  const [tilePreviewCache] = useLocalState<
    Record<string, { sig: string; previews: BasicTilePreviewEntry[] }>
  >(context, 'basicAppearanceTilePreviewCache', {});
  const [tileBasePreviewCache] = useLocalState<TileBasePreviewCache>(
    context,
    'basicAppearanceTileBasePreviewCache',
    {}
  );
  const [assetRevision] = useLocalState<number>(
    context,
    'basicAppearanceAssetRevision',
    0
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

  const updateAppearanceState = (
    updater: (prev: BasicAppearanceState) => BasicAppearanceState
  ) =>
    updateSharedState({
      key: 'basicAppearanceState',
      fallback: appearanceState,
      updater,
    });

  const signalAssetUpdate = () => {
    if (assetUpdateScheduled) {
      return;
    }
    assetUpdateScheduled = true;
    setTimeout(() => {
      assetUpdateScheduled = false;
      updateSharedState({
        key: 'basicAppearanceAssetRevision',
        fallback: assetRevision,
        updater: (prev) => ((prev || 0) + 1) % 1000000,
      });
    }, 0);
  };

  const canvasWidth = basicPayload?.preview_width || 64;
  const canvasHeight = basicPayload?.preview_height || 64;

  const requestPayload = () => {
    act('load_basic_appearance');
  };

  const requestBodyPayload = () => {
    if (!bodyPayloadRequestPending) {
      setBodyPayloadRequestPending(true);
    }
    act('load_body_markings');
  };

  const syncBodyPayload = (payload: BodyMarkingsPayload) => {
    const shouldSyncBodyPayload =
      !bodyPayload || bodyPayloadRequestPending || bodyReloadPending;
    if (!shouldSyncBodyPayload) {
      return;
    }
    if (bodyMarkingsDirty) {
      if (bodyPayloadRequestPending) {
        setBodyPayloadRequestPending(false);
      }
      if (bodyReloadPending) {
        setBodyReloadPending(false);
      }
      return;
    }
    setBodyPayload(payload);
    const nextMarkings = deepCopyMarkings(payload.body_markings);
    const nextOrder =
      (payload.order as string[]) || Object.keys(payload.body_markings || {});
    const nextSelectedId =
      bodyMarkingsSelected && nextOrder.includes(bodyMarkingsSelected)
        ? bodyMarkingsSelected
        : typeof nextOrder[0] === 'string'
          ? nextOrder[0]
          : null;
    setBodyMarkingsState(nextMarkings);
    setBodyMarkingsOrder([...nextOrder]);
    setBodyMarkingsSelected(nextSelectedId);
    setBodySavedState({
      order: [...nextOrder],
      markings: deepCopyMarkings(nextMarkings),
      selectedId: nextSelectedId,
    });
    setBodyMarkingsDirty(false);
    if (bodyPayloadRequestPending) {
      setBodyPayloadRequestPending(false);
    }
    if (bodyReloadPending) {
      setBodyReloadPending(false);
    }
  };

  const syncPayload = (payload: BasicAppearancePayload) => {
    setBasicPayload(payload);
    const nextState = buildBasicStateFromPayload(payload);
    setAppearanceState(nextState);
    setSavedState(nextState);
    setTilePage(0);
    setDirty(false);
    setBasicReloadPending(false);
  };

  const syncPreviewPayload = (payload: BasicAppearancePayload) => {
    const backendState = selectBackend(context.store.getState()) as {
      shared?: Record<string, unknown>;
    };
    const shared = backendState?.shared || {};
    const resolvedPayload =
      (shared.basicPayload as BasicAppearancePayload | null) || basicPayload;
    setBasicPayload({
      ...(resolvedPayload || ({} as BasicAppearancePayload)),
      ...payload,
      preview_only: false,
    });
    setBasicReloadPending(false);
  };

  const resolveLatestBasicState = () => {
    const backendState = selectBackend(context.store.getState()) as {
      shared?: Record<string, unknown>;
    };
    const shared = backendState?.shared || {};
    return {
      latestState:
        (shared.basicAppearanceState as BasicAppearanceState) ||
        appearanceState,
      latestPayload:
        (shared.basicPayload as BasicAppearancePayload | null) || basicPayload,
      latestDirty:
        typeof shared.basicAppearanceDirty === 'boolean'
          ? (shared.basicAppearanceDirty as boolean)
          : dirty,
    };
  };

  const setStyle = (
    targetType: BasicAppearanceType,
    styleId: string | null
  ) => {
    applyStyleChange({
      targetType,
      styleId,
      updateAppearanceState,
      setDirty,
      isDirty: dirty,
    });
  };

  const setDigitigrade = (value: boolean) => {
    applyDigitigradeChange({
      value,
      allowed: digitigradeAllowed,
      updateAppearanceState,
      setDirty,
      isDirty: dirty,
    });
  };

  const applyColorTarget = (hex: string) => {
    applyBasicColorTarget({
      hex,
      colorTarget,
      activeType: galleryType,
      maxAccessoryChannels,
      resolveLatestState: resolveLatestBasicState,
      updateAppearanceState,
      setDirty,
    });
  };

  const handleSave = async (close = false) => {
    const { latestState, latestDirty } = resolveLatestBasicState();
    const wasDirty = latestDirty;
    const startingPreviewRevision =
      typeof data.preview_revision === 'number' ? data.preview_revision : 0;
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
      await act('save_basic_appearance', {
        digitigrade: latestState.digitigrade ? 1 : 0,
        body_color: latestState.body_color,
        eye_color: latestState.eye_color,
        hair_style: latestState.hair_style,
        hair_color: latestState.hair_color,
        hair_gradient_style: latestState.hair_gradient_style,
        hair_gradient_color: latestState.hair_gradient_color,
        facial_hair_style: latestState.facial_hair_style,
        facial_hair_color: latestState.facial_hair_color,
        ear_style: latestState.ear_style,
        ear_colors: latestState.ear_colors,
        horn_style: latestState.horn_style,
        horn_colors: latestState.horn_colors,
        tail_style: latestState.tail_style,
        tail_colors: latestState.tail_colors,
        wing_style: latestState.wing_style,
        wing_colors: latestState.wing_colors,
        close,
      });
      if (!close) {
        if (wasDirty) {
          setReloadTargetRevision(startingPreviewRevision + 1);
          setReloadPending(true);
        }
        setDirty(false);
        setSavedState(latestState);
        setAppearanceState(latestState);
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
      await act('close_basic_appearance');
    } finally {
      setPendingClose(false);
      setPendingCloseLocal(false);
    }
  };

  const {
    hair_styles,
    gradient_styles,
    facial_hair_styles,
    ear_styles,
    tail_styles,
    wing_styles,
  } = basicPayload || ({} as BasicAppearancePayload);

  const maxAccessoryChannels: BasicAppearanceAccessoryChannelCaps = {
    ears: resolveAccessoryMaxChannels(ear_styles),
    horns: Math.max(
      resolveAccessoryMaxChannels(ear_styles),
      Array.isArray(appearanceState.horn_colors)
        ? appearanceState.horn_colors.length
        : 0
    ),
    tail: resolveAccessoryMaxChannels(tail_styles),
    wings: resolveAccessoryMaxChannels(wing_styles),
  };

  const hairDef = resolveSelectedDef(hair_styles, appearanceState.hair_style);
  const gradientDef = resolveSelectedDef(
    gradient_styles,
    appearanceState.hair_gradient_style
  );
  const facialHairDef = resolveSelectedDef(
    facial_hair_styles,
    appearanceState.facial_hair_style
  );
  const earDef = resolveSelectedDef(ear_styles, appearanceState.ear_style);
  const hornDef = resolveSelectedDef(ear_styles, appearanceState.horn_style);
  const tailDef = resolveSelectedDef(tail_styles, appearanceState.tail_style);
  const wingDef = resolveSelectedDef(wing_styles, appearanceState.wing_style);

  const activeColorTarget = resolveBasicColorTarget({
    target: colorTarget,
    activeType: galleryType,
    maxAccessoryChannels,
  });

  const colorPickerValue = resolveColorTargetHexForState(
    appearanceState,
    activeColorTarget
  );

  const { previewUsesAltSources, activePreviewSources, activePreviewRevision } =
    resolvePreviewSourceSelection(basicPayload, appearanceState);
  const {
    previewBaseBodyColor,
    previewTargetBodyColor,
    previewBaseEyeColor,
    previewTargetEyeColor,
  } = resolvePreviewColors(basicPayload, appearanceState);
  const { tileDirections, tileDirectionsSignature, directionSignature } =
    resolveDirectionData(data.directions);
  const previewDirStates = resolvePreviewDirStates({
    activePreviewSources,
    activePreviewRevision,
    data,
    canvasWidth,
    canvasHeight,
  });
  const tailHiddenBodyParts = resolveHiddenBodyParts(tailDef?.hide_body_parts);
  const previewDirStatesForLive = mergeHiddenBodyPartsInPreviewStates(
    previewDirStates,
    tailHiddenBodyParts
  );
  const previewHiddenPartsByDir = buildHiddenBodyPartsByDir(previewDirStates);
  const liveHiddenPartsByDir = buildHiddenBodyPartsByDir(
    previewDirStatesForLive
  );
  const bodyColorExcludedParts = collectBodyColorExcludedParts(
    previewDirStatesForLive
  );
  const {
    definitions: bodyMarkingsDefinitions,
    signature: bodyMarkingsSignature,
    contextSignature: bodyMarkingsContextSignature,
    context: bodyMarkingsContext,
  } = resolveBodyMarkingsContext({
    bodyPayload,
    bodyMarkingsState,
    bodyMarkingsOrder,
    appearanceState,
    canvasWidth,
    canvasHeight,
    assetRevision,
    directionSignature,
    directions: data.directions,
    markingLayersCache,
    signalAssetUpdate,
    definitionCache: bodyMarkingDefinitionCache,
    signatureCache: bodyMarkingsSignatureCache,
    previewCache: bodyMarkingsPreviewCache,
  });
  const stripReferenceMarkings =
    Object.keys(bodyMarkingsDefinitions || {}).length > 0;
  const applyBodyMarkings = (
    preview: PreviewDirectionEntry[],
    suppressedPartsByDir?: Record<number, Record<string, boolean>>
  ) =>
    applyBodyMarkingsToPreview({
      preview,
      context: bodyMarkingsContext,
      stripReferenceMarkings,
      suppressedPartsByDir,
    });
  const partPaintPresenceMap = resolvePartPaintPresenceMap({
    activePreviewSources,
    resolvedPartReplacementMap,
    previewDirStates: previewDirStatesForLive,
    activeDirKey: data.active_dir_key,
    activePartKey: data.active_body_part,
    canvasWidth,
    canvasHeight,
    replacementDependents: data.replacement_dependents,
  });
  const partPrioritySignature = buildBooleanMapSignature(
    resolvedPartPriorityMap
  );
  const partReplacementSignature = buildBooleanMapSignature(
    resolvedPartReplacementMap
  );
  const partPaintSignature = buildBooleanMapSignature(partPaintPresenceMap);
  const tailHiddenSignature = buildTailHiddenSignature(tailHiddenBodyParts);
  const galleryBaseSignature = buildGalleryBasePreviewSignature({
    payloadSignature,
    activePreviewRevision,
    previewUsesAltSources,
    canvasWidth,
    canvasHeight,
    tileDirectionsSignature,
    directionSignature,
    bodyMarkingsContextSignature,
    stripReferenceMarkings,
  });
  const { preview: galleryBasePreview } = resolveGalleryBasePreview({
    cache: galleryBasePreviewCache,
    signature: galleryBaseSignature,
    activePreviewSources,
    previewDirStates,
    tileDirections,
    canvasWidth,
    canvasHeight,
    applyBodyMarkings,
    suppressedPartsByDir: previewHiddenPartsByDir,
    signalAssetUpdate,
    stripReferenceMarkings,
  });
  const galleryMannequinPreview = applyBodyAndEyeColorToPreview(
    galleryBasePreview,
    previewBaseBodyColor,
    previewTargetBodyColor,
    bodyColorExcludedParts,
    previewBaseEyeColor,
    previewTargetEyeColor,
    previewTargetBodyColor
  );
  const galleryMannequinPreviewByDir = galleryMannequinPreview.reduce(
    (acc, entry) => {
      acc[entry.dir] = entry;
      return acc;
    },
    {} as Record<number, PreviewDirectionEntry>
  );

  const setGallerySelection = (id: string | null) =>
    applyGallerySelection({
      galleryType,
      id,
      setStyle,
      setColorTarget,
    });

  const getTilePreviewEntries = (def: { id: string; name: string }) =>
    buildTilePreviewEntries({
      def,
      galleryType,
      tileDirections,
      tileDirectionsSignature,
      canvasWidth,
      canvasHeight,
      activePreviewRevision,
      appearanceState,
      assetRevision,
      bodyMarkingsSignature,
      bodyMarkingsContextSignature,
      previewTargetBodyColor,
      previewTargetEyeColor,
      hairStyles: hair_styles,
      gradientStyles: gradient_styles,
      facialHairStyles: facial_hair_styles,
      earStyles: ear_styles,
      tailStyles: tail_styles,
      wingStyles: wing_styles,
      hairDef,
      gradientDef,
      previewDirStates,
      tilePreviewCache,
      tileBasePreviewCache,
      galleryMannequinPreviewByDir,
      previewBaseBodyColor,
      previewBaseEyeColor,
      bodyColorExcludedParts,
      applyBodyMarkings,
      signalAssetUpdate,
      stripReferenceMarkings,
    });

  const basePreviewRaw = buildBasePreviewRaw({
    activePreviewSources,
    previewDirStates: previewDirStatesForLive,
    directions: data.directions,
    canvasWidth,
    canvasHeight,
    activeDirKey: data.active_dir_key,
    resolvedPartPriorityMap,
    resolvedPartReplacementMap,
    partPaintPresenceMap,
    showJobGear,
    showLoadoutGear,
    signalAssetUpdate,
    stripReferenceMarkings,
  });
  const basePreviewSignature = buildBasePreviewSignature({
    payloadSignature,
    activePreviewRevision,
    previewUsesAltSources,
    appearanceState,
    canvasWidth,
    canvasHeight,
    tailHiddenSignature,
    directionSignature,
    activeDirKey: data.active_dir_key,
    activeDir: data.active_dir,
    partPrioritySignature,
    partReplacementSignature,
    partPaintSignature,
    showJobGear,
    showLoadoutGear,
  });
  const markedBaseSignature = `${basePreviewSignature}::${bodyMarkingsContextSignature}::${stripReferenceMarkings ? 's1' : 's0'}`;
  const { markedBasePreviewByDir, basePreviewAfterByDir } =
    resolveMarkedBasePreview({
      cache: markedBasePreviewCache,
      signature: markedBaseSignature,
      basePreview: basePreviewRaw,
      applyBodyMarkings,
      suppressedPartsByDir: liveHiddenPartsByDir,
    });

  const livePreviewWithMarkingsBase = basePreviewRaw.map((dirEntry) => {
    const markedEntry = markedBasePreviewByDir[dirEntry.dir];
    const overlayEntries = buildBasicAppearanceOverlayEntries({
      dir: dirEntry.dir,
      dirState: previewDirStatesForLive[dirEntry.dir],
      canvasWidth,
      canvasHeight,
      appearanceState,
      previewBaseEyeColor,
      previewTargetEyeColor,
      hairDef,
      gradientDef,
      facialHairDef,
      earDef,
      hornDef,
      tailDef,
      wingDef,
      showJobGear,
      showLoadoutGear,
      signalAssetUpdate,
    });
    const fallbackSplit = splitOverlayGroup(dirEntry.layers || []);
    const baseLayers = markedEntry?.layers || fallbackSplit.before;
    const afterLayers =
      basePreviewAfterByDir[dirEntry.dir] || fallbackSplit.after;
    return {
      ...dirEntry,
      layers: [...baseLayers, ...overlayEntries, ...afterLayers],
    };
  });
  const livePreviewWithMarkings = applyBodyAndEyeColorToPreview(
    livePreviewWithMarkingsBase,
    previewBaseBodyColor,
    previewTargetBodyColor,
    bodyColorExcludedParts,
    previewBaseEyeColor,
    previewTargetEyeColor,
    previewTargetBodyColor
  );
  const {
    previewBackgroundImage,
    previewBackgroundTileWidth,
    previewBackgroundTileHeight,
  } = resolvePreviewBackgroundData(
    resolvedCanvasBackground,
    canvasBackgroundScale
  );

  if (!basicPayload) {
    return (
      <Box className="RogueStar" position="relative" minHeight="100%">
        <BodyMarkingsPreviewInitializer
          bodyPayload={bodyPayload}
          dataPayload={data.body_markings_payload}
          requestAllowed={!!basicPayload}
          loadInProgress={bodyMarkingsLoadInProgress}
          setLoadInProgress={setBodyMarkingsLoadInProgress}
          reloadPending={bodyReloadPending}
          setReloadPending={setBodyReloadPending}
          requestPayload={requestBodyPayload}
          syncPayload={syncBodyPayload}
        />
        <BasicAppearanceInitializer
          basicPayload={basicPayload}
          dataPayload={data.basic_appearance_payload}
          payloadSignature={payloadSignature}
          setPayloadSignature={setPayloadSignature}
          loadInProgress={loadInProgress}
          setLoadInProgress={setLoadInProgress}
          requestPayload={requestPayload}
          syncPayload={(payload) => {
            setPayloadSignature(buildBasicPayloadSignature(payload));
            syncPayload(payload);
          }}
          syncPreviewPayload={(payload) => {
            setPayloadSignature(buildBasicPayloadSignature(payload));
            syncPreviewPayload(payload);
          }}
        />
        <LoadingOverlay
          title="Loading basic appearance…"
          subtitle="Fetching your available styles and previews. This should only take a moment."
        />
      </Box>
    );
  }

  const galleryDefinitions = resolveGalleryDefinitionsForType(
    galleryType,
    hair_styles,
    gradient_styles,
    facial_hair_styles,
    ear_styles,
    tail_styles,
    wing_styles
  );
  const selectedGalleryId = resolveSelectedIdForGalleryType(
    galleryType,
    appearanceState
  );

  return (
    <Box className="RogueStar" position="relative" minHeight="100%">
      <BodyMarkingsPreviewInitializer
        bodyPayload={bodyPayload}
        dataPayload={data.body_markings_payload}
        requestAllowed={!!basicPayload}
        loadInProgress={bodyMarkingsLoadInProgress}
        setLoadInProgress={setBodyMarkingsLoadInProgress}
        reloadPending={bodyReloadPending}
        setReloadPending={setBodyReloadPending}
        requestPayload={requestBodyPayload}
        syncPayload={syncBodyPayload}
      />
      <BasicAppearanceInitializer
        basicPayload={basicPayload}
        dataPayload={data.basic_appearance_payload}
        payloadSignature={payloadSignature}
        setPayloadSignature={setPayloadSignature}
        loadInProgress={loadInProgress}
        setLoadInProgress={setLoadInProgress}
        requestPayload={requestPayload}
        syncPayload={(payload) => {
          setPayloadSignature(buildBasicPayloadSignature(payload));
          syncPayload(payload);
        }}
        syncPreviewPayload={(payload) => {
          setPayloadSignature(buildBasicPayloadSignature(payload));
          syncPreviewPayload(payload);
        }}
      />
      <Flex direction="row" gap={1} wrap={false} height="100%">
        <Flex.Item basis="840px" shrink={0}>
          <Flex direction="column" gap={1}>
            <BasicAppearanceGallerySection
              type={galleryType}
              setType={(nextType) => {
                setType(nextType);
                setColorTarget(resolveDefaultColorTarget(nextType));
              }}
              search={search}
              setSearch={setSearch}
              tilePage={tilePage}
              setTilePage={setTilePage}
              definitions={galleryDefinitions}
              selectedId={selectedGalleryId}
              canvasWidth={canvasWidth}
              canvasHeight={canvasHeight}
              tileDirectionsSignature={tileDirectionsSignature}
              assetRevision={assetRevision}
              getTilePreviewEntries={getTilePreviewEntries}
              onSelect={setGallerySelection}
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
            <BasicAppearanceSaveSection
              pendingSave={pendingSave}
              pendingClose={pendingClose}
              uiLocked={uiLocked}
              dirty={dirty}
              onSave={() => handleSave(false)}
              onSaveAndClose={() => handleSave(true)}
              onDiscardAndClose={handleDiscard}
            />
            <BasicAppearanceSettingsSection
              state={appearanceState}
              uiLocked={uiLocked}
              digitigradeAllowed={digitigradeAllowed}
              hairDef={hairDef}
              facialHairDef={facialHairDef}
              maxAccessoryChannels={maxAccessoryChannels}
              activeColorTarget={activeColorTarget}
              setColorTarget={setColorTarget}
              setStyle={setStyle}
              setDigitigrade={setDigitigrade}
            />
          </Flex>
        </Flex.Item>
        <Flex.Item grow>
          <BasicAppearancePreviewColumn
            preview={livePreviewWithMarkings}
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
