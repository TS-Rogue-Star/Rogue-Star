// //////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star August 2026: New species selection tab added //
// //////////////////////////////////////////////////////////////////////////////

import { Component, type InfernoNode } from 'inferno';
import {
  backendSetSharedStates,
  selectBackend,
  useBackend,
  useLocalState,
} from '../../backend';
import {
  Box,
  Button,
  Flex,
  Icon,
  Input,
  LabeledList,
  NoticeBox,
  Section,
  Tabs,
  Tooltip,
} from '../../components';
import { sanitizeText } from '../../sanitize';
import {
  buildRenderedPreviewDirs as buildBasePreviewDirs,
  getPreviewGridFromAsset,
  type PreviewDirectionEntry,
  type PreviewDirectionSource,
  type PreviewDirState,
  type PreviewLayerEntry,
} from '../../utils/character-preview';
import {
  DirectionPreviewCanvas,
  LivePreviewCard,
  LoadingOverlay,
} from './components';
import { CHIP_BUTTON_CLASS } from './constants';
import {
  applyLimbHairColorToPreview,
  applyProstheticsToPreviewSources,
  buildBasicStateFromPayload,
  buildBodyPartLabelMap,
  buildSpeciesSaveCacheParams,
  CUSTOM_SPECIES_ID,
  deepCopyMarkings,
  isSpeciesDraftDirty,
  isSpeciesSaveAllowed,
  mergeSpeciesBodyPreviewSource,
  resolveBasicPreviewSourceSelection,
  resolveSpeciesBodyPreviewSources,
  resolveSpeciesIconBaseOptions,
  shouldReuseBasicPreviewCarrier,
  shouldUseSpeciesPreviewOverride,
  updatePreviewStateFromPayload,
} from './utils';
import { buildBodyMarkingsPreviewBases } from './BodyMarkingsTab';
import {
  applyBodyMarkingsToPreview,
  resolveBodyMarkingsContext,
  type BodyMarkingDefinitionCache,
  type BodyMarkingsPreviewCache,
  type BodyMarkingsSignatureCache,
  type MarkingLayersCacheEntry,
} from './BasicAppearanceTab';
import { buildSuppressedMarkingPartsByDir } from './utils/markingOverrides';
import { advanceSpeciesAssetRevision } from './utils/speciesAssetUpdate';
import type {
  BasicAppearancePayload,
  BasicAppearanceState,
  BodyMarkingEntry,
  BodyMarkingsPayload,
  CanvasBackgroundOption,
  CustomMarkingDesignerData,
  SpeciesDefinition,
  SpeciesIconBaseOption,
  SpeciesPayload,
} from './types';

type SpeciesTabProps = Readonly<{
  data: CustomMarkingDesignerData;
  setPendingClose: (state: boolean) => void;
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

const MARKING_TILE_PIXEL_SIZE = 4;
let assetUpdateScheduled = false;

const SPECIES_TILE_PREVIEWS: PreviewDirectionEntry[] = [
  { dir: 2, label: 'South', layers: [] },
];
const EMPTY_SPECIES_TILE_PREVIEWS: PreviewDirectionEntry[] = [];
const SPECIES_NEUTRAL_BODY_COLOR = '#ffffff';
const HUMAN_SPECIES_ID = 'Human';
const DEFAULT_CUSTOM_SPECIES_NAME_MAX_LENGTH = 52;

type SpeciesTilePreviewOptions = Readonly<{
  def: SpeciesGalleryEntry;
  canvasWidth: number;
  canvasHeight: number;
  hairColor: string | null;
  signalAssetUpdate: () => void;
}>;

type SpeciesTilePreviewCacheEntry = {
  def: SpeciesGalleryEntry;
  sourceSignature: string;
  canvasWidth: number;
  canvasHeight: number;
  hairColor: string | null;
  assetRevision: number;
  previews: PreviewDirectionEntry[];
};

const buildSpeciesTileSourceSignature = (def: SpeciesGalleryEntry) =>
  JSON.stringify([
    def.preview_assets || null,
    def.body_preview_sources || null,
  ]) || '';

const buildSpeciesTilePreviewsFromSources = ({
  def,
  canvasWidth,
  canvasHeight,
  hairColor,
  signalAssetUpdate,
}: SpeciesTilePreviewOptions): PreviewDirectionEntry[] => {
  const previewSources = def.body_preview_sources;
  if (!previewSources?.length) {
    return [];
  }
  const previewDirStates = updatePreviewStateFromPayload(
    { revision: 0, lastDiffSeq: 0, dirs: {} },
    {
      data: {
        preview_sources: previewSources,
        preview_revision: 1,
        active_dir_key: 2,
        active_dir: 'South',
        grid: [],
      } as any,
      sessionKey: `species-tile-${def.id}`,
      activePartKey: 'generic',
      canvasWidth,
      canvasHeight,
      canvasGrid: null,
    }
  ).dirs;
  return applyLimbHairColorToPreview(
    buildBasePreviewDirs(
      previewDirStates,
      SPECIES_TILE_PREVIEWS,
      {},
      canvasWidth,
      canvasHeight,
      signalAssetUpdate
    ),
    hairColor
  );
};

const buildSpeciesTilePreviews = ({
  def,
  canvasWidth,
  canvasHeight,
  hairColor,
  signalAssetUpdate,
}: SpeciesTilePreviewOptions): PreviewDirectionEntry[] => {
  const hasAuthoredLimbHair = def.body_preview_sources?.some(
    (source) =>
      !!source.reference_part_hair_assets &&
      Object.keys(source.reference_part_hair_assets).length > 0
  );
  if (hasAuthoredLimbHair) {
    const authoredBodyPreview = buildSpeciesTilePreviewsFromSources({
      def,
      canvasWidth,
      canvasHeight,
      hairColor,
      signalAssetUpdate,
    });
    if (authoredBodyPreview.length) {
      return authoredBodyPreview;
    }
  }
  const previewAssets = def.preview_assets;
  if (previewAssets && Object.keys(previewAssets).length) {
    const previews = SPECIES_TILE_PREVIEWS.map((preview) => {
      const asset = previewAssets[`${preview.dir}`];
      if (!asset) {
        return preview;
      }
      const grid = getPreviewGridFromAsset(
        asset,
        canvasWidth,
        canvasHeight,
        signalAssetUpdate
      );
      const layers: PreviewLayerEntry[] = grid
        ? [
            {
              type: 'body',
              key: `${def.id}-preview-${preview.dir}`,
              grid: grid as string[][],
            },
          ]
        : [];
      return {
        ...preview,
        layers,
      };
    });
    if (previews.some((preview) => preview.layers.length)) {
      return previews;
    }
  }
  const bodyPreview = buildSpeciesTilePreviewsFromSources({
    def,
    canvasWidth,
    canvasHeight,
    hairColor,
    signalAssetUpdate,
  });
  return bodyPreview.length ? bodyPreview : SPECIES_TILE_PREVIEWS;
};

type SpeciesGalleryMode = 'species' | 'icon_base';

type SpeciesGalleryEntry = Readonly<{
  id: string;
  name: string;
  preview_assets?: SpeciesDefinition['preview_assets'];
  body_preview_sources?: SpeciesDefinition['body_preview_sources'];
  body_color_blend_mode?: SpeciesDefinition['body_color_blend_mode'];
  icon_base_count?: SpeciesDefinition['icon_base_count'];
  selectable?: SpeciesDefinition['selectable'];
  whitelist_locked?: SpeciesDefinition['whitelist_locked'];
  restricted_reason?: string | null;
}>;

const compareByName = (a: SpeciesGalleryEntry, b: SpeciesGalleryEntry) =>
  a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }) ||
  a.id.localeCompare(b.id, undefined, { sensitivity: 'base' });

const formatModifierValue = (value: number | string | boolean) => {
  if (typeof value === 'number') {
    return Number.isInteger(value) ? value.toString() : value.toFixed(2);
  }
  if (typeof value === 'boolean') {
    return value ? 'Yes' : 'No';
  }
  return value;
};

type SpeciesTileProps = Readonly<{
  def: SpeciesGalleryEntry;
  selected: boolean;
  disabled: boolean;
  onSelect: (id: string | null) => void;
  previews: PreviewDirectionEntry[];
  canvasWidth: number;
  canvasHeight: number;
  iconBaseCount: number;
}>;

class SpeciesTile extends Component<SpeciesTileProps> {
  private handleToggle = () => {
    const { def, selected, onSelect } = this.props;
    onSelect(selected ? null : def.id);
  };

  shouldComponentUpdate(next: SpeciesTileProps) {
    return (
      next.selected !== this.props.selected ||
      next.disabled !== this.props.disabled ||
      next.previews !== this.props.previews ||
      next.canvasWidth !== this.props.canvasWidth ||
      next.canvasHeight !== this.props.canvasHeight ||
      next.iconBaseCount !== this.props.iconBaseCount ||
      next.def.id !== this.props.def.id ||
      next.def.name !== this.props.def.name ||
      next.def.whitelist_locked !== this.props.def.whitelist_locked ||
      next.def.restricted_reason !== this.props.def.restricted_reason
    );
  }

