// //////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star August 2026: Character Designer - Traits Tab //
// //////////////////////////////////////////////////////////////////////////////

import type {
  CharacterTraitEntry,
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

  return {
    revision: payload.revision,
    trait_order: traitOrder,
    selected,
    preferences,
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

  return {
    revision: draft.revision,
    selected_traits: selectedTraits,
    trait_preferences: traitPreferences,
  };
};

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
      JSON.stringify(rightPayload.trait_preferences)
  );
};

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
