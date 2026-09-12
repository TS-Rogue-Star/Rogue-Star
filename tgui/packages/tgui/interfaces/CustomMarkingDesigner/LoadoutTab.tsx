// //////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Loadout //
// //////////////////////////////////////////////////////////////////////////////

import { useLocalState } from '../../backend';
import { LoadoutSettings } from './components/LoadoutSettings';
import {
  Box,
  Button,
  Dropdown,
  Flex,
  Input,
  NoticeBox,
  Section,
  Tabs,
} from '../../components';
import {
  resolveGearOverlayAssetReferences,
  resolveIconAssetReference,
  areIconAssetsReady,
  getIconAssetReadinessSignature,
  getPreviewGridFromAsset,
  type CharacterPreviewWorkPriority,
  type PreviewDirectionEntry,
} from '../../utils/character-preview';
import { getPreviewGridFromGearAsset } from '../../utils/character-preview/assets';
import {
  BasicAppearancePreviewColumn,
  type BasicTilePreviewEntry,
} from './BasicAppearanceTab';
import {
  LoadoutGallery,
  type LoadoutTilePreview,
} from './components/LoadoutGallery';
import {
  APPEARANCE_GALLERY_COLUMN_WIDTH,
  APPEARANCE_SETTINGS_COLUMN_WIDTH,
} from './constants';
import type { EquipmentTabProps } from './EquipmentTab';
import type { LoadoutGalleryRenderer } from './utils/loadoutPreview';
import type { LoadoutGear, LoadoutVariant } from './loadoutTypes';
import type { LoadoutSession } from './services/loadoutSession';
import {
  buildLoadoutRecipes,
  loadoutCost,
  loadoutTileId,
  loadoutVariantAssets,
  selectedVariant,
  tintLoadoutRecipes,
  toggleLoadoutItem,
  tweakValue,
} from './utils/loadout';

type Props = Omit<EquipmentTabProps, 'session'> & {
  readonly session: LoadoutSession;
  readonly baseAssetSignature: string;
  readonly prepareGalleryPreview: (
    onUpdated: () => void
  ) => LoadoutGalleryRenderer;
};
type Tile = {
  id: string;
  name: string;
  description: string;
  tooltip: string;
  pointCost: number;
  readonly disabled: boolean;
  singlePreview: boolean;
  gear: LoadoutGear;
  variant: LoadoutVariant;
  previewPending: boolean;
};
const tileCaches = new WeakMap<
  LoadoutSession,
  Map<string, LoadoutTilePreview>
>();
const preparedPreviews = new WeakMap<
  LoadoutSession,
  {
    signature: string;
    revision: number;
    render: LoadoutGalleryRenderer | null;
  }
>();
const livePreviews = new WeakMap<
  LoadoutSession,
  { signature: string; preview: PreviewDirectionEntry[] }
>();
const variantTokens = new WeakMap<LoadoutVariant, number>();
let nextVariantToken = 0;
const variantToken = (variant: LoadoutVariant) => {
  let token = variantTokens.get(variant);
  if (token === undefined) {
    token = ++nextVariantToken;
    variantTokens.set(variant, token);
  }
  return token;
};

