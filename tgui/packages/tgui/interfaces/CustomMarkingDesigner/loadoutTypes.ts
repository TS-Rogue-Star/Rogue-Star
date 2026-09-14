// //////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Loadout //
// //////////////////////////////////////////////////////////////////////////////

import type { BooleanLike } from '../../../common/react';
import type {
  GearOverlayAssetReference,
  IconAssetReference,
} from '../../utils/character-preview';
import type {
  EquipmentDirectionalRecipes,
  EquipmentGearRecipes,
} from './types';

export type LoadoutValue = string | number | null | (string | number | null)[];
export type LoadoutOption = { value: string | number; label: string };
export type LoadoutTweak = {
  id: string;
  label: string;
  kind: 'text' | 'color' | 'matrix' | 'choice' | 'choices' | 'path';
  default: LoadoutValue;
  options?: LoadoutOption[];
  fields?: { label: string; options: LoadoutOption[] }[];
  multiline?: BooleanLike;
  placeholder_key?: 'default_name' | 'default_description';
  max_length?: number;
  disabled?: BooleanLike;
};
export type LoadoutVariant = {
  id: string;
  name: string;
  default_name?: string;
  default_description?: string;
  icon?: IconAssetReference | null;
  recipes: EquipmentDirectionalRecipes;
  equippable: BooleanLike;
  worn: BooleanLike;
  color?: string | number[] | null;
  base_overlays?: GearOverlayAssetReference[];
  accessory_slot?: number;
  valid_accessory_slots?: number;
  restricted_accessory_slots?: number;
  preview_pending?: BooleanLike;
};
export type LoadoutGear = {
  id: string;
  name: string;
  category: string;
  description: string;
  cost: number;
  available: BooleanLike;
  permitted: BooleanLike;
  slot: string;
  stackable: BooleanLike;
  requires_uniform: BooleanLike;
  tweaks: LoadoutTweak[];
  variant_tweak?: string | null;
  variants: LoadoutVariant[];
};
export type LoadoutItem = { id: string; tweaks: Record<string, LoadoutValue> };
export type LoadoutDraft = {
  revision: string;
  active: number;
  slots: Record<string, LoadoutItem[]>;
};
export type LoadoutCatalog = {
  items: LoadoutGear[];
  slot_count: number;
  max_cost: number;
  gear: EquipmentGearRecipes;
  hide_shoes: BooleanLike;
  silicon_job: BooleanLike;
};
export type LoadoutPayload = {
  request_id: string;
  context_signature?: string;
  recipe_signature?: string;
  values?: LoadoutDraft;
  catalog?: LoadoutCatalog;
  error?: string;
};
export type LoadoutPreviewBatch = {
  request_id: string;
  recipe_signature: string;
  sequence: number;
  previews: { gear_id: string; variant: LoadoutVariant }[];
  complete: BooleanLike;
  error?: string;
};
export type LoadoutSaveResult = {
  request_id: string;
  accepted: BooleanLike;
  values?: LoadoutDraft;
  gear?: EquipmentGearRecipes;
  error?: string;
};
