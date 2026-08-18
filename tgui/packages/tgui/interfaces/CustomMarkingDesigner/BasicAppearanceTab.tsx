// ///////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Basic appearance selection tab added ////////
// ///////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star August 2026: Character Designer - Species and Prosthetics //
// ///////////////////////////////////////////////////////////////////////////////////////////

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
  Dropdown,
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
  areIconAssetsReady,
  buildRenderedPreviewDirs as buildBasePreviewDirs,
  cloneGridData,
  createBlankGrid,
  getGearPreviewRasterIdentity,
  getIconAssetReadinessSignature,
  getPreviewGridFromAsset,
  getPreviewGridFromGearAsset,
  getPreviewPartMapFromAssets,
  gridHasPixels,
  resolveIconAssetReference,
  type GearOverlayAsset,
  type IconAssetRegistry,
  type IconAssetReference,
  type IconAssetPayload,
  type PreviewDirState,
  type PreviewDirectionEntry,
  type PreviewLayerEntry,
  type PreviewLayerGroup,
} from '../../utils/character-preview';
import {
  DirectionPreviewCanvas,
  LivePreviewCard,
  LoadingOverlay,
  ProstheticMannequin,
} from './components';
import { CHIP_BUTTON_CLASS } from './constants';
import {
  applyBodyColorToPreview,
  applyEyeColorToPreview,
  applyInternalOrganOperation,
  applyLimbHairColorToPreview,
  applyProstheticGalleryCompositeToPreviewSources,
  applyProstheticSelectionToTargets,
  applyProstheticsToPreviewSources,
  attachProstheticColorModes,
  basicAppearanceStatesEqual,
  buildBasicAppearanceGalleryContextSignature,
  buildBasicAppearanceLoadParams,
  buildBasicStateFromPayload,
  buildCanonicalProstheticOperations,
  buildLimbPreviewSignature,
  buildProstheticPreviewLayerGroups,
  buildProstheticSaveParams,
  buildProstheticShowcaseState,
  buildProstheticShowcaseAppearanceStructureSignature,
  buildProstheticTileBaseCacheSignature,
  buildBodyMarkingsLoadParams,
  buildPartPaintPresenceMap,
  buildRenderedPreviewDirs as buildDesignerPreviewDirs,
  canApplyProstheticGalleryCompositeToPreviewSources,
  clampChannel,
  cloneLimbOverrideState,
  ICON_BLEND_MODE,
  isReferenceMarkingLayer,
  isProstheticTargetEditable,
  mergeBasicAppearancePayload,
  mergeBodyMarkingsPayload,
  normalizeProstheticTargets,
  normalizeBasicAppearanceGalleryStyleId,
  parseHex,
  PROSTHETIC_COLOR_MODE_DETAILS,
  PROSTHETIC_GALLERY_COMPOSITE_PART,
  PROSTHETIC_TARGET_LABELS,
  resolveBasicPreviewSourceSelection,
  resolveBasicBiologicalGender,
  resolveBasicBiologicalGenderOptions,
  resolveBlendMode,
  resolveEditableProstheticTargets,
  resolveGalleryTilePreviewStates,
  resolveInternalOrganDefinitions,
  resolveInternalOrganOptions,
  resolveInternalOrganStateDescription,
  resolveLockedInternalOrganLabel,
  resolveNextInternalOrganChoice,
  resolveApplicableProstheticTargets,
  isProstheticSelectionCompatibleWithTargets,
  resolveProstheticGalleryDefinitions,
  resolveProstheticGalleryDefinitionsForTargets,
  resolveProstheticGalleryComposite,
  resolveProstheticBodyColorPasses,
  resolveProstheticModelColorMode,
  resolveProstheticSynthColorPasses,
  resolveProstheticContextForBiologicalGender,
  resolveSelectedSpeciesPreviewSources,
  resetEditableProstheticSettings,
  shouldIncludeSpeciesTailInGalleryTile,
  shouldInvalidateSpeciesPayloadForBiologicalGenderChange,
  shouldRetainBodyMarkingBaseLayer,
  splitPreviewOverlayLayers,
  tintGrid,
  toggleProstheticTargetSelection,
  toHex,
  type BasicAppearanceGalleryType,
  type InternalOrganId,
  type ProstheticColorMode,
  type ProstheticPreviewTransformOptions,
  type ProstheticTarget,
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
  SpeciesPayload,
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
  livePreview?: PreviewDirectionEntry[];
  resolvedPartPriorityMap: Record<string, boolean>;
  resolvedPartReplacementMap: Record<string, boolean>;
  showEquipment: boolean;
  onToggleEquipment: () => void;
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
  | 'body'
  | 'prosthetics';

type BasicAppearanceColorTarget =
  | { type: 'hair' }
  | { type: 'gradient' }
  | { type: 'facial_hair' }
  | { type: 'eyes' }
  | { type: 'body' }
  | { type: 'blood' }
  | { type: 'synth' }
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
  rasterIdentity?: string;
  layer: number | null;
  slot?: string | null;
  source: 'base' | 'equipment' | 'job' | 'loadout';
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
  prosthetics: 'Body',
};

const DEFAULT_BASIC_APPEARANCE_TYPE: BasicAppearanceType = 'prosthetics';

const GALLERY_TYPES: BasicAppearanceType[] = [
  DEFAULT_BASIC_APPEARANCE_TYPE,
  'hair',
  'gradient',
  'facial_hair',
  'ears',
  'horns',
  'tail',
  'wings',
];

