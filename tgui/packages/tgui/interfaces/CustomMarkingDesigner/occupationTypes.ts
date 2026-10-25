// /////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Occupation //
// /////////////////////////////////////////////////////////////////////////////////

import type { BooleanLike } from 'common/react';
import type { EquipmentGearRecipes } from './types';

export type OccupationPriority = 1 | 2 | 3 | 4;

export type OccupationDraft = {
  revision: string;
  priorities: Record<string, OccupationPriority>;
  titles: Record<string, string>;
  alternate_option: number;
  spawnpoint: string;
  persist_spawn?: boolean;
  vantag_volunteer: boolean;
  vantag_preference: string;
  reset: boolean;
};

export type OccupationJob = {
  id: string;
  department: string;
  assistant: BooleanLike;
  available: BooleanLike;
  restriction: string | null;
  titles: string[];
  descriptions: Record<string, string[]>;
  supervisors: string;
  departments: string[];
  manages: string[];
  wiki_url: string | null;
};

export type OccupationCatalog = {
  jobs: OccupationJob[];
  departments: { id: string; color: string }[];
  hours: { department: string; played: number; pto: number }[];
  suppress_job_preview: BooleanLike;
  spawnpoint_options: string[];
  event_preference_options: { value: string; label: string }[];
};

export type OccupationPreview = {
  key: string;
  gear: EquipmentGearRecipes;
  silicon: BooleanLike;
};

export type OccupationPayload = {
  request_id: string;
  context_signature?: string;
  values?: OccupationDraft;
  catalog?: OccupationCatalog;
  previews?: OccupationPreview[];
  preview_complete?: BooleanLike;
  error?: string;
};

export type OccupationSaveResult = OccupationPayload & {
  accepted: BooleanLike;
};

export type OccupationPreviewBatch = {
  request_id: string;
  recipe_signature: string;
  sequence: number;
  previews: OccupationPreview[];
  complete: BooleanLike;
  error?: string;
};
