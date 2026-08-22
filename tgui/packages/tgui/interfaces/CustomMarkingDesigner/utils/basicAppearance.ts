// ///////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Helper to normalize basic appearence data ///
// ///////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star August 2026: Character Designer - Species and Prosthetics //
// ///////////////////////////////////////////////////////////////////////////////////////////

import { normalizeHex } from '../../../utils/color';
import type {
  IconAssetRegistry,
  PreviewDirState,
} from '../../../utils/character-preview';
import type {
  BasicAppearancePayload,
  BasicAppearanceState,
  BodyMarkingsPayload,
  CustomPreviewOverrideMap,
} from '../types';
import {
  applyProstheticsToPreviewSources,
  cloneLimbOverrideState,
  resolveBiologicalGenderSuffix,
} from './prosthetics';

export type BasicPreviewSourceSelection = Readonly<{
  usesAltSources: boolean;
  sources: NonNullable<BasicAppearancePayload['preview_sources']> | null;
  assetRegistry: IconAssetRegistry | null;
  revision: number;
  sourceKey:
    | 'basic'
    | 'basic-alt'
    | 'basic-gender-alt'
    | 'basic-gender-alt-digitigrade';
}>;

type BasicPreviewSourceVariant = Readonly<{
  sources: BasicAppearancePayload['preview_sources'];
  assetRegistry: IconAssetRegistry | undefined;
  revision: number | undefined;
  sourceKey: BasicPreviewSourceSelection['sourceKey'];
}>;

const resolveBasicPreviewSourceVariant = (
  payload: BasicAppearancePayload | null | undefined,
  usesGenderAlt: boolean,
  usesDigitigradeAlt: boolean
): BasicPreviewSourceVariant => {
  if (usesGenderAlt && usesDigitigradeAlt) {
    return {
      sources: payload?.preview_sources_gender_alt_digitigrade,
      assetRegistry: payload?.preview_asset_registry_gender_alt_digitigrade,
      revision: payload?.preview_revision_gender_alt_digitigrade,
      sourceKey: 'basic-gender-alt-digitigrade',
    };
  }
  if (usesGenderAlt) {
    return {
      sources: payload?.preview_sources_gender_alt,
      assetRegistry: payload?.preview_asset_registry_gender_alt,
      revision: payload?.preview_revision_gender_alt,
      sourceKey: 'basic-gender-alt',
    };
  }
  if (usesDigitigradeAlt) {
    return {
      sources: payload?.preview_sources_alt,
      assetRegistry: payload?.preview_asset_registry_alt,
      revision: payload?.preview_revision_alt,
      sourceKey: 'basic-alt',
    };
  }
  return {
    sources: payload?.preview_sources,
    assetRegistry: payload?.preview_asset_registry,
    revision: payload?.preview_revision,
    sourceKey: 'basic',
  };
};

const normalizeBiologicalGenderOptions = (options?: string[]) =>
  Array.isArray(options)
    ? options.filter(
        (option, index): option is string =>
          typeof option === 'string' &&
          !!option.length &&
          options.indexOf(option) === index
      )
    : [];

const hasCyborgTorso = (state?: BasicAppearanceState | null) =>
  state?.limbs.external?.torso?.status === 'cyborg';

export const resolveBasicBiologicalGenderOptions = (
  payload: BasicAppearancePayload | null | undefined,
  state?: BasicAppearanceState | null
): string[] => {
  const payloadOptions = normalizeBiologicalGenderOptions(
    payload?.biological_genders
  );
  if (!state) {
    return payloadOptions;
  }
  const baseOptions = normalizeBiologicalGenderOptions(
    payload?.base_biological_genders
  );
  const draftHasCyborgTorso = hasCyborgTorso(state);
  let resolved = baseOptions.length ? baseOptions : payloadOptions;
  if (
    !baseOptions.length &&
    !draftHasCyborgTorso &&
    payload?.prosthetic_context?.external?.torso?.status === 'cyborg'
  ) {
    resolved = resolved.filter((option) => option !== 'neuter');
  }
  if (draftHasCyborgTorso && !resolved.includes('neuter')) {
    return [...resolved, 'neuter'];
  }
  return resolved;
};

