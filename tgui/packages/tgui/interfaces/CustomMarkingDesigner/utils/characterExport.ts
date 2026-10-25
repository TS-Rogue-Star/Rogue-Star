// ////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star October 2026: Character Designer - JSON Export //
// ////////////////////////////////////////////////////////////////////////////////

import {
  applyDiffToGrid,
  createBlankGrid,
} from '../../../utils/character-preview';
import type { LoadoutDraft } from '../loadoutTypes';
import type { OccupationDraft } from '../occupationTypes';
import type {
  BasicAppearancePayload,
  BasicAppearanceState,
  BodyMarkingsPayload,
  EquipmentDraftState,
  IdentityDraftState,
  IdentityPayload,
  StrokeDraftState,
  TraitsSavePayload,
} from '../types';
import { buildBasicStateFromPayload } from './basicAppearance';
import { cloneEquipmentDraft } from './equipment';
import { convertCompositeGridToUi } from './gridConversion';
import { sanitizeFileToken, saveBlob } from './gridExport';
import { buildIdentityDraftState } from './identity';
import { cloneOccupationDraft } from './occupation';

type SpeciesExport = {
  species: string | null;
  icon_base: string | null;
  custom_species: string;
};

type BodyMarkingsExport = Pick<
  BodyMarkingsPayload,
  'body_markings' | 'order' | 'persist_markings'
>;

type CustomMarkingExport = {
  id: string;
  name: string;
  body_parts: string[];
  width: number;
  height: number;
  part_replacements: Record<string, boolean>;
  part_render_priority: Record<string, boolean>;
  part_canvas_size: Record<string, boolean>;
  frames: Record<string, (string | null)[][]>;
};

export type CharacterExportBaseline = {
  slot: number;
  species: SpeciesExport;
  identity: IdentityPayload;
  appearance: BasicAppearancePayload;
  body_markings: BodyMarkingsExport;
  traits: Omit<TraitsSavePayload, 'revision'>;
  equipment: EquipmentDraftState;
  loadout: LoadoutDraft;
  occupation: OccupationDraft;
  custom_markings: CustomMarkingExport | null;
};

export type CharacterExportDrafts = {
  species?: SpeciesExport;
  identity?: IdentityDraftState | null;
  appearance?: Partial<BasicAppearanceState>;
  body_markings?: BodyMarkingsExport;
  traits?: TraitsSavePayload;
  equipment?: EquipmentDraftState | null;
  loadout?: LoadoutDraft | null;
  occupation?: OccupationDraft | null;
  custom_markings: {
    width: number;
    height: number;
    strokes: StrokeDraftState;
    part_replacements?: Record<string, boolean>;
    part_render_priority?: Record<string, boolean>;
    part_canvas_size?: Record<string, boolean>;
  };
};

export type CharacterExportResult = {
  request_id: string;
  state_token: string;
  baseline?: CharacterExportBaseline;
  error?: string;
};

export const buildCharacterAppearanceDraft = (
  state: BasicAppearanceState,
  payload: BasicAppearancePayload | null | undefined
): Partial<BasicAppearanceState> => {
  if (payload?.prosthetic_context) {
    return state;
  }
  const {
    limbs,
    limb_operations,
    organ_operations,
    synth_color_enabled,
    synth_color,
    synth_markings,
    ...appearance
  } = state;
  return appearance;
};

const withoutRevision = <T extends { revision?: unknown }>(value: T) => {
  const { revision, ...values } = value;
  return values;
};

