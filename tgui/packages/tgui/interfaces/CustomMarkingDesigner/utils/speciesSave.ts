// ////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star August 2026: Character Designer species save utilities //
// ////////////////////////////////////////////////////////////////////////////////////////

import type { PreviewDirectionSource } from '../../../utils/character-preview';
import type { IconAssetRegistry } from '../../../utils/character-preview';
import type {
  BasicAppearancePayload,
  BodyMarkingsPayload,
  SpeciesPayload,
  SpeciesSaveResult,
} from '../types';
import { buildBasicStateFromPayload } from './basicAppearance';
import { deepCopyMarkings } from './bodyMarkings';
import {
  mergeBasicAppearancePayload,
  mergeBodyMarkingsPayload,
} from './payloadCache';

type SpeciesSavePreviewPayload = {
  preview_sources?: PreviewDirectionSource[];
  preview_asset_registry?: IconAssetRegistry;
  preview_signature?: string | null;
  preview_revision?: number;
};

export const applySpeciesSavePreviewBundle = <
  T extends SpeciesSavePreviewPayload,
>(
  payload: T,
  result: SpeciesSaveResult
): T => {
  const previewSources =
    Array.isArray(result.preview_sources) && result.preview_sources.length
      ? result.preview_sources
      : undefined;
  return {
    ...payload,
    preview_sources: previewSources,
    preview_asset_registry: previewSources
      ? result.preview_asset_registry
      : undefined,
    preview_signature: result.preview_signature,
    preview_revision:
      typeof result.preview_revision === 'number' ? result.preview_revision : 0,
  };
};

export const applySpeciesSaveBasicPreviewBundles = (
  payload: BasicAppearancePayload,
  result: SpeciesSaveResult
): BasicAppearancePayload => {
  const primaryPayload = applySpeciesSavePreviewBundle(payload, result);
  const previewSourcesAlt =
    Array.isArray(result.preview_sources_alt) &&
    result.preview_sources_alt.length
      ? result.preview_sources_alt
      : undefined;
  const previewSourcesGenderAlt =
    Array.isArray(result.preview_sources_gender_alt) &&
    result.preview_sources_gender_alt.length
      ? result.preview_sources_gender_alt
      : undefined;
  const previewSourcesGenderAltDigitigrade =
    Array.isArray(result.preview_sources_gender_alt_digitigrade) &&
    result.preview_sources_gender_alt_digitigrade.length
      ? result.preview_sources_gender_alt_digitigrade
      : undefined;
  return {
    ...primaryPayload,
    preview_sources_alt: previewSourcesAlt,
    preview_asset_registry_alt: previewSourcesAlt
      ? result.preview_asset_registry_alt
      : undefined,
    preview_signature_alt: result.preview_signature_alt,
    preview_revision_alt:
      typeof result.preview_revision_alt === 'number'
        ? result.preview_revision_alt
        : 0,
    preview_sources_gender_alt: previewSourcesGenderAlt,
    preview_asset_registry_gender_alt: previewSourcesGenderAlt
      ? result.preview_asset_registry_gender_alt
      : undefined,
    preview_signature_gender_alt: result.preview_signature_gender_alt,
    preview_revision_gender_alt:
      typeof result.preview_revision_gender_alt === 'number'
        ? result.preview_revision_gender_alt
        : 0,
    preview_sources_gender_alt_digitigrade: previewSourcesGenderAltDigitigrade,
    preview_asset_registry_gender_alt_digitigrade:
      previewSourcesGenderAltDigitigrade
        ? result.preview_asset_registry_gender_alt_digitigrade
        : undefined,
    preview_signature_gender_alt_digitigrade:
      result.preview_signature_gender_alt_digitigrade,
    preview_revision_gender_alt_digitigrade:
      typeof result.preview_revision_gender_alt_digitigrade === 'number'
        ? result.preview_revision_gender_alt_digitigrade
        : 0,
  };
};

type SpeciesSaveStateWriter = (states: Record<string, unknown>) => void;

type SpeciesSaveStateSyncOptions = Readonly<{
  result: SpeciesSaveResult;
  stateToken: string;
  speciesPayload: SpeciesPayload | null;
  bodyPayload: BodyMarkingsPayload | null;
  basicPayload: BasicAppearancePayload | null;
}>;

export const CUSTOM_SPECIES_ID = 'Custom Species';

export const isSpeciesSaveBlocked = (
  speciesSelection: string | null,
  customSpeciesName: string
) => speciesSelection === CUSTOM_SPECIES_ID && !customSpeciesName.trim().length;

export const isSpeciesSaveAllowed = (
  speciesSelection: string | null,
  customSpeciesName: string
): speciesSelection is string =>
  !!speciesSelection &&
  !isSpeciesSaveBlocked(speciesSelection, customSpeciesName);

export const isSpeciesDraftDirty = (
  speciesSelection: string | null,
  savedSpeciesSelection: string | null,
  iconBaseSelection: string | null,
  savedIconBaseSelection: string | null,
  customSpeciesName: string,
  savedCustomSpeciesName: string
) =>
  speciesSelection !== savedSpeciesSelection ||
  iconBaseSelection !== savedIconBaseSelection ||
  customSpeciesName !== savedCustomSpeciesName;