export const resolveBasicBiologicalGender = (
  biologicalGenders: readonly string[],
  requestedGender: string
) =>
  biologicalGenders.includes(requestedGender)
    ? requestedGender
    : biologicalGenders[0] || requestedGender;

export const shouldInvalidateSpeciesPayloadForBiologicalGenderChange = (
  previousGender: string | null | undefined,
  nextGender: string | null | undefined
) =>
  resolveBiologicalGenderSuffix(previousGender) !==
  resolveBiologicalGenderSuffix(nextGender);

const mergePreviewSourcesWithCustomOverrides = (
  sources: BasicAppearancePayload['preview_sources'],
  overrides: CustomPreviewOverrideMap
) => {
  if (!Array.isArray(sources) || !sources.length) {
    return { sources, changed: false };
  }
  let changed = false;
  const nextSources = sources.map((source) => {
    if (!source) {
      return source;
    }
    const override = overrides[source.dir];
    if (!override) {
      return source;
    }
    const customParts = override.custom_parts || null;
    const partOrder = override.part_order || null;
    if (!customParts && !partOrder) {
      return source;
    }
    changed = true;
    return {
      ...source,
      ...(customParts ? { custom_parts: customParts } : {}),
      ...(partOrder ? { part_order: partOrder } : {}),
    };
  });
  return { sources: nextSources, changed };
};

export const applyCustomPreviewOverridesToBasicPayload = (
  payload: BasicAppearancePayload,
  overrides: CustomPreviewOverrideMap
): BasicAppearancePayload => {
  const primary = mergePreviewSourcesWithCustomOverrides(
    payload.preview_sources,
    overrides
  );
  const alt = mergePreviewSourcesWithCustomOverrides(
    payload.preview_sources_alt,
    overrides
  );
  const genderAlt = mergePreviewSourcesWithCustomOverrides(
    payload.preview_sources_gender_alt,
    overrides
  );
  const genderAltDigitigrade = mergePreviewSourcesWithCustomOverrides(
    payload.preview_sources_gender_alt_digitigrade,
    overrides
  );
  if (
    !primary.changed &&
    !alt.changed &&
    !genderAlt.changed &&
    !genderAltDigitigrade.changed
  ) {
    return payload;
  }
  return {
    ...payload,
    ...(primary.changed
      ? {
          preview_sources: primary.sources,
          preview_revision: (payload.preview_revision || 0) + 1,
        }
      : {}),
    ...(alt.changed
      ? {
          preview_sources_alt: alt.sources,
          preview_revision_alt: (payload.preview_revision_alt || 0) + 1,
        }
      : {}),
    ...(genderAlt.changed
      ? {
          preview_sources_gender_alt: genderAlt.sources,
          preview_revision_gender_alt:
            (payload.preview_revision_gender_alt || 0) + 1,
        }
      : {}),
    ...(genderAltDigitigrade.changed
      ? {
          preview_sources_gender_alt_digitigrade: genderAltDigitigrade.sources,
          preview_revision_gender_alt_digitigrade:
            (payload.preview_revision_gender_alt_digitigrade || 0) + 1,
        }
      : {}),
  };
};

