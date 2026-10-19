// ///////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star August 2026: Character Designer species preview utilities //
// ///////////////////////////////////////////////////////////////////////////////////////////

import type {
  GearOverlayAssetReference,
  IconAssetReference,
  PreviewDirectionSource,
} from '../../../utils/character-preview';
import type {
  SpeciesDigitigradePreviewAssets,
  SpeciesIconBaseOption,
  SpeciesPayload,
} from '../types';

type SpeciesPreviewSources = NonNullable<
  SpeciesPayload['species'][number]['body_preview_sources']
>;

const digitigradePreviewSourceCache = new WeakMap<
  SpeciesPreviewSources,
  {
    assets: SpeciesDigitigradePreviewAssets;
    sources: SpeciesPreviewSources;
  }
>();

const isGearOverlayAsset = (
  entry: GearOverlayAssetReference | IconAssetReference
): entry is GearOverlayAssetReference =>
  typeof entry === 'object' && entry !== null && 'asset' in entry;

export const mergeSpeciesBodyPreviewSource = (
  base: PreviewDirectionSource,
  speciesBody: PreviewDirectionSource
): PreviewDirectionSource => {
  const appearanceLayers = { ...base };
  delete appearanceLayers.body_asset;
  delete appearanceLayers.reference_part_assets;
  delete appearanceLayers.reference_part_hair_assets;
  delete appearanceLayers.reference_part_marking_assets;
  delete appearanceLayers.body_color_excluded_parts;
  delete appearanceLayers.body_color_blend_mode;
  delete appearanceLayers.body_alpha;
  delete appearanceLayers.part_order;
  delete appearanceLayers.hidden_body_parts;
  delete appearanceLayers.marking_excluded_parts;
  const hasResolvedSpeciesGear =
    Object.prototype.hasOwnProperty.call(
      speciesBody,
      'equipment_overlay_assets'
    ) ||
    Object.prototype.hasOwnProperty.call(speciesBody, 'job_overlay_assets') ||
    Object.prototype.hasOwnProperty.call(speciesBody, 'loadout_overlay_assets');
  if (hasResolvedSpeciesGear) {
    delete appearanceLayers.equipment_overlay_assets;
    delete appearanceLayers.job_overlay_assets;
    delete appearanceLayers.loadout_overlay_assets;
  }
  const overlayAssets = appearanceLayers.overlay_assets;
  if (overlayAssets?.every(isGearOverlayAsset)) {
    appearanceLayers.overlay_assets = overlayAssets.filter(
      (entry) => entry.slot !== 'eyes'
    );
  }
  const appearanceOverlayAssets = (
    appearanceLayers.overlay_assets || []
  ).filter(
    (entry) => !(isGearOverlayAsset(entry) && entry.slot === 'species_tail')
  );
  const hasAppearanceTail = appearanceOverlayAssets.some(
    (entry) =>
      isGearOverlayAsset(entry) &&
      (entry.slot === 'tail_lower' ||
        entry.slot === 'tail_upper' ||
        entry.slot === 'tail_upper_alt')
  );
  const speciesOverlayAssets = (speciesBody.overlay_assets || []).filter(
    (entry) =>
      !(
        hasAppearanceTail &&
        isGearOverlayAsset(entry) &&
        entry.slot === 'species_tail'
      )
  );
  const result = { ...appearanceLayers, ...speciesBody };
  if (
    appearanceLayers.overlay_assets !== undefined ||
    speciesBody.overlay_assets !== undefined
  ) {
    result.overlay_assets = [
      ...appearanceOverlayAssets,
      ...speciesOverlayAssets,
    ];
  }
  return result;
};

export const shouldReuseBasicPreviewCarrier = (options: {
  bodyPayloadMatchesSelection: boolean;
  hasSpeciesPreviewOverride: boolean;
}): boolean =>
  !options.bodyPayloadMatchesSelection && options.hasSpeciesPreviewOverride;

export const shouldUseSpeciesPreviewOverride = (options: {
  hasSpeciesPreviewOverride: boolean;
  selectedSpeciesId?: string | null;
  selectedIconBase?: string | null;
  payloadSpeciesId?: string | null;
  payloadIconBaseId?: string | null;
}): boolean => {
  if (!options.hasSpeciesPreviewOverride) {
    return false;
  }
  if (
    !options.payloadSpeciesId ||
    (!!options.selectedSpeciesId &&
      options.selectedSpeciesId !== options.payloadSpeciesId)
  ) {
    return true;
  }
  return (
    !!options.selectedIconBase &&
    options.selectedIconBase !== options.payloadIconBaseId
  );
};

