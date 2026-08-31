// //////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star August 2026: Character Designer paylod cache //
// //////////////////////////////////////////////////////////////////////////////

import type {
  BasicAppearanceAllowedStyleIds,
  BasicAppearanceDefinitionData,
  BasicAppearancePayload,
  BodyMarkingDefinition,
  BodyMarkingsPayload,
} from '../types';

type PayloadRequestParams = Record<string, unknown>;

type PreviewCacheCarrier = Pick<
  BasicAppearancePayload,
  | 'preview_sources'
  | 'preview_asset_registry'
  | 'preview_signature'
  | 'preview_revision'
>;

const BASIC_DEFINITION_KEYS = [
  'hair_styles',
  'gradient_styles',
  'facial_hair_styles',
  'ear_styles',
  'tail_styles',
  'wing_styles',
] as const;

const hasOwn = (value: object, key: PropertyKey) =>
  Object.prototype.hasOwnProperty.call(value, key);

const previewMatches = (
  previous: PreviewCacheCarrier | null | undefined,
  incoming: PreviewCacheCarrier
): boolean => {
  if (!previous) {
    return false;
  }
  const previousSignature = previous.preview_signature || null;
  const incomingSignature = incoming.preview_signature || null;
  if (previousSignature && incomingSignature) {
    return previousSignature === incomingSignature;
  }
  return (
    typeof previous.preview_revision === 'number' &&
    previous.preview_revision === incoming.preview_revision
  );
};

const mergePrimaryPreview = <T extends PreviewCacheCarrier>(
  previous: T | null | undefined,
  incoming: T,
  fallback?: PreviewCacheCarrier | null,
  sourcesProvided = hasOwn(incoming, 'preview_sources') &&
    incoming.preview_sources !== undefined
): T => {
  if (sourcesProvided) {
    return incoming;
  }
  const source = previewMatches(previous, incoming)
    ? previous
    : previewMatches(fallback, incoming)
      ? fallback
      : null;
  if (source?.preview_sources?.length) {
    return {
      ...incoming,
      preview_sources: source.preview_sources,
      preview_asset_registry: source.preview_asset_registry,
    };
  }
  return {
    ...incoming,
    preview_sources: undefined,
    preview_asset_registry: undefined,
  };
};

type BasicPreviewVariantSuffix =
  | 'alt'
  | 'gender_alt'
  | 'gender_alt_digitigrade';

const getBasicPreviewVariant = (
  payload: BasicAppearancePayload | null | undefined,
  suffix: BasicPreviewVariantSuffix
): PreviewCacheCarrier | null =>
  payload
    ? {
        preview_sources: payload[`preview_sources_${suffix}`],
        preview_asset_registry: payload[`preview_asset_registry_${suffix}`],
        preview_signature: payload[`preview_signature_${suffix}`],
        preview_revision: payload[`preview_revision_${suffix}`],
      }
    : null;

const mergeBasicPreviewVariant = (
  previous: BasicAppearancePayload | null | undefined,
  incoming: BasicAppearancePayload,
  suffix: BasicPreviewVariantSuffix
) =>
  mergePrimaryPreview(
    getBasicPreviewVariant(previous, suffix),
    getBasicPreviewVariant(incoming, suffix)!,
    null,
    hasOwn(incoming, `preview_sources_${suffix}`) &&
      incoming[`preview_sources_${suffix}`] !== undefined
  );

const filterDefinitions = <T extends { id: string }>(
  definitions: T[] | undefined,
  allowedIds: string[] | undefined
): T[] | undefined => {
  if (!Array.isArray(definitions)) {
    return undefined;
  }
  if (!Array.isArray(allowedIds)) {
    return definitions;
  }
  const byId = new Map(
    definitions.map((definition) => [definition.id, definition])
  );
  return allowedIds
    .map((id) => byId.get(id))
    .filter((definition): definition is T => !!definition);
};

const materializeBasicDefinitions = (
  definitionData: BasicAppearanceDefinitionData | undefined,
  allowedStyleIds: BasicAppearanceAllowedStyleIds | undefined
): Partial<BasicAppearancePayload> => {
  const result: Partial<BasicAppearancePayload> = {};
  for (const key of BASIC_DEFINITION_KEYS) {
    const definitions = definitionData?.[key] as
      | Array<{ id: string }>
      | undefined;
    const filtered = filterDefinitions(definitions, allowedStyleIds?.[key]);
    if (filtered) {
      (result as Record<string, unknown>)[key] = filtered;
    }
  }
  return result;
};

