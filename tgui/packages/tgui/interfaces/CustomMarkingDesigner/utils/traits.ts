// //////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star August 2026: Character Designer - Traits Tab //
// //////////////////////////////////////////////////////////////////////////////

import type {
  CharacterTraitEntry,
  LanguagesDraftState,
  TraitPreferenceValue,
  TraitsDraftState,
  TraitsPayload,
  TraitsSaveResult,
  TraitsSavePayload,
} from '../types';

const hasOwn = (value: object, key: string) =>
  Object.prototype.hasOwnProperty.call(value, key);

export const sortTraitsByConfiguredOrder = <T extends { id: string }>(
  traits: readonly T[],
  configuredOrder?: readonly string[]
): T[] => {
  if (!configuredOrder?.length) {
    return [...traits];
  }

  const configuredIndexes = new Map<string, number>();
  configuredOrder.forEach((traitId, index) => {
    configuredIndexes.set(traitId, index);
  });

  return traits
    .map((trait, sourceIndex) => ({ trait, sourceIndex }))
    .sort((left, right) => {
      const leftIndex = configuredIndexes.get(left.trait.id);
      const rightIndex = configuredIndexes.get(right.trait.id);
      if (leftIndex !== undefined || rightIndex !== undefined) {
        return (leftIndex ?? Infinity) - (rightIndex ?? Infinity);
      }
      return left.sourceIndex - right.sourceIndex;
    })
    .map(({ trait }) => trait);
};

export const sortLanguagesAlphabetically = <
  T extends { id: string; name: string },
>(
  languages: readonly T[]
): T[] =>
  [...languages].sort(
    (left, right) =>
      left.name.localeCompare(right.name, undefined, { sensitivity: 'base' }) ||
      left.id.localeCompare(right.id, undefined, { sensitivity: 'base' })
  );

export const buildTraitsDraftState = (
  payload: TraitsPayload
): TraitsDraftState => {
  const traitOrder: string[] = [];
  const selected: Record<string, boolean> = {};
  const preferences: Record<string, Record<string, TraitPreferenceValue>> = {};

  for (const category of payload.categories) {
    for (const trait of category.traits) {
      traitOrder.push(trait.id);
      selected[trait.id] = !!trait.selected;
      preferences[trait.id] = {};
      for (const preference of trait.preferences || []) {
        preferences[trait.id][preference.id] =
          preference.kind === 'boolean'
            ? !!preference.value
            : (preference.value ?? null);
      }
    }
  }

  const languagePayload = payload.languages;
  const optionalLanguages =
    languagePayload?.entries.filter(
      (language) =>
        !language.automatic && (language.selectable || language.selected)
    ) || [];
  const selectedOptional: Record<string, boolean> = {};
  const customKeys: Record<string, string> = {};
  for (const language of optionalLanguages) {
    selectedOptional[language.id] = !!language.selected;
  }
  for (const language of languagePayload?.entries || []) {
    if (language.custom_key) {
      customKeys[language.id] = language.custom_key;
    }
  }
  const languages: LanguagesDraftState | null = languagePayload
    ? {
        optional_order: optionalLanguages.map((language) => language.id),
        selected_optional: selectedOptional,
        preferred_language: languagePayload.preferred_language,
        custom_keys: customKeys,
        language_prefixes: [...languagePayload.language_prefixes],
      }
    : null;

  return {
    revision: payload.revision,
    trait_order: traitOrder,
    selected,
    preferences,
    languages,
  };
};

export const buildTraitsSavePayload = (
  draft: TraitsDraftState
): TraitsSavePayload => {
  const selectedTraits = draft.trait_order.filter(
    (traitId) => !!draft.selected[traitId]
  );
  const traitPreferences: Record<
    string,
    Record<string, TraitPreferenceValue>
  > = {};

  for (const traitId of selectedTraits) {
    traitPreferences[traitId] = {
      ...(draft.preferences[traitId] || {}),
    };
  }

  const languages = draft.languages
    ? {
        alternate_languages: draft.languages.optional_order.filter(
          (languageId) => !!draft.languages?.selected_optional[languageId]
        ),
        preferred_language: draft.languages.preferred_language,
        custom_keys: { ...draft.languages.custom_keys },
        language_prefixes: [...draft.languages.language_prefixes],
      }
    : undefined;

  return {
    revision: draft.revision,
    selected_traits: selectedTraits,
    trait_preferences: traitPreferences,
    ...(languages ? { languages } : {}),
  };
};

