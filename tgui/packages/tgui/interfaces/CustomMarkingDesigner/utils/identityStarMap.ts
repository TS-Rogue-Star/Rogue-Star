// ///////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Identity Tab //
// ///////////////////////////////////////////////////////////////////////////////////

import type { IdentityLocationGroup, IdentityLocationOption } from '../types';
import { IDENTITY_MOBILE_LOCATION_GROUP } from './identity';

export type IdentityStarMapLabelPlacement =
  | 'above'
  | 'below'
  | 'left'
  | 'right';

export type IdentityStarMapNode = {
  id: string;
  label: string;
  system: string;
  aliases?: readonly string[];
  searchTerms?: readonly string[];
  sourceLabel?: string;
  locationNames?: readonly string[];
  x: number;
  y: number;
  region: string;
  labelPlacement: IdentityStarMapLabelPlacement;
  description?: string;
};

export type IdentityStarMapRegion = {
  id: string;
  label: string;
  detail?: string;
  path: string;
  labelX: number;
  labelY: number;
  tone:
    | 'human'
    | 'skrell'
    | 'unathi'
    | 'salthan'
    | 'elysian'
    | 'frontier'
    | 'tajaran'
    | 'ares';
};

export type IdentityStarMapAreaLabel = {
  id: string;
  label: string;
  x: number;
  y: number;
};

export type IdentityStarMapPoint = Readonly<{
  x: number;
  y: number;
}>;

export type IdentityStarMapPolyline = readonly IdentityStarMapPoint[];

export const IDENTITY_STAR_MAP_REGIONS: readonly IdentityStarMapRegion[] = [
  {
    id: 'unathi-space',
    label: 'Unathi Space',
    path: 'M 0 0 H 34 L 32 6 H 27 L 25 11 H 2 L 0 6 Z',
    labelX: 12,
    labelY: 5,
    tone: 'unathi',
  },
  {
    id: 'salthan-fyrds',
    label: 'Salthan Fyrds',
    path: 'M 34 0 H 48 L 50 8 L 54 7 L 56.2 11.95 L 62 25 H 37 L 33 15 H 27 L 25 11 L 27 6 H 32 Z',
    labelX: 44,
    labelY: 16,
    tone: 'salthan',
  },
  {
    id: 'ares-confederation',
    label: 'Ares Confederation',
    path: 'M 48 0 H 74 L 71 12 H 62 L 56.2 11.95 L 54 7 L 50 8 Z',
    labelX: 63,
    labelY: 5,
    tone: 'ares',
  },
  {
    id: 'skrell-consensus',
    label: 'Skrell Consensus',
    path: 'M 0 6 L 2 11 H 25 L 27 15 H 33 L 37 25 L 34.5 30 L 37 37 L 28.3 54 H 9.4 L 7.7 60 H 5.5 L 2.3 48 H 0 Z',
    labelX: 10,
    labelY: 40,
    tone: 'skrell',
  },
  {
    id: 'commonwealth',
    label: 'Commonwealth of Sol-Procyon',
    path: 'M 37 25 H 62 L 67 36 H 70 L 72 41 H 74 L 77 46 L 78.4 48.1 L 73 65 L 69 76 H 54 L 51.1 67.2 H 33.5 L 28.3 54 L 37 37 L 34.5 30 Z',
    labelX: 51,
    labelY: 39,
    tone: 'human',
  },
  {
    id: 'coreward-periphery',
    label: 'Coreward Periphery',
    path: 'M 56.2 11.95 L 62 12 H 71 L 74 0 H 100 V 45 H 88 L 86 41 H 78 L 77 46 L 74 41 H 72 L 70 36 H 67 L 62 25 Z',
    labelX: 82,
    labelY: 18,
    tone: 'frontier',
  },
  {
    id: 'elysian-colonies',
    label: 'Elysian Colonies',
    path: 'M 7.7 60 L 9.4 54 H 28.3 L 33.5 67.2 L 37.4 77 L 29.4 93.3 H 9.5 L 7.4 86.3 L 9.7 78.6 L 5.7 69.1 Z',
    labelX: 18,
    labelY: 73,
    tone: 'elysian',
  },
  {
    id: 'rimward-periphery',
    label: 'Rimward Periphery',
    path: 'M 33.5 67.2 H 51.1 L 54 76 H 69 L 67.1 82.6 L 69 89.5 L 65 100 H 31.9 L 29.4 93.3 L 37.4 77 Z',
    labelX: 45,
    labelY: 90,
    tone: 'frontier',
  },
  {
    id: 'trail-spin',
    label: 'Trailing "Wilderness"',
    path: 'M 77 46 L 78 41 H 86 L 88 45 H 100 V 77.8 H 88 L 86.9 74.4 H 84.8 L 82.1 71 H 77.2 L 73 65 L 78.4 48.1 Z',
    labelX: 91,
    labelY: 58,
    tone: 'frontier',
  },
  {
    id: 'tajaran-diaspora',
    label: 'Tajaran Diaspora',
    path: 'M 69 76 L 73 65 L 77.2 71 H 82.1 L 84.8 74.4 H 86.9 L 88 77.8 L 84.6 89.5 H 69 L 67.1 82.6 Z',
    labelX: 79,
    labelY: 78,
    tone: 'tajaran',
  },
];