export const resolveBasicPreviewSourceSelection = (
  payload: BasicAppearancePayload | null | undefined,
  digitigrade: boolean,
  state?: BasicAppearanceState | null,
  biologicalGender?: string | null
): BasicPreviewSourceSelection => {
  const requestedGender =
    biologicalGender ?? state?.biological_gender ?? payload?.biological_gender;
  const payloadGenderSuffix =
    payload?.preview_gender_suffix ||
    resolveBiologicalGenderSuffix(payload?.biological_gender);
  const usesGenderAlt =
    resolveBiologicalGenderSuffix(requestedGender) !== payloadGenderSuffix;
  const usesDigitigradeAlt = digitigrade !== !!payload?.digitigrade;
  const requestedVariant = resolveBasicPreviewSourceVariant(
    payload,
    usesGenderAlt,
    usesDigitigradeAlt
  );
  const sameGenderFallback = resolveBasicPreviewSourceVariant(
    payload,
    usesGenderAlt,
    false
  );
  const sameLegFallback = resolveBasicPreviewSourceVariant(
    payload,
    false,
    usesDigitigradeAlt
  );
  const primaryVariant = resolveBasicPreviewSourceVariant(
    payload,
    false,
    false
  );
  const selectedVariant =
    Array.isArray(requestedVariant.sources) && requestedVariant.sources.length
      ? requestedVariant
      : Array.isArray(sameGenderFallback.sources) &&
          sameGenderFallback.sources.length
        ? sameGenderFallback
        : Array.isArray(sameLegFallback.sources) &&
            sameLegFallback.sources.length
          ? sameLegFallback
          : primaryVariant;
  const rawSources = selectedVariant.sources;
  const sources = state
    ? applyProstheticsToPreviewSources(
        Array.isArray(rawSources) && rawSources.length ? rawSources : null,
        state,
        payload?.prosthetic_context
      )
    : Array.isArray(rawSources) && rawSources.length
      ? rawSources
      : null;
  return {
    usesAltSources: selectedVariant.sourceKey !== 'basic',
    sources,
    assetRegistry: selectedVariant.assetRegistry || null,
    revision: selectedVariant.revision ?? payload?.preview_revision ?? 0,
    sourceKey: selectedVariant.sourceKey,
  };
};

export type SharedPreviewSourceSelection = Readonly<{
  sources: NonNullable<BasicAppearancePayload['preview_sources']> | null;
  assetRegistry: IconAssetRegistry | null;
  revision: number;
  sourceKey:
    | 'basic'
    | 'basic-alt'
    | 'basic-gender-alt'
    | 'basic-gender-alt-digitigrade'
    | 'body'
    | 'none';
  payloadSpeciesId: string | null;
  payloadIconBaseId: string | null;
}>;

export const resolveSharedPreviewSourceSelection = (options: {
  basicPayload: BasicAppearancePayload | null | undefined;
  bodyPayload: BodyMarkingsPayload | null | undefined;
  digitigrade: boolean;
  basicAppearanceState?: BasicAppearanceState | null;
}): SharedPreviewSourceSelection => {
  const { basicPayload, bodyPayload, digitigrade, basicAppearanceState } =
    options;
  const basicSelection = resolveBasicPreviewSourceSelection(
    basicPayload,
    digitigrade,
    basicAppearanceState
  );
  if (basicSelection.sources) {
    return {
      sources: basicSelection.sources,
      assetRegistry: basicSelection.assetRegistry,
      revision: basicSelection.revision,
      sourceKey: basicSelection.sourceKey,
      payloadSpeciesId: basicPayload?.species_id || null,
      payloadIconBaseId: basicPayload?.custom_base || null,
    };
  }
  const bodySources =
    Array.isArray(bodyPayload?.preview_sources) &&
    bodyPayload.preview_sources.length
      ? bodyPayload.preview_sources
      : null;
  if (bodySources) {
    return {
      sources: bodySources,
      assetRegistry: bodyPayload?.preview_asset_registry || null,
      revision: bodyPayload?.preview_revision ?? 0,
      sourceKey: 'body',
      payloadSpeciesId: bodyPayload?.species_id || null,
      payloadIconBaseId: bodyPayload?.custom_base || null,
    };
  }
  return {
    sources: null,
    assetRegistry: null,
    revision: 0,
    sourceKey: 'none',
    payloadSpeciesId: null,
    payloadIconBaseId: null,
  };
};

export const shouldRetainLocalBasicPayload = (options: {
  basicPayload: BasicAppearancePayload | null;
  reloadPending: boolean;
  loadInProgress: boolean;
}): boolean => {
  const { basicPayload, reloadPending, loadInProgress } = options;
  return !!basicPayload && !reloadPending && !loadInProgress;
};