const buildTraitOnlySavePayload = (draft: TraitsDraftState) => {
  const { languages: _languages, ...payload } = buildTraitsSavePayload(draft);
  return payload;
};

export const traitDraftSelectionsEqual = (
  left: TraitsDraftState,
  right: TraitsDraftState
) =>
  JSON.stringify(buildTraitOnlySavePayload(left)) ===
  JSON.stringify(buildTraitOnlySavePayload(right));

export const traitsDraftStatesEqual = (
  left: TraitsDraftState,
  right: TraitsDraftState
) => {
  const leftPayload = buildTraitsSavePayload(left);
  const rightPayload = buildTraitsSavePayload(right);
  return (
    JSON.stringify(leftPayload.selected_traits) ===
      JSON.stringify(rightPayload.selected_traits) &&
    JSON.stringify(leftPayload.trait_preferences) ===
      JSON.stringify(rightPayload.trait_preferences) &&
    JSON.stringify(leftPayload.languages) ===
      JSON.stringify(rightPayload.languages)
  );
};

const findTraitById = (payload: TraitsPayload, traitId: string) => {
  for (const category of payload.categories) {
    const trait = category.traits.find((entry) => entry.id === traitId);
    if (trait) {
      return trait;
    }
  }
  return null;
};

export const resolveOptionalLanguageLimit = (
  payload: TraitsPayload,
  draft: TraitsDraftState
) => {
  let extraSlots = 0;
  for (const traitId of draft.trait_order) {
    if (!draft.selected[traitId]) {
      continue;
    }
    const modifier = findTraitById(payload, traitId)?.extra_language_slots;
    if (typeof modifier === 'number' && Number.isFinite(modifier)) {
      extraSlots = modifier;
    }
  }
  return Math.max(
    0,
    (payload.languages?.base_optional_slots || 0) + extraSlots
  );
};

export const resolveSelectedOptionalLanguageCount = (draft: TraitsDraftState) =>
  draft.languages?.optional_order.filter(
    (languageId) => !!draft.languages?.selected_optional[languageId]
  ).length || 0;

const applyLanguagesDraftToPayload = (
  payload: TraitsPayload,
  draft: TraitsDraftState
) => {
  if (!payload.languages || !draft.languages) {
    return payload.languages;
  }
  const optionalLimit = resolveOptionalLanguageLimit(payload, draft);
  const selectedOptionalCount = resolveSelectedOptionalLanguageCount(draft);
  const entries = payload.languages.entries.map((language) => {
    const selected = language.automatic
      ? true
      : !!draft.languages?.selected_optional[language.id];
    const preferredEligible =
      !!language.preferred_always || (!language.automatic && selected);
    const disabledReason =
      !selected && language.selectable && selectedOptionalCount >= optionalLimit
        ? 'All optional language slots are currently in use.'
        : language.disabled_reason;
    return {
      ...language,
      selected,
      preferred_eligible: preferredEligible,
      preferred: draft.languages?.preferred_language === language.id,
      custom_key: draft.languages?.custom_keys[language.id] || null,
      disabled_reason: selected ? language.disabled_reason : disabledReason,
    };
  });
  return {
    ...payload.languages,
    optional_limit: optionalLimit,
    selected_optional_count: selectedOptionalCount,
    preferred_language: draft.languages.preferred_language,
    language_prefixes: [...draft.languages.language_prefixes],
    entries,
  };
};

