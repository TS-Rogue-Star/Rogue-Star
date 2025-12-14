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
  buildRenderedPreviewDirs as buildDesignerPreviewDirs,
  updatePreviewStateFromPayload,
} from './utils';
import {
  buildRenderedPreviewDirs as buildBasePreviewDirs,
  cloneGridData,
  createBlankGrid,
  getPreviewGridFromAsset,
  gridHasPixels,
  PreviewDirectionEntry,
} from '../../utils/character-preview';
import { DirectionPreviewCanvas, LoadingOverlay } from './components';
import { CHIP_BUTTON_CLASS, PREVIEW_PIXEL_SIZE } from './constants';
import type {
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

const ICON_BLEND_MODE = {
  ADD: 0,
  SUBTRACT: 1,
  MULTIPLY: 2,
  OVERLAY: 3,
  AND: 4,
  OR: 5,
};

const CUSTOM_MARKING_LAYER_INDEX = 40;

const clampChannel = (value: number) =>
  Math.max(0, Math.min(255, Math.floor(value)));

let assetUpdateScheduled = false;

const BODY_MARKINGS_PREVIEW_TIMEOUT_MS = 5000;

const resolveBlendMode = (mode?: number) => {
  switch (mode) {
    case ICON_BLEND_MODE.ADD:
    case ICON_BLEND_MODE.SUBTRACT:
    case ICON_BLEND_MODE.MULTIPLY:
    case ICON_BLEND_MODE.OVERLAY:
    case ICON_BLEND_MODE.AND:
    case ICON_BLEND_MODE.OR:
      return mode;
    default:
      return ICON_BLEND_MODE.MULTIPLY;
  }
};

const blendChannel = (base: number, tint: number, mode: number) => {
  switch (resolveBlendMode(mode)) {
    case ICON_BLEND_MODE.MULTIPLY:
      return clampChannel((base * tint) / 255);
    case ICON_BLEND_MODE.OVERLAY:
      return clampChannel(tint);
    case ICON_BLEND_MODE.SUBTRACT:
      return clampChannel(base - tint);
    case ICON_BLEND_MODE.AND:
      return base & tint;
    case ICON_BLEND_MODE.OR:
      return base | tint;
    default:
      return clampChannel(base + tint);
  }
};

const parseHex = (hex?: string | null): [number, number, number, number] => {
  if (!hex || typeof hex !== 'string') {
    return [0, 0, 0, 0];
  }
  const cleaned = normalizeHex(hex, {
    preserveTransparent: true,
    preserveAlpha: true,
  });
  if (!cleaned) {
    return [0, 0, 0, 0];
  }
  const raw = cleaned.startsWith('#') ? cleaned.slice(1) : cleaned;
  const safeRaw = raw || '';
  const r = parseInt(safeRaw.slice(0, 2), 16) || 0;
  const g = parseInt(safeRaw.slice(2, 4), 16) || 0;
  const b = parseInt(safeRaw.slice(4, 6), 16) || 0;
  const a = safeRaw.length >= 8 ? parseInt(safeRaw.slice(6, 8), 16) || 0 : 255;
  return [r, g, b, a];
};

const toHex = (r: number, g: number, b: number, a?: number) => {
  const channel = (v: number) =>
    (v < 16 ? '0' : '') + Math.max(0, Math.min(255, v)).toString(16);
  if (typeof a === 'number') {
    return `#${channel(r)}${channel(g)}${channel(b)}${channel(a)}`;
  }
  return `#${channel(r)}${channel(g)}${channel(b)}`;
};

const tintGrid = (
  grid: string[][],
  tintHex: string,
  mode: number
): string[][] => {
  const blendMode = resolveBlendMode(mode);
  const [tr, tg, tb] = parseHex(tintHex);
  const tinted: string[][] = [];
  for (let x = 0; x < grid.length; x += 1) {
    const column = grid[x];
    if (!Array.isArray(column)) {
      tinted[x] = [];
      continue;
    }
    tinted[x] = [];
    for (let y = 0; y < column.length; y += 1) {
      const px = column[y];
      if (typeof px !== 'string' || px === TRANSPARENT_HEX) {
        tinted[x][y] = TRANSPARENT_HEX;
        continue;
      }
      const [r, g, b, a] = parseHex(px);
      const rr = blendChannel(r, tr, blendMode);
      const gg = blendChannel(g, tg, blendMode);
      const bb = blendChannel(b, tb, blendMode);
      tinted[x][y] = toHex(rr, gg, bb, a);
    }
  }
  return tinted;
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
      target[x][y] = val;
    }
  }
};