export type BasicAppearanceGalleryType =
  | 'hair'
  | 'gradient'
  | 'facial_hair'
  | 'ears'
  | 'horns'
  | 'tail'
  | 'wings';

export const normalizeBasicAppearanceGalleryStyleId = (
  styleId: string | null | undefined
): string | null => {
  if (!styleId) {
    return null;
  }
  return styleId === 'Normal' || styleId.toLowerCase() === 'none'
    ? null
    : styleId;
};

export const buildBasicAppearanceGalleryContextSignature = (
  state: BasicAppearanceState,
  galleryType: BasicAppearanceGalleryType
): string => {
  const activeStyle = 'active';
  return [
    galleryType,
    galleryType === 'hair' ? activeStyle : state.hair_style || 'hair-none',
    state.hair_color || 'hair-color',
    state.biological_gender || 'male',
    galleryType === 'gradient'
      ? activeStyle
      : state.hair_gradient_style || 'gradient-none',
    state.hair_gradient_color || 'gradient-color',
    galleryType === 'facial_hair'
      ? activeStyle
      : state.facial_hair_style || 'facial-none',
    state.facial_hair_color || 'facial-color',
    galleryType === 'ears' ? activeStyle : state.ear_style || 'ears-none',
    (state.ear_colors || []).join('|'),
    galleryType === 'horns' ? activeStyle : state.horn_style || 'horns-none',
    (state.horn_colors || []).join('|'),
    galleryType === 'tail' ? activeStyle : state.tail_style || 'tail-none',
    (state.tail_colors || []).join('|'),
    galleryType === 'wings' ? activeStyle : state.wing_style || 'wings-none',
    (state.wing_colors || []).join('|'),
  ].join('::');
};

export const shouldIncludeSpeciesTailInGalleryTile = (
  galleryType: BasicAppearanceGalleryType,
  definitionId: string,
  selectedTailStyle?: string | null
): boolean => {
  const effectiveTailStyle =
    galleryType === 'tail'
      ? normalizeBasicAppearanceGalleryStyleId(definitionId)
      : normalizeBasicAppearanceGalleryStyleId(selectedTailStyle);
  return !effectiveTailStyle;
};

const stripOverlaySlotsFromGalleryPreviewStates = (
  dirStates: Record<number, PreviewDirState>,
  slots: Set<string>
): Record<number, PreviewDirState> => {
  let result = dirStates;
  for (const dirState of Object.values(dirStates)) {
    const overlayAssets = dirState.overlayAssets;
    if (!Array.isArray(overlayAssets) || !overlayAssets.length) {
      continue;
    }
    const filteredOverlayAssets = overlayAssets.filter(
      (entry) => !('asset' in entry && !!entry.slot && slots.has(entry.slot))
    );
    if (filteredOverlayAssets.length === overlayAssets.length) {
      continue;
    }
    if (result === dirStates) {
      result = { ...dirStates };
    }
    result[dirState.dir] = {
      ...dirState,
      overlayAssets: filteredOverlayAssets,
    };
  }
  return result;
};

export const stripSpeciesTailFromGalleryPreviewStates = (
  dirStates: Record<number, PreviewDirState>
): Record<number, PreviewDirState> =>
  stripOverlaySlotsFromGalleryPreviewStates(
    dirStates,
    new Set(['species_tail'])
  );

export const resolveGalleryTilePreviewStates = (
  dirStates: Record<number, PreviewDirState>,
  galleryType: BasicAppearanceGalleryType,
  definitionId: string,
  selectedTailStyle?: string | null
): Record<number, PreviewDirState> => {
  const candidateId = normalizeBasicAppearanceGalleryStyleId(definitionId);
  const slots = new Set<string>();
  if (
    !shouldIncludeSpeciesTailInGalleryTile(
      galleryType,
      definitionId,
      selectedTailStyle
    )
  ) {
    slots.add('species_tail');
    slots.add('prosthetic_tail');
  }
  if (candidateId && (galleryType === 'ears' || galleryType === 'horns')) {
    slots.add('prosthetic_ears');
  }
  if (candidateId && galleryType === 'wings') {
    slots.add('prosthetic_wing');
  }
  return slots.size
    ? stripOverlaySlotsFromGalleryPreviewStates(dirStates, slots)
    : dirStates;
};