const OVERLAY_SLOT_PRIORITY_MAP: Record<string, number> = {
  underwear: 6,
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
const TAUR_CLOTHING_SLOTS = new Set([
  'underwear',
  'uniform',
  'belt',
  'suit',
  'back',
]);
const BODY_COLOR_OVERLAY_SLOTS = new Set([
  'species_tail',
  'prosthetic_tail',
  'prosthetic_wing',
]);

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

const collectBodyColorBlendMode = (
  dirStates: Record<number, PreviewDirState> | null | undefined
): number | null => {
  if (!dirStates) {
    return null;
  }
  for (const dirState of Object.values(dirStates)) {
    if (typeof dirState?.bodyColorBlendMode === 'number') {
      return dirState.bodyColorBlendMode;
    }
  }
  return null;
};

const applyBodyAndEyeColorToPreview = (
  preview: PreviewDirectionEntry[],
  bodyBaseHex: string | null,
  bodyTargetHex: string | null,
  bodyExcludedParts: Set<string> | null,
  bodyBlendMode: number | null,
  eyeBaseHex: string | null,
  eyeTargetHex: string | null,
  bodyHex?: string | null,
  hairHex?: string | null
): PreviewDirectionEntry[] =>
  applyEyeColorToPreview(
    applyLimbHairColorToPreview(
      applyBodyColorToPreview(
        preview,
        bodyBaseHex,
        bodyTargetHex,
        bodyExcludedParts,
        3,
        bodyBlendMode
      ),
      hairHex || null
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

const buildSuppressedMarkingPartsByDir = (
  previewDirStates: Record<number, PreviewDirState>
): Record<number, Record<string, boolean>> => {
  const result: Record<number, Record<string, boolean>> = {};
  for (const dirState of Object.values(previewDirStates)) {
    if (!dirState) {
      continue;
    }
    const suppressedMap: Record<string, boolean> = {};
    const suppressedParts = [
      ...(dirState.hiddenBodyParts || []),
      ...(dirState.markingExcludedParts || []),
    ];
    for (const partId of suppressedParts) {
      if (typeof partId === 'string' && partId.length) {
        suppressedMap[partId] = true;
      }
    }
    if (Object.keys(suppressedMap).length) {
      result[dirState.dir] = suppressedMap;
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

export const buildBasicPayloadSignature = (
  payload?: BasicAppearancePayload | null
) => {
  if (!payload) {
    return null;
  }
  const revision = `${payload.preview_signature || ''}@${
    payload.preview_revision || 0
  }`;
  const altRevision = `${payload.preview_signature_alt || ''}@${
    payload.preview_revision_alt || 0
  }`;
  const genderAltRevision = `${payload.preview_signature_gender_alt || ''}@${
    payload.preview_revision_gender_alt || 0
  }`;
  const genderAltDigitigradeRevision = `${
    payload.preview_signature_gender_alt_digitigrade || ''
  }@${payload.preview_revision_gender_alt_digitigrade || 0}`;
  const size = `${payload.preview_width || 0}x${payload.preview_height || 0}`;
  const digitigrade = payload.digitigrade ? 'd' : 'p';
  const digitigradeAllowed = payload.digitigrade_allowed === false ? '0' : '1';
  const species = `${payload.species_id || ''}:${payload.custom_base || ''}`;
  const defsSignature =
    payload.definition_revision ||
    [
      (payload.hair_styles || []).map((def) => def.id).join('|'),
      (payload.gradient_styles || []).map((def) => def.id).join('|'),
      (payload.facial_hair_styles || []).map((def) => def.id).join('|'),
      (payload.ear_styles || []).map((def) => def.id).join('|'),
      (payload.tail_styles || []).map((def) => def.id).join('|'),
      (payload.wing_styles || []).map((def) => def.id).join('|'),
    ].join('::');
  const prostheticSignature = payload.prosthetic_context
    ? JSON.stringify(payload.prosthetic_context)
    : '';
  const biologicalGender = `${payload.biological_gender || ''}:${
    payload.preview_gender_suffix || ''
  }:${(payload.base_biological_genders || []).join('|')}:${(
    payload.biological_genders || []
  ).join('|')}`;
  return `${species}:${revision}:${altRevision}:${genderAltRevision}:${genderAltDigitigradeRevision}:${size}:${digitigrade}:${digitigradeAllowed}:${biologicalGender}:${defsSignature}:${prostheticSignature}`;
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
    case 'prosthetics':
      return { type: 'synth' };
    default:
      return { type: 'hair' };
  }
};

const clampChannelIndex = (value: number, maxChannels: number) =>
  Math.max(0, Math.min(maxChannels - 1, Math.floor(value)));

const resolveStringOptions = (options?: string[]) =>
  Array.isArray(options)
    ? options.filter(
        (option): option is string =>
          typeof option === 'string' && !!option.length
      )
    : [];

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
    case 'blood':
      return { type: 'blood' };
    case 'synth':
      return { type: 'synth' };
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
  layerGroups?: PreviewLayerGroup[];
  baseLayers?: PreviewLayerEntry[];
  underlayLayers?: PreviewLayerEntry[];
  overlayLayers?: PreviewLayerEntry[];
  baseSignature?: string;
  renderSignature?: string;
  retainRenderedCanvasOnUnmount?: boolean;
};

type BasicTileDefinition = Readonly<{
  id: string;
  name: string;
  description?: string | null;
  disabled?: boolean;
  disabledReason?: string | null;
  tooltip?: string | null;
  colorMode?: ProstheticColorMode;
}>;

const ProstheticColorModeBadge = ({
  mode,
}: Readonly<{ mode: ProstheticColorMode }>) => {
  const details = PROSTHETIC_COLOR_MODE_DETAILS[mode];
  return (
    <Box
      as="span"
      className={`RogueStar__prostheticColorMode RogueStar__prostheticColorMode--${mode}`}
      title={details.description}>
      {details.label}
    </Box>
  );
};

type BasicTileProps = Readonly<{
  def: BasicTileDefinition;
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
      next.def.disabled !== this.props.def.disabled ||
      next.def.disabledReason !== this.props.def.disabledReason ||
      next.def.tooltip !== this.props.def.tooltip ||
      next.def.colorMode !== this.props.def.colorMode ||
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
    const disabled = !!def.disabled;
    return (
      <Box
        className={`RogueStar__markingTile${
          selected ? ' RogueStar__markingTile--selected' : ''
        }${disabled ? ' RogueStar__markingTile--disabled' : ''}${
          def.colorMode === 'prosthetic' || def.colorMode === 'body'
            ? ` RogueStar__markingTile--color-${def.colorMode}`
            : ''
        }`}
        aria-disabled={disabled}
        title={def.tooltip || def.disabledReason || def.description || def.name}
        onClick={disabled ? undefined : onToggle}>
        <Box className="RogueStar__markingTilePreviewGrid">
          {previews.map((preview) => (
            <Box
              key={`${def.id}-${preview.dir}`}
              className="RogueStar__markingTilePreview">
              <DirectionPreviewCanvas
                layers={
                  preview.layerGroups ||
                  preview.baseLayers ||
                  preview.underlayLayers ||
                  preview.overlayLayers
                    ? undefined
                    : preview.layers
                }
                layerGroups={preview.layerGroups}
                baseLayers={preview.baseLayers}
                underlayLayers={preview.underlayLayers}
                overlayLayers={preview.overlayLayers}
                bodyAlpha={preview.bodyAlpha}
                baseSignature={preview.baseSignature}
                renderSignature={preview.renderSignature}
                retainRenderedCanvasOnUnmount={
                  preview.retainRenderedCanvasOnUnmount
                }
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
        <Box
          className="RogueStar__markingTileLabel"
          title={
            def.tooltip || def.disabledReason || def.description || def.name
          }>
          {def.name}
        </Box>
      </Box>
    );
  }
}

type BasicTileSectionProps = Readonly<{
  definitions: BasicTileDefinition[];
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
  getTilePreviewEntries: (def: BasicTileDefinition) => BasicTilePreviewEntry[];
  onSelect: (id: string | null) => void;
  emptyMessage?: string;
  allowDeselect?: boolean;
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
      allowDeselect = true,
    } = this.props;
    const searchNeedle = search.trim().toLowerCase();
    const filtered = definitions.filter((def) => {
      if (!searchNeedle) {
        return true;
      }
      return (
        def.id.toLowerCase().includes(searchNeedle) ||
        def.name.toLowerCase().includes(searchNeedle) ||
        (def.description || '').toLowerCase().includes(searchNeedle)
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
                onToggle={() =>
                  !def.disabled &&
                  onSelect(selected && allowDeselect ? null : def.id)
                }
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
  definitions: BasicTileDefinition[];
  selectedId: string | null;
  canvasWidth: number;
  canvasHeight: number;
  tileDirectionsSignature: string;
  assetRevision: number;
  getTilePreviewEntries: (def: BasicTileDefinition) => BasicTilePreviewEntry[];
  backgroundImage: string | null;
  backgroundColor: string;
  backgroundScale: number;
  backgroundTileWidth?: number;
  backgroundTileHeight?: number;
  onSelect: (id: string | null) => void;
  emptyMessage?: string;
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
  emptyMessage,
}: BasicAppearanceGallerySectionProps) => (
  <Section
    title={
      type === 'prosthetics' ? 'Prosthetic Gallery' : 'Basic Appearance Gallery'
    }
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
      emptyMessage={emptyMessage}
      allowDeselect={type !== 'prosthetics'}
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
  hairDef: BasicAppearanceAccessoryDefinition | null;
  facialHairDef: BasicAppearanceAccessoryDefinition | null;
  maxAccessoryChannels: BasicAppearanceAccessoryChannelCaps;
  activeColorTarget: BasicAppearanceColorTarget | null;
  setColorTarget: (target: BasicAppearanceColorTarget | null) => void;
  setStyle: (type: BasicAppearanceType, styleId: string | null) => void;
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
  hairDef,
  facialHairDef,
  maxAccessoryChannels,
  activeColorTarget,
  setColorTarget,
  setStyle,
}: BasicAppearanceSettingsSectionProps) => {
  type BasicAppearanceStyleType =
    | 'hair'
    | 'gradient'
    | 'facial_hair'
    | 'ears'
    | 'horns'
    | 'tail'
    | 'wings';

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
        </LabeledList>
      </Flex>
    </Section>
  );
};

type ProstheticSettingsSectionProps = Readonly<{
  state: BasicAppearanceState;
  context: NonNullable<BasicAppearancePayload['prosthetic_context']>;
  biologicalGenders: string[];
  bloodTypes: string[];
  bloodReagents: string[];
  activeTargets: ProstheticTarget[];
  uiLocked: boolean;
  digitigradeAllowed: boolean;
  activeColorTarget: BasicAppearanceColorTarget | null;
  setColorTarget: (target: BasicAppearanceColorTarget | null) => void;
  setActiveTargets: (targets: ProstheticTarget[]) => void;
  applyExternalSelection: (id: string) => void;
  setInternalSelection: (target: InternalOrganId, state: string) => void;
  setBiologicalGender: (biologicalGender: string) => void;
  setBloodType: (bloodType: string) => void;
  setBloodReagent: (bloodReagent: string) => void;
  resetBloodColor: () => void;
  setNeedsGlasses: (needsGlasses: boolean) => void;
  setDigitigrade: (value: boolean) => void;
  setSynthColorEnabled: (enabled: boolean) => void;
  setSynthMarkings: (enabled: boolean) => void;
  resetSettings: () => void;
}>;

const PROSTHETIC_SELECTION_SUMMARY_PARTS: Array<{
  part: string;
  label: string;
}> = [
  { part: 'torso', label: 'Torso' },
  { part: 'groin', label: 'Groin' },
  { part: 'head', label: 'Head' },
  { part: 'l_arm', label: 'Left Arm' },
  { part: 'l_hand', label: 'Left Hand' },
  { part: 'r_arm', label: 'Right Arm' },
  { part: 'r_hand', label: 'Right Hand' },
  { part: 'l_leg', label: 'Left Leg' },
  { part: 'l_foot', label: 'Left Foot' },
  { part: 'r_leg', label: 'Right Leg' },
  { part: 'r_foot', label: 'Right Foot' },
];

const formatBiologicalGenderLabel = (biologicalGender: string) =>
  biologicalGender.length
    ? biologicalGender.charAt(0).toUpperCase() + biologicalGender.slice(1)
    : 'Unknown';

type ProstheticSelectionSummaryGroup = {
  id: string;
  status: 'cyborg' | 'amputated';
  name: string;
  parts: string[];
  fullBody: boolean;
  description?: string | null;
  colorMode?: ProstheticColorMode;
};

const resolveInternalOrganChipTone = (state: string) => {
  switch (state) {
    case 'normal':
    case 'native':
      return 'organic';
    case 'assisted':
      return 'assisted';
    case 'mechanical':
      return 'mechanical';
    case 'digital':
      return 'digital';
    default:
      return 'unavailable';
  }
};

export const buildProstheticSelectionSummary = (
  state: Pick<BasicAppearanceState, 'limbs'>,
  definitions: ReturnType<typeof resolveProstheticGalleryDefinitions>
): ProstheticSelectionSummaryGroup[] => {
  const modelDetails = definitions.reduce(
    (details, definition) => {
      details[definition.id] = {
        name: definition.name,
        description: definition.description,
      };
      return details;
    },
    {} as Record<string, { name: string; description?: string | null }>
  );
  const groups: Record<string, ProstheticSelectionSummaryGroup> = {};
  for (const summaryPart of PROSTHETIC_SELECTION_SUMMARY_PARTS) {
    const entry = state.limbs.external[summaryPart.part];
    if (!entry || entry.status === 'normal') {
      continue;
    }
    const status = entry.status === 'amputated' ? 'amputated' : 'cyborg';
    const modelId = status === 'cyborg' ? entry.model || 'prosthetic' : '';
    const id = status === 'cyborg' ? `cyborg:${modelId}` : 'amputated';
    if (!groups[id]) {
      groups[id] = {
        id,
        status,
        name:
          status === 'amputated'
            ? 'Amputated'
            : modelDetails[modelId]?.name || modelId || 'Prosthetic',
        parts: [],
        fullBody: false,
        description:
          status === 'cyborg' ? modelDetails[modelId]?.description : undefined,
        colorMode:
          status === 'cyborg'
            ? resolveProstheticModelColorMode(modelId)
            : undefined,
      };
    }
    groups[id].parts.push(summaryPart.label);
  }
  const resolvedGroups = Object.values(groups);
  if (
    resolvedGroups.length === 1 &&
    resolvedGroups[0].status === 'cyborg' &&
    resolvedGroups[0].parts.length === PROSTHETIC_SELECTION_SUMMARY_PARTS.length
  ) {
    resolvedGroups[0].parts = ['Full Body'];
    resolvedGroups[0].fullBody = true;
  }
  return resolvedGroups;
};

const ProstheticSettingsSection = ({
  state,
  context,
  biologicalGenders,
  bloodTypes,
  bloodReagents,
  activeTargets,
  uiLocked,
  digitigradeAllowed,
  activeColorTarget,
  setColorTarget,
  setActiveTargets,
  applyExternalSelection,
  setInternalSelection,
  setBiologicalGender,
  setBloodType,
  setBloodReagent,
  resetBloodColor,
  setNeedsGlasses,
  setDigitigrade,
  setSynthColorEnabled,
  setSynthMarkings,
  resetSettings,
}: ProstheticSettingsSectionProps) => {
  const normalizedActiveTargets = normalizeProstheticTargets(activeTargets);
  const activeTargetLabels = normalizedActiveTargets.map(
    (target) => PROSTHETIC_TARGET_LABELS[target]
  );
  const organicTargets = resolveApplicableProstheticTargets(
    normalizedActiveTargets,
    '__normal__',
    state.limbs,
    context
  );
  const amputatedTargets = resolveApplicableProstheticTargets(
    normalizedActiveTargets,
    '__amputated__',
    state.limbs,
    context
  );
  const selectionSummary = buildProstheticSelectionSummary(
    state,
    resolveProstheticGalleryDefinitions(context)
  );
  const synthColor = normalizeHex(state.synth_color) || '#ffffff';
  const bodyColor = normalizeHex(state.body_color) || '#ffffff';
  const eyesColor = normalizeHex(state.eye_color) || '#ffffff';
  const bloodColor = normalizeHex(state.blood_color) || '#a10808';
  const biologicalGenderOptions = biologicalGenders.map((biologicalGender) => ({
    displayText: formatBiologicalGenderLabel(biologicalGender),
    value: biologicalGender,
  }));
  const digitigradeEnabled = digitigradeAllowed && !!state.digitigrade;
  const digitigradeTooltip = !digitigradeAllowed
    ? 'Not available for the selected species.'
    : undefined;
  const fullBodyEditable = isProstheticTargetEditable(
    'full_body',
    state.limbs,
    context
  );

  const toggleActiveTarget = (target: ProstheticTarget) => {
    setActiveTargets(
      toggleProstheticTargetSelection(
        normalizedActiveTargets,
        target,
        state.limbs
      )
    );
  };

  return (
    <Section title="Body Settings" fill>
      <Flex direction="column" gap={1}>
        <Box>
          <Box bold mb={0.5}>
            Body & Physiology
          </Box>
          <Box className="RogueStar__physiologyPanel">
            <Box className="RogueStar__physiologyControl">
              <Box className="RogueStar__physiologyLabel">Body Color</Box>
              <Button
                className={`${CHIP_BUTTON_CLASS} RogueStar__physiologyToggle`}
                fluid
                icon="tint"
                disabled={uiLocked}
                selected={activeColorTarget?.type === 'body'}
                onClick={() => setColorTarget({ type: 'body' })}>
                <ColorBox mr={0.5} color={bodyColor} />
                Choose
              </Button>
            </Box>
            <Box className="RogueStar__physiologyControl">
              <Box className="RogueStar__physiologyLabel">Eye Color</Box>
              <Button
                className={`${CHIP_BUTTON_CLASS} RogueStar__physiologyToggle`}
                fluid
                icon="tint"
                disabled={uiLocked}
                selected={activeColorTarget?.type === 'eyes'}
                onClick={() => setColorTarget({ type: 'eyes' })}>
                <ColorBox mr={0.5} color={eyesColor} />
                Choose
              </Button>
            </Box>
            <Box className="RogueStar__physiologyControl">
              <Box className="RogueStar__physiologyLabel">Biological Sex</Box>
              <Dropdown
                key={state.biological_gender}
                className={`${CHIP_BUTTON_CLASS} RogueStar__physiologyDropdown`}
                color="transparent"
                dropdownStyle="rogue-star"
                controlContentClassName="Button__content RogueStar__physiologyDropdownContent"
                icon="venus-mars"
                width="100%"
                options={biologicalGenderOptions}
                selected={state.biological_gender}
                displayText={formatBiologicalGenderLabel(
                  state.biological_gender
                )}
                disabled={uiLocked || biologicalGenderOptions.length <= 1}
                onSelected={(biologicalGender) =>
                  typeof biologicalGender === 'string' &&
                  setBiologicalGender(biologicalGender)
                }
              />
            </Box>
            <Box className="RogueStar__physiologyControl">
              <Box className="RogueStar__physiologyLabel">Leg Shape</Box>
              <Button.Checkbox
                className={`${CHIP_BUTTON_CLASS} RogueStar__physiologyToggle`}
                fluid
                checked={digitigradeEnabled}
                disabled={uiLocked || !digitigradeAllowed}
                tooltip={digitigradeTooltip}
                onClick={() => setDigitigrade(!state.digitigrade)}>
                {digitigradeEnabled ? 'Digitigrade Legs' : 'Plantigrade Legs'}
              </Button.Checkbox>
            </Box>
            <Box className="RogueStar__physiologyControl">
              <Box className="RogueStar__physiologyLabel">Blood Type</Box>
              <Dropdown
                key={state.blood_type}
                className={`${CHIP_BUTTON_CLASS} RogueStar__physiologyDropdown`}
                color="transparent"
                dropdownStyle="rogue-star"
                controlContentClassName="Button__content RogueStar__physiologyDropdownContent"
                icon="tint"
                width="100%"
                options={bloodTypes}
                selected={state.blood_type}
                displayText={state.blood_type}
                disabled={uiLocked || !bloodTypes.length}
                onSelected={(bloodType) =>
                  typeof bloodType === 'string' && setBloodType(bloodType)
                }
              />
            </Box>
            <Box className="RogueStar__physiologyControl">
              <Box className="RogueStar__physiologyLabel">Blood Color</Box>
              <Flex gap={0.5}>
                <Flex.Item grow>
                  <Button
                    className={`${CHIP_BUTTON_CLASS} RogueStar__physiologyToggle`}
                    fluid
                    icon="tint"
                    disabled={uiLocked}
                    selected={activeColorTarget?.type === 'blood'}
                    tooltip="Blood color does not apply to synthetic characters."
                    onClick={() => setColorTarget({ type: 'blood' })}>
                    <ColorBox mr={0.5} color={bloodColor} />
                    Choose
                  </Button>
                </Flex.Item>
                <Flex.Item shrink={0}>
                  <Button
                    className={`${CHIP_BUTTON_CLASS} RogueStar__physiologyToggle`}
                    icon="rotate-left"
                    disabled={uiLocked}
                    tooltip="Reset to the human default (#A10808)."
                    onClick={resetBloodColor}
                  />
                </Flex.Item>
              </Flex>
            </Box>
            <Box className="RogueStar__physiologyControl">
              <Box className="RogueStar__physiologyLabel">Blood Reagent</Box>
              <Dropdown
                key={state.blood_reagent}
                className={`${CHIP_BUTTON_CLASS} RogueStar__physiologyDropdown`}
                color="transparent"
                dropdownStyle="rogue-star"
                controlContentClassName="Button__content RogueStar__physiologyDropdownContent"
                icon="flask"
                width="100%"
                options={bloodReagents}
                selected={state.blood_reagent}
                displayText={state.blood_reagent}
                disabled={uiLocked || !bloodReagents.length}
                onSelected={(bloodReagent) =>
                  typeof bloodReagent === 'string' &&
                  setBloodReagent(bloodReagent)
                }
              />
            </Box>
            <Box className="RogueStar__physiologyControl">
              <Box className="RogueStar__physiologyLabel">Vision</Box>
              <Button.Checkbox
                className={`${CHIP_BUTTON_CLASS} RogueStar__physiologyToggle`}
                fluid
                checked={state.needs_glasses}
                disabled={uiLocked}
                tooltip="Start nearsighted. Prescription glasses correct the resulting blurred vision."
                onClick={() => setNeedsGlasses(!state.needs_glasses)}>
                {state.needs_glasses ? 'Needs Glasses' : 'Normal Vision'}
              </Button.Checkbox>
            </Box>
          </Box>
        </Box>

        <Box>
          <Flex align="center" justify="space-between" mb={0.5}>
            <Flex.Item>
              <Box bold>Internal Organs</Box>
            </Flex.Item>
            <Flex.Item shrink={0}>
              <Box className="RogueStar__prostheticEyebrow">Click to cycle</Box>
            </Flex.Item>
          </Flex>
          <Box className="RogueStar__internalOrganPanel">
            <Box className="RogueStar__internalOrganGrid">
              {resolveInternalOrganDefinitions(context).map((definition) => {
                const target = definition.id as InternalOrganId;
                const options = resolveInternalOrganOptions(
                  target,
                  state.limbs,
                  context
                );
                const locked = !definition.allowed_states.length;
                const selected = locked
                  ? definition.locked_state || 'native'
                  : state.limbs.internal[target]?.status || 'normal';
                const selectedDefinition = options.find(
                  (entry) => entry.id === selected
                );
                const nextChoice = resolveNextInternalOrganChoice(
                  options,
                  selected
                );
                const organicBrain =
                  target === 'brain' &&
                  selected === 'normal' &&
                  !options.length &&
                  !locked;
                const lockedLabel = resolveLockedInternalOrganLabel(definition);
                const displayText = locked
                  ? lockedLabel
                  : options.length
                    ? selectedDefinition?.label || selected
                    : organicBrain
                      ? 'Organic'
                      : target === 'brain'
                        ? 'Needs synth head'
                        : 'Unavailable';
                const stateDescription = resolveInternalOrganStateDescription(
                  target,
                  selected
                );
                const tooltip = locked
                  ? `${definition.label}: ${displayText}. ${stateDescription}. This choice is fixed for this species.`
                  : nextChoice
                    ? `${definition.label}: ${displayText}. ${stateDescription}. Click to switch to ${nextChoice.label}.`
                    : organicBrain
                      ? `Brain: Organic. ${stateDescription}. Install a prosthetic head to choose a cybernetic brain type.`
                      : target === 'brain'
                        ? 'Install a prosthetic head to choose a cybernetic brain type.'
                        : `${definition.label} has no states available with the current anatomy.`;
                const tone = organicBrain
                  ? 'organic'
                  : options.length
                    ? resolveInternalOrganChipTone(selected)
                    : locked
                      ? resolveInternalOrganChipTone(selected)
                      : 'unavailable';
                return (
                  <Button
                    key={target}
                    className={`${CHIP_BUTTON_CLASS} RogueStar__internalOrganChip RogueStar__internalOrganChip--${tone}${
                      locked ? ' RogueStar__internalOrganChip--locked' : ''
                    }${
                      organicBrain
                        ? ' RogueStar__internalOrganChip--organicPassive'
                        : ''
                    }`}
                    fluid
                    disabled={uiLocked || locked || !nextChoice}
                    tooltip={tooltip}
                    onClick={() =>
                      nextChoice && setInternalSelection(target, nextChoice.id)
                    }>
                    <Box as="span" className="RogueStar__internalOrganChipName">
                      {definition.label}
                    </Box>
                    <Box
                      as="span"
                      className="RogueStar__internalOrganChipState">
                      {displayText}
                    </Box>
                  </Button>
                );
              })}
            </Box>
          </Box>
        </Box>

        <Box>
          <Box bold mb={0.5}>
            Prosthetics and Amputations
          </Box>
          <Box className="RogueStar__prostheticTargetPanel">
            <Flex gap={1} wrap={false} align="stretch">
              <Flex.Item basis="164px" shrink={0}>
                <ProstheticMannequin
                  activeTargets={normalizedActiveTargets}
                  uiLocked={uiLocked}
                  isTargetEditable={(target) =>
                    isProstheticTargetEditable(
                      target,
                      state.limbs,
                      context,
                      normalizedActiveTargets
                    )
                  }
                  onToggleTarget={toggleActiveTarget}
                />
              </Flex.Item>
              <Flex.Item grow className="RogueStar__prostheticTargetReadout">
                <Box className="RogueStar__prostheticEyebrow">
                  Active Targets
                </Box>
                <Box className="RogueStar__prostheticActiveTargets">
                  {activeTargetLabels.length
                    ? activeTargetLabels.join(' · ')
                    : 'No body areas selected'}
                </Box>
                <Flex mt={0.5} gap={0.5} wrap>
                  <Flex.Item>
                    <Button
                      className={CHIP_BUTTON_CLASS}
                      icon="person"
                      selected={normalizedActiveTargets.includes('full_body')}
                      disabled={uiLocked || !fullBodyEditable}
                      onClick={() => setActiveTargets(['full_body'])}>
                      Full Body
                    </Button>
                  </Flex.Item>
                  <Flex.Item>
                    <Button
                      className={CHIP_BUTTON_CLASS}
                      icon="times"
                      disabled={uiLocked || !normalizedActiveTargets.length}
                      onClick={() => setActiveTargets([])}>
                      Clear
                    </Button>
                  </Flex.Item>
                </Flex>
                <Box className="RogueStar__prostheticEyebrow" mt={1}>
                  Quick Set
                </Box>
                <Flex mt={0.5} gap={0.5} wrap>
                  <Flex.Item>
                    <Button
                      className={CHIP_BUTTON_CLASS}
                      icon="user"
                      disabled={uiLocked || !organicTargets.length}
                      tooltip="Restore every compatible active target to organic anatomy."
                      onClick={() => applyExternalSelection('__normal__')}>
                      Organic
                    </Button>
                  </Flex.Item>
                  <Flex.Item>
                    <Button
                      className={CHIP_BUTTON_CLASS}
                      icon="cut"
                      disabled={uiLocked || !amputatedTargets.length}
                      tooltip="Mark every compatible active limb as amputated."
                      onClick={() => applyExternalSelection('__amputated__')}>
                      Amputate
                    </Button>
                  </Flex.Item>
                </Flex>
                <Box className="RogueStar__prostheticEyebrow" mt={1}>
                  Appearance
                </Box>
                <Flex mt={0.5}>
                  <Flex.Item>
                    <Button.Checkbox
                      className={CHIP_BUTTON_CLASS}
                      checked={state.synth_markings}
                      disabled={uiLocked}
                      tooltip="Allow body markings to appear on prosthetic parts."
                      onClick={() => setSynthMarkings(!state.synth_markings)}>
                      Markings
                    </Button.Checkbox>
                  </Flex.Item>
                </Flex>
                <Flex mt={0.5} gap={0.5} wrap={false}>
                  <Flex.Item>
                    <Button.Checkbox
                      className={CHIP_BUTTON_CLASS}
                      checked={state.synth_color_enabled}
                      disabled={uiLocked}
                      tooltip="Enable recoloring for chassis labeled Prosthetic Color. Body Color and No Recoloring chassis are unaffected."
                      onClick={() =>
                        setSynthColorEnabled(!state.synth_color_enabled)
                      }>
                      Recolor
                    </Button.Checkbox>
                  </Flex.Item>
                  <Flex.Item>
                    <Button
                      className={CHIP_BUTTON_CLASS}
                      icon="tint"
                      disabled={uiLocked || !state.synth_color_enabled}
                      tooltip="Choose the color used by chassis labeled Prosthetic Color."
                      selected={activeColorTarget?.type === 'synth'}
                      onClick={() => setColorTarget({ type: 'synth' })}>
                      <ColorBox mr={0.5} color={synthColor} />
                      Choose
                    </Button>
                  </Flex.Item>
                </Flex>
              </Flex.Item>
            </Flex>
          </Box>
        </Box>

        <Box>
          <Flex align="center" justify="space-between" mb={0.5}>
            <Flex.Item>
              <Box bold>Current External Selections</Box>
            </Flex.Item>
            <Flex.Item shrink={0}>
              <Button.Confirm
                className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--negative`}
                icon="rotate-left"
                confirmIcon="triangle-exclamation"
                color="transparent"
                confirmColor="bad"
                confirmContent="Confirm Reset"
                disabled={uiLocked}
                tooltip="Reset all editable limbs and internal organs."
                onClick={resetSettings}
              />
            </Flex.Item>
          </Flex>
          <Box className="RogueStar__prostheticSelectionList">
            {selectionSummary.map((group) => (
              <Box
                key={group.id}
                className={`RogueStar__prostheticSelectionGroup${
                  group.status === 'amputated'
                    ? ' RogueStar__prostheticSelectionGroup--amputated'
                    : ''
                }`}>
                <Box>
                  <Box className="RogueStar__prostheticSelectionModel">
                    {group.name}
                  </Box>
                  {!!group.description && (
                    <Box className="RogueStar__prostheticHint" mt={0.25}>
                      {group.description}
                    </Box>
                  )}
                  <Box className="RogueStar__prostheticSelectionParts">
                    {group.parts.join(' · ')}
                  </Box>
                  {!!group.colorMode && (
                    <Box mt={0.3}>
                      <ProstheticColorModeBadge mode={group.colorMode} />
                    </Box>
                  )}
                </Box>
                <Box className="RogueStar__prostheticSelectionCount">
                  {group.fullBody ? 'ALL' : group.parts.length}
                </Box>
              </Box>
            ))}
            {!selectionSummary.length && (
              <Box className="RogueStar__prostheticSelectionEmpty">
                All external body parts are currently organic.
              </Box>
            )}
          </Box>
          {!!selectionSummary.length && (
            <Box className="RogueStar__prostheticHint" mt={0.5}>
              Unlisted body regions remain organic.
            </Box>
          )}
        </Box>
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
  iconScaleX?: number;
  iconScaleY?: number;
  showEquipment: boolean;
  onToggleEquipment: () => void;
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
  iconScaleX,
  iconScaleY,
  showEquipment,
  onToggleEquipment,
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
    <LivePreviewCard
      preview={preview}
      canvasWidth={canvasWidth}
      canvasHeight={canvasHeight}
      previewFitToFrame={previewFitToFrame}
      onTogglePreviewFit={onTogglePreviewFit}
      previewBackgroundImage={previewBackgroundImage}
      backgroundFallbackColor={backgroundFallbackColor}
      canvasBackgroundScale={canvasBackgroundScale}
      previewBackgroundTileWidth={previewBackgroundTileWidth}
      previewBackgroundTileHeight={previewBackgroundTileHeight}
      iconScaleX={iconScaleX}
      iconScaleY={iconScaleY}
      showEquipment={showEquipment}
      onToggleEquipment={onToggleEquipment}
      showJobGear={showJobGear}
      onToggleJobGear={onToggleJobGear}
      showLoadoutGear={showLoadoutGear}
      onToggleLoadout={onToggleLoadout}
      canvasBackgroundOptions={canvasBackgroundOptions}
      resolvedCanvasBackground={resolvedCanvasBackground}
      cycleCanvasBackground={cycleCanvasBackground}
    />
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
    if (basicPayload && !loadInProgress && !dataPayload.preview_only) {
      const basicSignature = buildBasicPayloadSignature(basicPayload);
      if (basicSignature !== payloadSignature) {
        setPayloadSignature(basicSignature);
      }
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
    const waitingForReload = loadInProgress && !basicPayload;
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
    if (!dataRefChanged && !signatureChanged) {
      return;
    }
    this.lastDataPayload = dataPayload;
    this.lastPayloadSignature = nextSignature;

    const signatureMatches = nextSignature === payloadSignature;
    if (signatureMatches) {
      if (waitingForReload) {
        setPayloadSignature(nextSignature);
        syncPayload(dataPayload);
        setLoadInProgress(false);
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
    const hadLastDataPayload = this.lastDataPayload !== null;
    if (!dataRefChanged && !signatureChanged) {
      return;
    }
    if (loadInProgress && !bodyPayload && !hadLastDataPayload) {
      this.lastDataPayload = dataPayload;
      this.lastPayloadSignature = nextSignature;
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
    const grid = getPreviewGridFromGearAsset(
      entry,
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
    const gearRasterIdentity = getGearPreviewRasterIdentity(entry);
    layers.push({
      grid: grid as string[][],
      rasterIdentity: gearRasterIdentity
        ? `${gearRasterIdentity}|preview:${canvasWidth}x${canvasHeight}`
        : undefined,
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
  equipmentLayers: OrderedOverlayLayer[],
  jobLayers: OrderedOverlayLayer[],
  loadoutLayers: OrderedOverlayLayer[]
): OrderedOverlayLayer[] =>
  [...baseLayers, ...equipmentLayers, ...jobLayers, ...loadoutLayers].sort(
    (a, b) => {
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
    }
  );

const splitOverlayGroup = (
  layers: PreviewLayerEntry[]
): {
  before: PreviewLayerEntry[];
  after: PreviewLayerEntry[];
} => {
  const { before, after } = splitPreviewOverlayLayers(layers);
  return { before, after };
};

const splitPriorityBodyMarkingLayers = (
  layers: PreviewLayerEntry[]
): {
  base: PreviewLayerEntry[];
  priority: PreviewLayerEntry[];
} => {
  const base: PreviewLayerEntry[] = [];
  const priority: PreviewLayerEntry[] = [];
  layers.forEach((layer) => {
    const isPriorityMarking =
      layer?.type === 'overlay' &&
      typeof layer.key === 'string' &&
      layer.key.startsWith('mark-priority-');
    (isPriorityMarking ? priority : base).push(layer);
  });
  return { base, priority };
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

type PreviewDirStatesCache = {
  sources: BasicAppearancePayload['preview_sources'] | null | undefined;
  assetRegistry: IconAssetRegistry | null | undefined;
  revision: number | null | undefined;
  activeDirKey: number;
  activeDir: string;
  canvasWidth: number;
  canvasHeight: number;
  dirs: Record<number, PreviewDirState>;
};

type BasePreviewRawCache = {
  signature: string;
  preview: PreviewDirectionEntry[];
};

type GalleryBasePreviewCache = {
  signature: string;
  preview: PreviewDirectionEntry[];
  previewByDir: Record<number, PreviewDirectionEntry>;
};

type GalleryAppearanceGridEntry = {
  hairGrid: string[][] | null;
  facialHairGrid: string[][] | null;
  earGrid: string[][] | null;
  hornGrid: string[][] | null;
  tailGrid: string[][] | null;
  wingGrid: string[][] | null;
  wingBackGrid: string[][] | null;
};

type GalleryAppearanceGridContextCache = {
  signature: string;
  byDir: Record<number, GalleryAppearanceGridEntry>;
};

type TileBasePreviewCacheEntry = {
  sig: string;
  structureSig?: string;
  preparedSig?: string;
  complete?: boolean;
  prostheticPrepared?: ProstheticTilePreparedBase;
  preview: PreviewDirectionEntry[];
  previewByDir: Record<number, PreviewDirectionEntry>;
};

type TileBasePreviewCache = Record<string, TileBasePreviewCacheEntry>;

type TilePreviewCache = Record<
  string,
  { sig: string; previews: BasicTilePreviewEntry[] }
>;

type BasicAppearanceRenderCache = {
  markingLayersCache: Record<string, MarkingLayersCacheEntry>;
  bodyMarkingsPreviewCache: BodyMarkingsPreviewCache;
  bodyMarkingDefinitionCache: BodyMarkingDefinitionCache;
  bodyMarkingsSignatureCache: BodyMarkingsSignatureCache;
  previewDirStatesCache: PreviewDirStatesCache;
  basePreviewRawCache: BasePreviewRawCache;
  markedBasePreviewCache: MarkedBasePreviewCache;
  galleryBasePreviewCache: GalleryBasePreviewCache;
  galleryAppearanceGridContextCache: GalleryAppearanceGridContextCache;
  tilePreviewCache: TilePreviewCache;
  tileBasePreviewCache: TileBasePreviewCache;
};

const createBasicAppearanceRenderCache = (): BasicAppearanceRenderCache => ({
  markingLayersCache: {},
  bodyMarkingsPreviewCache: { signature: '', context: null },
  bodyMarkingDefinitionCache: {
    payloadRef: null,
    definitions: {},
    offsetX: 0,
  },
  bodyMarkingsSignatureCache: {
    markingsRef: null,
    orderRef: null,
    definitionsRef: null,
    signature: 'none',
  },
  previewDirStatesCache: {
    sources: null,
    assetRegistry: null,
    revision: null,
    activeDirKey: 0,
    activeDir: '',
    canvasWidth: 0,
    canvasHeight: 0,
    dirs: {},
  },
  basePreviewRawCache: { signature: '', preview: [] },
  markedBasePreviewCache: {
    signature: '',
    previewByDir: {},
    afterByDir: {},
  },
  galleryBasePreviewCache: { signature: '', preview: [], previewByDir: {} },
  galleryAppearanceGridContextCache: { signature: '', byDir: {} },
  tilePreviewCache: {},
  tileBasePreviewCache: {},
});

const basicAppearanceRenderCacheByStore = new WeakMap<
  object,
  { stateToken: string; cache: BasicAppearanceRenderCache }
>();

export const resolveBasicAppearanceRenderCache = (
  store: object,
  stateToken: string
): BasicAppearanceRenderCache => {
  const cached = basicAppearanceRenderCacheByStore.get(store);
  if (cached?.stateToken === stateToken) {
    return cached.cache;
  }
  const cache = createBasicAppearanceRenderCache();
  basicAppearanceRenderCacheByStore.set(store, { stateToken, cache });
  return cache;
};

type ProstheticTilePreparedBase = {
  hairDef: BasicAppearanceAccessoryDefinition | null;
  gradientDef: BasicAppearanceGradientDefinition | null;
  facialHairDef: BasicAppearanceAccessoryDefinition | null;
  earDef: BasicAppearanceAccessoryDefinition | null;
  hornDef: BasicAppearanceAccessoryDefinition | null;
  tailDef: BasicAppearanceAccessoryDefinition | null;
  wingDef: BasicAppearanceAccessoryDefinition | null;
  selection: PreviewSourceSelection;
  dirStates: Record<number, PreviewDirState>;
  suppressedPartsByDir: Record<number, Record<string, boolean>>;
  assembledPreviewCache: ProstheticAssembledPreviewCache;
  assetReferences: IconAssetReference[];
};

export type ProstheticAssembledPreviewCache = {
  preview: PreviewDirectionEntry[] | null;
};

export const resolveProstheticAssembledPreview = (
  cache: ProstheticAssembledPreviewCache,
  resolver: () => PreviewDirectionEntry[]
): PreviewDirectionEntry[] => {
  if (cache.preview !== null) {
    return cache.preview;
  }
  cache.preview = resolver();
  return cache.preview;
};

const appendPreviewGearAssetReferences = (
  target: IconAssetReference[],
  assets?: Array<GearOverlayAsset | IconAssetPayload>
) => {
  if (!Array.isArray(assets)) {
    return;
  }
  for (const entry of assets) {
    if ('asset' in entry) {
      target.push(entry.asset);
      if (entry.mask_asset) {
        target.push(entry.mask_asset);
      }
      for (const overlay of entry.overlays || []) {
        target.push(overlay.asset);
      }
      continue;
    }
    target.push(entry);
  }
};

const collectPreviewDirStateAssetReferences = (options: {
  previewDirStates: Record<number, PreviewDirState>;
  directions: Array<{ dir: number }>;
  stripReferenceMarkings?: boolean;
}) => {
  const { previewDirStates, directions, stripReferenceMarkings } = options;
  const references: IconAssetReference[] = [];
  for (const direction of directions) {
    const dirState = previewDirStates[direction.dir];
    if (!dirState) {
      continue;
    }
    if (dirState.bodyAsset) {
      references.push(dirState.bodyAsset);
    }
    Object.values(dirState.referencePartAssets || {}).forEach((asset) =>
      references.push(asset)
    );
    Object.values(dirState.referencePartHairAssets || {}).forEach((asset) =>
      references.push(asset)
    );
    if (!stripReferenceMarkings) {
      Object.values(dirState.referencePartMarkingAssets || {}).forEach(
        (asset) => references.push(asset)
      );
    }
    appendPreviewGearAssetReferences(
      references,
      dirState.overlayAssets as Array<GearOverlayAsset | IconAssetPayload>
    );
  }
  return references;
};

const appendAccessoryAssetReferences = (
  target: IconAssetReference[],
  def: BasicAppearanceAccessoryDefinition | null,
  directions: Array<{ dir: number }>,
  includeBack = false
) => {
  if (!def) {
    return;
  }
  for (const direction of directions) {
    for (const asset of def.assets?.[direction.dir] || []) {
      if (asset) {
        target.push(asset);
      }
    }
    if (!includeBack || !def.multi_dir) {
      continue;
    }
    for (const asset of def.back_assets?.[direction.dir] || []) {
      if (asset) {
        target.push(asset);
      }
    }
  }
};

const collectAppearanceOverlayAssetReferences = (options: {
  directions: Array<{ dir: number }>;
  hairDef: BasicAppearanceAccessoryDefinition | null;
  gradientDef: BasicAppearanceGradientDefinition | null;
  facialHairDef: BasicAppearanceAccessoryDefinition | null;
  earDef: BasicAppearanceAccessoryDefinition | null;
  hornDef: BasicAppearanceAccessoryDefinition | null;
  tailDef: BasicAppearanceAccessoryDefinition | null;
  wingDef: BasicAppearanceAccessoryDefinition | null;
}) => {
  const {
    directions,
    hairDef,
    gradientDef,
    facialHairDef,
    earDef,
    hornDef,
    tailDef,
    wingDef,
  } = options;
  const references: IconAssetReference[] = [];
  appendAccessoryAssetReferences(references, facialHairDef, directions);
  appendAccessoryAssetReferences(references, earDef, directions);
  appendAccessoryAssetReferences(references, hornDef, directions);
  appendAccessoryAssetReferences(references, tailDef, directions);
  appendAccessoryAssetReferences(references, wingDef, directions, true);
  if (hairDef) {
    for (const direction of directions) {
      const hairAssets = hairDef.assets?.[direction.dir] || [];
      if (hairAssets[0]) {
        references.push(hairAssets[0]);
      }
      if (hairDef.do_colouration && hairAssets[1]) {
        references.push(hairAssets[1]);
      }
      const gradientAsset = gradientDef?.assets?.[direction.dir];
      if (hairDef.do_colouration && gradientAsset) {
        references.push(gradientAsset);
      }
    }
  }
  return references;
};

const collectActiveBodyMarkingAssetReferences = (options: {
  definitions: Record<string, BodyMarkingDefinition>;
  markings: Record<string, BodyMarkingEntry>;
  order: string[];
  directions: Array<{ dir: number }>;
  digitigrade: boolean;
  suppressedPartsByDir?: Record<number, Record<string, boolean>>;
}) => {
  const {
    definitions,
    markings,
    order,
    directions,
    digitigrade,
    suppressedPartsByDir,
  } = options;
  const references: IconAssetReference[] = [];
  for (const markId of order) {
    const def = definitions[markId];
    const entry = markings[markId];
    if (!def || !entry) {
      continue;
    }
    for (const direction of directions) {
      const assetsByPart =
        (digitigrade && def.digitigrade_assets?.[direction.dir]) ||
        def.assets?.[direction.dir];
      for (const [partId, asset] of Object.entries(assetsByPart || {})) {
        const partState = entry[partId] as BodyMarkingPartState;
        if (
          asset &&
          !suppressedPartsByDir?.[direction.dir]?.[partId] &&
          isBodyMarkingPartEnabled(partState?.on)
        ) {
          references.push(asset);
        }
      }
    }
  }
  return references;
};

const hasActiveBodyMarkingParts = (options: {
  definitions: Record<string, BodyMarkingDefinition>;
  markings: Record<string, BodyMarkingEntry>;
  order: string[];
}): boolean => {
  const { definitions, markings, order } = options;
  return order.some((markId) => {
    const def = definitions[markId];
    const entry = markings[markId];
    if (!def || !entry) {
      return false;
    }
    const partIds =
      def.body_parts && def.body_parts.length
        ? def.body_parts
        : Object.keys(entry).filter((partId) => partId !== 'color');
    return partIds.some((partId) =>
      isBodyMarkingPartEnabled(
        (entry[partId] as BodyMarkingPartState | undefined)?.on
      )
    );
  });
};

const primePreviewAssetReferences = (options: {
  references: IconAssetReference[];
  canvasWidth: number;
  canvasHeight: number;
  signalAssetUpdate: () => void;
}) => {
  const { references, canvasWidth, canvasHeight, signalAssetUpdate } = options;
  for (const reference of references) {
    getPreviewGridFromAsset(
      reference,
      canvasWidth,
      canvasHeight,
      signalAssetUpdate,
      'visible'
    );
  }
};

const buildPendingTilePreview = (
  directions: Array<{ dir: number; label: string }>
): PreviewDirectionEntry[] =>
  directions.map((direction) => ({
    dir: direction.dir,
    label: direction.label,
    layers: [],
  }));

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
  const considerMap = (assets?: Record<string, IconAssetReference> | null) => {
    if (!assets) return;
    for (const asset of Object.values(assets)) {
      consider(
        resolveIconAssetReference(asset, payload?.preview_asset_registry)
      );
    }
  };
  for (const entry of payload?.preview_sources || []) {
    consider(
      resolveIconAssetReference(
        entry?.body_asset,
        payload?.preview_asset_registry
      )
    );
    considerMap(entry?.reference_part_assets);
    considerMap(entry?.reference_part_hair_assets);
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
    } = splitPreviewOverlayLayers(baseLayers);
    const suppressedPartsMap = suppressedPartsByDir?.[dirEntry.dir];
    const hasSuppressedParts =
      !!suppressedPartsMap && Object.keys(suppressedPartsMap).length > 0;
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
      if (partId === 'generic' && hasHiddenParts && Array.isArray(layer.grid)) {
        resolvedLayer = {
          ...layer,
          grid: buildMaskedGenericGrid(
            layer.grid as string[][],
            referenceMasks,
            hiddenPartsMap
          ),
        };
      }
      if (
        shouldRetainBodyMarkingBaseLayer(layer, isHiddenPart, isSuppressedPart)
      ) {
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
      layers: [...normalLayers, ...overlayLayers, ...after, ...priorityLayers],
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

const applyBloodReagentChange = (options: {
  bloodReagent: string;
  allowedReagents: string[];
  uiLocked: boolean;
  updateDraft: (
    updater: (state: BasicAppearanceState) => BasicAppearanceState
  ) => void;
}) => {
  const { bloodReagent, allowedReagents, uiLocked, updateDraft } = options;
  if (uiLocked || !allowedReagents.includes(bloodReagent)) {
    return;
  }
  updateDraft((state) => ({ ...state, blood_reagent: bloodReagent }));
};

const applyBiologicalGenderChange = (options: {
  biologicalGender: string;
  allowedGenders: string[];
  uiLocked: boolean;
  updateDraft: (
    updater: (state: BasicAppearanceState) => BasicAppearanceState
  ) => void;
}) => {
  const { biologicalGender, allowedGenders, uiLocked, updateDraft } = options;
  if (uiLocked || !allowedGenders.includes(biologicalGender)) {
    return;
  }
  updateDraft((state) => ({
    ...state,
    biological_gender: biologicalGender,
  }));
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
    case 'blood':
      return normalizeHex(appearanceState.blood_color) || '#a10808';
    case 'synth':
      return normalizeHex(appearanceState.synth_color) || '#ffffff';
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
      case 'blood':
        return { ...prev, blood_color: normalized };
      case 'synth':
        return { ...prev, synth_color: normalized };
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
  galleryType: BasicAppearanceGalleryType,
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
  galleryType: BasicAppearanceGalleryType,
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
  galleryType: BasicAppearanceGalleryType;
  id: string | null;
  setStyle: (targetType: BasicAppearanceType, styleId: string | null) => void;
  setColorTarget: (target: BasicAppearanceColorTarget | null) => void;
}) => {
  const { galleryType, id, setStyle, setColorTarget } = options;
  const normalized = normalizeBasicAppearanceGalleryStyleId(id);
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
  galleryType: BasicAppearanceGalleryType;
  payloadSignature: string | null;
  tileDirections: DirectionEntry[];
  tileDirectionsSignature: string;
  canvasWidth: number;
  canvasHeight: number;
  activePreviewRevision?: number | null;
  previewSourceSignature: string;
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
  facialHairDef: BasicAppearanceAccessoryDefinition | null;
  earDef: BasicAppearanceAccessoryDefinition | null;
  hornDef: BasicAppearanceAccessoryDefinition | null;
  tailDef: BasicAppearanceAccessoryDefinition | null;
  wingDef: BasicAppearanceAccessoryDefinition | null;
  previewDirStates: Record<number, PreviewDirState>;
  tilePreviewCache: Record<
    string,
    { sig: string; previews: BasicTilePreviewEntry[] }
  >;
  tileBasePreviewCache: TileBasePreviewCache;
  galleryMannequinPreviewByDir: Record<number, PreviewDirectionEntry>;
  galleryBaseIncludesSpeciesTail: boolean;
  galleryBaseHiddenPartsSignature: string;
  galleryAppearanceGridContextByDir: Record<number, GalleryAppearanceGridEntry>;
  galleryAppearanceContextSignature: string;
  previewBaseBodyColor: string | null;
  previewBaseEyeColor: string | null;
  bodyColorExcludedParts: Set<string> | null;
  bodyColorBlendMode: number | null;
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
  galleryType: BasicAppearanceGalleryType,
  tailStyles: BasicAppearanceAccessoryDefinition[] | undefined,
  defId: string,
  selectedTailDef: BasicAppearanceAccessoryDefinition | null
): TailTileInfo => {
  const tailDef =
    galleryType === 'tail'
      ? resolveSelectedDef(
          tailStyles,
          normalizeBasicAppearanceGalleryStyleId(defId)
        )
      : selectedTailDef;
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
  previewSourceSignature: string;
  appearanceState: BasicAppearanceState;
  galleryContextSignature: string;
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
    previewSourceSignature,
    appearanceState,
    galleryContextSignature,
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
    previewSourceSignature,
    appearanceState.digitigrade ? 'd' : 'p',
    galleryContextSignature,
    `${assetRevision}`,
    bodyMarkingsSignature,
    previewTargetBodyColor || 'bc',
    previewTargetEyeColor || 'ec',
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
  previewSourceSignature: string;
  appearanceState: BasicAppearanceState;
  assetRevision: number;
  bodyMarkingsContextSignature: string;
  tailHiddenParts: string[];
  includeSpeciesTail: boolean;
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
    previewSourceSignature,
    appearanceState,
    assetRevision,
    bodyMarkingsContextSignature,
    tailHiddenParts,
    includeSpeciesTail,
    stripReferenceMarkings,
  } = options;
  return [
    tileDirectionsSignature,
    `${canvasWidth}x${canvasHeight}`,
    `${activePreviewRevision || 0}`,
    previewSourceSignature,
    appearanceState.digitigrade ? 'd' : 'p',
    `${assetRevision}`,
    bodyMarkingsContextSignature,
    tailHiddenParts.length ? tailHiddenParts.join('|') : 'no-hide',
    includeSpeciesTail ? 'species-tail' : 'no-species-tail',
    stripReferenceMarkings ? 's1' : 's0',
  ].join('::');
};

export const buildBasicTileBaseRenderSignature = (options: {
  payloadSignature: string | null;
  baseColorSignature: string;
  dir: number;
  hairColor: string | null;
  bodyColorBlendMode: number | null;
  bodyColorExcludedParts: Set<string> | null;
}): string => {
  const {
    payloadSignature,
    baseColorSignature,
    dir,
    hairColor,
    bodyColorBlendMode,
    bodyColorExcludedParts,
  } = options;
  const excludedPartsSignature = bodyColorExcludedParts?.size
    ? Array.from(bodyColorExcludedParts).sort().join('|')
    : 'none';
  return [
    'basic-tile-base-v1',
    payloadSignature || 'payload',
    baseColorSignature,
    `dir:${dir}`,
    `hair:${normalizeHex(hairColor) || ''}`,
    `blend:${bodyColorBlendMode ?? 'relative'}`,
    `excluded:${excludedPartsSignature}`,
  ].join('::');
};

type TileBasePreviewOptions = {
  cacheKey: string;
  galleryType: BasicAppearanceGalleryType;
  definitionId: string;
  selectedTailStyle: string | null;
  tailHiddenParts: string[];
  previewDirStates: Record<number, PreviewDirState>;
  tileDirections: DirectionEntry[];
  tileDirectionsSignature: string;
  canvasWidth: number;
  canvasHeight: number;
  activePreviewRevision?: number | null;
  previewSourceSignature: string;
  appearanceState: BasicAppearanceState;
  assetRevision: number;
  bodyMarkingsContextSignature: string;
  previewBaseBodyColor: string | null;
  previewTargetBodyColor: string | null;
  previewBaseEyeColor: string | null;
  previewTargetEyeColor: string | null;
  bodyColorExcludedParts: Set<string> | null;
  bodyColorBlendMode: number | null;
  applyBodyMarkings: (
    preview: PreviewDirectionEntry[],
    suppressedPartsByDir?: Record<number, Record<string, boolean>>
  ) => PreviewDirectionEntry[];
  signalAssetUpdate: () => void;
  galleryMannequinPreviewByDir: Record<number, PreviewDirectionEntry>;
  galleryBaseIncludesSpeciesTail: boolean;
  galleryBaseHiddenPartsSignature: string;
  tileBasePreviewCache: TileBasePreviewCache;
  stripReferenceMarkings?: boolean;
};

const buildTileBasePreviewByDir = (
  options: TileBasePreviewOptions
): Record<number, PreviewDirectionEntry> => {
  const {
    cacheKey,
    galleryType,
    definitionId,
    selectedTailStyle,
    tailHiddenParts,
    previewDirStates,
    tileDirections,
    tileDirectionsSignature,
    canvasWidth,
    canvasHeight,
    activePreviewRevision,
    previewSourceSignature,
    appearanceState,
    assetRevision,
    bodyMarkingsContextSignature,
    previewBaseBodyColor,
    previewTargetBodyColor,
    previewBaseEyeColor,
    previewTargetEyeColor,
    bodyColorExcludedParts,
    bodyColorBlendMode,
    applyBodyMarkings,
    signalAssetUpdate,
    galleryMannequinPreviewByDir,
    galleryBaseIncludesSpeciesTail,
    galleryBaseHiddenPartsSignature,
    tileBasePreviewCache,
    stripReferenceMarkings,
  } = options;
  const includeSpeciesTail = shouldIncludeSpeciesTailInGalleryTile(
    galleryType,
    definitionId,
    selectedTailStyle
  );
  const hiddenPartsSignature = tailHiddenParts.length
    ? tailHiddenParts.join('|')
    : 'no-hide';
  if (
    includeSpeciesTail === galleryBaseIncludesSpeciesTail &&
    hiddenPartsSignature === galleryBaseHiddenPartsSignature
  ) {
    return galleryMannequinPreviewByDir;
  }
  const baseSignature = buildTileBasePreviewSignature({
    tileDirectionsSignature,
    canvasWidth,
    canvasHeight,
    activePreviewRevision,
    previewSourceSignature,
    appearanceState,
    assetRevision,
    bodyMarkingsContextSignature,
    tailHiddenParts,
    includeSpeciesTail,
    stripReferenceMarkings,
  });
  const cachedBase = tileBasePreviewCache[cacheKey];
  let basePreview =
    cachedBase?.sig === baseSignature ? cachedBase.preview : null;
  if (!basePreview) {
    const previewDirStatesForTile = resolveGalleryTilePreviewStates(
      mergeHiddenBodyPartsInPreviewStates(previewDirStates, tailHiddenParts),
      galleryType,
      definitionId,
      selectedTailStyle
    );
    const suppressedPartsByDir = buildSuppressedMarkingPartsByDir(
      previewDirStatesForTile
    );
    const rawBasePreview = includeSpeciesTail
      ? buildDesignerPreviewDirs(
          previewDirStatesForTile,
          tileDirections,
          {},
          canvasWidth,
          canvasHeight,
          tileDirections[0]?.dir || 0,
          'generic',
          null,
          null,
          undefined,
          undefined,
          undefined,
          false,
          false,
          false,
          signalAssetUpdate,
          stripReferenceMarkings
        )
      : buildBasePreviewDirs(
          previewDirStatesForTile,
          tileDirections,
          {},
          canvasWidth,
          canvasHeight,
          signalAssetUpdate,
          stripReferenceMarkings
        );
    basePreview = applyBodyMarkings(rawBasePreview, suppressedPartsByDir);
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
    bodyColorBlendMode,
    previewBaseEyeColor,
    previewTargetEyeColor,
    previewTargetBodyColor,
    appearanceState.hair_color
  );
  return coloredPreview.reduce(
    (acc, entry) => {
      acc[entry.dir] = entry;
      return acc;
    },
    {} as Record<number, PreviewDirectionEntry>
  );
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

const buildGradientTileGrid = (options: {
  gradientDef: BasicAppearanceGradientDefinition | null;
  hairDef: BasicAppearanceAccessoryDefinition | null;
  dir: number;
  canvasWidth: number;
  canvasHeight: number;
  appearanceState: BasicAppearanceState;
  signalAssetUpdate: () => void;
}): string[][] | null => {
  const {
    gradientDef,
    hairDef,
    dir,
    canvasWidth,
    canvasHeight,
    appearanceState,
    signalAssetUpdate,
  } = options;
  if (hairDef) {
    return buildHairGridWithGradient({
      hairDef,
      gradientDef,
      dir,
      canvasWidth,
      canvasHeight,
      hairColor: appearanceState.hair_color,
      gradientColor: appearanceState.hair_gradient_color,
      signalAssetUpdate,
    });
  }
  if (!gradientDef) {
    return null;
  }
  const gradPayload = gradientDef.assets?.[dir];
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

const buildWingTileGrids = (options: {
  wingDef: BasicAppearanceAccessoryDefinition | null;
  dir: number;
  canvasWidth: number;
  canvasHeight: number;
  appearanceState: BasicAppearanceState;
  signalAssetUpdate: () => void;
}): Pick<GalleryAppearanceGridEntry, 'wingGrid' | 'wingBackGrid'> => {
  const {
    wingDef,
    dir,
    canvasWidth,
    canvasHeight,
    appearanceState,
    signalAssetUpdate,
  } = options;
  if (!wingDef) {
    return { wingGrid: null, wingBackGrid: null };
  }
  const wingGrid = buildAccessoryTileGrid({
    def: wingDef,
    dir,
    canvasWidth,
    canvasHeight,
    colors: appearanceState.wing_colors,
    signalAssetUpdate,
  });
  let wingBackGrid: string[][] | null = null;
  if (wingDef.multi_dir && wingDef.back_assets) {
    const backAssets = wingDef.back_assets?.[dir];
    if (backAssets && backAssets.length) {
      const backDef: BasicAppearanceAccessoryDefinition = {
        ...wingDef,
        assets: { [dir]: backAssets } as any,
      };
      wingBackGrid = buildAccessoryTileGrid({
        def: backDef,
        dir,
        canvasWidth,
        canvasHeight,
        colors: appearanceState.wing_colors,
        signalAssetUpdate,
      });
    }
  }
  return { wingGrid, wingBackGrid };
};

const buildGalleryAppearanceGridEntry = (options: {
  galleryType: BasicAppearanceGalleryType;
  dir: number;
  canvasWidth: number;
  canvasHeight: number;
  appearanceState: BasicAppearanceState;
  hairDef: BasicAppearanceAccessoryDefinition | null;
  gradientDef: BasicAppearanceGradientDefinition | null;
  facialHairDef: BasicAppearanceAccessoryDefinition | null;
  earDef: BasicAppearanceAccessoryDefinition | null;
  hornDef: BasicAppearanceAccessoryDefinition | null;
  tailDef: BasicAppearanceAccessoryDefinition | null;
  wingDef: BasicAppearanceAccessoryDefinition | null;
  signalAssetUpdate: () => void;
}): GalleryAppearanceGridEntry => {
  const {
    galleryType,
    dir,
    canvasWidth,
    canvasHeight,
    appearanceState,
    hairDef,
    gradientDef,
    facialHairDef,
    earDef,
    hornDef,
    tailDef,
    wingDef,
    signalAssetUpdate,
  } = options;
  const retainHair = galleryType !== 'hair' && galleryType !== 'gradient';
  const hairGrid =
    retainHair && hairDef
      ? buildHairGridWithGradient({
          hairDef,
          gradientDef,
          dir,
          canvasWidth,
          canvasHeight,
          hairColor: appearanceState.hair_color,
          gradientColor: appearanceState.hair_gradient_color,
          signalAssetUpdate,
        })
      : null;
  const facialHairGrid =
    galleryType === 'facial_hair'
      ? null
      : buildAccessoryTileGrid({
          def: facialHairDef,
          dir,
          canvasWidth,
          canvasHeight,
          colors: [appearanceState.facial_hair_color],
          signalAssetUpdate,
        });
  const earGrid =
    galleryType === 'ears'
      ? null
      : buildAccessoryTileGrid({
          def: earDef,
          dir,
          canvasWidth,
          canvasHeight,
          colors: appearanceState.ear_colors,
          signalAssetUpdate,
        });
  const hornGrid =
    galleryType === 'horns'
      ? null
      : buildAccessoryTileGrid({
          def: hornDef,
          dir,
          canvasWidth,
          canvasHeight,
          colors: appearanceState.horn_colors,
          signalAssetUpdate,
        });
  const tailGrid =
    galleryType === 'tail'
      ? null
      : buildAccessoryTileGrid({
          def: tailDef,
          dir,
          canvasWidth,
          canvasHeight,
          colors: appearanceState.tail_colors,
          signalAssetUpdate,
        });
  const { wingGrid, wingBackGrid } =
    galleryType === 'wings'
      ? { wingGrid: null, wingBackGrid: null }
      : buildWingTileGrids({
          wingDef,
          dir,
          canvasWidth,
          canvasHeight,
          appearanceState,
          signalAssetUpdate,
        });
  return {
    hairGrid,
    facialHairGrid,
    earGrid,
    hornGrid,
    tailGrid,
    wingGrid,
    wingBackGrid,
  };
};

const resolveGalleryAppearanceGridContext = (options: {
  cache: GalleryAppearanceGridContextCache;
  signature: string;
  galleryType: BasicAppearanceGalleryType;
  tileDirections: DirectionEntry[];
  canvasWidth: number;
  canvasHeight: number;
  appearanceState: BasicAppearanceState;
  hairDef: BasicAppearanceAccessoryDefinition | null;
  gradientDef: BasicAppearanceGradientDefinition | null;
  facialHairDef: BasicAppearanceAccessoryDefinition | null;
  earDef: BasicAppearanceAccessoryDefinition | null;
  hornDef: BasicAppearanceAccessoryDefinition | null;
  tailDef: BasicAppearanceAccessoryDefinition | null;
  wingDef: BasicAppearanceAccessoryDefinition | null;
  signalAssetUpdate: () => void;
}): Record<number, GalleryAppearanceGridEntry> => {
  const {
    cache,
    signature,
    galleryType,
    tileDirections,
    canvasWidth,
    canvasHeight,
    appearanceState,
    hairDef,
    gradientDef,
    facialHairDef,
    earDef,
    hornDef,
    tailDef,
    wingDef,
    signalAssetUpdate,
  } = options;
  if (cache.signature === signature) {
    return cache.byDir;
  }
  const byDir: Record<number, GalleryAppearanceGridEntry> = {};
  for (const direction of tileDirections) {
    byDir[direction.dir] = buildGalleryAppearanceGridEntry({
      galleryType,
      dir: direction.dir,
      canvasWidth,
      canvasHeight,
      appearanceState,
      hairDef,
      gradientDef,
      facialHairDef,
      earDef,
      hornDef,
      tailDef,
      wingDef,
      signalAssetUpdate,
    });
  }
  cache.signature = signature;
  cache.byDir = byDir;
  return byDir;
};

type TileAppearanceGrids = {
  headGrid: string[][] | null;
  tailGrid: string[][] | null;
  wingGrid: string[][] | null;
  wingBackGrid: string[][] | null;
};

const buildTileAppearanceGrids = (options: {
  defId: string;
  galleryType: BasicAppearanceGalleryType;
  dir: number;
  canvasWidth: number;
  canvasHeight: number;
  appearanceState: BasicAppearanceState;
  context: GalleryAppearanceGridEntry;
  hairStyles?: BasicAppearanceAccessoryDefinition[];
  gradientStyles?: BasicAppearanceGradientDefinition[];
  facialHairStyles?: BasicAppearanceAccessoryDefinition[];
  earStyles?: BasicAppearanceAccessoryDefinition[];
  wingStyles?: BasicAppearanceAccessoryDefinition[];
  hairDef: BasicAppearanceAccessoryDefinition | null;
  gradientDef: BasicAppearanceGradientDefinition | null;
  tailDef: BasicAppearanceAccessoryDefinition | null;
  signalAssetUpdate: () => void;
}): TileAppearanceGrids => {
  const {
    defId,
    galleryType,
    dir,
    canvasWidth,
    canvasHeight,
    appearanceState,
    context,
    hairStyles,
    gradientStyles,
    facialHairStyles,
    earStyles,
    wingStyles,
    hairDef,
    gradientDef,
    tailDef,
    signalAssetUpdate,
  } = options;
  const candidateId = normalizeBasicAppearanceGalleryStyleId(defId);
  let hairGrid = context.hairGrid;
  let facialHairGrid = context.facialHairGrid;
  let earGrid = context.earGrid;
  let hornGrid = context.hornGrid;
  let tailGrid = context.tailGrid;
  let wingGrid = context.wingGrid;
  let wingBackGrid = context.wingBackGrid;
  switch (galleryType) {
    case 'hair': {
      const candidate = resolveSelectedDef(hairStyles, candidateId);
      hairGrid = candidate
        ? buildHairGridWithGradient({
            hairDef: candidate,
            gradientDef,
            dir,
            canvasWidth,
            canvasHeight,
            hairColor: appearanceState.hair_color,
            gradientColor: appearanceState.hair_gradient_color,
            signalAssetUpdate,
          })
        : null;
      break;
    }
    case 'gradient': {
      hairGrid = buildGradientTileGrid({
        gradientDef: resolveSelectedDef(gradientStyles, candidateId),
        hairDef,
        dir,
        canvasWidth,
        canvasHeight,
        appearanceState,
        signalAssetUpdate,
      });
      break;
    }
    case 'facial_hair':
      facialHairGrid = buildAccessoryTileGrid({
        def: resolveSelectedDef(facialHairStyles, candidateId),
        dir,
        canvasWidth,
        canvasHeight,
        colors: [appearanceState.facial_hair_color],
        signalAssetUpdate,
      });
      break;
    case 'ears':
      earGrid = buildAccessoryTileGrid({
        def: resolveSelectedDef(earStyles, candidateId),
        dir,
        canvasWidth,
        canvasHeight,
        colors: appearanceState.ear_colors,
        signalAssetUpdate,
      });
      break;
    case 'horns':
      hornGrid = buildAccessoryTileGrid({
        def: resolveSelectedDef(earStyles, candidateId),
        dir,
        canvasWidth,
        canvasHeight,
        colors: appearanceState.horn_colors,
        signalAssetUpdate,
      });
      break;
    case 'tail':
      tailGrid = buildAccessoryTileGrid({
        def: tailDef,
        dir,
        canvasWidth,
        canvasHeight,
        colors: appearanceState.tail_colors,
        signalAssetUpdate,
      });
      break;
    case 'wings': {
      const wingGrids = buildWingTileGrids({
        wingDef: resolveSelectedDef(wingStyles, candidateId),
        dir,
        canvasWidth,
        canvasHeight,
        appearanceState,
        signalAssetUpdate,
      });
      wingGrid = wingGrids.wingGrid;
      wingBackGrid = wingGrids.wingBackGrid;
      break;
    }
  }
  let headGrid: string[][] | null = null;
  headGrid = mergeAccessoryGrid(headGrid, facialHairGrid);
  headGrid = mergeAccessoryGrid(headGrid, hairGrid);
  headGrid = mergeAccessoryGrid(headGrid, earGrid);
  headGrid = mergeAccessoryGrid(headGrid, hornGrid);
  return { headGrid, tailGrid, wingGrid, wingBackGrid };
};

const buildTilePreviewEntries = (
  options: TilePreviewOptions
): BasicTilePreviewEntry[] => {
  const {
    def,
    galleryType,
    payloadSignature,
    tileDirections,
    tileDirectionsSignature,
    canvasWidth,
    canvasHeight,
    activePreviewRevision,
    previewSourceSignature,
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
    facialHairDef,
    earDef,
    hornDef,
    tailDef,
    wingDef,
    previewDirStates,
    tilePreviewCache,
    tileBasePreviewCache,
    galleryMannequinPreviewByDir,
    galleryBaseIncludesSpeciesTail,
    galleryBaseHiddenPartsSignature,
    galleryAppearanceGridContextByDir,
    galleryAppearanceContextSignature,
    previewBaseBodyColor,
    previewBaseEyeColor,
    bodyColorExcludedParts,
    bodyColorBlendMode,
    applyBodyMarkings,
    signalAssetUpdate,
    stripReferenceMarkings,
  } = options;
  const tailInfo = resolveTailTileInfo(
    galleryType,
    tailStyles,
    def.id,
    tailDef
  );
  const includeSpeciesTail = shouldIncludeSpeciesTailInGalleryTile(
    galleryType,
    def.id,
    appearanceState.tail_style
  );
  const defKey = `${galleryType}:${def.id}`;
  const sig = buildTilePreviewSignature({
    tileDirectionsSignature,
    canvasWidth,
    canvasHeight,
    activePreviewRevision,
    previewSourceSignature,
    appearanceState,
    galleryContextSignature: galleryAppearanceContextSignature,
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
    previewSourceSignature,
    appearanceState,
    assetRevision,
    bodyMarkingsContextSignature,
    tailHiddenParts: tailInfo.hiddenParts,
    includeSpeciesTail,
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
    definitionId: def.id,
    selectedTailStyle: appearanceState.tail_style,
    tailHiddenParts: tailInfo.hiddenParts,
    previewDirStates,
    tileDirections,
    tileDirectionsSignature,
    canvasWidth,
    canvasHeight,
    activePreviewRevision,
    previewSourceSignature,
    appearanceState,
    assetRevision,
    bodyMarkingsContextSignature,
    previewBaseBodyColor,
    previewTargetBodyColor,
    previewBaseEyeColor,
    previewTargetEyeColor,
    bodyColorExcludedParts,
    bodyColorBlendMode,
    applyBodyMarkings,
    signalAssetUpdate,
    galleryMannequinPreviewByDir,
    galleryBaseIncludesSpeciesTail,
    galleryBaseHiddenPartsSignature,
    tileBasePreviewCache,
    stripReferenceMarkings,
  });

  const previews = tileDirections.map((entry) => {
    const context = galleryAppearanceGridContextByDir[entry.dir] || {
      hairGrid: null,
      facialHairGrid: null,
      earGrid: null,
      hornGrid: null,
      tailGrid: null,
      wingGrid: null,
      wingBackGrid: null,
    };
    const tileGrids = buildTileAppearanceGrids({
      defId: def.id,
      galleryType,
      dir: entry.dir,
      canvasWidth,
      canvasHeight,
      appearanceState,
      context,
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
    const { base: baseLayers, priority: priorityLayers } =
      splitPriorityBodyMarkingLayers(
        tileBasePreviewByDir[entry.dir]?.layers || []
      );
    const underlayLayers = tileGrids.wingBackGrid
      ? [
          {
            type: 'overlay',
            key: `tile-${galleryType}-${def.id}-${entry.dir}-back`,
            grid: tileGrids.wingBackGrid,
          },
        ]
      : [];
    const overlayLayers: PreviewLayerEntry[] = [];
    if (tileGrids.tailGrid) {
      overlayLayers.push({
        type: 'overlay',
        key: `tile-${galleryType}-${def.id}-${entry.dir}-tail`,
        grid: tileGrids.tailGrid,
      });
    }
    if (tileGrids.headGrid) {
      overlayLayers.push({
        type: 'overlay',
        key: `tile-${galleryType}-${def.id}-${entry.dir}-head`,
        grid: tileGrids.headGrid,
      });
    }
    if (tileGrids.wingGrid) {
      overlayLayers.push({
        type: 'overlay',
        key: `tile-${galleryType}-${def.id}-${entry.dir}-wing`,
        grid: tileGrids.wingGrid,
      });
    }
    overlayLayers.push(...priorityLayers);
    return {
      dir: entry.dir,
      label: entry.label,
      layers: [],
      baseLayers,
      underlayLayers,
      overlayLayers,
      baseSignature: buildBasicTileBaseRenderSignature({
        payloadSignature,
        baseColorSignature,
        dir: entry.dir,
        hairColor: appearanceState.hair_color,
        bodyColorBlendMode,
        bodyColorExcludedParts,
      }),
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
  hairDef: BasicAppearanceAccessoryDefinition | null;
  gradientDef: BasicAppearanceGradientDefinition | null;
  facialHairDef: BasicAppearanceAccessoryDefinition | null;
  earDef: BasicAppearanceAccessoryDefinition | null;
  hornDef: BasicAppearanceAccessoryDefinition | null;
  tailDef: BasicAppearanceAccessoryDefinition | null;
  wingDef: BasicAppearanceAccessoryDefinition | null;
  showEquipment: boolean;
  showJobGear: boolean;
  showLoadoutGear: boolean;
  signalAssetUpdate: () => void;
};

type GearOverlayLayerOptions = {
  dirState: PreviewDirState;
  canvasWidth: number;
  canvasHeight: number;
  showEquipment: boolean;
  showJobGear: boolean;
  showLoadoutGear: boolean;
  signalAssetUpdate: () => void;
};

type GearOverlayLayerGroups = {
  baseOverlayLayers: OrderedOverlayLayer[];
  equipmentLayers: OrderedOverlayLayer[];
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
    showEquipment,
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
  const higherPrioritySlots = new Set(
    [...jobLayers, ...loadoutLayers]
      .map((entry) => entry.slot)
      .filter((slot): slot is string => !!slot)
  );
  const equipmentLayers = showEquipment
    ? buildOrderedOverlayLayers(
        (dirState.gearEquipmentOverlayAssets as (
          | GearOverlayAsset
          | IconAssetPayload
        )[]) || [],
        canvasWidth,
        canvasHeight,
        'equipment',
        signalAssetUpdate,
        baseOverlayLayers.length + jobLayers.length + loadoutLayers.length
      ).filter((entry) => !entry.slot || !higherPrioritySlots.has(entry.slot))
    : [];
  return {
    baseOverlayLayers,
    equipmentLayers,
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
  referenceParts: Record<string, string[][]> | null;
  hiddenLegParts: string[];
}): PreviewLayerEntry[] => {
  const { merged, dir, hideShoes, referenceParts, hiddenLegParts } = options;
  const overlayEntries: PreviewLayerEntry[] = [];
  merged.forEach((entry, index) => {
    if (hideShoes && entry.slot === 'shoes') {
      return;
    }
    const grid = cloneGridData(entry.grid);
    let rasterIdentity = entry.rasterIdentity;
    if (referenceParts && entry.slot && TAUR_CLOTHING_SLOTS.has(entry.slot)) {
      maskGridForHiddenLegParts(grid, referenceParts, hiddenLegParts);
      rasterIdentity = undefined;
    }
    if (!gridHasPixels(grid)) {
      return;
    }
    overlayEntries.push({
      type: 'overlay',
      key: `overlay_basic_${dir}_${entry.source}_${entry.slot || index}_${index}`,
      label:
        entry.source === 'equipment'
          ? 'Equipment'
          : entry.source === 'job'
            ? 'Job Gear'
            : entry.source === 'loadout'
              ? 'Loadout Gear'
              : 'Overlay',
      source:
        entry.source === 'base'
          ? entry.slot === 'eyes'
            ? 'eyes'
            : entry.slot && BODY_COLOR_OVERLAY_SLOTS.has(entry.slot)
              ? entry.slot
              : undefined
          : entry.source,
      grid,
      opacity: 1,
      rasterIdentity,
      rasterDependency:
        entry.slot === 'species_tail'
          ? 'body-relative'
          : entry.slot === 'prosthetic_tail' || entry.slot === 'prosthetic_wing'
            ? 'body-direct'
            : 'stable',
      rasterShareable:
        !!rasterIdentity && !entry.slot?.startsWith('prosthetic_'),
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
    hairDef,
    gradientDef,
    facialHairDef,
    earDef,
    hornDef,
    tailDef,
    wingDef,
    showEquipment,
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
  const { baseOverlayLayers, equipmentLayers, loadoutLayers, jobLayers } =
    buildGearOverlayLayers({
      dirState,
      canvasWidth,
      canvasHeight,
      showEquipment,
      showJobGear,
      showLoadoutGear,
      signalAssetUpdate,
    });
  const resolvedBaseOverlayLayers =
    tailDef && tailDef.id !== 'Normal'
      ? baseOverlayLayers.filter((entry) => entry.slot !== 'species_tail')
      : baseOverlayLayers;
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
    [...resolvedBaseOverlayLayers, ...appearanceLayers],
    equipmentLayers,
    jobLayers,
    loadoutLayers
  );
  return buildOverlayEntriesFromMergedLayers({
    merged,
    dir,
    hideShoes,
    referenceParts,
    hiddenLegParts,
  });
};

const resolveGalleryType = (
  type: BasicAppearanceType
): BasicAppearanceGalleryType =>
  type === 'eyes' || type === 'body' || type === 'prosthetics' ? 'hair' : type;

type PreviewSourceSelection = {
  previewUsesAltSources: boolean;
  rawPreviewSources?: BasicAppearancePayload['preview_sources'];
  activePreviewSources?: BasicAppearancePayload['preview_sources'];
  activePreviewAssetRegistry?: IconAssetRegistry | null;
  activePreviewRevision?: number | null;
  previewSourceSignature: string;
};

const resolvePreviewSourceSelection = (
  basicPayload: BasicAppearancePayload | null | undefined,
  appearanceState: BasicAppearanceState,
  speciesPreviewSources?: BasicAppearancePayload['preview_sources'] | null,
  speciesPreviewSignature = '',
  options?: ProstheticPreviewTransformOptions
): PreviewSourceSelection => {
  if (speciesPreviewSources?.length) {
    const transformedSources = applyProstheticsToPreviewSources(
      speciesPreviewSources,
      appearanceState,
      basicPayload?.prosthetic_context,
      undefined,
      options
    );
    return {
      previewUsesAltSources: false,
      rawPreviewSources: speciesPreviewSources,
      activePreviewSources: transformedSources || undefined,
      activePreviewAssetRegistry: null,
      activePreviewRevision: basicPayload?.preview_revision || 1,
      previewSourceSignature: speciesPreviewSignature || 'species',
    };
  }
  const basicSelection = resolveBasicPreviewSourceSelection(
    basicPayload,
    appearanceState.digitigrade,
    undefined,
    appearanceState.biological_gender
  );
  const transformedSources = applyProstheticsToPreviewSources(
    basicSelection.sources,
    appearanceState,
    basicPayload?.prosthetic_context,
    undefined,
    options
  );
  return {
    previewUsesAltSources: basicSelection.usesAltSources,
    rawPreviewSources: basicSelection.sources || undefined,
    activePreviewSources: transformedSources || undefined,
    activePreviewAssetRegistry: basicSelection.assetRegistry,
    activePreviewRevision: basicSelection.revision,
    previewSourceSignature: basicSelection.sourceKey,
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

export const resolvePreviewDirStates = (options: {
  cache?: PreviewDirStatesCache;
  activePreviewSources?: BasicAppearancePayload['preview_sources'];
  activePreviewAssetRegistry?: IconAssetRegistry | null;
  activePreviewRevision?: number | null;
  activeDirKey: number;
  activeDir: string;
  canvasWidth: number;
  canvasHeight: number;
}): Record<number, PreviewDirState> => {
  const {
    cache,
    activePreviewSources,
    activePreviewAssetRegistry,
    activePreviewRevision,
    activeDirKey,
    activeDir,
    canvasWidth,
    canvasHeight,
  } = options;
  if (!activePreviewSources) {
    return {} as Record<number, PreviewDirState>;
  }
  if (
    cache &&
    cache.sources === activePreviewSources &&
    cache.assetRegistry === activePreviewAssetRegistry &&
    cache.revision === activePreviewRevision &&
    cache.activeDirKey === activeDirKey &&
    cache.activeDir === activeDir &&
    cache.canvasWidth === canvasWidth &&
    cache.canvasHeight === canvasHeight
  ) {
    return cache.dirs;
  }
  const dirs = updatePreviewStateFromPayload(
    { revision: 0, lastDiffSeq: 0, dirs: {} },
    {
      data: {
        preview_sources: activePreviewSources,
        preview_asset_registry: activePreviewAssetRegistry || undefined,
        preview_revision: activePreviewRevision || 0,
        active_dir_key: activeDirKey,
        active_dir: activeDir,
        grid: [],
      } as any,
      sessionKey: 'basic-appearance',
      activePartKey: 'generic',
      canvasWidth,
      canvasHeight,
      canvasGrid: null,
    }
  ).dirs;
  if (cache) {
    cache.sources = activePreviewSources;
    cache.assetRegistry = activePreviewAssetRegistry;
    cache.revision = activePreviewRevision;
    cache.activeDirKey = activeDirKey;
    cache.activeDir = activeDir;
    cache.canvasWidth = canvasWidth;
    cache.canvasHeight = canvasHeight;
    cache.dirs = dirs;
  }
  return dirs;
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
  previewSourceSignature: string;
  previewUsesAltSources: boolean;
  canvasWidth: number;
  canvasHeight: number;
  tileDirectionsSignature: string;
  directionSignature: string;
  bodyMarkingsContextSignature: string;
  galleryTailContextSignature: string;
  stripReferenceMarkings?: boolean;
};

const buildGalleryBasePreviewSignature = (
  options: GalleryBasePreviewSignatureOptions
): string => {
  const {
    payloadSignature,
    activePreviewRevision,
    previewSourceSignature,
    previewUsesAltSources,
    canvasWidth,
    canvasHeight,
    tileDirectionsSignature,
    directionSignature,
    bodyMarkingsContextSignature,
    galleryTailContextSignature,
    stripReferenceMarkings,
  } = options;
  return [
    payloadSignature || 'base',
    activePreviewRevision || 0,
    previewSourceSignature,
    previewUsesAltSources ? 'alt' : 'base',
    `${canvasWidth}x${canvasHeight}`,
    tileDirectionsSignature,
    directionSignature,
    bodyMarkingsContextSignature,
    galleryTailContextSignature,
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
  includeSpeciesTail: boolean;
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
    includeSpeciesTail,
    applyBodyMarkings,
    suppressedPartsByDir,
    signalAssetUpdate,
    stripReferenceMarkings,
  } = options;
  let preview = cache.preview;
  let previewByDir = cache.previewByDir;
  if (cache.signature !== signature) {
    const galleryMannequinPreviewRaw = activePreviewSources
      ? includeSpeciesTail
        ? buildDesignerPreviewDirs(
            previewDirStates,
            tileDirections,
            {},
            canvasWidth,
            canvasHeight,
            tileDirections[0]?.dir || 0,
            'generic',
            null,
            null,
            undefined,
            undefined,
            undefined,
            false,
            false,
            false,
            signalAssetUpdate,
            stripReferenceMarkings
          )
        : buildBasePreviewDirs(
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
  showEquipment: boolean;
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
    showEquipment,
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
    showEquipment,
    signalAssetUpdate,
    stripReferenceMarkings
  );
};

export const resolveCachedBasePreviewRaw = (
  cache: BasePreviewRawCache,
  signature: string,
  resolver: () => PreviewDirectionEntry[]
): PreviewDirectionEntry[] => {
  if (cache.signature === signature) {
    return cache.preview;
  }
  const preview = resolver();
  cache.signature = signature;
  cache.preview = preview;
  return preview;
};

type BasePreviewSignatureOptions = {
  payloadSignature: string | null;
  activePreviewRevision?: number | null;
  previewSourceSignature: string;
  previewUsesAltSources: boolean;
  digitigrade: boolean;
  previewTransformSignature: string;
  canvasWidth: number;
  canvasHeight: number;
  tailHiddenSignature: string;
  directionSignature: string;
  activeDirKey: number;
  activeDir: string;
  partPrioritySignature: string;
  partReplacementSignature: string;
  partPaintSignature: string;
  showEquipment: boolean;
  showJobGear: boolean;
  showLoadoutGear: boolean;
};

export const buildBasePreviewSignature = (
  options: BasePreviewSignatureOptions
): string => {
  const {
    payloadSignature,
    activePreviewRevision,
    previewSourceSignature,
    previewUsesAltSources,
    digitigrade,
    previewTransformSignature,
    canvasWidth,
    canvasHeight,
    tailHiddenSignature,
    directionSignature,
    activeDirKey,
    activeDir,
    partPrioritySignature,
    partReplacementSignature,
    partPaintSignature,
    showEquipment,
    showJobGear,
    showLoadoutGear,
  } = options;
  return [
    payloadSignature || 'base',
    activePreviewRevision || 0,
    previewSourceSignature,
    previewUsesAltSources ? 'alt' : 'base',
    digitigrade ? 'd' : 'p',
    previewTransformSignature || 'untransformed',
    `${canvasWidth}x${canvasHeight}`,
    tailHiddenSignature,
    directionSignature,
    activeDirKey,
    activeDir,
    partPrioritySignature,
    partReplacementSignature,
    partPaintSignature,
    showEquipment ? 'e1' : 'e0',
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

const resolveSelectedProstheticGalleryId = (
  definitions: ReturnType<typeof resolveProstheticGalleryDefinitions>,
  selectedId: string | null
) => {
  const selectedDefinition = definitions.find(
    (definition) => definition.id === selectedId && !definition.disabled
  );
  const resolvedDefinition =
    selectedDefinition ||
    definitions.find((definition) => !definition.disabled) ||
    null;
  return resolvedDefinition?.id || null;
};

export const resolveVisibleProstheticDefinitions = (
  visible: boolean,
  resolver: () => ReturnType<typeof resolveProstheticGalleryDefinitions>
): ReturnType<typeof resolveProstheticGalleryDefinitions> =>
  visible ? resolver() : [];

const applyInternalProstheticSelectionToDraft = (options: {
  target: InternalOrganId;
  status: string;
  context: BasicAppearancePayload['prosthetic_context'];
  currentState: BasicAppearanceState;
  updateDraft: (
    updater: (state: BasicAppearanceState) => BasicAppearanceState
  ) => void;
}) => {
  const { target, status, context, currentState, updateDraft } = options;
  if (
    !context ||
    !resolveInternalOrganOptions(target, currentState.limbs, context).some(
      (entry) => entry.id === status
    )
  ) {
    return;
  }
  updateDraft((state) => ({
    ...state,
    limbs: applyInternalOrganOperation(state.limbs, {
      target,
      state: status,
    }),
  }));
};

const resolveBasicAppearanceGalleryPresentation = (options: {
  type: BasicAppearanceType;
  galleryType: BasicAppearanceGalleryType;
  payload: BasicAppearancePayload;
  appearanceState: BasicAppearanceState;
  prostheticDefinitions: ReturnType<typeof resolveProstheticGalleryDefinitions>;
  prostheticContext: BasicAppearancePayload['prosthetic_context'];
  selectedProstheticModelId: string | null;
}) => {
  const {
    type,
    galleryType,
    payload,
    appearanceState,
    prostheticDefinitions,
    prostheticContext,
    selectedProstheticModelId,
  } = options;
  if (type === 'prosthetics') {
    return {
      definitions: prostheticDefinitions,
      selectedId: selectedProstheticModelId,
      emptyMessage: !prostheticContext
        ? 'Prosthetic data is unavailable for this character.'
        : !prostheticDefinitions.length
          ? 'No prosthetic manufacturers are available for this species.'
          : undefined,
    };
  }
  return {
    definitions: resolveGalleryDefinitionsForType(
      galleryType,
      payload.hair_styles,
      payload.gradient_styles,
      payload.facial_hair_styles,
      payload.ear_styles,
      payload.tail_styles,
      payload.wing_styles
    ),
    selectedId: resolveSelectedIdForGalleryType(galleryType, appearanceState),
    emptyMessage: undefined,
  };
};

export const resolveActiveProstheticTargetsFromSharedState = (
  shared: Record<string, unknown> | null | undefined,
  fallback: readonly ProstheticTarget[]
): ProstheticTarget[] => {
  const storedTargets = shared?.basicAppearanceProstheticTargets;
  return normalizeProstheticTargets(
    Array.isArray(storedTargets)
      ? (storedTargets as ProstheticTarget[])
      : fallback
  );
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
    livePreview,
    resolvedPartPriorityMap,
    resolvedPartReplacementMap,
    showEquipment,
    onToggleEquipment,
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
  const [, setSpeciesReloadPending] = useLocalState<boolean>(
    context,
    `speciesReloadPending-${stateToken}`,
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
    useLocalState<BasicAppearancePayload | null>(context, 'basicPayload', null);
  const [bodyPayload, setBodyPayload] =
    useLocalState<BodyMarkingsPayload | null>(context, 'bodyPayload', null);
  const [speciesPayload, setSpeciesPayload] =
    useLocalState<SpeciesPayload | null>(
      context,
      'speciesPayload',
      data.species_payload || null
    );
  const [speciesSelection] = useLocalState<string | null>(
    context,
    'speciesSelection',
    data.species_payload?.selected_species || null
  );
  const [speciesIconBaseSelection] = useLocalState<string | null>(
    context,
    'speciesIconBaseSelection',
    data.species_payload?.preview_icon_base ||
      data.species_payload?.selected_icon_base ||
      null
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
  const {
    markingLayersCache,
    bodyMarkingsPreviewCache,
    bodyMarkingDefinitionCache,
    bodyMarkingsSignatureCache,
    previewDirStatesCache,
    basePreviewRawCache,
    markedBasePreviewCache,
    galleryBasePreviewCache,
    galleryAppearanceGridContextCache,
    tilePreviewCache,
    tileBasePreviewCache,
  } = resolveBasicAppearanceRenderCache(context.store, stateToken);
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
    DEFAULT_BASIC_APPEARANCE_TYPE
  );
  const [selectedProstheticModelId, setSelectedProstheticModelId] =
    useLocalState<string | null>(
      context,
      'basicAppearanceProstheticModel',
      Object.values(appearanceState.limbs.external || {}).find(
        (entry) => entry.status === 'cyborg' && !!entry.model
      )?.model || null
    );
  const [activeProstheticTargets, setActiveProstheticTargets] = useLocalState<
    ProstheticTarget[]
  >(context, 'basicAppearanceProstheticTargets', ['full_body']);
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
      resolveDefaultColorTarget(DEFAULT_BASIC_APPEARANCE_TYPE)
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
    act(
      'load_basic_appearance',
      buildBasicAppearanceLoadParams(basicPayload, bodyPayload)
    );
  };

  const requestBodyPayload = () => {
    if (!bodyPayloadRequestPending) {
      setBodyPayloadRequestPending(true);
    }
    act(
      'load_body_markings',
      buildBodyMarkingsLoadParams(bodyPayload, basicPayload)
    );
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
    const mergedPayload = mergeBodyMarkingsPayload(
      bodyPayload,
      payload,
      basicPayload
    );
    setBodyPayload(mergedPayload);
    const nextMarkings = deepCopyMarkings(mergedPayload.body_markings);
    const nextOrder =
      (mergedPayload.order as string[]) ||
      Object.keys(mergedPayload.body_markings || {});
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
    const mergedPayload = mergeBasicAppearancePayload(
      basicPayload,
      payload,
      bodyPayload
    );
    setBasicPayload(mergedPayload);
    const nextState = buildBasicStateFromPayload(mergedPayload);
    const nextProstheticContext = mergedPayload.prosthetic_context;
    if (nextProstheticContext) {
      const backendState = selectBackend(context.store.getState()) as {
        shared?: Record<string, unknown>;
      };
      const latestTargets = resolveActiveProstheticTargetsFromSharedState(
        backendState?.shared,
        activeProstheticTargets
      );
      const nextTargets = resolveEditableProstheticTargets(
        latestTargets,
        nextState.limbs,
        nextProstheticContext
      );
      if (nextTargets.length !== latestTargets.length) {
        setActiveProstheticTargets(nextTargets);
      }
    }
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
    setBasicPayload(
      mergeBasicAppearancePayload(resolvedPayload, payload, bodyPayload)
    );
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
      latestSavedState:
        (shared.basicAppearanceSavedState as BasicAppearanceState) ||
        savedState,
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

  const rawProstheticContext = basicPayload?.prosthetic_context || null;
  const prostheticContext = resolveProstheticContextForBiologicalGender(
    rawProstheticContext,
    appearanceState.biological_gender
  );
  const biologicalGenders = resolveBasicBiologicalGenderOptions(
    basicPayload,
    appearanceState
  );
  const bloodTypes = resolveStringOptions(basicPayload?.blood_types);
  const bloodReagents = resolveStringOptions(basicPayload?.blood_reagents);
  const prostheticsMode = type === 'prosthetics';
  const normalizedActiveProstheticTargets = normalizeProstheticTargets(
    activeProstheticTargets
  );
  const resolvedActiveProstheticTargets = prostheticContext
    ? resolveEditableProstheticTargets(
        normalizedActiveProstheticTargets,
        appearanceState.limbs,
        prostheticContext
      )
    : normalizedActiveProstheticTargets;
  const resolveLatestActiveProstheticTargets = () => {
    const backendState = selectBackend(context.store.getState()) as {
      shared?: Record<string, unknown>;
    };
    const shared = backendState?.shared;
    const latestTargets = resolveActiveProstheticTargetsFromSharedState(
      shared,
      activeProstheticTargets
    );
    const latestState =
      (shared?.basicAppearanceState as BasicAppearanceState) || appearanceState;
    return prostheticContext
      ? resolveEditableProstheticTargets(
          latestTargets,
          latestState.limbs,
          prostheticContext
        )
      : latestTargets;
  };
  const prostheticDefinitions = resolveVisibleProstheticDefinitions(
    prostheticsMode,
    () =>
      attachProstheticColorModes(
        resolveProstheticGalleryDefinitionsForTargets(
          resolvedActiveProstheticTargets,
          appearanceState.limbs,
          prostheticContext
        )
      )
  );
  const resolvedSelectedProstheticModelId = prostheticsMode
    ? resolveSelectedProstheticGalleryId(
        prostheticDefinitions,
        selectedProstheticModelId
      )
    : selectedProstheticModelId;

  const updateBasicDraft = (
    updater: (state: BasicAppearanceState) => BasicAppearanceState
  ) => {
    const { latestState, latestSavedState } = resolveLatestBasicState();
    const latestTargets = resolveLatestActiveProstheticTargets();
    const updated = updater(latestState);
    const operations = buildCanonicalProstheticOperations(
      latestSavedState.limbs,
      updated.limbs,
      prostheticContext
    );
    let nextState: BasicAppearanceState = {
      ...updated,
      limbs: cloneLimbOverrideState(updated.limbs),
      ...operations,
    };
    const nextBiologicalGenders = resolveBasicBiologicalGenderOptions(
      basicPayload,
      nextState
    );
    const nextBiologicalGender = resolveBasicBiologicalGender(
      nextBiologicalGenders,
      nextState.biological_gender
    );
    if (nextBiologicalGender !== nextState.biological_gender) {
      nextState = {
        ...nextState,
        biological_gender: nextBiologicalGender,
      };
    }
    if (prostheticContext) {
      const nextTargets = resolveEditableProstheticTargets(
        latestTargets,
        nextState.limbs,
        prostheticContext
      );
      if (nextTargets.length !== latestTargets.length) {
        setActiveProstheticTargets(nextTargets);
      }
    }
    updateAppearanceState(() => nextState);
    setDirty(!basicAppearanceStatesEqual(nextState, latestSavedState));
  };

  const applyExternalProstheticSelection = (id: string) => {
    if (!prostheticContext || !id || uiLocked) {
      return;
    }
    const latestTargets = resolveLatestActiveProstheticTargets();
    updateBasicDraft((state) => {
      const quickSet = id === '__normal__' || id === '__amputated__';
      if (
        !quickSet &&
        !isProstheticSelectionCompatibleWithTargets(
          latestTargets,
          id,
          state.limbs,
          prostheticContext
        )
      ) {
        return state;
      }
      return {
        ...state,
        limbs: applyProstheticSelectionToTargets(
          state.limbs,
          latestTargets,
          id,
          prostheticContext
        ),
      };
    });
  };

  const setInternalProstheticSelection = (
    target: InternalOrganId,
    status: string
  ) => {
    const { latestState } = resolveLatestBasicState();
    applyInternalProstheticSelectionToDraft({
      target,
      status,
      context: prostheticContext,
      currentState: latestState,
      updateDraft: updateBasicDraft,
    });
  };

  const setBloodType = (bloodType: string) => {
    if (uiLocked || !bloodTypes.includes(bloodType)) {
      return;
    }
    updateBasicDraft((state) => ({ ...state, blood_type: bloodType }));
  };

  const setBiologicalGender = (biologicalGender: string) =>
    applyBiologicalGenderChange({
      biologicalGender,
      allowedGenders: biologicalGenders,
      uiLocked,
      updateDraft: updateBasicDraft,
    });

  const setBloodReagent = (bloodReagent: string) =>
    applyBloodReagentChange({
      bloodReagent,
      allowedReagents: bloodReagents,
      uiLocked,
      updateDraft: updateBasicDraft,
    });

  const resetBloodColor = () => {
    setColorTarget({ type: 'blood' });
    updateBasicDraft((state) => ({ ...state, blood_color: '#a10808' }));
  };

  const setNeedsGlasses = (needsGlasses: boolean) =>
    updateBasicDraft((state) => ({
      ...state,
      needs_glasses: !!needsGlasses,
    }));

  const setSynthColorEnabled = (enabled: boolean) =>
    updateBasicDraft((state) => ({
      ...state,
      synth_color_enabled: !!enabled,
    }));

  const setSynthMarkings = (enabled: boolean) =>
    updateBasicDraft((state) => ({
      ...state,
      synth_markings: !!enabled,
    }));

  const resetProstheticSettings = () =>
    updateBasicDraft((state) =>
      resetEditableProstheticSettings(state, prostheticContext)
    );

  const applyColorTarget = (hex: string) => {
    if (colorTarget?.type === 'synth') {
      const { latestState } = resolveLatestBasicState();
      if (!latestState.synth_color_enabled) {
        return;
      }
      const normalized = normalizeHex(hex) || '#ffffff';
      if ((normalizeHex(latestState.synth_color) || '#ffffff') === normalized) {
        return;
      }
      updateBasicDraft((state) => ({
        ...state,
        synth_color: normalized,
      }));
      return;
    }
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
    const { latestState, latestSavedState, latestDirty } =
      resolveLatestBasicState();
    const wasDirty = latestDirty;
    const speciesPreviewStale =
      shouldInvalidateSpeciesPayloadForBiologicalGenderChange(
        latestSavedState.biological_gender,
        latestState.biological_gender
      );
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
        biological_gender: latestState.biological_gender,
        digitigrade: latestState.digitigrade ? 1 : 0,
        body_color: latestState.body_color,
        eye_color: latestState.eye_color,
        blood_type: latestState.blood_type,
        blood_reagent: latestState.blood_reagent,
        blood_color: latestState.blood_color,
        needs_glasses: latestState.needs_glasses ? 1 : 0,
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
        ...buildProstheticSaveParams(latestState, prostheticContext),
        close,
      });
      if (!close) {
        if (speciesPreviewStale) {
          setSpeciesPayload(null);
          setSpeciesReloadPending(true);
        }
        if (wasDirty) {
          setReloadTargetRevision(startingPreviewRevision + 1);
          setReloadPending(true);
        }
        const committedState: BasicAppearanceState = {
          ...latestState,
          limbs: cloneLimbOverrideState(latestState.limbs),
          limb_operations: [],
          organ_operations: [],
        };
        setDirty(false);
        setSavedState(committedState);
        setAppearanceState(committedState);
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
    activeType: type,
    maxAccessoryChannels,
  });

  const colorPickerValue = resolveColorTargetHexForState(
    appearanceState,
    activeColorTarget
  );

  const { speciesPreviewSources, speciesPreviewSignature } =
    resolveSelectedSpeciesPreviewSources({
      speciesPayload,
      speciesSelection,
      speciesIconBaseSelection,
      payloadSpeciesId: basicPayload?.species_id,
      payloadIconBaseId: basicPayload?.custom_base,
      digitigrade: appearanceState.digitigrade,
    });
  const {
    previewUsesAltSources,
    rawPreviewSources,
    activePreviewSources,
    activePreviewAssetRegistry,
    activePreviewRevision,
    previewSourceSignature,
  } = resolvePreviewSourceSelection(
    basicPayload,
    appearanceState,
    speciesPreviewSources,
    speciesPreviewSignature
  );
  const {
    previewBaseBodyColor,
    previewTargetBodyColor,
    previewBaseEyeColor,
    previewTargetEyeColor,
  } = resolvePreviewColors(basicPayload, appearanceState);
  const { tileDirections, tileDirectionsSignature, directionSignature } =
    resolveDirectionData(data.directions);
  const previewDirStates = resolvePreviewDirStates({
    cache: previewDirStatesCache,
    activePreviewSources,
    activePreviewAssetRegistry,
    activePreviewRevision,
    activeDirKey: data.active_dir_key,
    activeDir: data.active_dir,
    canvasWidth,
    canvasHeight,
  });
  const tailHiddenBodyParts = resolveHiddenBodyParts(tailDef?.hide_body_parts);
  const galleryBaseDefinitionId =
    galleryType === 'tail' ? '__replacement__' : '';
  const galleryBaseIncludesSpeciesTail = shouldIncludeSpeciesTailInGalleryTile(
    galleryType,
    galleryBaseDefinitionId,
    appearanceState.tail_style
  );
  const galleryBaseTailHiddenBodyParts =
    galleryType === 'tail' ? [] : tailHiddenBodyParts;
  const galleryBaseHiddenPartsSignature = galleryBaseTailHiddenBodyParts.length
    ? galleryBaseTailHiddenBodyParts.join('|')
    : 'no-hide';
  const galleryPreviewDirStates = mergeHiddenBodyPartsInPreviewStates(
    resolveGalleryTilePreviewStates(
      previewDirStates,
      galleryType,
      galleryBaseDefinitionId,
      appearanceState.tail_style
    ),
    galleryBaseTailHiddenBodyParts
  );
  const previewDirStatesForLive = mergeHiddenBodyPartsInPreviewStates(
    previewDirStates,
    tailHiddenBodyParts
  );
  const galleryHiddenPartsByDir = buildSuppressedMarkingPartsByDir(
    galleryPreviewDirStates
  );
  const liveHiddenPartsByDir = buildSuppressedMarkingPartsByDir(
    previewDirStatesForLive
  );
  const bodyColorExcludedParts = collectBodyColorExcludedParts(
    previewDirStatesForLive
  );
  const bodyColorBlendMode = collectBodyColorBlendMode(previewDirStatesForLive);
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
  const hasActiveBodyMarkings = hasActiveBodyMarkingParts({
    definitions: bodyMarkingsDefinitions,
    markings: bodyMarkingsState,
    order: bodyMarkingsOrder,
  });
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
  const galleryTailContextSignature = [
    galleryBaseIncludesSpeciesTail ? 'species-tail' : 'no-species-tail',
    galleryBaseHiddenPartsSignature,
  ].join('::');
  const galleryBaseSignature = buildGalleryBasePreviewSignature({
    payloadSignature,
    activePreviewRevision,
    previewSourceSignature,
    previewUsesAltSources,
    canvasWidth,
    canvasHeight,
    tileDirectionsSignature,
    directionSignature,
    bodyMarkingsContextSignature,
    galleryTailContextSignature,
    stripReferenceMarkings,
  });
  const { preview: galleryBasePreview } = resolveGalleryBasePreview({
    cache: galleryBasePreviewCache,
    signature: galleryBaseSignature,
    activePreviewSources,
    previewDirStates: galleryPreviewDirStates,
    tileDirections,
    canvasWidth,
    canvasHeight,
    includeSpeciesTail: galleryBaseIncludesSpeciesTail,
    applyBodyMarkings,
    suppressedPartsByDir: galleryHiddenPartsByDir,
    signalAssetUpdate,
    stripReferenceMarkings,
  });
  const galleryMannequinPreview = applyBodyAndEyeColorToPreview(
    galleryBasePreview,
    previewBaseBodyColor,
    previewTargetBodyColor,
    bodyColorExcludedParts,
    bodyColorBlendMode,
    previewBaseEyeColor,
    previewTargetEyeColor,
    previewTargetBodyColor,
    appearanceState.hair_color
  );
  const galleryMannequinPreviewByDir = galleryMannequinPreview.reduce(
    (acc, entry) => {
      acc[entry.dir] = entry;
      return acc;
    },
    {} as Record<number, PreviewDirectionEntry>
  );
  const galleryAppearanceContextSignature = [
    buildBasicAppearanceGalleryContextSignature(appearanceState, galleryType),
    basicPayload?.definition_revision || 'definitions',
    tileDirectionsSignature,
    `${canvasWidth}x${canvasHeight}`,
    `${assetRevision}`,
  ].join('::');
  const galleryAppearanceGridContextByDir = resolveGalleryAppearanceGridContext(
    {
      cache: galleryAppearanceGridContextCache,
      signature: galleryAppearanceContextSignature,
      galleryType,
      tileDirections,
      canvasWidth,
      canvasHeight,
      appearanceState,
      hairDef,
      gradientDef,
      facialHairDef,
      earDef,
      hornDef,
      tailDef,
      wingDef,
      signalAssetUpdate,
    }
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
      payloadSignature,
      tileDirections,
      tileDirectionsSignature,
      canvasWidth,
      canvasHeight,
      activePreviewRevision,
      previewSourceSignature,
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
      facialHairDef,
      earDef,
      hornDef,
      tailDef,
      wingDef,
      previewDirStates,
      tilePreviewCache,
      tileBasePreviewCache,
      galleryMannequinPreviewByDir,
      galleryBaseIncludesSpeciesTail,
      galleryBaseHiddenPartsSignature,
      galleryAppearanceGridContextByDir,
      galleryAppearanceContextSignature,
      previewBaseBodyColor,
      previewBaseEyeColor,
      bodyColorExcludedParts,
      bodyColorBlendMode,
      applyBodyMarkings,
      signalAssetUpdate,
      stripReferenceMarkings,
    });

  const getProstheticTilePreviewEntries = (def: {
    id: string;
    name: string;
    description?: string | null;
  }): BasicTilePreviewEntry[] => {
    if (!prostheticsMode || !prostheticContext) {
      return [];
    }
    const candidateState = buildProstheticShowcaseState(
      appearanceState,
      def.id,
      prostheticContext
    );
    const galleryPreviewTransformOptions = {
      deferSynthColor: true,
      deferBodyColor: true,
      applyBodyColorToProsthetics: true,
    } as const;
    const galleryCompositeSelection = resolveProstheticGalleryComposite(
      def.id,
      candidateState,
      prostheticContext
    );
    const galleryCompositeOptions = {
      requiresPartLevelMarkingComposition:
        candidateState.synth_markings && hasActiveBodyMarkings,
      preservesSourcePartMarkings: candidateState.synth_markings,
      deferBodyColor: true,
    };
    const galleryComposite = canApplyProstheticGalleryCompositeToPreviewSources(
      rawPreviewSources,
      galleryCompositeSelection,
      prostheticContext,
      galleryCompositeOptions
    )
      ? galleryCompositeSelection
      : null;
    const cacheKey = `prosthetics:${def.id}`;
    const preparedStructureParts = [
      payloadSignature || 'payload',
      speciesPreviewSignature || 'species',
      previewSourceSignature,
      tileDirectionsSignature,
      directionSignature,
      `${canvasWidth}x${canvasHeight}`,
      `${activePreviewRevision || 0}`,
      bodyMarkingsSignature,
      stripReferenceMarkings ? 's1' : 's0',
      galleryComposite?.key || 'part-recipe',
    ];
    const appearanceStructureSignature =
      buildProstheticShowcaseAppearanceStructureSignature(candidateState);
    const preparedStructureSignature = [
      'prosthetic-showcase-prepared-v1',
      ...preparedStructureParts,
      buildLimbPreviewSignature(
        candidateState,
        prostheticContext,
        galleryPreviewTransformOptions
      ),
      appearanceStructureSignature,
    ].join('::');
    const colorLayerStructureSignature = [
      'prosthetic-showcase-color-layer-v1',
      ...preparedStructureParts,
      buildLimbPreviewSignature(
        { ...candidateState, body_color: null },
        prostheticContext,
        galleryPreviewTransformOptions
      ),
      appearanceStructureSignature,
    ].join('::');
    const baseStructureSignature = [
      'prosthetic-showcase-base-v6',
      preparedStructureSignature,
      `body:${candidateState.body_color || ''}`,
      `eye:${candidateState.eye_color || ''}`,
    ].join('::');
    const eyeColorCacheSignature = [
      colorLayerStructureSignature,
      `eye:${candidateState.eye_color || ''}`,
    ].join('::');
    const synthColorPasses =
      galleryComposite?.colorable && candidateState.synth_color_enabled
        ? { [PROSTHETIC_GALLERY_COMPOSITE_PART]: 1 }
        : resolveProstheticSynthColorPasses(candidateState, prostheticContext);
    const hasSynthColorPasses = Object.values(synthColorPasses).some(
      (passes) => passes > 0
    );
    const synthColor = normalizeHex(candidateState.synth_color) || '#ffffff';
    const synthSignature = hasSynthColorPasses
      ? `synth:${synthColor}`
      : 'synth:authored';
    const bodyColorPasses =
      galleryComposite &&
      !galleryComposite.colorable &&
      prostheticContext.apply_skin_color
        ? { [PROSTHETIC_GALLERY_COMPOSITE_PART]: 1 }
        : resolveProstheticBodyColorPasses(candidateState, prostheticContext);
    const unsharedProstheticLayerKeys = new Set<string>();
    const addUnsharedProstheticPart = (part: string) => {
      unsharedProstheticLayerKeys.add(`ref_${part}`);
      unsharedProstheticLayerKeys.add(`ref_${part}_hair`);
      unsharedProstheticLayerKeys.add(`ref_${part}_markings`);
    };
    if (galleryComposite) {
      addUnsharedProstheticPart(PROSTHETIC_GALLERY_COMPOSITE_PART);
    } else {
      const lockedParts = new Set(prostheticContext.locked_parts || []);
      Object.entries(candidateState.limbs.external || {}).forEach(
        ([part, entry]) => {
          if (entry.status === 'cyborg' && !lockedParts.has(part)) {
            addUnsharedProstheticPart(part);
          }
        }
      );
    }
    const buildColoredPreviews = (
      basePreview: PreviewDirectionEntry[],
      cacheSignature: string,
      colorCacheSignature: string,
      renderSignature?: string
    ): BasicTilePreviewEntry[] =>
      basePreview.map((entry) => ({
        ...entry,
        layers: [],
        renderSignature: renderSignature
          ? `${renderSignature}::dir:${entry.dir}`
          : undefined,
        retainRenderedCanvasOnUnmount: !!renderSignature,
        layerGroups: buildProstheticPreviewLayerGroups({
          layers: entry.layers,
          colorPasses: synthColorPasses,
          color: synthColor,
          multiply: !!prostheticContext.color_multiply,
          cacheKey: `${cacheKey}:${entry.dir}`,
          cacheSignature,
          colorCacheSignature,
          stableCacheSignature: colorLayerStructureSignature,
          bodyColorPasses,
          bodyColor: previewTargetBodyColor,
          bodyColorMultiply: !!prostheticContext.color_multiply,
          bodyColorCacheSignature: colorLayerStructureSignature,
          eyeColorCacheSignature,
          rasterScope: stateToken,
          direction: entry.dir,
          unsharedLayerKeys: unsharedProstheticLayerKeys,
        }),
      }));

    let cachedBase = tileBasePreviewCache[cacheKey];
    if (
      cachedBase?.complete &&
      cachedBase.structureSig === baseStructureSignature
    ) {
      const signature = [baseStructureSignature, synthSignature].join('::');
      const cached = tilePreviewCache[cacheKey];
      if (cached?.sig === signature) {
        return cached.previews;
      }
      const previews = buildColoredPreviews(
        cachedBase.preview,
        baseStructureSignature,
        colorLayerStructureSignature,
        signature
      );
      tilePreviewCache[cacheKey] = { sig: signature, previews };
      return previews;
    }

    let prepared =
      cachedBase?.preparedSig === preparedStructureSignature
        ? cachedBase.prostheticPrepared
        : undefined;
    if (!prepared) {
      const candidateHairDef = resolveSelectedDef(
        hair_styles,
        candidateState.hair_style
      );
      const candidateGradientDef = resolveSelectedDef(
        gradient_styles,
        candidateState.hair_gradient_style
      );
      const candidateFacialHairDef = resolveSelectedDef(
        facial_hair_styles,
        candidateState.facial_hair_style
      );
      const candidateEarDef = resolveSelectedDef(
        ear_styles,
        candidateState.ear_style
      );
      const candidateHornDef = resolveSelectedDef(
        ear_styles,
        candidateState.horn_style
      );
      const candidateTailDef = resolveSelectedDef(
        tail_styles,
        candidateState.tail_style
      );
      const candidateWingDef = resolveSelectedDef(
        wing_styles,
        candidateState.wing_style
      );
      const rawCandidateSelection = resolvePreviewSourceSelection(
        basicPayload,
        candidateState,
        speciesPreviewSources,
        speciesPreviewSignature,
        galleryPreviewTransformOptions
      );
      const compositePreviewSources =
        applyProstheticGalleryCompositeToPreviewSources(
          rawCandidateSelection.activePreviewSources || null,
          galleryComposite,
          prostheticContext,
          galleryCompositeOptions
        );
      const candidateSelection =
        compositePreviewSources &&
        compositePreviewSources !== rawCandidateSelection.activePreviewSources
          ? {
              ...rawCandidateSelection,
              activePreviewSources: compositePreviewSources,
            }
          : rawCandidateSelection;
      const candidateDirStates = resolvePreviewDirStates({
        activePreviewSources: candidateSelection.activePreviewSources,
        activePreviewAssetRegistry:
          candidateSelection.activePreviewAssetRegistry,
        activePreviewRevision: candidateSelection.activePreviewRevision,
        activeDirKey: data.active_dir_key,
        activeDir: data.active_dir,
        canvasWidth,
        canvasHeight,
      });
      const candidateSuppressedParts =
        buildSuppressedMarkingPartsByDir(candidateDirStates);
      prepared = {
        hairDef: candidateHairDef,
        gradientDef: candidateGradientDef,
        facialHairDef: candidateFacialHairDef,
        earDef: candidateEarDef,
        hornDef: candidateHornDef,
        tailDef: candidateTailDef,
        wingDef: candidateWingDef,
        selection: candidateSelection,
        dirStates: candidateDirStates,
        suppressedPartsByDir: candidateSuppressedParts,
        assembledPreviewCache: { preview: null },
        assetReferences: [
          ...collectPreviewDirStateAssetReferences({
            previewDirStates: candidateDirStates,
            directions: tileDirections,
            stripReferenceMarkings,
          }),
          ...collectAppearanceOverlayAssetReferences({
            directions: tileDirections,
            hairDef: candidateHairDef,
            gradientDef: candidateGradientDef,
            facialHairDef: candidateFacialHairDef,
            earDef: candidateEarDef,
            hornDef: candidateHornDef,
            tailDef: candidateTailDef,
            wingDef: candidateWingDef,
          }),
          ...collectActiveBodyMarkingAssetReferences({
            definitions: bodyMarkingsDefinitions,
            markings: bodyMarkingsState,
            order: bodyMarkingsOrder,
            directions: tileDirections,
            digitigrade: candidateState.digitigrade,
            suppressedPartsByDir: candidateSuppressedParts,
          }),
        ],
      };
    }
    const {
      hairDef: candidateHairDef,
      gradientDef: candidateGradientDef,
      facialHairDef: candidateFacialHairDef,
      earDef: candidateEarDef,
      hornDef: candidateHornDef,
      tailDef: candidateTailDef,
      wingDef: candidateWingDef,
      selection: candidateSelection,
      dirStates: candidateDirStates,
      suppressedPartsByDir: candidateSuppressedParts,
      assetReferences: candidateAssetReferences,
    } = prepared;
    let assetsReady = areIconAssetsReady(candidateAssetReferences);
    let assetReadinessSignature = getIconAssetReadinessSignature(
      candidateAssetReferences
    );
    if (!assetsReady && assetReadinessSignature.includes(':idle')) {
      primePreviewAssetReferences({
        references: candidateAssetReferences,
        canvasWidth,
        canvasHeight,
        signalAssetUpdate,
      });
      assetsReady = areIconAssetsReady(candidateAssetReferences);
      assetReadinessSignature = getIconAssetReadinessSignature(
        candidateAssetReferences
      );
    }
    const loadingBaseSignature = buildProstheticTileBaseCacheSignature({
      structureSignature: baseStructureSignature,
      assetReadinessSignature,
      complete: assetsReady,
    });

    if (!assetsReady) {
      if (cachedBase?.structureSig !== baseStructureSignature) {
        const pendingPreview = buildPendingTilePreview(tileDirections);
        cachedBase = {
          sig: loadingBaseSignature,
          structureSig: baseStructureSignature,
          preparedSig: preparedStructureSignature,
          complete: false,
          prostheticPrepared: prepared,
          preview: pendingPreview,
          previewByDir: pendingPreview.reduce(
            (result, entry) => {
              result[entry.dir] = entry;
              return result;
            },
            {} as Record<number, PreviewDirectionEntry>
          ),
        };
        tileBasePreviewCache[cacheKey] = cachedBase;
      } else {
        cachedBase.sig = loadingBaseSignature;
        cachedBase.preparedSig = preparedStructureSignature;
        cachedBase.prostheticPrepared = prepared;
      }
      const signature = [loadingBaseSignature, synthSignature].join('::');
      const cached = tilePreviewCache[cacheKey];
      if (cached?.sig === signature) {
        return cached.previews;
      }
      const previews = buildColoredPreviews(
        cachedBase.preview,
        loadingBaseSignature,
        colorLayerStructureSignature
      );
      tilePreviewCache[cacheKey] = { sig: signature, previews };
      return previews;
    }

    let basePreview = cachedBase?.preview;
    if (
      !cachedBase?.complete ||
      cachedBase.structureSig !== baseStructureSignature
    ) {
      const assembledPreview = resolveProstheticAssembledPreview(
        prepared.assembledPreviewCache,
        () => {
          const rawPreview = buildBasePreviewRaw({
            activePreviewSources: candidateSelection.activePreviewSources,
            previewDirStates: candidateDirStates,
            directions: tileDirections,
            canvasWidth,
            canvasHeight,
            activeDirKey: tileDirections[0]?.dir || data.active_dir_key,
            resolvedPartPriorityMap: {},
            resolvedPartReplacementMap: {},
            partPaintPresenceMap: undefined,
            showEquipment: false,
            showJobGear: false,
            showLoadoutGear: false,
            signalAssetUpdate,
            stripReferenceMarkings,
          });
          const baseSegments = rawPreview.map((entry) => {
            const { before, after } = splitOverlayGroup(entry.layers || []);
            return { entry, before, after };
          });
          const markedPreview = applyBodyMarkings(
            baseSegments.map(({ entry, before }) => ({
              ...entry,
              layers: before,
            })),
            candidateSuppressedParts
          );
          const markedByDir = markedPreview.reduce(
            (result, entry) => {
              result[entry.dir] = entry;
              return result;
            },
            {} as Record<number, PreviewDirectionEntry>
          );
          return baseSegments.map(({ entry, before, after }) => {
            const markedEntry = markedByDir[entry.dir];
            const fallbackLayers = markedEntry?.layers || before;
            const { base: baseLayers, priority: priorityLayers } =
              splitPriorityBodyMarkingLayers(fallbackLayers);
            const overlayEntries = buildBasicAppearanceOverlayEntries({
              dir: entry.dir,
              dirState: candidateDirStates[entry.dir],
              canvasWidth,
              canvasHeight,
              appearanceState: candidateState,
              hairDef: candidateHairDef,
              gradientDef: candidateGradientDef,
              facialHairDef: candidateFacialHairDef,
              earDef: candidateEarDef,
              hornDef: candidateHornDef,
              tailDef: candidateTailDef,
              wingDef: candidateWingDef,
              showEquipment: false,
              showJobGear: false,
              showLoadoutGear: false,
              signalAssetUpdate,
            });
            return {
              ...entry,
              layers: [
                ...baseLayers,
                ...overlayEntries,
                ...after,
                ...priorityLayers,
              ],
            };
          });
        }
      );
      const candidateExcludedParts =
        collectBodyColorExcludedParts(candidateDirStates);
      const candidateBlendMode = collectBodyColorBlendMode(candidateDirStates);
      basePreview = applyBodyAndEyeColorToPreview(
        assembledPreview,
        previewBaseBodyColor,
        previewTargetBodyColor,
        candidateExcludedParts,
        candidateBlendMode,
        previewBaseEyeColor,
        previewTargetEyeColor,
        previewTargetBodyColor,
        candidateState.hair_color
      );
      tileBasePreviewCache[cacheKey] = {
        sig: baseStructureSignature,
        structureSig: baseStructureSignature,
        preparedSig: preparedStructureSignature,
        complete: true,
        prostheticPrepared: prepared,
        preview: basePreview,
        previewByDir: basePreview.reduce(
          (result, entry) => {
            result[entry.dir] = entry;
            return result;
          },
          {} as Record<number, PreviewDirectionEntry>
        ),
      };
    }
    const signature = [baseStructureSignature, synthSignature].join('::');
    const previews = buildColoredPreviews(
      basePreview || [],
      baseStructureSignature,
      colorLayerStructureSignature,
      signature
    );
    tilePreviewCache[cacheKey] = { sig: signature, previews };
    return previews;
  };

  const basePreviewSignature = buildBasePreviewSignature({
    payloadSignature,
    activePreviewRevision,
    previewSourceSignature,
    previewUsesAltSources,
    digitigrade: appearanceState.digitigrade,
    previewTransformSignature: buildLimbPreviewSignature(
      appearanceState,
      prostheticContext
    ),
    canvasWidth,
    canvasHeight,
    tailHiddenSignature,
    directionSignature,
    activeDirKey: data.active_dir_key,
    activeDir: data.active_dir,
    partPrioritySignature,
    partReplacementSignature,
    partPaintSignature,
    showEquipment,
    showJobGear,
    showLoadoutGear,
  });
  const rawBasePreviewSignature = [
    basePreviewSignature,
    `assets:${assetRevision}`,
    stripReferenceMarkings ? 's1' : 's0',
  ].join('::');
  const basePreviewRaw = resolveCachedBasePreviewRaw(
    basePreviewRawCache,
    rawBasePreviewSignature,
    () =>
      buildBasePreviewRaw({
        activePreviewSources,
        previewDirStates: previewDirStatesForLive,
        directions: data.directions,
        canvasWidth,
        canvasHeight,
        activeDirKey: data.active_dir_key,
        resolvedPartPriorityMap,
        resolvedPartReplacementMap,
        partPaintPresenceMap,
        showEquipment,
        showJobGear,
        showLoadoutGear,
        signalAssetUpdate,
        stripReferenceMarkings,
      })
  );
  const markedBaseSignature = `${rawBasePreviewSignature}::${bodyMarkingsContextSignature}`;
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
      hairDef,
      gradientDef,
      facialHairDef,
      earDef,
      hornDef,
      tailDef,
      wingDef,
      showEquipment,
      showJobGear,
      showLoadoutGear,
      signalAssetUpdate,
    });
    const fallbackSplit = splitOverlayGroup(dirEntry.layers || []);
    const { base: baseLayers, priority: priorityLayers } =
      splitPriorityBodyMarkingLayers(
        markedEntry?.layers || fallbackSplit.before
      );
    const afterLayers =
      basePreviewAfterByDir[dirEntry.dir] || fallbackSplit.after;
    return {
      ...dirEntry,
      layers: [
        ...baseLayers,
        ...overlayEntries,
        ...afterLayers,
        ...priorityLayers,
      ],
    };
  });
  const livePreviewWithMarkings = applyBodyAndEyeColorToPreview(
    livePreviewWithMarkingsBase,
    previewBaseBodyColor,
    previewTargetBodyColor,
    bodyColorExcludedParts,
    bodyColorBlendMode,
    previewBaseEyeColor,
    previewTargetEyeColor,
    previewTargetBodyColor,
    appearanceState.hair_color
  );
  const previewForLive =
    livePreview && livePreview.length ? livePreview : livePreviewWithMarkings;
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
            const mergedPayload = mergeBasicAppearancePayload(
              basicPayload,
              payload,
              bodyPayload
            );
            setPayloadSignature(buildBasicPayloadSignature(mergedPayload));
            syncPayload(mergedPayload);
          }}
          syncPreviewPayload={(payload) => {
            const mergedPayload = mergeBasicAppearancePayload(
              basicPayload,
              payload,
              bodyPayload
            );
            setPayloadSignature(buildBasicPayloadSignature(mergedPayload));
            syncPreviewPayload(mergedPayload);
          }}
        />
        <LoadingOverlay
          title="Loading basic appearance…"
          subtitle="Fetching your available styles and previews. This should only take a moment."
        />
      </Box>
    );
  }

  const {
    definitions: galleryDefinitions,
    selectedId: selectedGalleryId,
    emptyMessage: galleryEmptyMessage,
  } = resolveBasicAppearanceGalleryPresentation({
    type,
    galleryType,
    payload: basicPayload,
    appearanceState,
    prostheticDefinitions,
    prostheticContext,
    selectedProstheticModelId: resolvedSelectedProstheticModelId,
  });

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
          const mergedPayload = mergeBasicAppearancePayload(
            basicPayload,
            payload,
            bodyPayload
          );
          setPayloadSignature(buildBasicPayloadSignature(mergedPayload));
          syncPayload(mergedPayload);
        }}
        syncPreviewPayload={(payload) => {
          const mergedPayload = mergeBasicAppearancePayload(
            basicPayload,
            payload,
            bodyPayload
          );
          setPayloadSignature(buildBasicPayloadSignature(mergedPayload));
          syncPreviewPayload(mergedPayload);
        }}
      />
      <Flex direction="row" gap={1} wrap={false} height="100%">
        <Flex.Item basis="840px" shrink={0}>
          <Flex direction="column" gap={1}>
            <BasicAppearanceGallerySection
              type={type}
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
              getTilePreviewEntries={
                prostheticsMode
                  ? getProstheticTilePreviewEntries
                  : getTilePreviewEntries
              }
              onSelect={(id) => {
                if (prostheticsMode) {
                  if (id) {
                    setSelectedProstheticModelId(id);
                    applyExternalProstheticSelection(id);
                  }
                  return;
                }
                setGallerySelection(id);
              }}
              emptyMessage={galleryEmptyMessage}
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
            {prostheticsMode ? (
              prostheticContext ? (
                <ProstheticSettingsSection
                  state={appearanceState}
                  context={prostheticContext}
                  biologicalGenders={biologicalGenders}
                  bloodTypes={bloodTypes}
                  bloodReagents={bloodReagents}
                  activeTargets={resolvedActiveProstheticTargets}
                  uiLocked={uiLocked}
                  digitigradeAllowed={digitigradeAllowed}
                  activeColorTarget={activeColorTarget}
                  setColorTarget={setColorTarget}
                  setActiveTargets={setActiveProstheticTargets}
                  applyExternalSelection={applyExternalProstheticSelection}
                  setInternalSelection={setInternalProstheticSelection}
                  setBiologicalGender={setBiologicalGender}
                  setBloodType={setBloodType}
                  setBloodReagent={setBloodReagent}
                  resetBloodColor={resetBloodColor}
                  setNeedsGlasses={setNeedsGlasses}
                  setDigitigrade={setDigitigrade}
                  setSynthColorEnabled={setSynthColorEnabled}
                  setSynthMarkings={setSynthMarkings}
                  resetSettings={resetProstheticSettings}
                />
              ) : (
                <Section title="Body Settings" fill>
                  <NoticeBox warning>
                    Prosthetic settings could not be loaded for this character.
                  </NoticeBox>
                </Section>
              )
            ) : (
              <BasicAppearanceSettingsSection
                state={appearanceState}
                uiLocked={uiLocked}
                hairDef={hairDef}
                facialHairDef={facialHairDef}
                maxAccessoryChannels={maxAccessoryChannels}
                activeColorTarget={activeColorTarget}
                setColorTarget={setColorTarget}
                setStyle={setStyle}
              />
            )}
          </Flex>
        </Flex.Item>
        <Flex.Item grow>
          <BasicAppearancePreviewColumn
            preview={previewForLive}
            canvasWidth={canvasWidth}
            canvasHeight={canvasHeight}
            previewFitToFrame={previewFitToFrame}
            onTogglePreviewFit={togglePreviewFit}
            previewBackgroundImage={previewBackgroundImage}
            backgroundFallbackColor={backgroundFallbackColor}
            canvasBackgroundScale={canvasBackgroundScale}
            previewBackgroundTileWidth={previewBackgroundTileWidth}
            previewBackgroundTileHeight={previewBackgroundTileHeight}
            iconScaleX={data.trait_icon_scale_x}
            iconScaleY={data.trait_icon_scale_y}
            showEquipment={showEquipment}
            onToggleEquipment={onToggleEquipment}
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