  render() {
    const {
      def,
      selected,
      disabled,
      previews,
      canvasWidth,
      canvasHeight,
      iconBaseCount,
    } = this.props;
    const preview =
      previews.find((entry) => entry.dir === 2) || previews[0] || null;
    const hasMultipleIconBases = iconBaseCount > 1;
    const whitelistLocked = !!def.whitelist_locked;
    const tileTitle = whitelistLocked
      ? `${def.name}: requires whitelist approval`
      : disabled
        ? def.restricted_reason || def.name
        : hasMultipleIconBases
          ? `${def.name}: choose from ${iconBaseCount} icon bases`
          : def.name;
    return (
      <Box
        className={`RogueStar__markingTile${
          selected ? ' RogueStar__markingTile--selected' : ''
        }${whitelistLocked ? ' RogueStar__markingTile--whitelistLocked' : ''}`}
        onClick={disabled ? undefined : this.handleToggle}
        style={
          disabled
            ? {
                opacity: whitelistLocked ? 0.78 : 0.6,
                cursor: 'not-allowed',
              }
            : undefined
        }
        title={tileTitle}>
        <Box
          className="RogueStar__markingTilePreviewGrid"
          style={{ display: 'flex' }}>
          <Box className="RogueStar__markingTilePreview">
            {hasMultipleIconBases ? (
              <Box className="RogueStar__speciesTileMultipleBases">
                <Icon name="layer-group" size={3} />
                <Box className="RogueStar__speciesTileMultipleBasesLabel">
                  {iconBaseCount} icon bases
                </Box>
              </Box>
            ) : (
              <DirectionPreviewCanvas
                baseLayers={preview?.layers || []}
                bodyAlpha={preview?.bodyAlpha}
                pixelSize={MARKING_TILE_PIXEL_SIZE}
                width={canvasWidth}
                height={canvasHeight}
              />
            )}
          </Box>
        </Box>
        <Box className="RogueStar__markingTileLabel" title={def.name}>
          {def.name}
        </Box>
      </Box>
    );
  }
}

type SpeciesTileSectionProps = Readonly<{
  definitions: SpeciesGalleryEntry[];
  canvasWidth: number;
  canvasHeight: number;
  search: string;
  page: number;
  onPageChange: (page: number) => void;
  selectedId: string | null;
  onSelect: (id: string | null) => void;
  hairColor: string | null;
  assetRevision: number;
  signalAssetUpdate: () => void;
}>;

class SpeciesTileSection extends Component<SpeciesTileSectionProps> {
  private previewCache = new Map<string, SpeciesTilePreviewCacheEntry>();
  private handleSelect = (id: string | null) => this.props.onSelect(id);

  shouldComponentUpdate(next: SpeciesTileSectionProps) {
    return (
      next.definitions !== this.props.definitions ||
      next.canvasWidth !== this.props.canvasWidth ||
      next.canvasHeight !== this.props.canvasHeight ||
      next.search !== this.props.search ||
      next.page !== this.props.page ||
      next.selectedId !== this.props.selectedId ||
      next.hairColor !== this.props.hairColor ||
      next.assetRevision !== this.props.assetRevision
    );
  }

  private getTilePreviews(def: SpeciesGalleryEntry) {
    const {
      canvasWidth,
      canvasHeight,
      hairColor,
      assetRevision,
      signalAssetUpdate,
    } = this.props;
    const cached = this.previewCache.get(def.id);
    const contextMatches =
      cached &&
      cached.canvasWidth === canvasWidth &&
      cached.canvasHeight === canvasHeight &&
      cached.hairColor === hairColor &&
      cached.assetRevision === assetRevision;
    if (contextMatches && cached.def === def) {
      return cached.previews;
    }
    const sourceSignature = buildSpeciesTileSourceSignature(def);
    if (contextMatches && cached.sourceSignature === sourceSignature) {
      cached.def = def;
      return cached.previews;
    }
    const previews = buildSpeciesTilePreviews({
      def,
      canvasWidth,
      canvasHeight,
      hairColor,
      signalAssetUpdate,
    });
    this.previewCache.set(def.id, {
      def,
      sourceSignature,
      canvasWidth,
      canvasHeight,
      hairColor,
      assetRevision,
      previews,
    });
    return previews;
  }