export const IDENTITY_STAR_MAP_AREA_LABELS: readonly IdentityStarMapAreaLabel[] =
  [
    {
      id: 'spinward-unknown',
      label: 'Spinward Unknown',
      x: 15,
      y: 96,
    },
    {
      id: 'orion-persean-unknown',
      label: 'Orion-Persean Unknown',
      x: 83,
      y: 96,
    },
  ];

export const IDENTITY_STAR_MAP_BOUNDARIES: readonly IdentityStarMapPolyline[] =
  [
    [
      { x: 34, y: 0 },
      { x: 32, y: 6 },
      { x: 27, y: 6 },
      { x: 25, y: 11 },
      { x: 2, y: 11 },
      { x: 0, y: 6 },
    ],
    [
      { x: 25, y: 11 },
      { x: 27, y: 15 },
    ],
    [
      { x: 27, y: 15 },
      { x: 33, y: 15 },
      { x: 37, y: 25 },
      { x: 62, y: 25 },
      { x: 56.2, y: 11.95 },
      { x: 54, y: 7 },
      { x: 50, y: 8 },
      { x: 48, y: 0 },
    ],
    [
      { x: 56.2, y: 11.95 },
      { x: 62, y: 12 },
      { x: 71, y: 12 },
      { x: 74, y: 0 },
    ],
    [
      { x: 0, y: 48 },
      { x: 2.3, y: 48 },
      { x: 5.5, y: 60 },
      { x: 7.7, y: 60 },
      { x: 9.4, y: 54 },
      { x: 28.3, y: 54 },
      { x: 37, y: 37 },
      { x: 34.5, y: 30 },
      { x: 37, y: 25 },
    ],
    [
      { x: 28.3, y: 54 },
      { x: 33.5, y: 67.2 },
      { x: 51.1, y: 67.2 },
      { x: 54, y: 76 },
      { x: 69, y: 76 },
      { x: 73, y: 65 },
      { x: 78.4, y: 48.1 },
      { x: 77, y: 46 },
      { x: 74, y: 41 },
      { x: 72, y: 41 },
      { x: 70, y: 36 },
      { x: 67, y: 36 },
      { x: 62, y: 25 },
    ],
    [
      { x: 77, y: 46 },
      { x: 78, y: 41 },
      { x: 86, y: 41 },
      { x: 88, y: 45 },
      { x: 100, y: 45 },
    ],
    [
      { x: 7.7, y: 60 },
      { x: 5.7, y: 69.1 },
      { x: 9.7, y: 78.6 },
      { x: 7.4, y: 86.3 },
      { x: 9.5, y: 93.3 },
      { x: 29.4, y: 93.3 },
      { x: 37.4, y: 77 },
      { x: 33.5, y: 67.2 },
    ],
    [
      { x: 29.4, y: 93.3 },
      { x: 31.9, y: 100 },
    ],
    [
      { x: 69, y: 76 },
      { x: 67.1, y: 82.6 },
      { x: 69, y: 89.5 },
      { x: 65, y: 100 },
    ],
    [
      { x: 73, y: 65 },
      { x: 77.2, y: 71 },
      { x: 82.1, y: 71 },
      { x: 84.8, y: 74.4 },
      { x: 86.9, y: 74.4 },
      { x: 88, y: 77.8 },
      { x: 100, y: 77.8 },
    ],
    [
      { x: 69, y: 89.5 },
      { x: 84.6, y: 89.5 },
      { x: 88, y: 77.8 },
    ],
  ];

