// //////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Loadout //
// //////////////////////////////////////////////////////////////////////////////

import type {
  CharacterPreviewWorkPriority,
  PreviewDirectionEntry,
  PreviewLayerEntry,
  PreviewLayerGroup,
} from '../../../utils/character-preview';
import type { EquipmentGearRecipes } from '../types';
import type { BasicTilePreviewEntry } from '../BasicAppearanceTab';
import { splitPreviewOverlayLayers } from './previewLayers';

export type LoadoutGalleryRenderer = (
  recipes: EquipmentGearRecipes,
  onUpdated: () => void,
  priority: CharacterPreviewWorkPriority
) => PreviewDirectionEntry[];
let nextPreparedBase = 0;

export const prepareLoadoutGalleryPreview = (
  preview: PreviewDirectionEntry[],
  renderAppearance: LoadoutGalleryRenderer,
  applyMarkings: (preview: PreviewDirectionEntry[]) => PreviewDirectionEntry[]
): ((
  ...args: Parameters<LoadoutGalleryRenderer>
) => BasicTilePreviewEntry[]) => {
  const namespace = `loadout-base-${++nextPreparedBase}`;
  const marker: PreviewLayerEntry = {
    type: 'overlay',
    key: 'loadout-overlay-insertion',
  };
  const bases = new Map(
    applyMarkings(
      preview.map((entry) => {
        const { before, after } = splitPreviewOverlayLayers(entry.layers || []);
        return { ...entry, layers: [...before, marker, ...after] };
      })
    ).map((entry) => [entry.dir, entry])
  );
  const identities = new WeakMap<PreviewLayerEntry, number>();
  let nextIdentity = 0;
  const identity = (layer: PreviewLayerEntry) => {
    let id = identities.get(layer);
    if (id === undefined) {
      id = ++nextIdentity;
      identities.set(layer, id);
    }
    return id;
  };
  return (recipes, onUpdated, priority) =>
    renderAppearance(recipes, onUpdated, priority).map((appearance) => {
      const base = bases.get(appearance.dir) || appearance;
      const overlays = splitPreviewOverlayLayers(
        appearance.layers || []
      ).overlay;
      const layers = (base.layers || []).flatMap((layer) =>
        layer.key === marker.key ? overlays : [layer]
      );
      const layerGroups: PreviewLayerGroup[] = [];
      let common: PreviewLayerEntry[] = [];
      const flush = () => {
        if (!common.length) {
          return;
        }
        const signature = `${namespace}|${base.dir}|${common.map(identity).join(',')}`;
        layerGroups.push({
          key: signature,
          layers: common,
          sharedRasterSignature: signature,
        });
        common = [];
      };
      for (const layer of layers) {
        if (layer.source === 'loadout') {
          flush();
          layerGroups.push({ key: layer.key, layers: [layer] });
        } else {
          common.push(layer);
        }
      }
      flush();
      return { ...base, layers, layerGroups };
    });
};