const pixelHasColor = (value?: string): boolean =>
  typeof value === 'string' && value.length > 0 && value !== TRANSPARENT_HEX;

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
    if (partState && partState.on === false) {
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
      if (partState && partState.on === false) {
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
    if (partState && partState.on === false) {
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
    return layer.key.slice('ref_'.length);
  }
  if (layer?.key === 'body' || layer?.type === 'body') {
    return 'generic';
  }
  return null;
};

type BodyMarkingsInitializerProps = Readonly<{
  bodyPayload: BodyMarkingsPayload | null;
  dataPayload?: BodyMarkingsPayload | null;
  payloadSignature: string | null;
  setPayloadSignature: (signature: string | null) => void;
  requestPayload: () => void;
  syncPayload: (payload: BodyMarkingsPayload) => void;
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
      loadInProgress,
      setLoadInProgress,
    } = this.props;
    if (!dataPayload) {
      this.lastPayloadSignature = null;
      this.lastDataPayload = null;
      return;
    }
    const nextSignature = buildBodyPayloadSignature(dataPayload);
    const hadLastDataPayload = this.lastDataPayload !== null;
    const dataRefChanged = dataPayload !== this.lastDataPayload;
    if (!dataRefChanged && nextSignature === this.lastPayloadSignature) {
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
}>;

class MarkingTile extends Component<MarkingTileProps> {
  shouldComponentUpdate(next: MarkingTileProps) {
    return (
      next.selected !== this.props.selected ||
      next.previews !== this.props.previews ||
      next.def.id !== this.props.def.id ||
      next.def.name !== this.props.def.name
    );
  }

  render() {
    const { def, selected, previews, onToggle, canvasWidth, canvasHeight } =
      this.props;
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
                backgroundColor="#000000"
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
      next.definitions !== this.props.definitions
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
                    checked={partState?.on !== false}
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
              fitToFrame={false}
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
          onChange={(hex) => applyColorTarget(hex)}
          onCommit={(hex) => applyColorTarget(hex)}
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
    showJobGear,
    onToggleJobGear,
    showLoadoutGear,
    onToggleLoadout,
  } = props;
  const { act } = useBackend<CustomMarkingDesignerData>(context);
  const uiLocked = data.ui_locked ?? false;
  const stateToken = data.state_token || 'session';
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
    for (const entry of bodyPayload?.preview_sources || []) {
      consider(entry?.body_asset);
      consider(entry?.composite_asset);
      const allOverlays = [
        ...(entry?.overlay_assets || []),
        ...((entry as any)?.job_overlay_assets || []),
        ...((entry as any)?.loadout_overlay_assets || []),
      ];
      for (const raw of allOverlays) {
        const overlayEntry = raw as any;
        const overlayLayer =
          typeof overlayEntry?.layer === 'number' ? overlayEntry.layer : null;
        if (overlayLayer === CUSTOM_MARKING_LAYER_INDEX) {
          continue;
        }
        const overlayAsset = overlayEntry?.asset || raw;
        consider(overlayAsset);
      }
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
    if (activeColorTarget.type === 'galleryPreview') {
      setPreviewColor(normalizeHex(hex) || '#ffffff');
      return;
    }
    if (activeColorTarget.type === 'mark' && activeColorTarget.partId) {
      setPartColor(activeColorTarget.markId, activeColorTarget.partId, hex);
    } else {
      setMarkColor(activeColorTarget.markId, hex);
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
      part.on = !part.on;
      current[partId] = part;
      return {
        ...prev,
        [markId]: current,
      };
    });
    setDirty(true);
  };

  const setPartColor = (markId: string, partId: string, color: string) => {
    updateMarkingsState((prev) => {
      const current = cloneEntry<BodyMarkingEntry>(
        prev[markId] || ({} as BodyMarkingEntry)
      );
      const part =
        cloneEntry<BodyMarkingPartState>(
          (current[partId] as BodyMarkingPartState) ||
            ({} as BodyMarkingPartState)
        ) || ({} as BodyMarkingPartState);
      part.color = normalizeHex(color);
      current[partId] = part;
      current.color = null;
      return {
        ...prev,
        [markId]: current,
      };
    });
    setDirty(true);
  };

  const setMarkColor = (markId: string, color: string) => {
    const def = definitions[markId];
    updateMarkingsState((prev) => {
      const current = cloneEntry<BodyMarkingEntry>(
        prev[markId] || ({} as BodyMarkingEntry)
      );
      current.color = normalizeHex(color);
      if (def?.body_parts) {
        for (const partId of def.body_parts) {
          const part =
            cloneEntry<BodyMarkingPartState>(
              (current[partId] as BodyMarkingPartState) ||
                ({} as BodyMarkingPartState)
            ) || ({} as BodyMarkingPartState);
          part.color = normalizeHex(color);
          part.on = part.on !== false;
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
        on: raw.on !== false,
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
      : ({} as Record<number, any>);
    const basePreview = bodyPayload?.preview_sources
      ? buildBasePreviewDirs(
          previewDirStates,
          data.directions,
          bodyPartLabels,
          canvasWidth,
          canvasHeight,
          signalAssetUpdate
        )
      : [];
    const liveBasePreview = bodyPayload?.preview_sources
      ? buildDesignerPreviewDirs(
          previewDirStates,
          data.directions,
          bodyPartLabels,
          canvasWidth,
          canvasHeight,
          data.active_dir_key,
          'generic',
          null,
          null,
          undefined,
          undefined,
          undefined,
          showJobGear,
          showLoadoutGear,
          signalAssetUpdate
        )
      : [];
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

    const digitigrade = !!bodyPayload?.digitigrade;
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
            (layer) => layer.type === 'overlay'
          );
          const nonOverlayLayers = baseLayers.filter(
            (layer) => layer.type !== 'overlay'
          );
          const referenceMasks = hasHiddenParts
            ? buildReferencePartMaskMap(
                nonOverlayLayers as Array<{
                  key?: string;
                  type?: string;
                  grid?: string[][];
                }>
              )
            : {};
          const normalStack: typeof baseLayers = [];
          const priorityStack: typeof baseLayers = [];
          nonOverlayLayers.forEach((layer) => {
            const partId = resolveLayerPartId(layer);
            const isHiddenPart = !!(partId && hiddenPartsMap[partId]);
            let resolvedLayer = layer;
            if (
              partId === 'generic' &&
              hasHiddenParts &&
              Array.isArray(layer.grid)
            ) {
              resolvedLayer = {
                ...layer,
                grid: buildMaskedGenericGrid(
                  layer.grid as string[][],
                  referenceMasks,
                  hiddenPartsMap
                ),
              };
            }
            if (!isHiddenPart) {
              normalStack.push(resolvedLayer);
            }
            if (!partId || !layersForDir[partId]) {
              return;
            }
            const partLayers = layersForDir[partId];
            partLayers.normal.forEach((markLayer, idx) => {
              normalStack.push({
                type: 'custom',
                key: `tile-${def.id}-${dir.dir}-${partId}-n-${idx}`,
                label: markLayer.label,
                grid: markLayer.grid,
              });
            });
            partLayers.priority.forEach((markLayer, idx) => {
              priorityStack.push({
                type: 'overlay',
                key: `tile-${def.id}-${dir.dir}-${partId}-p-${idx}`,
                label: markLayer.label,
                grid: markLayer.grid,
              });
            });
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
        const built = buildMarkingLayersForDir(
          def,
          entry,
          dir.dir,
          digitigrade,
          canvasWidth,
          canvasHeight,
          markingOffsetX,
          signalAssetUpdate
        );
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
      const overlayLayers = baseLayers.filter(
        (layer) => layer.type === 'overlay'
      );
      const nonOverlayLayers = baseLayers.filter(
        (layer) => layer.type !== 'overlay'
      );
      const referenceMasks = hasHiddenParts
        ? buildReferencePartMaskMap(
            nonOverlayLayers as Array<{
              key?: string;
              type?: string;
              grid?: string[][];
            }>
          )
        : {};
      const normalLayers: typeof baseLayers = [];
      const priorityLayers: typeof baseLayers = [];
      nonOverlayLayers.forEach((layer) => {
        const partId = resolveLayerPartId(layer);
        const isHiddenPart = !!(partId && hiddenPartsMap[partId]);
        let resolvedLayer = layer;
        if (
          partId === 'generic' &&
          hasHiddenParts &&
          Array.isArray(layer.grid)
        ) {
          resolvedLayer = {
            ...layer,
            grid: buildMaskedGenericGrid(
              layer.grid as string[][],
              referenceMasks,
              hiddenPartsMap
            ),
          };
        }
        if (!isHiddenPart) {
          normalLayers.push(resolvedLayer);
        }
        if (!partId || !layerGroup[partId]) {
          return;
        }
        const partLayers = layerGroup[partId];
        partLayers.normal.forEach((markLayer, idx) => {
          normalLayers.push({
            type: 'custom',
            key: `mark-${dirEntry.dir}-${partId}-n-${idx}`,
            label: markLayer.label,
            grid: markLayer.grid,
          });
        });
        partLayers.priority.forEach((markLayer, idx) => {
          priorityLayers.push({
            type: 'overlay',
            key: `mark-priority-${dirEntry.dir}-${partId}-p-${idx}`,
            label: markLayer.label,
            grid: markLayer.grid,
          });
        });
      });
      return {
        ...dirEntry,
        layers: [...normalLayers, ...priorityLayers, ...overlayLayers],
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