export const applyCustomSpeciesNameToPayload = (
  payload: SpeciesPayload,
  customSpeciesName: string | null
): SpeciesPayload => ({
  ...payload,
  custom_species: customSpeciesName,
});

export const syncSpeciesSaveResultState = (
  writeStates: SpeciesSaveStateWriter,
  options: SpeciesSaveStateSyncOptions
) => {
  const { result, stateToken, speciesPayload, bodyPayload, basicPayload } =
    options;
  const nextSpeciesId = result.species_id || null;
  const nextIconBase = result.custom_base || null;
  const nextCustomSpeciesName = result.custom_species || null;
  const nextMarkings = deepCopyMarkings(result.body_markings);
  const nextOrder = (result.order || []).filter(
    (markId) => !!nextMarkings?.[markId]
  );
  const resolvedOrder = nextOrder.length
    ? nextOrder
    : Object.keys(nextMarkings || {});
  const nextSelectedId =
    typeof resolvedOrder[0] === 'string' ? resolvedOrder[0] : null;
  const nextBodyPayload = mergeBodyMarkingsPayload(bodyPayload, {
    species_id: nextSpeciesId,
    custom_base: nextIconBase,
    definition_revision: result.body_definition_revision,
    definition_data: result.body_definition_data,
    allowed_definition_ids: result.body_allowed_definition_ids,
    body_marking_definitions: result.body_marking_definitions,
    body_markings: deepCopyMarkings(nextMarkings),
    order: [...resolvedOrder],
    digitigrade:
      result.basic_appearance?.digitigrade ?? bodyPayload?.digitigrade,
    preview_only: false,
    preview_sources: result.preview_sources,
    preview_asset_registry: result.preview_asset_registry,
    preview_signature: result.preview_signature,
    preview_revision: result.preview_revision,
  });
  const nextBasicPayload = mergeBasicAppearancePayload(
    basicPayload,
    {
      ...(result.basic_appearance || {}),
      species_id: nextSpeciesId,
      custom_base: nextIconBase,
      preview_only: false,
      preview_sources: result.preview_sources,
      preview_asset_registry: result.preview_asset_registry,
      preview_signature: result.preview_signature,
      preview_revision: result.preview_revision,
      preview_sources_alt: result.preview_sources_alt,
      preview_asset_registry_alt: result.preview_asset_registry_alt,
      preview_signature_alt: result.preview_signature_alt,
      preview_revision_alt: result.preview_revision_alt,
      preview_sources_gender_alt: result.preview_sources_gender_alt,
      preview_asset_registry_gender_alt:
        result.preview_asset_registry_gender_alt,
      preview_signature_gender_alt: result.preview_signature_gender_alt,
      preview_revision_gender_alt: result.preview_revision_gender_alt,
      preview_sources_gender_alt_digitigrade:
        result.preview_sources_gender_alt_digitigrade,
      preview_asset_registry_gender_alt_digitigrade:
        result.preview_asset_registry_gender_alt_digitigrade,
      preview_signature_gender_alt_digitigrade:
        result.preview_signature_gender_alt_digitigrade,
      preview_revision_gender_alt_digitigrade:
        result.preview_revision_gender_alt_digitigrade,
    },
    nextBodyPayload
  );
  const nextBasicState = buildBasicStateFromPayload(nextBasicPayload);

  writeStates({
    ...(speciesPayload
      ? {
          speciesPayload: applyCustomSpeciesNameToPayload(
            {
              ...speciesPayload,
              selected_species: nextSpeciesId,
              preview_species: nextSpeciesId,
              selected_icon_base: nextIconBase,
              preview_icon_base: nextIconBase,
            },
            nextCustomSpeciesName
          ),
        }
      : {}),
    speciesSelection: nextSpeciesId,
    speciesSavedSelection: nextSpeciesId,
    speciesIconBaseSelection: nextIconBase,
    speciesSavedIconBaseSelection: nextIconBase,
    speciesCustomName: nextCustomSpeciesName || '',
    speciesSavedCustomName: nextCustomSpeciesName || '',
    speciesDirty: false,
    [`speciesLoadInProgress-${stateToken}`]: false,
    [`speciesReloadPending-${stateToken}`]: false,
    bodyMarkingsState: nextMarkings,
    bodyMarkingsOrder: resolvedOrder,
    bodyMarkingsSelected: nextSelectedId,
    bodyMarkingsSavedState: {
      order: [...resolvedOrder],
      markings: deepCopyMarkings(nextMarkings),
      selectedId: nextSelectedId,
    },
    bodyMarkingsDirty: false,
    bodyPayload: nextBodyPayload,
    basicPayload: nextBasicPayload,
    basicAppearanceState: nextBasicState,
    basicAppearanceSavedState: nextBasicState,
    basicAppearanceDirty: false,
    [`bodyMarkingsReloadPending-${stateToken}`]: false,
    [`basicAppearanceReloadPending-${stateToken}`]: false,
    speciesPendingSave: false,
    speciesPendingClose: false,
    [`pendingSave-${stateToken}`]: false,
    [`pendingClose-${stateToken}`]: false,
  });
};