  render() {
    const {
      definitions,
      canvasWidth,
      canvasHeight,
      search,
      page,
      onPageChange,
      selectedId,
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
            const disabled = def.selectable === false || def.selectable === 0;
            const iconBaseCount = def.icon_base_count || 0;
            const previews =
              iconBaseCount > 1
                ? EMPTY_SPECIES_TILE_PREVIEWS
                : this.getTilePreviews(def);
            return (
              <SpeciesTile
                key={def.id}
                def={def}
                selected={selected}
                disabled={disabled}
                previews={previews}
                canvasWidth={canvasWidth}
                canvasHeight={canvasHeight}
                iconBaseCount={iconBaseCount}
                onSelect={this.handleSelect}
              />
            );
          })}
          {!filtered.length && (
            <NoticeBox>No entries found for this filter.</NoticeBox>
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
                Page {currentPage + 1} / {totalPages} - Showing {showStart}-
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

type SpeciesGallerySectionProps = Readonly<{
  search: string;
  setSearch: (search: string) => void;
  tilePage: number;
  setTilePage: (page: number) => void;
  definitions: SpeciesDefinition[];
  iconBaseOptions: SpeciesIconBaseOption[];
  activeGallery: SpeciesGalleryMode;
  setActiveGallery: (mode: SpeciesGalleryMode) => void;
  selectedId: string | null;
  selectedIconBase: string | null;
  canvasWidth: number;
  canvasHeight: number;
  hairColor: string | null;
  assetRevision: number;
  onSelect: (id: string | null) => void;
  onSelectIconBase: (id: string | null) => void;
  signalAssetUpdate: () => void;
}>;

const SpeciesGallerySection = ({
  search,
  setSearch,
  tilePage,
  setTilePage,
  definitions,
  iconBaseOptions,
  activeGallery,
  setActiveGallery,
  selectedId,
  selectedIconBase,
  canvasWidth,
  canvasHeight,
  hairColor,
  assetRevision,
  onSelect,
  onSelectIconBase,
  signalAssetUpdate,
}: SpeciesGallerySectionProps) => {
  const showIconBaseTab = iconBaseOptions.length > 1;
  const resolvedGallery =
    showIconBaseTab && activeGallery === 'icon_base' ? 'icon_base' : 'species';
  const galleryDefinitions =
    resolvedGallery === 'icon_base' ? iconBaseOptions : definitions;
  const gallerySelectedId =
    resolvedGallery === 'icon_base' ? selectedIconBase : selectedId;
  const gallerySelect =
    resolvedGallery === 'icon_base' ? onSelectIconBase : onSelect;
  return (
    <Section
      title="Species Gallery"
      fill
      buttons={
        showIconBaseTab ? (
          <Tabs>
            <Tabs.Tab
              selected={resolvedGallery === 'species'}
              onClick={() => {
                setActiveGallery('species');
                setTilePage(0);
              }}>
              Species
            </Tabs.Tab>
            <Tabs.Tab
              selected={resolvedGallery === 'icon_base'}
              onClick={() => {
                setActiveGallery('icon_base');
                setTilePage(0);
              }}>
              Icon Base
            </Tabs.Tab>
          </Tabs>
        ) : null
      }>
      <Box mb={1}>
        <Input
          fluid
          value={search}
          placeholder={
            resolvedGallery === 'icon_base'
              ? 'Search icon bases...'
              : 'Search species...'
          }
          onInput={(e, value) => {
            setSearch(value);
            setTilePage(0);
          }}
        />
      </Box>
      <SpeciesTileSection
        definitions={galleryDefinitions}
        canvasWidth={canvasWidth}
        canvasHeight={canvasHeight}
        search={search}
        page={tilePage}
        onPageChange={setTilePage}
        selectedId={gallerySelectedId}
        onSelect={gallerySelect}
        hairColor={hairColor}
        assetRevision={assetRevision}
        signalAssetUpdate={signalAssetUpdate}
      />
    </Section>
  );
};

type SpeciesSaveSectionProps = Readonly<{
  pendingSave: boolean;
  pendingClose: boolean;
  uiLocked: boolean;
  dirty: boolean;
  saveBlocked: boolean;
  onSave: () => void;
  onSaveAndClose: () => void;
  onDiscardAndClose: () => void;
}>;

const SpeciesSaveSection = ({
  pendingSave,
  pendingClose,
  uiLocked,
  dirty,
  saveBlocked,
  onSave,
  onSaveAndClose,
  onDiscardAndClose,
}: SpeciesSaveSectionProps) => (
  <Section title="Save">
    <Flex justify="space-between" wrap className="RogueStar__sessionButtons">
      <Flex.Item>
        <Button
          className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--positive`}
          icon={pendingSave ? 'spinner-third' : 'save'}
          iconSpin={pendingSave}
          disabled={
            pendingClose || pendingSave || uiLocked || saveBlocked || !dirty
          }
          onClick={onSave}>
          Save
        </Button>
      </Flex.Item>
      <Flex.Item>
        <Button
          className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--positive`}
          icon={pendingClose ? 'spinner-third' : 'floppy-disk'}
          iconSpin={pendingClose}
          disabled={pendingClose || pendingSave || uiLocked || saveBlocked}
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

type SpeciesNameSectionProps = Readonly<{
  value: string;
  maxLength: number;
  required: boolean;
  disabled: boolean;
  onInput: (value: string) => void;
}>;

const SpeciesNameSection = ({
  value,
  maxLength,
  required,
  disabled,
  onInput,
}: SpeciesNameSectionProps) => (
  <Section
    title={
      <SpeciesTooltipLabel
        label="Species Name Override"
        description="Optional for most species, but required when Custom Species is selected."
      />
    }>
    <Input
      fluid
      value={value}
      maxLength={maxLength}
      placeholder={
        required
          ? 'Enter a species name...'
          : 'Optional species name override...'
      }
      disabled={disabled}
      onInput={(event, nextValue) => onInput(nextValue)}
    />
    {required && !value.trim() && (
      <NoticeBox danger mt={1} mb={0}>
        A name is required before you can save this custom species.
      </NoticeBox>
    )}
  </Section>
);

type SpeciesDetailsSectionProps = Readonly<{
  modifiers: SpeciesDefinition['modifiers'];
  traits: SpeciesDefinition['traits'];
  detailSections?: SpeciesDefinition['detail_sections'];
  activeDetailSection: string | null;
  onSelectDetailSection: (sectionId: string) => void;
}>;

type SpeciesDetailSeverity = NonNullable<
  SpeciesDefinition['detail_sections']
>[number]['entries'][number]['severity'];

type SpeciesDetailSectionEntry = NonNullable<
  SpeciesDefinition['detail_sections']
>[number];

const STANDARD_SPECIES_DETAIL_SECTIONS: SpeciesDetailSectionEntry[] = [
  { id: 'survival', title: 'Atmosphere & Survival', entries: [] },
  { id: 'environment', title: 'Temperature & Pressure', entries: [] },
  { id: 'damage', title: 'Damage & Medicine', entries: [] },
  { id: 'body', title: 'Body & Physiology', entries: [] },
  { id: 'biochemical', title: 'Biochemical', entries: [] },
  { id: 'movement', title: 'Movement & Senses', entries: [] },
  { id: 'abilities', title: 'Abilities & Restrictions', entries: [] },
  { id: 'languages', title: 'Languages & Culture', entries: [] },
];

const buildSpeciesDetailSections = (
  detailSections: NonNullable<SpeciesDefinition['detail_sections']>
) => {
  const receivedSections = detailSections.filter((section) =>
    Array.isArray(section.entries)
  );
  const standardSectionIds = STANDARD_SPECIES_DETAIL_SECTIONS.map(
    (section) => section.id
  );
  return [
    ...STANDARD_SPECIES_DETAIL_SECTIONS.map(
      (standardSection) =>
        receivedSections.find((section) => section.id === standardSection.id) ||
        standardSection
    ),
    ...receivedSections.filter(
      (section) => !standardSectionIds.includes(section.id)
    ),
  ];
};

const getSpeciesDetailSeverityColor = (severity?: SpeciesDetailSeverity) => {
  if (severity === 'critical') {
    return 'bad';
  }
  if (severity === 'warning') {
    return 'average';
  }
  if (severity === 'positive') {
    return 'good';
  }
  return undefined;
};

const hasDetailValue = (
  value: number | string | boolean | null | undefined
): value is number | string | boolean =>
  value !== null && value !== undefined && value !== '';

type SpeciesTooltipLabelProps = Readonly<{
  label: string;
  description?: string | null;
  colon?: boolean;
}>;

const SpeciesTooltipLabel = ({
  label,
  description,
  colon,
}: SpeciesTooltipLabelProps) => {
  if (!description) {
    return label;
  }
  return (
    <Tooltip content={description} position="left">
      <Box
        as="span"
        style={{ cursor: 'help', 'text-decoration': 'underline dotted' }}>
        {label}
        {colon ? ':' : ''}
      </Box>
    </Tooltip>
  );
};

const getSpeciesDetailTabLabel = (section: SpeciesDetailSectionEntry) => {
  switch (section.id) {
    case 'survival':
      return 'Atmosphere';
    case 'environment':
      return 'Climate';
    case 'damage':
      return 'Damage';
    case 'body':
      return 'Body';
    case 'biochemical':
      return 'Biochemical';
    case 'movement':
      return 'Movement';
    case 'abilities':
      return 'Abilities';
    case 'languages':
      return 'Languages';
    default:
      return section.title;
  }
};

const getSpeciesDetailTabIcon = (section: SpeciesDetailSectionEntry) => {
  switch (section.id) {
    case 'survival':
      return 'wind';
    case 'environment':
      return 'thermometer-half';
    case 'damage':
      return 'heartbeat';
    case 'body':
      return 'dna';
    case 'biochemical':
      return 'flask';
    case 'movement':
      return 'walking';
    case 'abilities':
      return 'bolt';
    case 'languages':
      return 'comments';
    default:
      return 'star';
  }
};

const getSpeciesDetailSeverityClassName = (
  severity?: SpeciesDetailSeverity
) => {
  switch (severity) {
    case 'critical':
    case 'warning':
    case 'positive':
    case 'info':
      return `RogueStar__speciesDetailCard--${severity}`;
    default:
      return '';
  }
};

type SpeciesStructuredDetailsProps = Readonly<{
  detailSections: NonNullable<SpeciesDefinition['detail_sections']>;
  activeDetailSection: string | null;
  onSelectDetailSection: (sectionId: string) => void;
}>;

const SpeciesStructuredDetails = ({
  detailSections,
  activeDetailSection,
  onSelectDetailSection,
}: SpeciesStructuredDetailsProps) => {
  const availableSections = buildSpeciesDetailSections(detailSections);
  if (!availableSections.length) {
    return (
      <NoticeBox>
        No player-facing mechanics differ from the human baseline.
      </NoticeBox>
    );
  }
  const selectedSection =
    availableSections.find((section) => section.id === activeDetailSection) ||
    availableSections[0];
  const differenceCount = selectedSection.entries.length;
  const isLanguageSection = selectedSection.id === 'languages';
  return (
    <Box className="RogueStar__speciesDetails">
      {availableSections.length > 1 ? (
        <Box className="RogueStar__speciesDetailNav">
          {availableSections.map((section) => (
            <Button
              className="RogueStar__speciesDetailTab"
              key={section.id}
              icon={getSpeciesDetailTabIcon(section)}
              selected={section.id === selectedSection.id}
              tooltip={section.title}
              tooltipPosition="bottom"
              onClick={() => onSelectDetailSection(section.id)}>
              <Box as="span" className="RogueStar__speciesDetailTabLabel">
                {getSpeciesDetailTabLabel(section)}
              </Box>
            </Button>
          ))}
        </Box>
      ) : null}
      <Box className="RogueStar__speciesDetailHeader">
        <Box className="RogueStar__speciesDetailHeaderIcon">
          <Icon name={getSpeciesDetailTabIcon(selectedSection)} />
        </Box>
        <Box className="RogueStar__speciesDetailHeaderCopy">
          <Box className="RogueStar__speciesDetailHeaderTitle">
            {selectedSection.title}
          </Box>
          <Box className="RogueStar__speciesDetailHeaderSummary">
            {isLanguageSection
              ? differenceCount
                ? `${differenceCount} language ${
                    differenceCount === 1 ? 'detail' : 'details'
                  }`
                : 'No language information listed'
              : differenceCount
                ? `${differenceCount} ${
                    differenceCount === 1 ? 'difference' : 'differences'
                  } from the human baseline`
                : 'No differences from the human baseline'}
          </Box>
        </Box>
      </Box>
      <Box className="RogueStar__speciesDetailList">
        {differenceCount ? (
          selectedSection.entries.map((entry) => {
            const color = getSpeciesDetailSeverityColor(entry.severity);
            const severityClassName = getSpeciesDetailSeverityClassName(
              entry.severity
            );
            return (
              <Box
                key={entry.id}
                className={`RogueStar__speciesDetailCard ${severityClassName}`}>
                <Box className="RogueStar__speciesDetailCardLabel">
                  <SpeciesTooltipLabel
                    label={entry.label}
                    description={entry.description}
                  />
                </Box>
                <Box className="RogueStar__speciesDetailComparison">
                  {hasDetailValue(entry.value) ? (
                    <Box className="RogueStar__speciesDetailValue">
                      <Box className="RogueStar__speciesDetailValueLabel">
                        Selected species
                      </Box>
                      <Box
                        className="RogueStar__speciesDetailValueText"
                        color={color}>
                        {formatModifierValue(entry.value)}
                      </Box>
                    </Box>
                  ) : null}
                  {hasDetailValue(entry.baseline_value) ? (
                    <Box className="RogueStar__speciesDetailValue RogueStar__speciesDetailValue--baseline">
                      <Box className="RogueStar__speciesDetailValueLabel">
                        Human baseline
                      </Box>
                      <Box className="RogueStar__speciesDetailValueText">
                        {formatModifierValue(entry.baseline_value)}
                      </Box>
                    </Box>
                  ) : null}
                </Box>
              </Box>
            );
          })
        ) : (
          <Box className="RogueStar__speciesDetailEmpty">
            <Box className="RogueStar__speciesDetailEmptyIcon">
              <Icon name={isLanguageSection ? 'comments' : 'check'} />
            </Box>
            <Box className="RogueStar__speciesDetailEmptyCopy">
              <Box className="RogueStar__speciesDetailEmptyTitle">
                {isLanguageSection
                  ? 'No language information listed'
                  : 'Matches the human baseline'}
              </Box>
              <Box className="RogueStar__speciesDetailEmptyText">
                {isLanguageSection
                  ? 'This species has no listed language associations or defaults.'
                  : 'This species has no listed differences in this category.'}
              </Box>
            </Box>
          </Box>
        )}
      </Box>
    </Box>
  );
};

const SpeciesDetailsSection = ({
  modifiers,
  traits,
  detailSections,
  activeDetailSection,
  onSelectDetailSection,
}: SpeciesDetailsSectionProps) => (
  <Section
    className="RogueStar__speciesDetailsSection"
    title="Species Details"
    fill
    scrollable>
    {Array.isArray(detailSections) ? (
      <SpeciesStructuredDetails
        detailSections={detailSections}
        activeDetailSection={activeDetailSection}
        onSelectDetailSection={onSelectDetailSection}
      />
    ) : (
      <>
        <Box color="label" fontWeight="bold" mb={0.5}>
          Modifiers
        </Box>
        {modifiers.length ? (
          <LabeledList>
            {modifiers.map((modifier) => (
              <LabeledList.Item
                key={modifier.id}
                label={
                  <SpeciesTooltipLabel
                    label={modifier.label || modifier.id}
                    description={modifier.description}
                    colon
                  />
                }>
                <Box>{formatModifierValue(modifier.value)}</Box>
              </LabeledList.Item>
            ))}
          </LabeledList>
        ) : (
          <NoticeBox>No modifiers differ from the human baseline.</NoticeBox>
        )}
        <Box color="label" fontWeight="bold" mt={1} mb={0.5}>
          Special Traits
        </Box>
        {traits.length ? (
          <Box>
            {traits.map((trait) => (
              <Box key={trait.id || trait.name} mb={0.5}>
                <Box fontWeight="bold">
                  <SpeciesTooltipLabel
                    label={trait.name}
                    description={trait.description}
                  />
                </Box>
              </Box>
            ))}
          </Box>
        ) : (
          <NoticeBox>
            No special traits differ from the human baseline.
          </NoticeBox>
        )}
      </>
    )}
  </Section>
);

type SpeciesPreviewColumnProps = Readonly<{
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
  blurb: string;
  whitelistLocked: boolean;
}>;

const sanitizeSpeciesBlurb = (blurb: string) =>
  sanitizeText(blurb, false, ['br', 'i']);

const renderSpeciesBlurbNodes = (
  nodes: NodeListOf<ChildNode>,
  keyPrefix: string
): InfernoNode[] =>
  Array.from(nodes).map((node, index) => {
    const key = `${keyPrefix}-${index}`;

    if (node.nodeType === Node.TEXT_NODE) {
      return node.textContent || '';
    }

    if (node.nodeName === 'BR') {
      return <br key={key} />;
    }

    if (node.nodeName === 'I') {
      return <i key={key}>{renderSpeciesBlurbNodes(node.childNodes, key)}</i>;
    }

    return null;
  });

const renderSpeciesBlurb = (blurb: string) => {
  const document = new DOMParser().parseFromString(
    sanitizeSpeciesBlurb(blurb || 'No species blurb available.'),
    'text/html'
  );

  return renderSpeciesBlurbNodes(document.body.childNodes, 'species-blurb');
};

const SpeciesPreviewColumn = ({
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
  blurb,
  whitelistLocked,
}: SpeciesPreviewColumnProps) => (
  <Flex direction="column" gap={1} height="100%" minHeight={0}>
    <Flex.Item basis="448px" shrink={0} minHeight={0}>
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
    </Flex.Item>
    <Flex.Item grow minHeight={0}>
      <Section
        className="RogueStar__speciesBlurbSection"
        title="Species Blurb"
        fill
        scrollable>
        {whitelistLocked && (
          <NoticeBox danger mb={1}>
            <Box fontWeight="bold" mb={0.5}>
              <Icon name="lock" /> Whitelist Required
            </Box>
            You are not currently whitelisted to play this species. It cannot be
            used to join the round until whitelist approval is granted.
          </NoticeBox>
        )}
        <div>{renderSpeciesBlurb(blurb)}</div>
      </Section>
    </Flex.Item>
  </Flex>
);

type SpeciesInitializerProps = Readonly<{
  speciesPayload: SpeciesPayload | null;
  dataPayload?: SpeciesPayload | null;
  requestPayload: () => void;
  syncPayload: (payload: SpeciesPayload) => void;
  loadInProgress: boolean;
  reloadPending: boolean;
  setLoadInProgress: (value: boolean) => void;
}>;

class SpeciesInitializer extends Component<SpeciesInitializerProps> {
  private hasRequested = false;
  private lastDataPayload: SpeciesPayload | null = null;

  componentDidMount() {
    if (this.props.reloadPending) {
      this.lastDataPayload = this.props.dataPayload || null;
    }
    this.requestIfNeeded();
    this.syncIfNeeded();
  }

  componentDidUpdate(prevProps: SpeciesInitializerProps) {
    if (
      prevProps.speciesPayload !== this.props.speciesPayload ||
      prevProps.dataPayload !== this.props.dataPayload ||
      prevProps.reloadPending !== this.props.reloadPending
    ) {
      this.requestIfNeeded();
      this.syncIfNeeded();
    }
  }

  requestIfNeeded() {
    const {
      speciesPayload,
      dataPayload,
      requestPayload,
      loadInProgress,
      reloadPending,
      setLoadInProgress,
    } = this.props;
    if (
      !speciesPayload &&
      (!dataPayload || reloadPending) &&
      !this.hasRequested &&
      !loadInProgress
    ) {
      this.hasRequested = true;
      setLoadInProgress(true);
      requestPayload();
    }
  }

  syncIfNeeded() {
    const { dataPayload, syncPayload } = this.props;
    if (!dataPayload) {
      this.lastDataPayload = null;
      return;
    }
    if (dataPayload === this.lastDataPayload) {
      return;
    }
    this.lastDataPayload = dataPayload;
    syncPayload(dataPayload);
  }

  render() {
    return null;
  }
}

const isBodyPayloadForSpecies = (
  payload: BodyMarkingsPayload | null | undefined,
  speciesId: string | null,
  iconBaseId?: string | null
) =>
  !!payload &&
  !!speciesId &&
  payload.species_id === speciesId &&
  (!iconBaseId || payload.custom_base === iconBaseId);

const optionListContains = (
  options: SpeciesIconBaseOption[] | undefined,
  value: string | null
) => !!value && !!options?.some((option) => option.id === value);

const resolvePayloadIconBase = (
  payload: SpeciesPayload | null | undefined,
  fallback?: string | null
) => {
  const options = payload?.icon_base_options || [];
  const preview =
    payload?.preview_icon_base || payload?.selected_icon_base || null;
  if (optionListContains(options, fallback || null)) {
    return fallback || null;
  }
  if (optionListContains(options, preview)) {
    return preview;
  }
  return options[0]?.id || preview || null;
};

const isPreviewPayloadForSelection = (
  payload:
    | Pick<BodyMarkingsPayload, 'species_id' | 'custom_base'>
    | Pick<BasicAppearancePayload, 'species_id' | 'custom_base'>
    | null,
  selectedSpeciesId: string | null,
  selectedIconBase: string | null
) => {
  if (!selectedSpeciesId || !payload?.species_id) {
    return true;
  }
  if (payload.species_id !== selectedSpeciesId) {
    return false;
  }
  return !selectedIconBase || payload.custom_base === selectedIconBase;
};

const useSpeciesTabLocalState = (
  context,
  data: CustomMarkingDesignerData,
  stateToken: string
) => {
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
  const [, setDesignerReloadPending] = useLocalState<boolean>(
    context,
    `customMarkingDesignerReloadPending-${stateToken}`,
    false
  );
  const [, setReloadTargetRevision] = useLocalState<number>(
    context,
    `customMarkingDesignerReloadTargetRevision-${stateToken}`,
    0
  );
  const [, setBodyReloadPending] = useLocalState<boolean>(
    context,
    `bodyMarkingsReloadPending-${stateToken}`,
    false
  );
  const [, setBasicReloadPending] = useLocalState<boolean>(
    context,
    `basicAppearanceReloadPending-${stateToken}`,
    false
  );
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
  const [speciesSavedSelection, setSpeciesSavedSelection] = useLocalState<
    string | null
  >(
    context,
    'speciesSavedSelection',
    data.species_payload?.selected_species || null
  );
  const [speciesIconBaseSelection, setSpeciesIconBaseSelection] = useLocalState<
    string | null
  >(
    context,
    'speciesIconBaseSelection',
    data.species_payload?.preview_icon_base ||
      data.species_payload?.selected_icon_base ||
      null
  );
  const [speciesSavedIconBaseSelection, setSpeciesSavedIconBaseSelection] =
    useLocalState<string | null>(
      context,
      'speciesSavedIconBaseSelection',
      data.species_payload?.selected_icon_base ||
        data.species_payload?.preview_icon_base ||
        null
    );
  const [speciesCustomName] = useLocalState<string>(
    context,
    'speciesCustomName',
    data.species_payload?.custom_species || ''
  );
  const [speciesSavedCustomName] = useLocalState<string>(
    context,
    'speciesSavedCustomName',
    data.species_payload?.custom_species || ''
  );
  const [speciesDirty, setSpeciesDirty] = useLocalState<boolean>(
    context,
    'speciesDirty',
    false
  );
  const [pendingSave, setPendingSaveLocal] = useLocalState<boolean>(
    context,
    'speciesPendingSave',
    false
  );
  const [pendingClose, setPendingCloseLocal] = useLocalState<boolean>(
    context,
    'speciesPendingClose',
    false
  );
  const [loadInProgress, setLoadInProgress] = useLocalState<boolean>(
    context,
    `speciesLoadInProgress-${stateToken}`,
    false
  );
  const [assetRevision] = useLocalState<number>(
    context,
    'speciesAssetRevision',
    0
  );
  const [speciesReloadPending] = useLocalState<boolean>(
    context,
    `speciesReloadPending-${stateToken}`,
    false
  );
  const [search, setSearch] = useLocalState<string>(
    context,
    `speciesGallerySearch-${stateToken}`,
    ''
  );
  const [tilePage, setTilePage] = useLocalState<number>(
    context,
    `speciesGalleryPage-${stateToken}`,
    0
  );
  const [activeGallery, setActiveGallery] = useLocalState<SpeciesGalleryMode>(
    context,
    `speciesGalleryMode-${stateToken}`,
    'species'
  );
  const [activeDetailSection, setActiveDetailSection] = useLocalState<
    string | null
  >(context, `speciesDetailSection-${stateToken}`, null);
  const [bodyPayload, setBodyPayload] =
    useLocalState<BodyMarkingsPayload | null>(context, 'bodyPayload', null);
  const [bodyMarkingsState] = useLocalState<Record<string, BodyMarkingEntry>>(
    context,
    'bodyMarkingsState',
    deepCopyMarkings(data.body_markings_payload?.body_markings)
  );
  const [bodyMarkingsOrder] = useLocalState<string[]>(
    context,
    'bodyMarkingsOrder',
    (data.body_markings_payload?.order as string[]) || []
  );
  const [, setBodyMarkingsDirty] = useLocalState<boolean>(
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
  const [basicPayload, setBasicPayload] =
    useLocalState<BasicAppearancePayload | null>(context, 'basicPayload', null);
  const basicInitialState = buildBasicStateFromPayload(
    data.basic_appearance_payload
  );
  const [basicAppearanceState] = useLocalState<BasicAppearanceState>(
    context,
    'basicAppearanceState',
    basicInitialState
  );
  const [, setBasicAppearanceDirty] = useLocalState<boolean>(
    context,
    'basicAppearanceDirty',
    false
  );

  return {
    setCanvasFitToFrame,
    previewFitToFrame,
    setPreviewFitToFrame,
    setDesignerReloadPending,
    setReloadTargetRevision,
    setBodyReloadPending,
    setBasicReloadPending,
    speciesPayload,
    setSpeciesPayload,
    speciesSelection,
    speciesSavedSelection,
    setSpeciesSavedSelection,
    speciesIconBaseSelection,
    setSpeciesIconBaseSelection,
    speciesSavedIconBaseSelection,
    setSpeciesSavedIconBaseSelection,
    speciesCustomName,
    speciesSavedCustomName,
    speciesDirty,
    setSpeciesDirty,
    pendingSave,
    setPendingSaveLocal,
    pendingClose,
    setPendingCloseLocal,
    loadInProgress,
    setLoadInProgress,
    assetRevision,
    speciesReloadPending,
    search,
    setSearch,
    tilePage,
    setTilePage,
    activeGallery,
    setActiveGallery,
    activeDetailSection,
    setActiveDetailSection,
    bodyPayload,
    bodyMarkingsState,
    bodyMarkingsOrder,
    setBodyMarkingsDirty,
    markingLayersCache,
    bodyMarkingsPreviewCache,
    bodyMarkingDefinitionCache,
    bodyMarkingsSignatureCache,
    basicPayload,
    basicAppearanceState,
    setBasicAppearanceDirty,
  };
};

const buildSpeciesPreviewSourceMap = (
  sources?: PreviewDirectionSource[] | null
): Record<number, PreviewDirectionSource> | null => {
  if (!Array.isArray(sources) || !sources.length) {
    return null;
  }
  const byDir: Record<number, PreviewDirectionSource> = {};
  sources.forEach((entry) => {
    if (entry && typeof entry.dir === 'number') {
      byDir[entry.dir] = entry;
    }
  });
  return Object.keys(byDir).length ? byDir : null;
};

const hasSharedStateKey = (context: any, key: string) => {
  const sharedState = selectBackend(context.store.getState()).shared || {};
  return Object.prototype.hasOwnProperty.call(sharedState, key);
};

const resolveSelectedSpeciesState = (
  speciesPayload: SpeciesPayload | null,
  speciesSelection: string | null,
  speciesIconBaseSelection: string | null,
  digitigrade: boolean
) => {
  const selectedId =
    speciesSelection || speciesPayload?.selected_species || null;
  const selectedSpecies = speciesPayload?.species.find(
    (entry) => entry.id === selectedId
  );
  const humanSpecies = speciesPayload?.species.find(
    (entry) => entry.id === HUMAN_SPECIES_ID
  );
  const iconBaseOptions = resolveSpeciesIconBaseOptions(
    speciesPayload,
    selectedId
  );
  const selectedSpeciesPreviewSources = resolveSpeciesBodyPreviewSources({
    selectedSpecies,
    iconBaseOptions,
    iconBaseSelection: speciesIconBaseSelection,
    digitigrade,
  });
  const modifiers = selectedSpecies?.modifiers || [];
  const traits = selectedSpecies?.traits || [];
  const detailSections = selectedSpecies?.detail_sections;
  const humanModifierById = new Map(
    (humanSpecies?.modifiers || []).map((modifier) => [
      modifier.id,
      modifier.value,
    ])
  );
  const humanTraitKeys = new Set(
    (humanSpecies?.traits || []).map((trait) => trait.id || trait.name)
  );
  return {
    selectedId,
    selectedSpecies,
    iconBaseOptions,
    selectedSpeciesPreviewSources,
    selectedSpeciesPreviewByDir: buildSpeciesPreviewSourceMap(
      selectedSpeciesPreviewSources
    ),
    modifiers: modifiers.filter(
      (modifier) =>
        !humanModifierById.has(modifier.id) ||
        humanModifierById.get(modifier.id) !== modifier.value
    ),
    traits: traits.filter(
      (trait) => !humanTraitKeys.has(trait.id || trait.name)
    ),
    detailSections,
    blurb: selectedSpecies?.blurb || '',
    whitelistLocked: !!selectedSpecies?.whitelist_locked,
  };
};

const resolveSpeciesPreviewPayloads = (options: {
  data: CustomMarkingDesignerData;
  bodyPayload: BodyMarkingsPayload | null;
  basicPayload: BasicAppearancePayload | null;
  bodyPayloadCleared: boolean;
  basicPayloadCleared: boolean;
  basicAppearanceState: BasicAppearanceState;
}) => {
  const {
    data,
    bodyPayload,
    basicPayload,
    bodyPayloadCleared,
    basicPayloadCleared,
    basicAppearanceState,
  } = options;
  const dataBodyPayload = data.body_markings_payload || null;
  const dataBasicPayload = data.basic_appearance_payload || null;
  const resolvedBodyPayload = bodyPayloadCleared
    ? null
    : bodyPayload || dataBodyPayload;
  const resolvedBasicPayload = basicPayloadCleared
    ? null
    : basicPayload || dataBasicPayload;
  const previewAppearanceState = basicAppearanceState;
  const canvasWidth =
    resolvedBasicPayload?.preview_width ||
    resolvedBodyPayload?.preview_width ||
    64;
  const canvasHeight =
    resolvedBasicPayload?.preview_height ||
    resolvedBodyPayload?.preview_height ||
    64;

  return {
    resolvedBodyPayload,
    resolvedBasicPayload,
    previewAppearanceState,
    canvasWidth,
    canvasHeight,
  };
};

const resolveSelectedSpeciesBodyPayload = (options: {
  selectedSpeciesId: string | null;
  selectedIconBase: string | null;
  resolvedBodyPayload: BodyMarkingsPayload | null;
  dataBodyPayload?: BodyMarkingsPayload | null;
}) => {
  const {
    selectedSpeciesId,
    selectedIconBase,
    resolvedBodyPayload,
    dataBodyPayload,
  } = options;
  if (!selectedSpeciesId) {
    return resolvedBodyPayload;
  }
  if (
    isBodyPayloadForSpecies(
      resolvedBodyPayload,
      selectedSpeciesId,
      selectedIconBase
    )
  ) {
    return resolvedBodyPayload;
  }
  if (
    isBodyPayloadForSpecies(
      dataBodyPayload,
      selectedSpeciesId,
      selectedIconBase
    )
  ) {
    return dataBodyPayload || null;
  }
  return resolvedBodyPayload || dataBodyPayload || null;
};

const resolveSpeciesPreviewBodyMarkings = (options: {
  bodyPayload: BodyMarkingsPayload | null;
  bodyMarkingsState: Record<string, BodyMarkingEntry>;
  bodyMarkingsOrder: string[];
}) => {
  const { bodyPayload, bodyMarkingsState, bodyMarkingsOrder } = options;
  const localMarkingKeys = Object.keys(bodyMarkingsState || {});
  if (localMarkingKeys.length) {
    const localOrder = (bodyMarkingsOrder || []).filter(
      (markId) => !!bodyMarkingsState?.[markId]
    );
    return {
      markings: bodyMarkingsState,
      order: localOrder.length ? localOrder : localMarkingKeys,
    };
  }
  const payloadMarkings = bodyPayload?.body_markings || {};
  const payloadOrder = (bodyPayload?.order || []).filter(
    (markId) => !!payloadMarkings?.[markId]
  );
  return {
    markings: payloadMarkings,
    order: payloadOrder.length ? payloadOrder : Object.keys(payloadMarkings),
  };
};

const resolveSpeciesPreviewDirStates = (options: {
  data: CustomMarkingDesignerData;
  stateToken: string;
  selectedSpeciesId: string | null;
  selectedIconBase: string | null;
  selectedSpeciesPreviewSources: PreviewDirectionSource[] | null;
  selectedSpeciesPreviewByDir: Record<number, PreviewDirectionSource> | null;
  resolvedBodyPayload: BodyMarkingsPayload | null;
  resolvedBasicPayload: BasicAppearancePayload | null;
  previewAppearanceState: BasicAppearanceState;
  canvasWidth: number;
  canvasHeight: number;
}): {
  dirs: Record<number, PreviewDirState>;
  usesNeutralSpeciesPreviewBase: boolean;
} => {
  const {
    data,
    stateToken,
    selectedSpeciesId,
    selectedIconBase,
    selectedSpeciesPreviewSources,
    selectedSpeciesPreviewByDir,
    resolvedBodyPayload,
    resolvedBasicPayload,
    previewAppearanceState,
    canvasWidth,
    canvasHeight,
  } = options;
  const basicPreviewSelection = resolveBasicPreviewSourceSelection(
    resolvedBasicPayload,
    previewAppearanceState.digitigrade,
    undefined,
    previewAppearanceState.biological_gender
  );
  const rawSelectedBasicSources = basicPreviewSelection.sources;
  const bodySources = Array.isArray(resolvedBodyPayload?.preview_sources)
    ? resolvedBodyPayload?.preview_sources
    : null;
  const basicPayloadSpeciesId = resolvedBasicPayload?.species_id || null;
  const bodyPayloadSpeciesId = resolvedBodyPayload?.species_id || null;
  const basicPayloadMatchesSelection = isPreviewPayloadForSelection(
    resolvedBasicPayload,
    selectedSpeciesId,
    selectedIconBase
  );
  const bodyPayloadMatchesSelection = isPreviewPayloadForSelection(
    resolvedBodyPayload,
    selectedSpeciesId,
    selectedIconBase
  );
  const useStaleBasicWithSpeciesOverride = shouldReuseBasicPreviewCarrier({
    bodyPayloadMatchesSelection,
    hasSpeciesPreviewOverride: !!selectedSpeciesPreviewByDir,
  });
  const selectedBasicSources =
    basicPayloadMatchesSelection || useStaleBasicWithSpeciesOverride
      ? rawSelectedBasicSources
      : null;
  const previewSourceSelection =
    selectedBasicSources && selectedBasicSources.length
      ? {
          sources: selectedBasicSources,
          assetRegistry: basicPreviewSelection.assetRegistry,
          revision: basicPreviewSelection.revision,
          speciesId: basicPayloadSpeciesId,
          iconBaseId: resolvedBasicPayload?.custom_base || null,
        }
      : bodySources && bodySources.length && bodyPayloadMatchesSelection
        ? {
            sources: bodySources,
            assetRegistry: resolvedBodyPayload?.preview_asset_registry || null,
            revision: resolvedBodyPayload?.preview_revision ?? 0,
            speciesId: bodyPayloadSpeciesId,
            iconBaseId: resolvedBodyPayload?.custom_base || null,
          }
        : {
            sources: null,
            assetRegistry: null,
            revision: 0,
            speciesId: null,
            iconBaseId: null,
          };
  const payloadSpeciesId = previewSourceSelection.speciesId;
  const useSpeciesPreviewOverride = shouldUseSpeciesPreviewOverride({
    hasSpeciesPreviewOverride: !!selectedSpeciesPreviewByDir,
    selectedSpeciesId,
    selectedIconBase,
    payloadSpeciesId,
    payloadIconBaseId: previewSourceSelection.iconBaseId,
  });
  const neutralResolvedPreviewSources = previewSourceSelection.sources
    ? previewSourceSelection.sources.map((entry) => {
        const override = useSpeciesPreviewOverride
          ? selectedSpeciesPreviewByDir?.[entry.dir]
          : null;
        return override
          ? mergeSpeciesBodyPreviewSource(entry, override)
          : entry;
      })
    : selectedSpeciesPreviewSources;
  const resolvedPreviewSources = applyProstheticsToPreviewSources(
    neutralResolvedPreviewSources,
    previewAppearanceState,
    resolvedBasicPayload?.prosthetic_context
  );
  const usesNeutralSpeciesPreviewBase =
    !!selectedSpeciesPreviewSources?.length &&
    (!previewSourceSelection.sources || useSpeciesPreviewOverride);
  const previewRevision =
    previewSourceSelection.revision || (resolvedPreviewSources ? 1 : 0);
  const dirs = resolvedPreviewSources
    ? updatePreviewStateFromPayload(
        { revision: 0, lastDiffSeq: 0, dirs: {} },
        {
          data: {
            preview_sources: resolvedPreviewSources,
            preview_asset_registry:
              previewSourceSelection.assetRegistry || undefined,
            preview_revision: previewRevision,
            active_dir_key: data.active_dir_key,
            active_dir: data.active_dir,
            grid: [],
          } as any,
          sessionKey: `species-preview-${stateToken}`,
          activePartKey: 'generic',
          canvasWidth,
          canvasHeight,
          canvasGrid: null,
        }
      ).dirs
    : ({} as Record<number, PreviewDirState>);
  return {
    dirs,
    usesNeutralSpeciesPreviewBase,
  };
};

const resolveSpeciesPreviewBackground = (
  resolvedCanvasBackground: CanvasBackgroundOption | null,
  canvasBackgroundScale: number
) => ({
  previewBackgroundImage: resolvedCanvasBackground?.asset?.png
    ? `data:image/png;base64,${resolvedCanvasBackground.asset.png}`
    : null,
  previewBackgroundTileWidth: resolvedCanvasBackground?.asset?.width
    ? resolvedCanvasBackground.asset.width * canvasBackgroundScale
    : undefined,
  previewBackgroundTileHeight: resolvedCanvasBackground?.asset?.height
    ? resolvedCanvasBackground.asset.height * canvasBackgroundScale
    : undefined,
});

export const SpeciesTab = (props: SpeciesTabProps, context) => {
  const {
    data,
    setPendingClose,
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

  const {
    setCanvasFitToFrame,
    previewFitToFrame,
    setPreviewFitToFrame,
    speciesPayload,
    speciesSelection,
    speciesSavedSelection,
    speciesIconBaseSelection,
    speciesSavedIconBaseSelection,
    speciesCustomName,
    speciesSavedCustomName,
    speciesDirty,
    pendingSave,
    pendingClose,
    setPendingCloseLocal,
    loadInProgress,
    setLoadInProgress,
    assetRevision,
    speciesReloadPending,
    search,
    setSearch,
    tilePage,
    setTilePage,
    activeGallery,
    setActiveGallery,
    activeDetailSection,
    setActiveDetailSection,
    bodyPayload,
    bodyMarkingsState,
    bodyMarkingsOrder,
    setBodyMarkingsDirty,
    markingLayersCache,
    bodyMarkingsPreviewCache,
    bodyMarkingDefinitionCache,
    bodyMarkingsSignatureCache,
    basicPayload,
    basicAppearanceState,
    setBasicAppearanceDirty,
  } = useSpeciesTabLocalState(context, data, stateToken);

  const speciesNameInputLocked =
    uiLocked || loadInProgress || pendingSave || pendingClose;

  const togglePreviewFit = () => {
    const next = !previewFitToFrame;
    setPreviewFitToFrame(next);
    setCanvasFitToFrame(next);
  };

  const requestPayload = () => {
    act('load_species');
  };

  const syncPayload = (payload: SpeciesPayload) => {
    const previewSpecies =
      payload.preview_species || payload.selected_species || null;
    const previewIconBase =
      payload.preview_icon_base || payload.selected_icon_base || null;
    const selectedSpecies = payload.selected_species || null;
    const selectedIconBase = payload.selected_icon_base || previewIconBase;
    const payloadCustomSpeciesName = payload.custom_species || '';
    if (
      !speciesDirty &&
      speciesSavedSelection !== null &&
      (selectedSpecies !== speciesSavedSelection ||
        (speciesSavedIconBaseSelection !== null &&
          selectedIconBase !== speciesSavedIconBaseSelection) ||
        payloadCustomSpeciesName !== speciesSavedCustomName)
    ) {
      return;
    }
    if (speciesDirty) {
      if (
        speciesSelection &&
        previewSpecies &&
        previewSpecies !== speciesSelection
      ) {
        return;
      }
      if (
        speciesIconBaseSelection &&
        previewIconBase &&
        previewIconBase !== speciesIconBaseSelection
      ) {
        return;
      }
      const nextIconBase = resolvePayloadIconBase(
        payload,
        speciesIconBaseSelection
      );
      const nextStates: Record<string, unknown> = {
        speciesPayload: payload,
      };
      if (nextIconBase !== speciesIconBaseSelection) {
        nextStates.speciesIconBaseSelection = nextIconBase;
        nextStates.speciesDirty = isSpeciesDraftDirty(
          speciesSelection,
          speciesSavedSelection,
          nextIconBase,
          speciesSavedIconBaseSelection,
          speciesCustomName,
          speciesSavedCustomName
        );
      }
      if (loadInProgress) {
        nextStates[`speciesLoadInProgress-${stateToken}`] = false;
      }
      if (speciesReloadPending) {
        nextStates[`speciesReloadPending-${stateToken}`] = false;
      }
      context.store.dispatch(
        backendSetSharedStates({
          states: nextStates,
        })
      );
      return;
    }
    context.store.dispatch(
      backendSetSharedStates({
        states: {
          speciesPayload: payload,
          speciesSelection: selectedSpecies,
          speciesSavedSelection: selectedSpecies,
          speciesIconBaseSelection: selectedIconBase,
          speciesSavedIconBaseSelection: selectedIconBase,
          speciesCustomName: payloadCustomSpeciesName,
          speciesSavedCustomName: payloadCustomSpeciesName,
          speciesDirty: false,
          ...(loadInProgress
            ? { [`speciesLoadInProgress-${stateToken}`]: false }
            : {}),
          ...(speciesReloadPending
            ? { [`speciesReloadPending-${stateToken}`]: false }
            : {}),
        },
      })
    );
  };

  const handleSelectSpecies = (id: string | null) => {
    if (uiLocked || !id) {
      return;
    }
    const iconBaseOptions = resolveSpeciesIconBaseOptions(speciesPayload, id);
    let nextIconBase: string | null = null;
    if (
      speciesSavedSelection === id &&
      (optionListContains(iconBaseOptions, speciesSavedIconBaseSelection) ||
        !iconBaseOptions.length)
    ) {
      nextIconBase = speciesSavedIconBaseSelection;
    } else if (optionListContains(iconBaseOptions, speciesIconBaseSelection)) {
      nextIconBase = speciesIconBaseSelection;
    } else {
      nextIconBase = iconBaseOptions[0]?.id || null;
    }
    context.store.dispatch(
      backendSetSharedStates({
        states: {
          speciesSelection: id,
          speciesIconBaseSelection: nextIconBase,
          speciesDirty: isSpeciesDraftDirty(
            id,
            speciesSavedSelection,
            nextIconBase,
            speciesSavedIconBaseSelection,
            speciesCustomName,
            speciesSavedCustomName
          ),
          [`speciesLoadInProgress-${stateToken}`]: true,
        },
      })
    );
    act('load_species', {
      preview_species: id,
      preview_icon_base: nextIconBase,
    });
  };

  const handleSelectIconBase = (id: string | null) => {
    if (uiLocked || !id || !selectedId) {
      return;
    }
    context.store.dispatch(
      backendSetSharedStates({
        states: {
          speciesIconBaseSelection: id,
          speciesDirty: isSpeciesDraftDirty(
            selectedId,
            speciesSavedSelection,
            id,
            speciesSavedIconBaseSelection,
            speciesCustomName,
            speciesSavedCustomName
          ),
          [`speciesLoadInProgress-${stateToken}`]: true,
        },
      })
    );
    act('load_species', {
      preview_species: selectedId,
      preview_icon_base: id,
    });
  };

  const handleCustomSpeciesNameInput = (value: string) => {
    if (speciesNameInputLocked) {
      return;
    }
    context.store.dispatch(
      backendSetSharedStates({
        states: {
          speciesCustomName: value,
          speciesDirty: isSpeciesDraftDirty(
            speciesSelection,
            speciesSavedSelection,
            speciesIconBaseSelection,
            speciesSavedIconBaseSelection,
            value,
            speciesSavedCustomName
          ),
        },
      })
    );
  };

  const handleSave = async (close = false) => {
    if (!isSpeciesSaveAllowed(speciesSelection, speciesCustomName)) {
      return;
    }
    const previousSelection = speciesSavedSelection;
    const previousIconBase = speciesSavedIconBaseSelection;
    const customSpeciesNameToSave = speciesCustomName;
    const iconBaseToSave = activeIconBaseSelection;
    context.store.dispatch(
      backendSetSharedStates({
        states: {
          [`pendingSave-${stateToken}`]: true,
          speciesPendingSave: true,
          [`pendingClose-${stateToken}`]: close,
          speciesPendingClose: close,
        },
      })
    );
    try {
      await act('save_species', {
        species: speciesSelection,
        icon_base: iconBaseToSave,
        custom_species: customSpeciesNameToSave,
        close,
        ...buildSpeciesSaveCacheParams(bodyPayload, basicPayload),
      });
      if (!close) {
        const selectionChanged =
          previousSelection !== speciesSelection ||
          previousIconBase !== iconBaseToSave;
        context.store.dispatch(
          backendSetSharedStates({
            states: {
              speciesDirty: false,
              speciesSavedSelection: speciesSelection,
              speciesIconBaseSelection: iconBaseToSave,
              speciesSavedIconBaseSelection: iconBaseToSave,
              speciesCustomName: customSpeciesNameToSave,
              speciesSavedCustomName: customSpeciesNameToSave,
              ...(speciesPayload
                ? {
                    speciesPayload: {
                      ...speciesPayload,
                      selected_species: speciesSelection,
                      selected_icon_base: iconBaseToSave,
                      preview_icon_base: iconBaseToSave,
                      custom_species: customSpeciesNameToSave || null,
                    },
                  }
                : {}),
              ...(selectionChanged
                ? {
                    [`bodyMarkingsReloadPending-${stateToken}`]: true,
                    [`basicAppearanceReloadPending-${stateToken}`]: true,
                    bodyMarkingsDirty: false,
                    basicAppearanceDirty: false,
                    [`customMarkingDesignerReloadTargetRevision-${stateToken}`]: 0,
                    [`customMarkingDesignerReloadPending-${stateToken}`]: true,
                  }
                : {}),
            },
          })
        );
      }
    } catch (error) {
      context.store.dispatch(
        backendSetSharedStates({
          states: {
            [`pendingSave-${stateToken}`]: false,
            speciesPendingSave: false,
            [`pendingClose-${stateToken}`]: false,
            speciesPendingClose: false,
          },
        })
      );
      throw error;
    }
  };

  const handleDiscard = async () => {
    setPendingClose(true);
    setPendingCloseLocal(true);
    try {
      await act('close_species');
    } finally {
      setPendingClose(false);
      setPendingCloseLocal(false);
    }
  };

  const {
    selectedId,
    iconBaseOptions,
    selectedSpeciesPreviewSources,
    selectedSpeciesPreviewByDir,
    modifiers,
    traits,
    detailSections,
    blurb,
    whitelistLocked,
  } = resolveSelectedSpeciesState(
    speciesPayload,
    speciesSelection,
    speciesIconBaseSelection,
    basicAppearanceState.digitigrade
  );
  const activeIconBaseSelection = optionListContains(
    iconBaseOptions,
    speciesIconBaseSelection
  )
    ? speciesIconBaseSelection
    : iconBaseOptions[0]?.id || speciesIconBaseSelection;
  const {
    resolvedBodyPayload,
    resolvedBasicPayload,
    previewAppearanceState,
    canvasWidth,
    canvasHeight,
  } = resolveSpeciesPreviewPayloads({
    data,
    bodyPayload,
    basicPayload,
    bodyPayloadCleared:
      hasSharedStateKey(context, 'bodyPayload') && !bodyPayload,
    basicPayloadCleared:
      hasSharedStateKey(context, 'basicPayload') && !basicPayload,
    basicAppearanceState,
  });
  const selectedSpeciesBodyPayload = resolveSelectedSpeciesBodyPayload({
    selectedSpeciesId: selectedId,
    selectedIconBase: activeIconBaseSelection,
    resolvedBodyPayload,
    dataBodyPayload: data.body_markings_payload || null,
  });
  const speciesPreviewMarkings = resolveSpeciesPreviewBodyMarkings({
    bodyPayload: selectedSpeciesBodyPayload,
    bodyMarkingsState,
    bodyMarkingsOrder,
  });
  const previewCanvasWidth =
    selectedSpeciesBodyPayload?.preview_width || canvasWidth;
  const previewCanvasHeight =
    selectedSpeciesBodyPayload?.preview_height || canvasHeight;
  const { dirs: previewDirStates, usesNeutralSpeciesPreviewBase } =
    resolveSpeciesPreviewDirStates({
      data,
      stateToken,
      selectedSpeciesId: selectedId,
      selectedIconBase: activeIconBaseSelection,
      selectedSpeciesPreviewSources,
      selectedSpeciesPreviewByDir,
      resolvedBodyPayload: selectedSpeciesBodyPayload,
      resolvedBasicPayload,
      previewAppearanceState,
      canvasWidth: previewCanvasWidth,
      canvasHeight: previewCanvasHeight,
    });
  const previewBasicPayload = usesNeutralSpeciesPreviewBase
    ? ({
        ...(resolvedBasicPayload || {}),
        body_color: SPECIES_NEUTRAL_BODY_COLOR,
      } as BasicAppearancePayload)
    : resolvedBasicPayload;

  const bodyPartLabels = buildBodyPartLabelMap(data.body_parts);

  const signalAssetUpdate = () => {
    if (assetUpdateScheduled) {
      return;
    }
    assetUpdateScheduled = true;
    setTimeout(() => {
      assetUpdateScheduled = false;
      advanceSpeciesAssetRevision(context.store);
    }, 0);
  };

  const { liveBasePreview, appearanceContext } = buildBodyMarkingsPreviewBases({
    previewDirStates,
    bodyPayload: selectedSpeciesBodyPayload,
    basicPayload: previewBasicPayload,
    basicAppearanceState: previewAppearanceState,
    data,
    bodyPartLabels,
    canvasWidth: previewCanvasWidth,
    canvasHeight: previewCanvasHeight,
    resolvedPartPriorityMap,
    resolvedPartReplacementMap,
    showEquipment,
    showJobGear,
    showLoadoutGear,
    signalAssetUpdate,
    bodyColorMaxFactor: 3,
  });

  const directionSignature = Array.isArray(data.directions)
    ? data.directions.map((entry) => entry.dir).join('|')
    : '';
  const { definitions: bodyMarkingsDefinitions, context: bodyMarkingsContext } =
    resolveBodyMarkingsContext({
      bodyPayload: selectedSpeciesBodyPayload,
      bodyMarkingsState: speciesPreviewMarkings.markings,
      bodyMarkingsOrder: speciesPreviewMarkings.order,
      appearanceState: appearanceContext.appearanceState,
      canvasWidth: previewCanvasWidth,
      canvasHeight: previewCanvasHeight,
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
  const suppressedPartsByDir = buildSuppressedMarkingPartsByDir(
    appearanceContext.previewDirStatesForLive
  );
  const livePreviewWithMarkings = applyBodyMarkingsToPreview({
    preview: liveBasePreview,
    context: bodyMarkingsContext,
    stripReferenceMarkings,
    suppressedPartsByDir,
  });
  const previewForLive =
    livePreview && livePreview.length ? livePreview : livePreviewWithMarkings;

  const {
    previewBackgroundImage,
    previewBackgroundTileWidth,
    previewBackgroundTileHeight,
  } = resolveSpeciesPreviewBackground(
    resolvedCanvasBackground,
    canvasBackgroundScale
  );

  if (!speciesPayload) {
    return (
      <Box className="RogueStar" position="relative" minHeight="100%">
        <SpeciesInitializer
          speciesPayload={speciesPayload}
          dataPayload={data.species_payload}
          requestPayload={requestPayload}
          syncPayload={syncPayload}
          loadInProgress={loadInProgress}
          reloadPending={speciesReloadPending}
          setLoadInProgress={setLoadInProgress}
        />
        <LoadingOverlay
          title="Loading species..."
          subtitle="Fetching available species data. This should only take a moment."
        />
      </Box>
    );
  }

  return (
    <Box className="RogueStar" position="relative" minHeight="100%">
      <SpeciesInitializer
        speciesPayload={speciesPayload}
        dataPayload={data.species_payload}
        requestPayload={requestPayload}
        syncPayload={syncPayload}
        loadInProgress={loadInProgress}
        reloadPending={speciesReloadPending}
        setLoadInProgress={setLoadInProgress}
      />
      <Flex direction="row" gap={1} wrap={false} align="stretch" height="100%">
        <Flex.Item basis="840px" shrink={0}>
          <Flex direction="column" gap={1} height="100%" minHeight={0}>
            <SpeciesGallerySection
              search={search}
              setSearch={setSearch}
              tilePage={tilePage}
              setTilePage={setTilePage}
              definitions={speciesPayload.species}
              iconBaseOptions={iconBaseOptions}
              activeGallery={activeGallery}
              setActiveGallery={setActiveGallery}
              selectedId={selectedId}
              selectedIconBase={activeIconBaseSelection}
              canvasWidth={canvasWidth}
              canvasHeight={canvasHeight}
              hairColor={previewAppearanceState.hair_color}
              assetRevision={assetRevision}
              onSelect={handleSelectSpecies}
              onSelectIconBase={handleSelectIconBase}
              signalAssetUpdate={signalAssetUpdate}
            />
          </Flex>
        </Flex.Item>
        <Flex.Item basis="418px" shrink={0}>
          <Flex direction="column" gap={1} height="100%" minHeight={0}>
            <Flex.Item shrink={0}>
              <SpeciesSaveSection
                pendingSave={pendingSave}
                pendingClose={pendingClose}
                uiLocked={uiLocked || loadInProgress}
                dirty={speciesDirty}
                saveBlocked={
                  !isSpeciesSaveAllowed(selectedId, speciesCustomName)
                }
                onSave={() => handleSave(false)}
                onSaveAndClose={() => handleSave(true)}
                onDiscardAndClose={handleDiscard}
              />
            </Flex.Item>
            <Flex.Item shrink={0}>
              <SpeciesNameSection
                value={speciesCustomName}
                maxLength={
                  speciesPayload.custom_species_max_length ||
                  DEFAULT_CUSTOM_SPECIES_NAME_MAX_LENGTH
                }
                required={selectedId === CUSTOM_SPECIES_ID}
                disabled={speciesNameInputLocked}
                onInput={handleCustomSpeciesNameInput}
              />
            </Flex.Item>
            <Flex.Item grow minHeight={0}>
              <SpeciesDetailsSection
                modifiers={modifiers}
                traits={traits}
                detailSections={detailSections}
                activeDetailSection={activeDetailSection}
                onSelectDetailSection={setActiveDetailSection}
              />
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item grow>
          <SpeciesPreviewColumn
            preview={previewForLive}
            canvasWidth={previewCanvasWidth}
            canvasHeight={previewCanvasHeight}
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
            blurb={blurb}
            whitelistLocked={whitelistLocked}
          />
        </Flex.Item>
      </Flex>
    </Box>
  );
};
