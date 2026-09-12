// //////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Loadout //
// //////////////////////////////////////////////////////////////////////////////

import { applyGearColorMatrix } from '../../../utils/character-preview/assets';
import {
  resolveIconAssetReference,
  type GearOverlayAssetReference,
  type IconAssetPayload,
} from '../../../utils/character-preview';
import type {
  LoadoutCatalog,
  LoadoutDraft,
  LoadoutGear,
  LoadoutItem,
  LoadoutTweak,
  LoadoutValue,
  LoadoutVariant,
} from '../loadoutTypes';
import type { EquipmentGearRecipes } from '../types';

export const loadoutVariantAssets = (
  variant: LoadoutVariant,
  worn: boolean
) => {
  const assets: IconAssetPayload[] = [];
  const add = (reference) => {
    const asset = resolveIconAssetReference(reference);
    if (asset) {
      assets.push(asset);
    }
  };
  const visit = (recipe) => {
    add(recipe.asset);
    add(recipe.mask_asset);
    recipe.overlays?.forEach(visit);
  };
  if (worn && variant.worn) {
    Object.values(variant.recipes).forEach((recipes) => recipes.forEach(visit));
  } else {
    add(variant.icon);
    variant.base_overlays?.forEach(visit);
  }
  return assets;
};

export const cloneLoadout = (draft: LoadoutDraft): LoadoutDraft =>
  JSON.parse(JSON.stringify(draft));

export const loadoutsEqual = (a: LoadoutDraft | null, b: LoadoutDraft | null) =>
  !!a &&
  !!b &&
  a.active === b.active &&
  JSON.stringify(a.slots) === JSON.stringify(b.slots);

export const loadoutCost = (items: LoadoutItem[], catalog: LoadoutCatalog) =>
  items.reduce(
    (sum, item) =>
      sum + (catalog.items.find((gear) => gear.id === item.id)?.cost || 0),
    0
  );

export const tweakValue = (
  item: LoadoutItem,
  tweak: LoadoutTweak
): LoadoutValue =>
  Object.prototype.hasOwnProperty.call(item.tweaks, tweak.id)
    ? item.tweaks[tweak.id]
    : tweak.default;

export const selectedVariant = (gear: LoadoutGear, item?: LoadoutItem) =>
  gear.variants.find(
    (variant) =>
      variant.id ===
      (gear.variant_tweak && item
        ? (item.tweaks[gear.variant_tweak] ??
          gear.tweaks.find((t) => t.id === gear.variant_tweak)?.default)
        : '')
  ) || gear.variants[0];

export const loadoutTileId = (gear: LoadoutGear, variant: LoadoutVariant) =>
  JSON.stringify([gear.id, variant.id]);

export const toggleLoadoutItem = (
  draft: LoadoutDraft,
  catalog: LoadoutCatalog,
  gear: LoadoutGear,
  variant: LoadoutVariant
): LoadoutDraft => {
  const next = cloneLoadout(draft);
  const items = next.slots[next.active] || (next.slots[next.active] = []);
  const index = items.findIndex((item) => item.id === gear.id);
  if (index >= 0 && selectedVariant(gear, items[index])?.id === variant.id) {
    items.splice(index, 1);
  } else if (index >= 0 && gear.variant_tweak) {
    items[index].tweaks[gear.variant_tweak] = variant.id;
  } else if (
    gear.available &&
    loadoutCost(items, catalog) + gear.cost <= catalog.max_cost
  ) {
    const item: LoadoutItem = {
      id: gear.id,
      tweaks: Object.fromEntries(
        gear.tweaks.map((tweak) => [tweak.id, tweak.default])
      ),
    };
    if (gear.variant_tweak) {
      item.tweaks[gear.variant_tweak] = variant.id;
    }
    items.push(item);
  }
  return next;
};

export const LOADOUT_IDENTITY_MATRIX = [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0];

export const loadoutMatrixError = (value: LoadoutValue): string | null => {
  if (value === null || (Array.isArray(value) && !value.length)) {
    return null;
  }
  if (
    !Array.isArray(value) ||
    ![9, 12, 16, 20].includes(value.length) ||
    !value.every(
      (v) => typeof v === 'number' && Number.isFinite(v) && v >= -10 && v <= 10
    )
  ) {
    return 'Enter a valid color matrix.';
  }
  const colors = [
    [255, 0, 0, 255],
    [0, 255, 0, 255],
    [0, 0, 255, 255],
    [255, 255, 255, 255],
  ];
  const passed = colors.filter((color) => {
    const transformed = applyGearColorMatrix(
      color as [number, number, number, number],
      value as number[]
    );
    return Math.max(...transformed.slice(0, 3)) >= 75;
  }).length;
  return passed >= 2
    ? null
    : 'Matrix is too dark. At least two test colors must reach lightness 75.';
};