export const resolveLanguagesDraftValidationError = (
  payload: TraitsPayload,
  draft: TraitsDraftState
): string | null => {
  if (!payload.languages || !draft.languages) {
    return null;
  }
  const selectedCount = resolveSelectedOptionalLanguageCount(draft);
  const limit = resolveOptionalLanguageLimit(payload, draft);
  if (selectedCount > limit) {
    return `Remove ${selectedCount - limit} optional ${
      selectedCount - limit === 1 ? 'language' : 'languages'
    } before saving (${selectedCount}/${limit} selected).`;
  }
  const draftedLanguages = applyLanguagesDraftToPayload(payload, draft);
  const unavailableSelected = draftedLanguages?.entries.find(
    (language) =>
      language.selected && !language.automatic && !language.selectable
  );
  if (unavailableSelected) {
    return `${unavailableSelected.name} is no longer available. Remove it before saving.`;
  }
  const assignedKeys = new Set<string>();
  for (const customKey of Object.values(draft.languages.custom_keys)) {
    if (!/^[A-Za-z0-9]$/.test(customKey)) {
      return 'Every custom language key must be one letter or number.';
    }
    if (assignedKeys.has(customKey)) {
      return `The custom language key “${customKey}” is assigned more than once.`;
    }
    assignedKeys.add(customKey);
  }
  if (
    !draft.languages.language_prefixes.length ||
    draft.languages.language_prefixes.length > 3 ||
    draft.languages.language_prefixes.some(
      (prefix) =>
        prefix.length !== 1 ||
        /[A-Za-z0-9]/.test(prefix) ||
        [';', ':', '.', '!', '*', '^', '-'].includes(prefix)
    )
  ) {
    return 'Language prefixes must be one to three allowed special characters.';
  }
  const preferredEntry = draftedLanguages?.entries.find(
    (language) => language.id === draft.languages?.preferred_language
  );
  if (!preferredEntry?.preferred_eligible) {
    return 'Choose an available preferred language before saving.';
  }
  return null;
};

export const updateLanguageDraftSelection = (
  draft: TraitsDraftState,
  languageId: string,
  selected: boolean,
  preferredFallback: string
): TraitsDraftState => {
  if (!draft.languages) {
    return draft;
  }
  const optionalOrder =
    selected && !draft.languages.selected_optional[languageId]
      ? [
          ...draft.languages.optional_order.filter((id) => id !== languageId),
          languageId,
        ]
      : draft.languages.optional_order;
  const customKeys = { ...draft.languages.custom_keys };
  if (!selected) {
    delete customKeys[languageId];
  }
  return {
    ...draft,
    languages: {
      ...draft.languages,
      optional_order: optionalOrder,
      selected_optional: {
        ...draft.languages.selected_optional,
        [languageId]: selected,
      },
      preferred_language:
        !selected && draft.languages.preferred_language === languageId
          ? preferredFallback
          : draft.languages.preferred_language,
      custom_keys: customKeys,
    },
  };
};

export const updateLanguageDraftPreferred = (
  draft: TraitsDraftState,
  languageId: string
): TraitsDraftState =>
  draft.languages
    ? {
        ...draft,
        languages: {
          ...draft.languages,
          preferred_language: languageId,
        },
      }
    : draft;

export const updateLanguageDraftCustomKey = (
  draft: TraitsDraftState,
  languageId: string,
  customKey: string
): TraitsDraftState => {
  if (!draft.languages) {
    return draft;
  }
  const customKeys = { ...draft.languages.custom_keys };
  if (customKey) {
    customKeys[languageId] = customKey;
  } else {
    delete customKeys[languageId];
  }
  return {
    ...draft,
    languages: {
      ...draft.languages,
      custom_keys: customKeys,
    },
  };
};

export const updateLanguageDraftPrefixes = (
  draft: TraitsDraftState,
  prefixes: string[]
): TraitsDraftState =>
  draft.languages
    ? {
        ...draft,
        languages: {
          ...draft.languages,
          language_prefixes: [...prefixes],
        },
      }
    : draft;

export const resolveTraitsSaveAcknowledgement = (
  pendingRequestId: string | null,
  result: TraitsSaveResult | null,
  payload: TraitsPayload | null
): boolean | null => {
  if (!pendingRequestId || result?.request_id !== pendingRequestId) {
    return null;
  }
  if (!result.accepted) {
    return false;
  }
  if (!payload || payload.revision < result.traits_revision) {
    return null;
  }
  return true;
};

export const updateTraitsDraftSelection = (
  draft: TraitsDraftState,
  traitId: string,
  selected: boolean
): TraitsDraftState => {
  const traitOrder =
    selected && !draft.selected[traitId]
      ? [...draft.trait_order.filter((id) => id !== traitId), traitId]
      : draft.trait_order;
  return {
    ...draft,
    trait_order: traitOrder,
    selected: {
      ...draft.selected,
      [traitId]: selected,
    },
  };
};