export const resolveSpeciesIconBaseOptions = (
  speciesPayload?: SpeciesPayload | null,
  speciesId?: string | null
): SpeciesIconBaseOption[] => {
  if (!speciesPayload || !speciesId) {
    return [];
  }
  const previewSpecies =
    speciesPayload.preview_species || speciesPayload.selected_species || null;
  return previewSpecies === speciesId
    ? speciesPayload.icon_base_options || []
    : [];
};

export const applySpeciesDigitigradePreviewAssets = (
  sources: SpeciesPreviewSources,
  digitigradeAssets?: SpeciesDigitigradePreviewAssets
): SpeciesPreviewSources => {
  if (!digitigradeAssets) {
    return sources;
  }
  const cached = digitigradePreviewSourceCache.get(sources);
  if (cached?.assets === digitigradeAssets) {
    return cached.sources;
  }
  let changed = false;
  const resolvedSources = sources.map((source) => {
    const partAssets = digitigradeAssets[source.dir];
    if (!partAssets || !Object.keys(partAssets).length) {
      return source;
    }
    changed = true;
    return {
      ...source,
      reference_part_assets: {
        ...(source.reference_part_assets || {}),
        ...partAssets,
      },
    };
  });
  const result = changed ? resolvedSources : sources;
  digitigradePreviewSourceCache.set(sources, {
    assets: digitigradeAssets,
    sources: result,
  });
  return result;
};

export const resolveSpeciesBodyPreviewSources = (options: {
  selectedSpecies?: SpeciesPayload['species'][number] | null;
  iconBaseOptions?: SpeciesIconBaseOption[];
  iconBaseSelection?: string | null;
  digitigrade?: boolean;
}): SpeciesPreviewSources | null => {
  const {
    selectedSpecies,
    iconBaseOptions = [],
    iconBaseSelection,
    digitigrade = false,
  } = options;
  if (!selectedSpecies) {
    return null;
  }
  const selectedIconBaseOption = iconBaseSelection
    ? iconBaseOptions.find((entry) => entry.id === iconBaseSelection) || null
    : null;
  const fallbackIconBaseOption = iconBaseOptions[0] || null;
  const sourceOwner = [
    selectedIconBaseOption,
    selectedSpecies,
    fallbackIconBaseOption,
  ].find((entry) => !!entry?.body_preview_sources?.length);
  if (!sourceOwner?.body_preview_sources?.length) {
    return null;
  }
  return digitigrade
    ? applySpeciesDigitigradePreviewAssets(
        sourceOwner.body_preview_sources,
        sourceOwner.body_preview_digitigrade_assets
      )
    : sourceOwner.body_preview_sources;
};

export const resolveSelectedSpeciesPreviewSources = (options: {
  speciesPayload?: SpeciesPayload | null;
  speciesSelection?: string | null;
  payloadSpeciesId?: string | null;
  payloadIconBaseId?: string | null;
  speciesIconBaseSelection?: string | null;
  digitigrade?: boolean;
}): {
  selectedSpeciesId: string | null;
  speciesPreviewSources: SpeciesPreviewSources | null;
  speciesPreviewSignature: string;
} => {
  const {
    speciesPayload,
    speciesSelection,
    payloadSpeciesId,
    payloadIconBaseId,
    speciesIconBaseSelection,
    digitigrade = false,
  } = options;
  const selectedSpeciesId =
    speciesSelection ||
    speciesPayload?.preview_species ||
    speciesPayload?.selected_species ||
    null;
  const selectedIconBase =
    speciesIconBaseSelection ||
    speciesPayload?.preview_icon_base ||
    speciesPayload?.selected_icon_base ||
    null;
  const selectedSpecies =
    selectedSpeciesId && speciesPayload?.species
      ? speciesPayload.species.find((entry) => entry.id === selectedSpeciesId)
      : null;
  const previewSources = resolveSpeciesBodyPreviewSources({
    selectedSpecies,
    iconBaseOptions: resolveSpeciesIconBaseOptions(
      speciesPayload,
      selectedSpeciesId
    ),
    iconBaseSelection: selectedIconBase,
    digitigrade,
  });
  const usePreviewSources =
    !!previewSources?.length &&
    (!payloadSpeciesId ||
      selectedSpeciesId !== payloadSpeciesId ||
      (!!selectedIconBase &&
        !!payloadIconBaseId &&
        selectedIconBase !== payloadIconBaseId));
  return {
    selectedSpeciesId,
    speciesPreviewSources: usePreviewSources ? previewSources : null,
    speciesPreviewSignature:
      usePreviewSources && selectedSpeciesId
        ? [
            'species',
            selectedSpeciesId,
            selectedIconBase || '',
            digitigrade ? 'digi' : 'normal',
          ].join(':')
        : '',
  };
};