export const loadoutValidationError = (
  draft: LoadoutDraft,
  catalog: LoadoutCatalog,
  saved: LoadoutDraft
) => {
  for (const [slot, items] of Object.entries(draft.slots)) {
    if (loadoutCost(items, catalog) > catalog.max_cost) {
      return `Preset ${slot} exceeds the point limit.`;
    }
    for (const item of items) {
      const gear = catalog.items.find((entry) => entry.id === item.id);
      if (!gear?.available) {
        return `Remove unavailable item ${item.id} from preset ${slot}.`;
      }
      const savedItem = saved.slots[slot]?.find(
        (entry) => entry.id === item.id
      );
      for (const tweak of gear.tweaks) {
        if (tweak.kind === 'matrix') {
          const value = tweakValue(item, tweak);
          const oldValue = savedItem
            ? tweakValue(savedItem, tweak)
            : tweak.default;
          if (JSON.stringify(value) === JSON.stringify(oldValue)) {
            continue;
          }
          const error = loadoutMatrixError(value);
          if (error) {
            return `${gear.name}: ${error}`;
          }
        }
      }
    }
  }
  return null;
};

export const tintLoadoutRecipes = (
  recipes: GearOverlayAssetReference[],
  gear: LoadoutGear,
  item?: LoadoutItem,
  baseColor?: string | number[] | null
): GearOverlayAssetReference[] => {
  const colors: (string | number[])[] = [];
  for (const tweak of gear.tweaks) {
    const value = item ? tweakValue(item, tweak) : tweak.default;
    if (
      tweak.kind === 'color' &&
      typeof value === 'string' &&
      value !== '#ffffff'
    ) {
      colors.splice(0, colors.length, value);
    } else if (
      tweak.kind === 'matrix' &&
      Array.isArray(value) &&
      value.length >= 12
    ) {
      colors.splice(0, colors.length, value as number[]);
    }
  }
  if (!colors.length && baseColor) {
    colors.push(baseColor);
  }
  if (!colors.length) {
    return recipes;
  }
  const tint = (component) => ({
    ...component,
    colors:
      'loadout_tint' in component && !component.loadout_tint
        ? component.colors
        : [...(component.colors || []), ...colors],
    ...(component.overlays ? { overlays: component.overlays.map(tint) } : {}),
  });
  return recipes.map(tint);
};

export const buildLoadoutRecipes = (
  catalog: LoadoutCatalog,
  draft: LoadoutDraft,
  candidate?: { gear: LoadoutGear; variant: LoadoutVariant },
  showJob = true
): EquipmentGearRecipes => {
  const loadout: EquipmentGearRecipes['loadout'] = {};
  const items = draft.slots[draft.active] || [];
  for (const dir of [1, 2, 4, 8]) {
    const overlays: GearOverlayAssetReference[] = [];
    const occupied = new Set<string>();
    let hasUniform = false;
    const carriers: {
      valid: number;
      restricted: number;
      used: number;
      layer: number | undefined;
    }[] = [];
    for (const item of candidate
      ? [
          {
            id: candidate.gear.id,
            tweaks: items.find((i) => i.id === candidate.gear.id)?.tweaks || {},
          },
        ]
      : items) {
      const gear =
        candidate?.gear || catalog.items.find((g) => g.id === item.id);
      const variant =
        candidate?.variant || (gear && selectedVariant(gear, item));
      if (
        !gear ||
        !variant ||
        !variant.equippable ||
        (!candidate && (!gear.permitted || (showJob && catalog.silicon_job)))
      ) {
        continue;
      }
      if (
        !candidate &&
        ((occupied.has(gear.slot) && !gear.stackable) ||
          (gear.requires_uniform && !hasUniform))
      ) {
        continue;
      }
      let accessoryLayer: number | undefined;
      if (!candidate && gear.stackable && variant.accessory_slot) {
        const slot = variant.accessory_slot;
        const carrier = carriers.find(
          (entry) =>
            (entry.valid & slot) === slot &&
            !(entry.used & entry.restricted & slot)
        );
        if (!carrier) {
          continue;
        }
        carrier.used |= slot;
        accessoryLayer = carrier.layer;
      }
      const recipes = (variant.recipes[dir] || [])
        .filter((r) => candidate || !catalog.hide_shoes || r.slot !== 'shoes')
        .map((recipe) =>
          accessoryLayer !== undefined
            ? { ...recipe, slot: 'accessory', layer: accessoryLayer }
            : recipe
        );
      overlays.push(...tintLoadoutRecipes(recipes, gear, item, variant.color));
      occupied.add(gear.slot);
      if (variant.valid_accessory_slots) {
        carriers.push({
          valid: variant.valid_accessory_slots,
          restricted: variant.restricted_accessory_slots || 0,
          used: 0,
          layer: recipes[0]?.layer ?? undefined,
        });
      }
      hasUniform ||= recipes.some((recipe) => recipe.slot === 'uniform');
    }
    loadout[dir] = overlays;
  }
  return {
    equipment: candidate ? {} : catalog.gear.equipment,
    job: candidate ? {} : catalog.gear.job,
    loadout,
  };
};

export const buildLoadoutSave = (draft: LoadoutDraft, saved: LoadoutDraft) => ({
  revision: draft.revision,
  active: draft.active,
  slots: Object.fromEntries(
    Object.entries(draft.slots).filter(
      ([slot, items]) =>
        JSON.stringify(items) !== JSON.stringify(saved.slots[slot]) ||
        (Number(slot) === draft.active && draft.active !== saved.active)
    )
  ),
});