export const IDENTITY_STAR_MAP_NODES: readonly IdentityStarMapNode[] = [
  {
    id: 'kelezakata',
    label: 'Kelezakata',
    system: 'Kelezakata',
    x: 22.8,
    y: 6.9,
    region: 'Unathi Space',
    labelPlacement: 'below',
  },
  {
    id: 'myria',
    label: 'Myria',
    system: 'Myria',
    sourceLabel: 'Salthan',
    searchTerms: ['Salthan', 'The Pact', 'Salthan Fyrds'],
    x: 35.1,
    y: 11.1,
    region: 'Salthan Fyrds',
    labelPlacement: 'right',
  },
  {
    id: 'virgo-erigone',
    label: 'Virgo-Erigone',
    system: 'Virgo-Erigone',
    aliases: ['Virgo', 'Alat-Hahr'],
    x: 91.2,
    y: 12.4,
    region: 'Coreward Periphery',
    labelPlacement: 'left',
  },
  {
    id: 'vilous',
    label: 'Vilous',
    system: 'Vilous',
    sourceLabel: 'Tal',
    searchTerms: ['Tal', 'Sergal', 'Nevrean'],
    x: 71.4,
    y: 24,
    region: 'Coreward Periphery',
    labelPlacement: 'right',
  },
  {
    id: 'qerr-vallis',
    label: "Qerr'Vallis",
    system: "Qerr'Vallis",
    aliases: ["Qerr'valis"],
    x: 22.3,
    y: 28.3,
    region: 'Skrell Consensus',
    labelPlacement: 'right',
  },
  {
    id: 'vazzend',
    label: 'Vazzend',
    system: 'Vazzend',
    x: 95.9,
    y: 41.2,
    region: 'Trailing "Wilderness"',
    labelPlacement: 'left',
  },
  {
    id: 'sol',
    label: 'Sol',
    system: 'Sol',
    x: 54.1,
    y: 50.1,
    region: 'Commonwealth of Sol-Procyon',
    labelPlacement: 'left',
  },
  {
    id: 'procyon',
    label: 'Procyon',
    system: 'Procyon',
    x: 57,
    y: 54.4,
    region: 'Commonwealth of Sol-Procyon',
    labelPlacement: 'right',
  },
  {
    id: 'sanctum',
    label: 'Sanctum',
    system: 'Sanctum',
    x: 26.4,
    y: 67.1,
    region: 'Elysian Colonies',
    labelPlacement: 'right',
  },
  {
    id: 'rarkajar',
    label: 'Rarkajar',
    system: 'Rarkajar',
    x: 78.6,
    y: 84.5,
    region: 'Tajaran Diaspora',
    labelPlacement: 'left',
  },
  {
    id: 'new-ohio',
    label: 'New Ohio',
    system: 'New Ohio',
    searchTerms: ['Sagittarius Heights', 'Skrell Consensus border', 'Toledo'],
    x: 37.6,
    y: 30.3,
    region: 'Commonwealth of Sol-Procyon',
    labelPlacement: 'right',
  },
  {
    id: 'alpha-centauri',
    label: 'Alpha Centauri',
    system: 'Alpha Centauri',
    searchTerms: ['Commonwealth Core'],
    x: 52,
    y: 46.5,
    region: 'Commonwealth of Sol-Procyon',
    labelPlacement: 'left',
  },
  {
    id: 'altair',
    label: 'Altair',
    system: 'Altair',
    searchTerms: ['Commonwealth Core'],
    x: 54.4,
    y: 58.1,
    region: 'Commonwealth of Sol-Procyon',
    labelPlacement: 'right',
  },
  {
    id: 'vir',
    label: 'Vir',
    system: 'Vir',
    searchTerms: ['Golden Crescent'],
    x: 34.7,
    y: 52.1,
    region: 'Commonwealth of Sol-Procyon',
    labelPlacement: 'left',
  },
  {
    id: 'nyx',
    label: 'Nyx',
    system: 'Nyx',
    searchTerms: ['Trailing Commonwealth frontier'],
    x: 75.5,
    y: 49.2,
    region: 'Commonwealth of Sol-Procyon',
    labelPlacement: 'left',
  },
  {
    id: 'tau-ceti',
    label: 'Tau Ceti',
    system: 'Tau Ceti',
    searchTerms: ['Commonwealth Core'],
    x: 55.8,
    y: 43.8,
    region: 'Commonwealth of Sol-Procyon',
    labelPlacement: 'right',
  },
  {
    id: 'epsilon-ursae-minoris',
    label: 'Epsilon Ursae Minoris',
    system: 'Epsilon Ursae Minoris',
    searchTerms: ['Outer Skrell space'],
    x: 11,
    y: 31,
    region: 'Skrell Consensus',
    labelPlacement: 'right',
  },
  {
    id: 'uueoa-esa',
    label: 'Uueoa-Esa',
    system: 'Uueoa-Esa',
    x: 13,
    y: 8,
    region: 'Unathi Space',
    labelPlacement: 'left',
  },
  {
    id: 'vengeful-father',
    label: 'Vengeful Father',
    system: 'Vengeful Father',
    searchTerms: ['Xohok', 'Zaddat'],
    x: 17,
    y: 2.5,
    region: 'Unathi Space',
    labelPlacement: 'right',
  },
  {
    id: 'antares',
    label: 'Antares',
    system: 'Antares',
    x: 83,
    y: 27,
    region: 'Coreward Periphery',
    labelPlacement: 'right',
  },
  {
    id: 'beta-carnelium-ventrum',
    label: 'Beta-Carnelium Ventrum',
    system: 'Beta-Carnelium Ventrum',
    searchTerms: ['Roanoke', 'Alraune'],
    x: 22,
    y: 81,
    region: 'Elysian Colonies',
    labelPlacement: 'below',
  },
  {
    id: 'barkalis',
    label: 'Barkalis',
    system: 'Barkalis',
    x: 30,
    y: 36,
    region: 'Skrell Consensus',
    labelPlacement: 'left',
  },
  {
    id: 'shelf-flotilla',
    label: 'Shelf',
    system: IDENTITY_MOBILE_LOCATION_GROUP,
    locationNames: ['Shelf Flotilla'],
    searchTerms: ['Commonwealth / Rimward frontier'],
    x: 58.6,
    y: 84,
    region: 'Rimward Periphery',
    labelPlacement: 'right',
  },
  {
    id: 'ue-orsi-flotilla',
    label: 'Ue-Orsi',
    system: IDENTITY_MOBILE_LOCATION_GROUP,
    aliases: ["Ue'Orsi"],
    locationNames: ['Ue-Orsi Flotilla'],
    x: 1.9,
    y: 57.9,
    region: 'Spinward Unknown',
    labelPlacement: 'right',
  },
];

