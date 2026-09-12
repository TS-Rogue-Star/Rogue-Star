// ////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Equipment //
// ////////////////////////////////////////////////////////////////////////////////

import { useLocalState } from '../../backend';
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
} from '../../components';
import {
  getPreviewGridFromAsset,
  resolveIconAssetReference,
  type PreviewDirectionEntry,
} from '../../utils/character-preview';
import {
  BasicAppearancePreviewColumn,
  BasicAppearanceSaveSection,
  BasicTileSection,
  type BasicTilePreviewEntry,
} from './BasicAppearanceTab';
import {
  APPEARANCE_GALLERY_COLUMN_WIDTH,
  APPEARANCE_SETTINGS_COLUMN_WIDTH,
  CHIP_BUTTON_CLASS,
} from './constants';
import type { EquipmentSession } from './services/equipmentSession';
import type {
  CanvasBackgroundOption,
  EquipmentCategory,
  EquipmentCatalogEntry,
  EquipmentGearOptions,
  EquipmentGearRecipes,
} from './types';
import {
  buildEquipmentRecipes,
  EQUIPMENT_CATEGORIES,
  selectedEquipmentId,
} from './utils/equipment';

export type EquipmentTabProps = Readonly<{
  session: EquipmentSession;
  stateToken: string;
  uiLocked: boolean;
  previewReady: boolean;
  previewSignature: string;
  assetRevision: number;
  notifyAssetReady: () => void;
  renderPreview: (
    recipes: EquipmentGearRecipes,
    gallery: boolean
  ) => PreviewDirectionEntry[];
  canvasWidth: number;
  canvasHeight: number;
  iconScaleX?: number;
  iconScaleY?: number;
  previewFitToFrame: boolean;
  onTogglePreviewFit: () => void;
  showEquipment: boolean;
  onToggleEquipment: () => void;
  showJobGear: boolean;
  onToggleJobGear: () => void;
  showLoadoutGear: boolean;
  onToggleLoadout: () => void;
  canvasBackgroundOptions: CanvasBackgroundOption[];
  resolvedCanvasBackground: CanvasBackgroundOption | null;
  backgroundFallbackColor: string;
  cycleCanvasBackground: () => void;
  canvasBackgroundScale: number;
}>;

class EquipmentTileCache {
  entries = new Map<
    string,
    { signature: string; preview: BasicTilePreviewEntry[] }
  >();
  liveSignature = '';
  livePreview: PreviewDirectionEntry[] = [];
  gearOptions: EquipmentGearOptions | null = null;
  gearOptionsRevision = 0;
}

const equipmentTileCaches = new WeakMap<EquipmentSession, EquipmentTileCache>();