export const mergeBasicAppearancePayload = (
  previous: BasicAppearancePayload | null | undefined,
  incoming: BasicAppearancePayload,
  previewFallback?: PreviewCacheCarrier | null
): BasicAppearancePayload => {
  const sameDefinitionRevision =
    !!previous &&
    !!incoming.definition_revision &&
    previous.definition_revision === incoming.definition_revision;
  const definitionData =
    incoming.definition_data ||
    (sameDefinitionRevision ? previous?.definition_data : undefined);
  const allowedStyleIds =
    incoming.allowed_style_ids ||
    (sameDefinitionRevision ? previous?.allowed_style_ids : undefined);
  const resolvedPrimary = mergePrimaryPreview(
    previous,
    incoming,
    previewFallback,
    hasOwn(incoming, 'preview_sources') &&
      incoming.preview_sources !== undefined
  );
  const merged = {
    ...(previous || {}),
    ...incoming,
    definition_data: definitionData,
    allowed_style_ids: allowedStyleIds,
    ...materializeBasicDefinitions(definitionData, allowedStyleIds),
    preview_sources: resolvedPrimary.preview_sources,
    preview_asset_registry: resolvedPrimary.preview_asset_registry,
  };

  const resolvedAlt = mergeBasicPreviewVariant(previous, incoming, 'alt');
  const resolvedGenderAlt = mergeBasicPreviewVariant(
    previous,
    incoming,
    'gender_alt'
  );
  const resolvedGenderAltDigitigrade = mergeBasicPreviewVariant(
    previous,
    incoming,
    'gender_alt_digitigrade'
  );
  return {
    ...merged,
    preview_sources_alt: resolvedAlt.preview_sources,
    preview_asset_registry_alt: resolvedAlt.preview_asset_registry,
    preview_signature_alt: resolvedAlt.preview_signature,
    preview_revision_alt: resolvedAlt.preview_revision,
    preview_sources_gender_alt: resolvedGenderAlt.preview_sources,
    preview_asset_registry_gender_alt: resolvedGenderAlt.preview_asset_registry,
    preview_signature_gender_alt: resolvedGenderAlt.preview_signature,
    preview_revision_gender_alt: resolvedGenderAlt.preview_revision,
    preview_sources_gender_alt_digitigrade:
      resolvedGenderAltDigitigrade.preview_sources,
    preview_asset_registry_gender_alt_digitigrade:
      resolvedGenderAltDigitigrade.preview_asset_registry,
    preview_signature_gender_alt_digitigrade:
      resolvedGenderAltDigitigrade.preview_signature,
    preview_revision_gender_alt_digitigrade:
      resolvedGenderAltDigitigrade.preview_revision,
    preview_only:
      incoming.preview_only && previous && !previous.preview_only
        ? false
        : incoming.preview_only,
  };
};

export const mergeBodyMarkingsPayload = (
  previous: BodyMarkingsPayload | null | undefined,
  incoming: BodyMarkingsPayload,
  previewFallback?: PreviewCacheCarrier | null
): BodyMarkingsPayload => {
  const sameDefinitionRevision =
    !!previous &&
    !!incoming.definition_revision &&
    previous.definition_revision === incoming.definition_revision;
  const definitionData =
    incoming.definition_data ||
    (sameDefinitionRevision ? previous?.definition_data : undefined);
  const allowedDefinitionIds =
    incoming.allowed_definition_ids ||
    (sameDefinitionRevision ? previous?.allowed_definition_ids : undefined);
  const definitions = filterDefinitions<BodyMarkingDefinition>(
    definitionData ||
      (sameDefinitionRevision
        ? previous?.body_marking_definitions
        : undefined) ||
      incoming.body_marking_definitions,
    allowedDefinitionIds
  );
  const resolvedPrimary = mergePrimaryPreview(
    previous,
    incoming,
    previewFallback,
    hasOwn(incoming, 'preview_sources') &&
      incoming.preview_sources !== undefined
  );
  const merged = {
    ...(previous || {}),
    ...incoming,
    definition_data: definitionData,
    allowed_definition_ids: allowedDefinitionIds,
    body_marking_definitions: definitions,
    preview_sources: resolvedPrimary.preview_sources,
    preview_asset_registry: resolvedPrimary.preview_asset_registry,
  };
  return {
    ...merged,
    preview_only:
      incoming.preview_only && previous && !previous.preview_only
        ? false
        : incoming.preview_only,
  };
};

const appendKnownPreview = (
  params: PayloadRequestParams,
  payload: PreviewCacheCarrier | null | undefined,
  prefix = ''
) => {
  if (!payload?.preview_sources?.length) {
    return;
  }
  if (typeof payload?.preview_revision === 'number') {
    params[`known_${prefix}preview_revision`] = payload.preview_revision;
  }
  if (payload?.preview_signature) {
    params[`known_${prefix}preview_signature`] = payload.preview_signature;
  }
};