const normalizeIdentityMapSearch = (value: string): string =>
  value.trim().toLowerCase();

export const getIdentityStarMapGroupForNode = (
  node: IdentityStarMapNode,
  groups: readonly IdentityLocationGroup[]
): IdentityLocationGroup | null => {
  const group = groups.find((candidate) => candidate.name === node.system);
  if (!group) {
    return null;
  }
  if (!node.locationNames?.length) {
    return group;
  }
  const allowedLocations = new Set(node.locationNames);
  const locations = group.locations.filter((location) =>
    allowedLocations.has(location.name)
  );
  if (!locations.length) {
    return null;
  }
  return {
    ...group,
    id: `${group.id}:${node.id}`,
    description:
      (locations.length === 1 && locations[0].description) || group.description,
    locations,
  };
};

const identityMapNodeOwnTerms = (node: IdentityStarMapNode): string[] => [
  node.label,
  node.system,
  node.region,
  node.description || '',
  node.sourceLabel || '',
  ...(node.aliases || []),
  ...(node.searchTerms || []),
  ...(node.locationNames || []),
];

const identityMapGroupTerms = (
  node: IdentityStarMapNode,
  groups: readonly IdentityLocationGroup[]
): string[] => {
  const group = getIdentityStarMapGroupForNode(node, groups);
  if (!group) {
    return [];
  }
  return [
    group.name,
    group.description || '',
    ...group.locations.reduce<string[]>((terms, location) => {
      terms.push(
        location.name,
        location.display_name || '',
        location.description || '',
        location.kind
      );
      return terms;
    }, []),
  ];
};

