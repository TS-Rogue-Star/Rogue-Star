// ///////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Identity Tab //
// ///////////////////////////////////////////////////////////////////////////////////

import type { IdentityLocationGroup, IdentityLocationOption } from '../types';
import {
  buildIdentityLocationGroups,
  getIdentityLocationDisplayName,
  IDENTITY_MOBILE_LOCATION_GROUP,
} from './identity';
import { findIdentityStarMapNodeForLocation } from './identityStarMap';

export type IdentityLocationRegion = {
  name: string;
  groups: IdentityLocationGroup[];
  locationCount: number;
};

export const buildIdentityLocationRegions = (
  options: readonly IdentityLocationOption[],
  search = ''
): IdentityLocationRegion[] => {
  const normalizedSearch = search.trim().toLowerCase();
  const regionOptions = new Map<string, IdentityLocationOption[]>();

  for (const option of options) {
    const node = findIdentityStarMapNodeForLocation(option.name, options);
    if (!node?.region) {
      continue;
    }
    const regionName = node.region;
    const groupName = option.system || getIdentityLocationDisplayName(option);
    const terms = [
      regionName,
      groupName,
      option.name,
      option.display_name,
      option.description,
      option.system_description,
      node.label,
      node.sourceLabel,
      ...(node.aliases || []),
      ...(node.searchTerms || []),
      option.kind === 'flotilla' ? IDENTITY_MOBILE_LOCATION_GROUP : null,
    ];
    if (
      normalizedSearch &&
      !terms.some((term) => term?.toLowerCase().includes(normalizedSearch))
    ) {
      continue;
    }

    const locations = regionOptions.get(regionName) || [];
    locations.push(option);
    regionOptions.set(regionName, locations);
  }

  return Array.from(regionOptions, ([name, locations]) => ({
    name,
    groups: buildIdentityLocationGroups(locations)
      .flatMap((group) =>
        group.kind === 'mobile'
          ? group.locations.map((option): IdentityLocationGroup => ({
              id: `flotilla:${option.name}`,
              name: getIdentityLocationDisplayName(option),
              kind: 'mobile',
              description: option.description || null,
              locations: [option],
            }))
          : [group]
      )
      .sort((left, right) => left.name.localeCompare(right.name)),
    locationCount: locations.length,
  })).sort((left, right) => left.name.localeCompare(right.name));
};