export const EquipmentTab = (props: EquipmentTabProps, context) => {
  const { session, stateToken, canvasWidth, canvasHeight, assetRevision } =
    props;
  const [category, setCategory] = useLocalState<EquipmentCategory>(
    context,
    `equipmentCategory-${stateToken}`,
    'Underwear, top'
  );
  const [search, setSearch] = useLocalState(
    context,
    `equipmentSearch-${stateToken}`,
    ''
  );
  const [page, setPage] = useLocalState(
    context,
    `equipmentPage-${stateToken}`,
    0
  );
  const [colorTarget, setColorTarget] = useLocalState<EquipmentCategory | null>(
    context,
    `equipmentColorTarget-${stateToken}`,
    'Underwear, top'
  );
  let cache = equipmentTileCaches.get(session);
  if (!cache) {
    cache = new EquipmentTileCache();
    equipmentTileCaches.set(session, cache);
  }
  const { draft, catalog } = session;
  if (!draft || !catalog) {
    return (
      <Section title="Equipment">
        <NoticeBox danger={!!session.error}>
          {session.error || 'Loading Equipment…'}
        </NoticeBox>
        {session.error && (
          <Button
            className={CHIP_BUTTON_CLASS}
            icon="rotate"
            disabled={session.loading}
            onClick={() => session.load()}>
            Retry
          </Button>
        )}
      </Section>
    );
  }
  const locked = props.uiLocked || session.saving || session.loading;
  const entries = catalog[category] || [];
  const targetEntry = colorTarget
    ? catalog[colorTarget]?.find(
        (entry) => entry.id === selectedEquipmentId(draft, colorTarget)
      )
    : null;
  const canColor = !!targetEntry?.colorable && !locked;
  const pickerColor = (colorTarget && draft.colors[colorTarget]) || '#ffffff';
  const select = (
    id: string | null,
    targetCategory: EquipmentCategory = category
  ) => {
    const currentDraft = session.draft;
    if (locked || id === null || !currentDraft) {
      return;
    }
    const next = { ...currentDraft };
    if (targetCategory === 'backpack') {
      next.backbag = Number(id);
    } else if (targetCategory === 'pda') {
      next.pdachoice = Number(id);
    } else {
      next.underwear = { ...currentDraft.underwear, [targetCategory]: id };
    }
    session.update(next);
    setColorTarget(targetCategory);
  };
  const backgroundAsset = props.resolvedCanvasBackground?.asset;
  const backgroundImage = backgroundAsset?.png
    ? `data:image/png;base64,${backgroundAsset.png}`
    : null;
  const backgroundTileWidth = backgroundAsset?.width
    ? backgroundAsset.width * props.canvasBackgroundScale
    : undefined;
  const backgroundTileHeight = backgroundAsset?.height
    ? backgroundAsset.height * props.canvasBackgroundScale
    : undefined;
  const previewKey = `${props.previewSignature}|${assetRevision}|${canvasWidth}x${canvasHeight}`;
  const galleryGearOptions = props.showJobGear ? session.gearOptions : null;
  if (cache.gearOptions !== galleryGearOptions) {
    cache.gearOptions = galleryGearOptions;
    cache.gearOptionsRevision++;
  }
  const galleryPreviewKey = `${previewKey}|${session.catalogSignature}|${category === 'backpack' ? cache.gearOptionsRevision : ''}`;
  const getTilePreview = (
    entry: EquipmentCatalogEntry
  ): BasicTilePreviewEntry[] => {
    const signature = `${galleryPreviewKey}|${category}|${entry.id}|${entry.colorable ? draft.colors[category] : ''}`;
    const key = `${category}|${entry.id}`;
    const cached = cache.entries.get(key);
    if (cached?.signature === signature) {
      return cached.preview;
    }
    let preview: BasicTilePreviewEntry[];
    let ready = props.previewReady;
    if (category === 'pda') {
      const asset = resolveIconAssetReference(entry.icon || undefined);
      const grid =
        asset &&
        getPreviewGridFromAsset(
          asset,
          canvasWidth,
          canvasHeight,
          props.notifyAssetReady
        );
      ready = !!grid;
      preview = [
        {
          dir: 2,
          label: entry.name,
          layers: grid
            ? [{ type: 'overlay', key: `pda-${entry.id}`, grid }]
            : [],
        },
      ];
    } else {
      preview = props.previewReady
        ? props.renderPreview(
            buildEquipmentRecipes(catalog, draft, galleryGearOptions, {
              category,
              entry,
            }),
            true
          )
        : [];
    }
    preview = preview.map((dir) => ({
      ...dir,
      renderSignature: `equipment|${signature}|${dir.dir}`,
      retainRenderedCanvasOnUnmount: ready,
    }));
    if (ready) {
      cache.entries.set(key, { signature, preview });
    }
    return preview;
  };
  const liveSignature = `${previewKey}|${props.previewReady}|${session.version}|${props.showEquipment}|${props.showJobGear}|${props.showLoadoutGear}`;
  if (cache.liveSignature !== liveSignature) {
    cache.liveSignature = liveSignature;
    cache.livePreview = props.previewReady
      ? props.renderPreview(
          buildEquipmentRecipes(catalog, draft, session.gearOptions),
          false
        )
      : [];
  }
  return (
    <Box className="RogueStar" position="relative" minHeight="100%">
      <Flex direction="row" gap={1} wrap={false} height="100%">
        <Flex.Item basis={APPEARANCE_GALLERY_COLUMN_WIDTH} shrink={0}>
          <Section
            title="Equipment Gallery"
            buttons={
              <Tabs>
                {EQUIPMENT_CATEGORIES.map(({ id, label }) => (
                  <Tabs.Tab
                    key={id}
                    selected={category === id}
                    onClick={() => {
                      if (!locked) {
                        setCategory(id);
                        setColorTarget(id);
                        setPage(0);
                        setSearch('');
                      }
                    }}>
                    {label}
                  </Tabs.Tab>
                ))}
              </Tabs>
            }>
            <Box mb={1}>
              <Input
                fluid
                value={search}
                placeholder={`Search ${EQUIPMENT_CATEGORIES.find((entry) => entry.id === category)?.label.toLowerCase()}…`}
                onInput={(_, value) => {
                  setSearch(value);
                  setPage(0);
                }}
              />
            </Box>
            <Box style={{ pointerEvents: locked ? 'none' : undefined }}>
              <BasicTileSection
                definitions={entries}
                canvasWidth={canvasWidth}
                canvasHeight={canvasHeight}
                search={search}
                page={page}
                onPageChange={setPage}
                tileDirectionsSignature={`${galleryPreviewKey}|${category}|${draft.colors[category] || ''}`}
                assetRevision={assetRevision}
                selectedId={selectedEquipmentId(draft, category)}
                backgroundImage={backgroundImage}
                backgroundColor={props.backgroundFallbackColor}
                backgroundScale={props.canvasBackgroundScale}
                backgroundTileWidth={backgroundTileWidth}
                backgroundTileHeight={backgroundTileHeight}
                getTilePreviewEntries={getTilePreview}
                onSelect={select}
                allowDeselect={false}
              />
            </Box>
          </Section>
        </Flex.Item>
        <Flex.Item basis={APPEARANCE_SETTINGS_COLUMN_WIDTH} shrink={0}>
          <Flex direction="column" gap={1}>
            <BasicAppearanceSaveSection
              pendingSave={session.saving && !session.closing}
              pendingClose={session.closing}
              uiLocked={locked}
              dirty={session.dirty}
              onSave={() => session.save()}
              onSaveAndClose={() => session.save(true)}
              onDiscardAndClose={() => session.discard(true)}
            />
            <Section title="Settings" fill>
              {session.error && <NoticeBox danger>{session.error}</NoticeBox>}
              {session.error && (
                <Box mb={1}>
                  <Button.Confirm
                    className={CHIP_BUTTON_CLASS}
                    disabled={locked}
                    content="Reload Saved Equipment"
                    confirmContent="Discard Draft & Reload"
                    onClick={() => session.load(true)}
                  />
                </Box>
              )}
              {session.loading && <NoticeBox>Loading Equipment…</NoticeBox>}
              <LabeledList>
                {EQUIPMENT_CATEGORIES.map(({ id, label }) => {
                  const selectedId = selectedEquipmentId(draft, id);
                  const clearedId =
                    id === 'backpack' || id === 'pda' ? '1' : 'None';
                  const selected = catalog[id]?.find(
                    (entry) => entry.id === selectedId
                  );
                  return (
                    <LabeledList.Item key={id} label={label}>
                      <Flex align="center" gap={0.5} wrap>
                        <Flex.Item grow>
                          <Box title={selected?.name}>
                            {selected?.name || selectedId}
                          </Box>
                        </Flex.Item>
                        {!!selected?.colorable && (
                          <Flex.Item>
                            <Button
                              className={CHIP_BUTTON_CLASS}
                              icon="tint"
                              selected={colorTarget === id}
                              disabled={locked}
                              tooltip={`Edit ${label.toLowerCase()} color`}
                              onClick={() => setColorTarget(id)}>
                              <ColorBox mr={0.5} color={draft.colors[id]} />
                              Color
                            </Button>
                          </Flex.Item>
                        )}
                        <Flex.Item>
                          <Button
                            className={CHIP_BUTTON_CLASS}
                            icon="eraser"
                            disabled={locked || selectedId === clearedId}
                            tooltip={
                              id === 'pda'
                                ? 'Reset PDA to Default.'
                                : `Clear ${label.toLowerCase()}.`
                            }
                            onClick={() => select(clearedId, id)}>
                            Clear
                          </Button>
                        </Flex.Item>
                      </Flex>
                    </LabeledList.Item>
                  );
                })}
                <LabeledList.Item label="Communicator Visibility">
                  <Button
                    className={CHIP_BUTTON_CLASS}
                    selected={draft.communicator_visibility}
                    disabled={locked}
                    tooltip="Appear in communicator listings."
                    onClick={() =>
                      session.update({
                        ...draft,
                        communicator_visibility: !draft.communicator_visibility,
                      })
                    }>
                    {draft.communicator_visibility ? 'Yes' : 'No'}
                  </Button>
                </LabeledList.Item>
                <LabeledList.Item label="Shoes">
                  <Button
                    className={CHIP_BUTTON_CLASS}
                    selected={!draft.shoe_hater}
                    disabled={locked}
                    tooltip="Wear shoes supplied by your job or loadout when spawning."
                    onClick={() =>
                      session.update({
                        ...draft,
                        shoe_hater: !draft.shoe_hater,
                      })
                    }>
                    {draft.shoe_hater ? 'No' : 'Yes'}
                  </Button>
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Flex>
        </Flex.Item>
        <Flex.Item grow>
          <BasicAppearancePreviewColumn
            {...props}
            preview={cache.livePreview}
            previewBackgroundImage={backgroundImage}
            backgroundFallbackColor={props.backgroundFallbackColor}
            previewBackgroundTileWidth={backgroundTileWidth}
            previewBackgroundTileHeight={backgroundTileHeight}
            colorPickerValue={pickerColor}
            colorPickerDisabled={!canColor}
            applyColorTarget={(hex) => {
              if (canColor && colorTarget) {
                session.update({
                  ...draft,
                  colors: { ...draft.colors, [colorTarget]: hex },
                });
              }
            }}
          />
        </Flex.Item>
      </Flex>
    </Box>
  );
};