export const buildBasicStateFromPayload = (
  payload?: BasicAppearancePayload | null
  // eslint-disable-next-line complexity
): BasicAppearanceState => {
  const rawGradientStyle =
    typeof payload?.hair_gradient_style === 'string'
      ? payload.hair_gradient_style.trim()
      : '';
  const digitigradeAllowed = payload?.digitigrade_allowed !== false;
  return {
    biological_gender:
      typeof payload?.biological_gender === 'string' &&
      payload.biological_gender.length
        ? payload.biological_gender
        : 'male',
    digitigrade: digitigradeAllowed && !!payload?.digitigrade,
    blood_type:
      typeof payload?.blood_type === 'string' && payload.blood_type.length
        ? payload.blood_type
        : 'A+',
    blood_reagent:
      typeof payload?.blood_reagent === 'string' && payload.blood_reagent.length
        ? payload.blood_reagent
        : 'iron',
    blood_color: normalizeHex(payload?.blood_color) || '#a10808',
    needs_glasses: !!payload?.needs_glasses,
    body_color: payload?.body_color ? normalizeHex(payload.body_color) : null,
    eye_color: payload?.eye_color ? normalizeHex(payload.eye_color) : null,
    hair_style:
      typeof payload?.hair_style === 'string' && payload.hair_style.length
        ? payload.hair_style
        : null,
    hair_color: payload?.hair_color ? normalizeHex(payload.hair_color) : null,
    hair_gradient_style:
      rawGradientStyle.length && rawGradientStyle.toLowerCase() !== 'none'
        ? rawGradientStyle
        : null,
    hair_gradient_color: payload?.hair_gradient_color
      ? normalizeHex(payload.hair_gradient_color)
      : null,
    facial_hair_style:
      typeof payload?.facial_hair_style === 'string' &&
      payload.facial_hair_style.length
        ? payload.facial_hair_style
        : null,
    facial_hair_color: payload?.facial_hair_color
      ? normalizeHex(payload.facial_hair_color)
      : null,
    ear_style:
      typeof payload?.ear_style === 'string' && payload.ear_style.length
        ? payload.ear_style
        : null,
    ear_colors: Array.isArray(payload?.ear_colors)
      ? (payload?.ear_colors || []).map((color) =>
          color ? normalizeHex(color) : null
        )
      : [null, null, null],
    horn_style:
      typeof payload?.horn_style === 'string' && payload.horn_style.length
        ? payload.horn_style
        : null,
    horn_colors: Array.isArray(payload?.horn_colors)
      ? (payload?.horn_colors || []).map((color) =>
          color ? normalizeHex(color) : null
        )
      : [],
    tail_style:
      typeof payload?.tail_style === 'string' && payload.tail_style.length
        ? payload.tail_style
        : null,
    tail_colors: Array.isArray(payload?.tail_colors)
      ? (payload?.tail_colors || []).map((color) =>
          color ? normalizeHex(color) : null
        )
      : [null, null, null],
    wing_style:
      typeof payload?.wing_style === 'string' && payload.wing_style.length
        ? payload.wing_style
        : null,
    wing_colors: Array.isArray(payload?.wing_colors)
      ? (payload?.wing_colors || []).map((color) =>
          color ? normalizeHex(color) : null
        )
      : [null, null, null],
    limbs: cloneLimbOverrideState(payload?.prosthetic_context),
    limb_operations: [],
    organ_operations: [],
    synth_color_enabled: !!payload?.prosthetic_context?.synth_color_enabled,
    synth_color: payload?.prosthetic_context?.synth_color
      ? normalizeHex(payload.prosthetic_context.synth_color)
      : null,
    synth_markings: !!payload?.prosthetic_context?.synth_markings,
  };
};