export const LoadoutTab = (props: Props, context) => {
  const { session, stateToken, canvasWidth, canvasHeight } = props;
  const [category, setCategory] = useLocalState(
    context,
    `loadoutCategory-${stateToken}`,
    'General'
  );
  const [search, setSearch] = useLocalState(
    context,
    `loadoutSearch-${stateToken}`,
    ''
  );
  const [page, setPage] = useLocalState(
    context,
    `loadoutPage-${stateToken}`,
    0
  );
  const [worn, setWorn] = useLocalState(
    context,
    `loadoutWorn-${stateToken}`,
    true
  );
  const [focused, setFocused] = useLocalState<string | null>(
    context,
    `loadoutFocused-${stateToken}`,
    null
  );
  const { draft, catalog } = session;
  if (!draft || !catalog) {
    return (
      <Section title="Loadout">
        <NoticeBox danger={!!session.error}>
          {session.error || 'Loading Loadout…'}
        </NoticeBox>
        {session.error && (
          <Button
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
  const categories = Array.from(
    new Set(catalog.items.map((gear) => gear.category))
  ).sort();
  const activeCategory = categories.includes(category)
    ? category
    : categories[0];
  const items = draft.slots[draft.active] || [];
  const cost = loadoutCost(items, catalog);
  const focusedItem = items.find((item) => item.id === focused) || items[0];
  const focusedGear = catalog.items.find((gear) => gear.id === focusedItem?.id);
  const colorTweak = focusedGear?.tweaks.find(
    (tweak) => tweak.kind === 'color' && !tweak.options?.length
  );
  const selectedIds = new Set(
    items.flatMap((item) => {
      const gear = catalog.items.find((entry) => entry.id === item.id);
      const variant = gear && selectedVariant(gear, item);
      return gear && variant ? [loadoutTileId(gear, variant)] : [];
    })
  );
  const definitions: Tile[] = catalog.items
    .filter((gear) => gear.category === activeCategory)
    .flatMap((gear) =>
      gear.variants.map((variant) => {
        const selected = items.some((item) => item.id === gear.id);
        const reason = !gear.available
          ? 'Unavailable for this character.'
          : !selected && cost + gear.cost > catalog.max_cost
            ? 'Not enough loadout points.'
            : '';
        return {
          id: loadoutTileId(gear, variant),
          name: variant.name,
          pointCost: gear.cost,
          description: `${gear.name} ${gear.description}`,
          tooltip: `${variant.name}\n${gear.description}\n${reason || (!gear.permitted ? 'Will not equip for the current preview job or species.' : '')}`,
          disabled: !selected && !!reason,
          singlePreview: !worn || !variant.worn,
          gear,
          variant,
          previewPending: worn && !!variant.preview_pending,
        };
      })
    );
  const background = props.resolvedCanvasBackground?.asset;
  const backgroundImage = background?.png
    ? `data:image/png;base64,${background.png}`
    : null;
  const backgroundTileWidth = background?.width
    ? background.width * props.canvasBackgroundScale
    : undefined;
  const backgroundTileHeight = background?.height
    ? background.height * props.canvasBackgroundScale
    : undefined;
  let cache = tileCaches.get(session);
  if (!cache) {
    cache = new Map();
    tileCaches.set(session, cache);
  }
  let base = preparedPreviews.get(session);
  if (!base) {
    base = { signature: '', revision: 0, render: null };
    preparedPreviews.set(session, base);
  }
  const baseSignature = `${props.previewSignature}|${props.baseAssetSignature}|${canvasWidth}x${canvasHeight}`;
  if (base.signature !== baseSignature) {
    base.signature = baseSignature;
    base.revision++;
    base.render = null;
  }
  const previewKey = `${baseSignature}|${worn}`;
  const getSignature = (definition) => {
    const tile = definition as Tile;
    const item = items.find((entry) => entry.id === tile.gear.id);
    const colors = tile.gear.tweaks
      .filter((tweak) => tweak.kind === 'color' || tweak.kind === 'matrix')
      .map((tweak) => (item ? tweakValue(item, tweak) : tweak.default));
    return `${previewKey}|${worn ? base.revision : 0}|${tile.id}|${variantToken(tile.variant)}|${JSON.stringify(colors)}|${getIconAssetReadinessSignature(loadoutVariantAssets(tile.variant, worn))}`;
  };
  const getCachedPreview = (definition) => {
    const tile = definition as Tile;
    const cached = cache.get(tile.id);
    if (cached?.signature === getSignature(tile)) {
      cache.delete(tile.id);
      cache.set(tile.id, cached);
      return cached;
    }
    return null;
  };
  const buildPreview = (
    definition,
    priority: CharacterPreviewWorkPriority,
    onUpdated: () => void
  ): LoadoutTilePreview => {
    const tile = definition as Tile;
    const item = items.find((entry) => entry.id === tile.gear.id);
    let preview: BasicTilePreviewEntry[] = [];
    let ready = props.previewReady;
    if (worn && tile.variant.worn) {
      const assets = loadoutVariantAssets(tile.variant, true);
      for (const asset of assets) {
        getPreviewGridFromAsset(
          asset,
          asset.width,
          asset.height,
          onUpdated,
          priority
        );
      }
      ready = ready && areIconAssetsReady(assets);
      if (ready) {
        if (!base.render) {
          const revision = base.revision;
          base.render = props.prepareGalleryPreview(() => {
            if (base.revision === revision) {
              base.render = null;
              base.revision++;
              props.notifyAssetReady();
            }
          });
        }
        preview = base.render(
          buildLoadoutRecipes(catalog, draft, {
            gear: tile.gear,
            variant: tile.variant,
          }),
          onUpdated,
          priority
        );
      }
    } else {
      const asset = resolveIconAssetReference(tile.variant.icon || undefined);
      const recipe =
        asset &&
        tintLoadoutRecipes(
          [{ asset, overlays: tile.variant.base_overlays }],
          tile.gear,
          item,
          tile.variant.color
        )[0];
      const baseWidth = asset?.width || 32;
      const baseHeight = asset?.height || 32;
      const grid = recipe
        ? getPreviewGridFromGearAsset(
            resolveGearOverlayAssetReferences([recipe])![0],
            baseWidth,
            baseHeight,
            onUpdated,
            priority
          )
        : null;
      ready = !asset || !!grid;
      preview = [
        {
          dir: 2,
          label: tile.variant.name,
          canvasWidth: baseWidth,
          canvasHeight: baseHeight,
          layers: grid ? [{ type: 'overlay', key: tile.id, grid }] : [],
        },
      ];
    }
    ready =
      ready && areIconAssetsReady(loadoutVariantAssets(tile.variant, worn));
    const signature = getSignature(tile);
    preview = preview.map((direction) => ({
      ...direction,
      renderSignature: `loadout|${signature}|${direction.dir}`,
      retainRenderedCanvasOnUnmount: ready,
    }));
    const result = { signature, preview, complete: ready };
    cache.delete(tile.id);
    cache.set(tile.id, result);
    while (cache.size > 100) {
      cache.delete(cache.keys().next().value!);
    }
    return result;
  };
  const liveRecipes = buildLoadoutRecipes(
    catalog,
    draft,
    undefined,
    props.showJobGear
  );
  const liveSignature = `${baseSignature}|${props.assetRevision}|${props.previewReady}|${props.showEquipment}|${props.showJobGear}|${props.showLoadoutGear}|${JSON.stringify(liveRecipes)}`;
  let live = livePreviews.get(session);
  if (live?.signature !== liveSignature) {
    live = {
      signature: liveSignature,
      preview: props.previewReady
        ? props.renderPreview(liveRecipes, false)
        : [],
    };
    livePreviews.set(session, live);
  }
  const livePreview = live.preview;
  return (
    <Box
      className="RogueStar RogueStar--loadout"
      position="relative"
      minHeight="100%">
      <Flex direction="row" gap={1} wrap={false} height="100%">
        <Flex.Item basis={APPEARANCE_GALLERY_COLUMN_WIDTH} shrink={0}>
          <Section
            className="RogueStar__loadoutGallery"
            title="Loadout Gallery"
            buttons={
              <Flex align="center" gap={1}>
                <Flex.Item>
                  <Dropdown
                    className="RogueStar__dropdown"
                    dropdownStyle="rogue-star"
                    aria-label="Loadout category"
                    width="240px"
                    options={categories}
                    selected={activeCategory}
                    onSelected={(next) => {
                      setCategory(next);
                      setPage(0);
                      setSearch('');
                    }}
                  />
                </Flex.Item>
                <Flex.Item>
                  <Tabs>
                    <Tabs.Tab selected={!worn} onClick={() => setWorn(false)}>
                      Base
                    </Tabs.Tab>
                    <Tabs.Tab selected={worn} onClick={() => setWorn(true)}>
                      Worn
                    </Tabs.Tab>
                  </Tabs>
                </Flex.Item>
              </Flex>
            }>
            <Box mb={1}>
              <Input
                fluid
                placeholder={`Search ${activeCategory || 'loadout'}…`}
                value={search}
                onInput={(_, next) => {
                  setSearch(next);
                  setPage(0);
                }}
              />
            </Box>
            <Box style={{ pointerEvents: locked ? 'none' : undefined }}>
              <LoadoutGallery
                definitions={definitions}
                canvasWidth={canvasWidth}
                canvasHeight={canvasHeight}
                search={search}
                page={page}
                onPageChange={setPage}
                tileDirectionsSignature={`${previewKey}|${session.version}`}
                assetRevision={props.assetRevision}
                selectedId={null}
                selectedIds={selectedIds}
                backgroundImage={backgroundImage}
                backgroundColor={props.backgroundFallbackColor}
                backgroundScale={props.canvasBackgroundScale}
                backgroundTileWidth={backgroundTileWidth}
                backgroundTileHeight={backgroundTileHeight}
                getSignature={getSignature}
                getCachedPreview={getCachedPreview}
                buildPreview={buildPreview}
                allowDeselect={false}
                onSelect={(id) => {
                  const tile = definitions.find((entry) => entry.id === id);
                  if (!locked && tile && session.draft) {
                    session.update(
                      toggleLoadoutItem(
                        session.draft,
                        catalog,
                        tile.gear,
                        tile.variant
                      )
                    );
                    setFocused(tile.gear.id);
                  }
                }}
              />
            </Box>
          </Section>
        </Flex.Item>
        <Flex.Item basis={APPEARANCE_SETTINGS_COLUMN_WIDTH} shrink={0}>
          <LoadoutSettings
            session={session}
            uiLocked={props.uiLocked}
            focused={focused}
            onFocusItem={setFocused}
          />
        </Flex.Item>
        <Flex.Item grow>
          <BasicAppearancePreviewColumn
            {...props}
            preview={livePreview}
            previewBackgroundImage={backgroundImage}
            previewBackgroundTileWidth={backgroundTileWidth}
            previewBackgroundTileHeight={backgroundTileHeight}
            colorPickerValue={
              colorTweak && focusedItem
                ? String(tweakValue(focusedItem, colorTweak))
                : '#ffffff'
            }
            colorPickerDisabled={locked || !colorTweak}
            applyColorTarget={(hex) => {
              if (!locked && colorTweak && focusedItem) {
                session.updateTweak(focusedItem.id, colorTweak, hex);
              }
            }}
          />
        </Flex.Item>
      </Flex>
    </Box>
  );
};