const exportCustomMarking = (
  baseline: CustomMarkingExport | null,
  draft: CharacterExportDrafts['custom_markings']
) => {
  if (!baseline) {
    return null;
  }
  const width = Math.max(baseline.width, draft.width);
  const height = Math.max(baseline.height, draft.height);
  const frames: Record<string, string[][]> = {};
  for (const [key, grid] of Object.entries(baseline.frames || {})) {
    frames[key] =
      convertCompositeGridToUi(grid, width, height) ||
      createBlankGrid(width, height);
  }
  const bodyParts = [...baseline.body_parts];
  const strokes = Object.values(draft.strokes).sort(
    (left, right) => left.sequence - right.sequence
  );
  for (const stroke of strokes) {
    const key = `${stroke.dirKey}|${stroke.part}`;
    const pixels = stroke.pixels.map((pixel) => ({
      ...pixel,
      x: pixel.x + Math.floor((width - draft.width) / 2),
      y: pixel.y + height - draft.height,
    }));
    frames[key] = applyDiffToGrid(
      frames[key] || createBlankGrid(width, height),
      pixels,
      width,
      height
    );
    if (!bodyParts.includes(stroke.part)) {
      bodyParts.push(stroke.part);
    }
  }
  return {
    ...baseline,
    width,
    height,
    pixel_origin: 'top-left',
    pixel_layout: 'columns',
    body_parts: bodyParts,
    part_replacements: {
      ...(draft.part_replacements || baseline.part_replacements),
    },
    part_render_priority: {
      ...(draft.part_render_priority || baseline.part_render_priority),
    },
    part_canvas_size: {
      ...(draft.part_canvas_size || baseline.part_canvas_size),
    },
    frames,
  };
};

export const buildCharacterExport = (
  baseline: CharacterExportBaseline,
  drafts: CharacterExportDrafts
) => {
  const identity = withoutRevision(
    drafts.identity || buildIdentityDraftState(baseline.identity)
  );
  const appearance = {
    ...buildBasicStateFromPayload(baseline.appearance),
    ...drafts.appearance,
    skin_tone: baseline.appearance.prosthetic_context?.skin_tone ?? null,
  };
  const { limb_operations, organ_operations, ...appearanceValues } = appearance;
  const { reset, ...occupation } = withoutRevision(
    cloneOccupationDraft(drafts.occupation || baseline.occupation)
  );
  const traits = withoutRevision({
    revision: undefined,
    ...(drafts.traits || baseline.traits),
  });
  const body = drafts.body_markings || baseline.body_markings;
  const character = {
    species: drafts.species || baseline.species,
    identity,
    appearance: appearanceValues,
    body_markings: {
      ...body,
      body_markings: { ...body.body_markings },
      persist_markings: !!body.persist_markings,
    },
    traits: {
      ...traits,
      trait_preferences: { ...traits.trait_preferences },
      languages: traits.languages && {
        ...traits.languages,
        custom_keys: { ...traits.languages.custom_keys },
      },
    },
    equipment: withoutRevision(
      cloneEquipmentDraft(drafts.equipment || baseline.equipment)
    ),
    loadout: withoutRevision(drafts.loadout || baseline.loadout),
    occupation,
    custom_markings: exportCustomMarking(
      baseline.custom_markings,
      drafts.custom_markings
    ),
  };
  return {
    filename: `${sanitizeFileToken(identity.real_name, 'character')}.json`,
    json: JSON.stringify(
      {
        format: 'rogue-star-character',
        version: 1,
        character,
      },
      null,
      2
    ),
  };
};

export const pickCharacterExportFile = (
  characterName?: string
): Promise<FileSystemFileHandle> | null => {
  const browser = window as typeof window & {
    showSaveFilePicker?: (options: {
      suggestedName: string;
      types: { description: string; accept: Record<string, string[]> }[];
    }) => Promise<FileSystemFileHandle>;
  };
  if (browser.showSaveFilePicker) {
    return browser.showSaveFilePicker({
      suggestedName: `${sanitizeFileToken(characterName, 'character')}.json`,
      types: [
        {
          description: 'Character JSON',
          accept: { 'application/json': ['.json'] },
        },
      ],
    });
  }
  return null;
};

export const downloadCharacterJson = async (
  json: string,
  filename: string,
  handle: FileSystemFileHandle | null
): Promise<void> => {
  const blob = new Blob([json], { type: 'application/json' });
  if (handle) {
    const writable = await handle.createWritable();
    await writable.write(blob);
    await writable.close();
    return;
  }
  const legacyNavigator = navigator as typeof navigator & {
    msSaveBlob?: (blob: Blob, filename: string) => boolean;
  };
  if (legacyNavigator.msSaveBlob) {
    if (!legacyNavigator.msSaveBlob(blob, filename)) {
      throw new Error('Download unavailable');
    }
    return;
  }
  if ((globalThis as any).Byond || !saveBlob(blob, filename, '.json')) {
    throw new Error('This client does not support file downloads.');
  }
};