const primaryPreviewForBody = (
  bodyPayload: BodyMarkingsPayload | null | undefined,
  basicPayload: BasicAppearancePayload | null | undefined
): PreviewCacheCarrier | null => {
  if (bodyPayload?.preview_revision || bodyPayload?.preview_signature) {
    return bodyPayload;
  }
  if (!basicPayload) {
    return null;
  }
  const bodyDigitigrade = bodyPayload?.digitigrade ?? basicPayload.digitigrade;
  if (
    bodyDigitigrade !== basicPayload.digitigrade &&
    (basicPayload.preview_revision_alt || basicPayload.preview_signature_alt)
  ) {
    return {
      preview_sources: basicPayload.preview_sources_alt,
      preview_asset_registry: basicPayload.preview_asset_registry_alt,
      preview_signature: basicPayload.preview_signature_alt,
      preview_revision: basicPayload.preview_revision_alt,
    };
  }
  return basicPayload;
};

const hasBodyDefinitionData = (
  payload: BodyMarkingsPayload | null | undefined
): boolean =>
  !!payload?.definition_data?.length ||
  !!payload?.body_marking_definitions?.length;

const hasBasicDefinitionData = (
  payload: BasicAppearancePayload | null | undefined
): boolean =>
  !!payload?.definition_data ||
  BASIC_DEFINITION_KEYS.some((key) => !!payload?.[key]?.length);

export const buildBodyMarkingsLoadParams = (
  bodyPayload: BodyMarkingsPayload | null | undefined,
  basicPayload: BasicAppearancePayload | null | undefined,
  extra: PayloadRequestParams = {},
  retainKnown = true
): PayloadRequestParams => {
  const params = { ...extra };
  if (!retainKnown) {
    return params;
  }
  if (bodyPayload?.definition_revision && hasBodyDefinitionData(bodyPayload)) {
    params.known_definition_revision = bodyPayload.definition_revision;
  }
  appendKnownPreview(params, primaryPreviewForBody(bodyPayload, basicPayload));
  return params;
};

export const buildBasicAppearanceLoadParams = (
  basicPayload: BasicAppearancePayload | null | undefined,
  bodyPayload: BodyMarkingsPayload | null | undefined,
  extra: PayloadRequestParams = {},
  retainKnown = true
): PayloadRequestParams => {
  const params = { ...extra };
  if (!retainKnown) {
    return params;
  }
  if (
    basicPayload?.definition_revision &&
    hasBasicDefinitionData(basicPayload)
  ) {
    params.known_definition_revision = basicPayload.definition_revision;
  }
  appendKnownPreview(params, basicPayload || bodyPayload || null);
  if (
    basicPayload?.preview_revision_alt ||
    basicPayload?.preview_signature_alt
  ) {
    appendKnownPreview(
      params,
      {
        preview_sources: basicPayload.preview_sources_alt,
        preview_asset_registry: basicPayload.preview_asset_registry_alt,
        preview_signature: basicPayload.preview_signature_alt,
        preview_revision: basicPayload.preview_revision_alt,
      },
      'alt_'
    );
  }
  for (const suffix of ['gender_alt', 'gender_alt_digitigrade'] as const) {
    const variant = getBasicPreviewVariant(basicPayload, suffix);
    if (variant?.preview_revision || variant?.preview_signature) {
      appendKnownPreview(params, variant, `${suffix}_`);
    }
  }
  return params;
};

export const buildSpeciesSaveCacheParams = (
  bodyPayload: BodyMarkingsPayload | null | undefined,
  basicPayload: BasicAppearancePayload | null | undefined
): PayloadRequestParams => {
  const params: PayloadRequestParams = {};
  if (bodyPayload?.definition_revision && hasBodyDefinitionData(bodyPayload)) {
    params.known_body_definition_revision = bodyPayload.definition_revision;
  }
  if (
    basicPayload?.definition_revision &&
    hasBasicDefinitionData(basicPayload)
  ) {
    params.known_basic_definition_revision = basicPayload.definition_revision;
  }
  appendKnownPreview(
    params,
    primaryPreviewForBody(bodyPayload, basicPayload),
    'body_'
  );
  if (
    basicPayload?.preview_revision_alt ||
    basicPayload?.preview_signature_alt
  ) {
    appendKnownPreview(
      params,
      {
        preview_sources: basicPayload.preview_sources_alt,
        preview_asset_registry: basicPayload.preview_asset_registry_alt,
        preview_signature: basicPayload.preview_signature_alt,
        preview_revision: basicPayload.preview_revision_alt,
      },
      'body_alt_'
    );
  }
  for (const suffix of ['gender_alt', 'gender_alt_digitigrade'] as const) {
    const variant = getBasicPreviewVariant(basicPayload, suffix);
    if (variant?.preview_revision || variant?.preview_signature) {
      appendKnownPreview(params, variant, `body_${suffix}_`);
    }
  }
  return params;
};
