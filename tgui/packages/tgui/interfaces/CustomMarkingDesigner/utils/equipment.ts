// ////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Equipment //
// ////////////////////////////////////////////////////////////////////////////////

import { normalizeHex } from '../../../utils/color';
import type { GearOverlayAssetReference } from '../../../utils/character-preview';
import type {
  EquipmentCategory,
  EquipmentCatalog,
  EquipmentCatalogEntry,
  EquipmentDraftState,
  EquipmentDirectionalRecipes,
  EquipmentGearOptions,
  EquipmentGearRecipes,
} from '../types';

export const EQUIPMENT_CATEGORIES: ReadonlyArray<{
  id: EquipmentCategory;
  label: string;
}> = [
  { id: 'Underwear, top', label: 'Underwear Top' },
  { id: 'Underwear, bottom', label: 'Underwear Bottom' },
  { id: 'Socks', label: 'Socks' },
  { id: 'Undershirt', label: 'Undershirt' },
  { id: 'backpack', label: 'Backpack' },
  { id: 'pda', label: 'PDA' },
];

export const cloneEquipmentDraft = (
  draft: EquipmentDraftState
): EquipmentDraftState => ({
  ...draft,
  underwear: { ...draft.underwear },
  colors: Object.fromEntries(
    Object.entries(draft.colors).map(([category, color]) => [
      category,
      normalizeHex(color) || color,
    ])
  ),
  communicator_visibility: !!draft.communicator_visibility,
  shoe_hater: !!draft.shoe_hater,
});

export const equipmentDraftsEqual = (
  left: EquipmentDraftState | null,
  right: EquipmentDraftState | null
) =>
  !!left &&
  !!right &&
  left.backbag === right.backbag &&
  left.pdachoice === right.pdachoice &&
  left.communicator_visibility === right.communicator_visibility &&
  left.shoe_hater === right.shoe_hater &&
  EQUIPMENT_CATEGORIES.slice(0, 4).every(
    ({ id }) =>
      left.underwear[id] === right.underwear[id] &&
      normalizeHex(left.colors[id]) === normalizeHex(right.colors[id])
  );

export const selectedEquipmentId = (
  draft: EquipmentDraftState,
  category: EquipmentCategory
) => {
  if (category === 'backpack') {
    return String(draft.backbag);
  }
  if (category === 'pda') {
    return String(draft.pdachoice);
  }
  return draft.underwear[category] || 'None';
};

const tintEquipmentEntry = (
  entry: EquipmentCatalogEntry,
  dir: number,
  color: string | undefined
): GearOverlayAssetReference[] =>
  (entry.recipes?.[dir] || []).map((recipe) =>
    entry.colorable && color
      ? { ...recipe, colors: [...(recipe.colors || []), color] }
      : recipe
  );

const combineUnderwear = (entries: GearOverlayAssetReference[]) => {
  if (!entries.length) {
    return [];
  }
  const [base, ...rest] = entries;
  return [{ ...base, overlays: [...(base.overlays || []), ...rest] }];
};

const applyShoePreference = (
  recipes: EquipmentDirectionalRecipes | undefined,
  hideShoes: boolean
): EquipmentDirectionalRecipes => {
  if (!recipes) {
    return {};
  }
  if (!hideShoes) {
    return recipes;
  }
  return Object.fromEntries(
    Object.entries(recipes).map(([dir, overlays]) => [
      dir,
      overlays.filter((overlay) => overlay.slot !== 'shoes'),
    ])
  );
};

export const buildEquipmentRecipes = (
  catalog: EquipmentCatalog,
  draft: EquipmentDraftState,
  gearOptions: EquipmentGearOptions | null,
  candidate?: { category: EquipmentCategory; entry: EquipmentCatalogEntry }
): EquipmentGearRecipes => {
  const equipment: EquipmentGearRecipes['equipment'] = {};
  for (const dir of [1, 2, 4, 8]) {
    if (candidate) {
      const jobBag =
        candidate.category === 'backpack'
          ? gearOptions?.job_by_backbag[candidate.entry.id]?.[dir]?.filter(
              (recipe) => recipe.slot === 'back'
            )
          : undefined;
      equipment[dir] = jobBag?.length
        ? jobBag
        : tintEquipmentEntry(
            candidate.entry,
            dir,
            draft.colors[candidate.category]
          );
      continue;
    }
    const underwear: GearOverlayAssetReference[] = [];
    for (const { id } of EQUIPMENT_CATEGORIES.slice(0, 4)) {
      const entry = catalog[id]?.find(
        (item) => item.id === selectedEquipmentId(draft, id)
      );
      if (entry) {
        underwear.push(...tintEquipmentEntry(entry, dir, draft.colors[id]));
      }
    }
    const bag = catalog.backpack?.find(
      (item) => item.id === String(draft.backbag)
    );
    equipment[dir] = [
      ...combineUnderwear(underwear),
      ...(bag?.recipes?.[dir] || []),
    ];
  }
  return {
    equipment,
    job: candidate
      ? {}
      : applyShoePreference(
          gearOptions?.job_by_backbag[draft.backbag],
          draft.shoe_hater
        ),
    loadout: candidate
      ? {}
      : applyShoePreference(
          gearOptions?.loadout_by_pda[draft.pdachoice],
          draft.shoe_hater
        ),
  };
};