export const updateTraitsDraftPreference = (
  draft: TraitsDraftState,
  traitId: string,
  preferenceId: string,
  value: TraitPreferenceValue
): TraitsDraftState => ({
  ...draft,
  preferences: {
    ...draft.preferences,
    [traitId]: {
      ...(draft.preferences[traitId] || {}),
      [preferenceId]: value,
    },
  },
});

const resolveDraftPreferenceValue = (
  draft: TraitsDraftState,
  trait: CharacterTraitEntry,
  preferenceId: string,
  fallback: TraitPreferenceValue | undefined
) => {
  const traitPreferences = draft.preferences[trait.id];
  if (traitPreferences && hasOwn(traitPreferences, preferenceId)) {
    return traitPreferences[preferenceId];
  }
  return fallback;
};

export const applyTraitsDraftToPayload = (
  payload: TraitsPayload,
  draft: TraitsDraftState
): TraitsPayload => {
  const selectedIds = new Set(
    draft.trait_order.filter((traitId) => !!draft.selected[traitId])
  );
  const traitById = new Map<string, CharacterTraitEntry>();
  const categoryByTraitId = new Map<string, string>();
  for (const category of payload.categories) {
    for (const trait of category.traits) {
      traitById.set(trait.id, trait);
      categoryByTraitId.set(trait.id, category.id);
    }
  }

  const limitedTraitsSelected = Array.from(selectedIds).filter(
    (traitId) => categoryByTraitId.get(traitId) === 'positive'
  ).length;
  const neutralTraitsSelected = Array.from(selectedIds).filter(
    (traitId) => categoryByTraitId.get(traitId) === 'neutral'
  ).length;
  const traitsRemaining = payload.max_traits - limitedTraitsSelected;

  const categories = payload.categories.map((category) => {
    const traits = category.traits.map((trait) => {
      const selected = selectedIds.has(trait.id);
      const conflictingTraitId = (trait.conflicts || []).find((traitId) =>
        selectedIds.has(traitId)
      );
      const conflictingTrait = conflictingTraitId
        ? traitById.get(conflictingTraitId)
        : null;
      const dynamicDisabledReason = conflictingTrait
        ? `Conflicts with ${conflictingTrait.name}.`
        : category.id === 'positive' && traitsRemaining <= 0
          ? 'All positive trait slots are currently in use.'
          : null;
      const disabledReason = selected
        ? null
        : trait.disabled_reason || dynamicDisabledReason;
      const preferences = trait.preferences?.map((preference) => ({
        ...preference,
        value: resolveDraftPreferenceValue(
          draft,
          trait,
          preference.id,
          preference.value
        ),
      }));

      return {
        ...trait,
        selected,
        disabled_reason: disabledReason,
        warning_reason: selected ? trait.warning_reason : null,
        preferences,
      };
    });

    return {
      ...category,
      selected_count: traits.filter((trait) => trait.selected).length,
      traits,
    };
  });

  return {
    ...payload,
    limited_traits_selected: limitedTraitsSelected,
    traits_remaining: traitsRemaining,
    neutral_traits_selected: neutralTraitsSelected,
    total_selected: selectedIds.size,
    languages: applyLanguagesDraftToPayload(payload, draft),
    categories,
  };
};

export const resolveTraitsPreviewScale = (
  payload: TraitsPayload,
  draft: TraitsDraftState
) => {
  const traitById = new Map<string, CharacterTraitEntry>();
  for (const category of payload.categories) {
    for (const trait of category.traits) {
      traitById.set(trait.id, trait);
    }
  }

  let iconScaleX = 1;
  let iconScaleY = 1;
  for (const traitId of draft.trait_order) {
    if (!draft.selected[traitId]) {
      continue;
    }
    const trait = traitById.get(traitId);
    if (
      typeof trait?.icon_scale_x === 'number' &&
      Number.isFinite(trait.icon_scale_x) &&
      trait.icon_scale_x > 0
    ) {
      iconScaleX = trait.icon_scale_x;
    }
    if (
      typeof trait?.icon_scale_y === 'number' &&
      Number.isFinite(trait.icon_scale_y) &&
      trait.icon_scale_y > 0
    ) {
      iconScaleY = trait.icon_scale_y;
    }
  }

  return { iconScaleX, iconScaleY };
};