export const findIdentityStarMapNodeForSystem = (
  system: string | null | undefined
): IdentityStarMapNode | null => {
  const normalizedSystem = normalizeIdentityMapSearch(system || '');
  if (!normalizedSystem) {
    return null;
  }
  return (
    IDENTITY_STAR_MAP_NODES.find(
      (node) =>
        !node.locationNames?.length &&
        (node.system.toLowerCase() === normalizedSystem ||
          node.label.toLowerCase() === normalizedSystem ||
          node.aliases?.some(
            (alias) => alias.toLowerCase() === normalizedSystem
          ))
    ) || null
  );
};

export const findIdentityStarMapNodeForLocation = (
  value: string,
  options: readonly IdentityLocationOption[]
): IdentityStarMapNode | null => {
  const option = options.find((candidate) => candidate.name === value);
  if (!option) {
    return null;
  }
  const locationNode = IDENTITY_STAR_MAP_NODES.find((node) =>
    node.locationNames?.includes(option.name)
  );
  if (locationNode) {
    return locationNode;
  }
  return findIdentityStarMapNodeForSystem(option.system);
};

export const getIdentityStarMapMatchingNodes = (
  query: string,
  groups: readonly IdentityLocationGroup[]
): IdentityStarMapNode[] => {
  const normalizedQuery = normalizeIdentityMapSearch(query);
  if (!normalizedQuery) {
    return [...IDENTITY_STAR_MAP_NODES];
  }
  return IDENTITY_STAR_MAP_NODES.filter((node) =>
    [...identityMapNodeOwnTerms(node), ...identityMapGroupTerms(node, groups)]
      .filter(Boolean)
      .some((term) => term.toLowerCase().includes(normalizedQuery))
  );
};

export const findIdentityStarMapNodeForSearch = (
  query: string,
  groups: readonly IdentityLocationGroup[]
): IdentityStarMapNode | null => {
  const normalizedQuery = normalizeIdentityMapSearch(query);
  if (!normalizedQuery) {
    return null;
  }
  const exactMatch = IDENTITY_STAR_MAP_NODES.find((node) =>
    identityMapNodeOwnTerms(node).some(
      (term) => term.toLowerCase() === normalizedQuery
    )
  );
  return (
    exactMatch || getIdentityStarMapMatchingNodes(query, groups)[0] || null
  );
};
