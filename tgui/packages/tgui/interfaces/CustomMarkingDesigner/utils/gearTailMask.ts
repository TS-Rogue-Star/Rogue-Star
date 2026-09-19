// /////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Expression //
// /////////////////////////////////////////////////////////////////////////////////

import {
  resolveIconAssetReference,
  type GearOverlayAsset,
  type IconAssetPayload,
  type IconAssetReference,
} from '../../../utils/character-preview';

const tailoredGearCache = new WeakMap<
  GearOverlayAsset,
  Map<IconAssetPayload | undefined, GearOverlayAsset>
>();

export const resolveGearAssetForTail = (
  entry: GearOverlayAsset | IconAssetPayload,
  clipMask?: IconAssetReference | null
): GearOverlayAsset | IconAssetPayload => {
  if (!('asset' in entry) || !entry.use_tail_mask) {
    return entry;
  }
  const mask = resolveIconAssetReference(clipMask || undefined);
  if (entry.mask_asset === mask || (!entry.mask_asset && !mask)) {
    return entry;
  }
  let cache = tailoredGearCache.get(entry);
  if (!cache) {
    cache = new Map();
    tailoredGearCache.set(entry, cache);
  }
  let resolved = cache.get(mask);
  if (!resolved) {
    resolved = { ...entry, mask_asset: mask };
    cache.set(mask, resolved);
  }
  return resolved;
};
