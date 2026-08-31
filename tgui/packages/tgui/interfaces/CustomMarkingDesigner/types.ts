// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Types for custom marking designer ////////////////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Updated to support 64x64 markings ////////////////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support loaout and job gear ///////////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support new body marking selector /////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star August 2026: Character Designer - Species and Prosthetics ///////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////

import type { BooleanLike } from '../../../common/react';
import type {
  DiffEntry,
  IconAssetRegistryAsset,
  IconAssetRegistry,
  IconAssetPayload,
  IconAssetReference,
  PreviewDirectionEntry,
  PreviewDirectionSource,
  PreviewState,
} from '../../utils/character-preview';

export type DirectionEntry = {
  dir: number;
  label: string;
};

export type BodyPartEntry = {
  id: string;
  label: string;
};

export type StrokeDraftEntry = {
  stroke: string;
  session: string;
  dirKey: number;
  part: string;
  sequence: number;
  pixels: DiffEntry[];
};

export type StrokeDraftState = Record<string, StrokeDraftEntry>;

export type DraftStrokePayload = {
  stroke: string;
  sequence: number;
  pixels: DiffEntry[];
};

export type CustomMarkingDesignerData = {
  marking_id?: string;
  mark_name?: string;
  initial_tab?: 'custom' | 'body' | 'basic' | 'species' | 'traits';
  allow_custom_tab?: boolean;
  custom_marking_enable_disclaimer?: string;
  active_dir: string;
  active_dir_key: number;
  active_body_part: string | null;
  active_body_part_label?: string;
  grid: string[][];
  body_part_layers?: Record<string, (string | null)[][]>;
  body_part_layer_order?: string[];
  body_part_layer_revision?: number;
  diff?: DiffEntry[];
  diff_seq?: number;
  stroke?: string | number;
  limited: boolean;
  finalized: boolean;
  can_finalize: boolean;
  directions: DirectionEntry[];
  body_parts: BodyPartEntry[];
  selected_body_parts: string[];
  is_new?: boolean;
  width: number;
  height: number;
  max_width?: number;
  max_height?: number;
  default_width?: number;
  default_height?: number;
  session_token?: string;
  state_token?: string;
  ui_locked?: boolean;
  preview_sources?: PreviewDirectionSource[];
  preview_asset_registry?: IconAssetRegistry;
  preview_revision?: number;
  preview_refresh_token?: number;
  reference_build_in_progress?: boolean;
  part_replacements?: Record<string, boolean>;
  part_render_priority?: Record<string, boolean>;
  replacement_dependents?: Record<string, string[]>;
  part_canvas_size?: Record<string, boolean>;
  active_canvas_width?: number;
  active_canvas_height?: number;
  canvas_backgrounds?: CanvasBackgroundOption[];
  default_canvas_background?: string;
  show_equipment?: boolean;
  show_job_gear?: boolean;
  show_loadout_gear?: boolean;
  body_markings_payload?: BodyMarkingsPayload | null;
  basic_appearance_payload?: BasicAppearancePayload | null;
  species_payload?: SpeciesPayload | null;
  traits_payload?: TraitsPayload | null;
  traits_save_result?: TraitsSaveResult | null;
  traits_revision?: number;
  traits_species?: string | null;
  trait_icon_scale_x?: number;
  trait_icon_scale_y?: number;
  species_save_result?: SpeciesSaveResult | null;
  static_asset_manifest?: IconAssetRegistryAsset;
  static_asset_manifest_error?: string | null;
  static_asset_manifest_fallback?: boolean;
};

export type CustomColorSlotsState = Array<string | null>;

export type BooleanMapState = {
  map: Record<string, boolean>;
  dirty: boolean;
  sourceHash: string;
};

export type PartReplacementState = BooleanMapState;
export type PartRenderPriorityState = BooleanMapState;
export type PartCanvasSizeState = BooleanMapState;

export type PendingCloseMessage = {
  title?: string;
  subtitle?: string;
};

export type SavingProgressState = {
  value: number | null;
  label?: string;
};

export type CanvasBackgroundOption = {
  id: string;
  label: string;
  asset?: IconAssetPayload | null;
};

export type BodyMarkingPartState = {
  on?: boolean;
  color?: string | null;
};

export type BodyMarkingColorTarget =
  | { type: 'mark'; markId: string; partId?: string | null }
  | { type: 'galleryPreview' };

export type BodyMarkingEntry = {
  color?: string | null;
  [partId: string]: BodyMarkingPartState | string | null | undefined;
};

export type BodyMarkingDefinition = {
  id: string;
  name: string;
  category: string;
  body_parts: string[];
  hide_body_parts?: string[] | null;
  do_colouration: boolean;
  color_blend_mode: number;
  render_above_body: boolean;
  render_above_body_parts?: Record<string, boolean> | null;
  digitigrade_acceptance?: number;
  hide_from_gallery?: boolean;
  default_color?: string;
  default_entry?: BodyMarkingEntry;
  assets?: Record<number, Record<string, IconAssetReference>>;
  digitigrade_assets?: Record<number, Record<string, IconAssetReference>>;
};

export type BodyMarkingDefinitionData = BodyMarkingDefinition[];

export type BodyMarkingsPayload = {
  species_id?: string | null;
  custom_base?: string | null;
  definition_revision?: string | null;
  definition_data?: BodyMarkingDefinitionData;
  allowed_definition_ids?: string[];
  body_marking_definitions?: BodyMarkingDefinition[];
  body_markings: Record<string, BodyMarkingEntry>;
  order: string[];
  digitigrade?: boolean;
  preview_only?: boolean;
  preview_sources?: PreviewDirectionSource[];
  preview_asset_registry?: IconAssetRegistry;
  preview_signature?: string | null;
  preview_revision?: number;
  preview_width?: number;
  preview_height?: number;
  canvas_backgrounds?: CanvasBackgroundOption[];
  default_canvas_background?: string;
};

export type BodyMarkingsSavedState = {
  order: string[];
  markings: Record<string, BodyMarkingEntry>;
  selectedId: string | null;
};

export type BasicAppearanceAccessoryDefinition = {
  id: string;
  name: string;
  do_colouration?: boolean;
  color_blend_mode?: number;
  channel_count?: number;
  assets?: Record<number, (IconAssetReference | null)[]>;
  hide_body_parts?: string[] | null;
  lower_layer_dirs?: number[];
  multi_dir?: boolean;
  wing_offset?: number;
  back_assets?: Record<number, (IconAssetReference | null)[]>;
};

export type BasicAppearanceGradientDefinition = {
  id: string;
  name: string;
  icon_state?: string | null;
  assets?: Record<number, IconAssetReference>;
};

export type BasicAppearanceDefinitionData = {
  hair_styles?: BasicAppearanceAccessoryDefinition[];
  gradient_styles?: BasicAppearanceGradientDefinition[];
  facial_hair_styles?: BasicAppearanceAccessoryDefinition[];
  ear_styles?: BasicAppearanceAccessoryDefinition[];
  tail_styles?: BasicAppearanceAccessoryDefinition[];
  wing_styles?: BasicAppearanceAccessoryDefinition[];
};

export type BasicAppearanceAllowedStyleIds = {
  hair_styles?: string[];
  gradient_styles?: string[];
  facial_hair_styles?: string[];
  ear_styles?: string[];
  tail_styles?: string[];
  wing_styles?: string[];
};

export type LimbOverrideStatus = 'normal' | 'amputated' | 'cyborg';

export type LimbOverrideEntry = {
  status: LimbOverrideStatus | string;
  model?: string | null;
};

export type LimbOverrideState = {
  external: Record<string, LimbOverrideEntry>;
  internal: Record<string, LimbOverrideEntry>;
};

export type LimbOperationState = 'normal' | 'amputated' | 'prosthesis';

export type LimbOperation = {
  target: string;
  state: LimbOperationState;
  model?: string | null;
};

export type InternalOrganOperation = {
  target: string;
  state: string;
};

export type ProstheticPartState = {
  state: string;
  gendered_state?: string | null;
};

export type InternalOrganProstheticDefinition = {
  id: string;
  label: string;
  allowed_states: string[];
  locked_state?: string | null;
};

export type BasicProstheticContext = LimbOverrideState & {
  allowed_model_ids: string[];
  internal_organ_ids: string[];
  internal_organ_definitions?: InternalOrganProstheticDefinition[];
  part_states: Record<string, ProstheticPartState>;
  locked_parts: string[];
  gender_suffix: 'm' | 'f';
  digitigrade_parts: string[];
  full_body_allowed: boolean;
  brain_positronic_allowed: boolean;
  brain_drone_allowed: boolean;
  skin_tone?: number | null;
  apply_skin_tone?: boolean;
  apply_skin_color?: boolean;
  synth_color_enabled: boolean;
  synth_color: string;
  synth_color_parts?: string[];
  synth_markings: boolean;
  color_multiply?: boolean;
};

export type BasicAppearancePayload = {
  species_id?: string | null;
  custom_base?: string | null;
  biological_gender?: string | null;
  base_biological_genders?: string[];
  biological_genders?: string[];
  preview_gender_suffix?: 'm' | 'f';
  definition_revision?: string | null;
  definition_data?: BasicAppearanceDefinitionData;
  allowed_style_ids?: BasicAppearanceAllowedStyleIds;
  hair_styles?: BasicAppearanceAccessoryDefinition[];
  ear_styles?: BasicAppearanceAccessoryDefinition[];
  tail_styles?: BasicAppearanceAccessoryDefinition[];
  wing_styles?: BasicAppearanceAccessoryDefinition[];
  gradient_styles?: BasicAppearanceGradientDefinition[];
  facial_hair_styles?: BasicAppearanceAccessoryDefinition[];
  hair_style?: string | null;
  hair_color?: string | null;
  hair_gradient_style?: string | null;
  hair_gradient_color?: string | null;
  facial_hair_style?: string | null;
  facial_hair_color?: string | null;
  ear_style?: string | null;
  ear_colors?: (string | null)[];
  horn_style?: string | null;
  horn_colors?: (string | null)[];
  tail_style?: string | null;
  tail_colors?: (string | null)[];
  wing_style?: string | null;
  wing_colors?: (string | null)[];
  eye_color?: string | null;
  body_color?: string | null;
  digitigrade?: boolean;
  digitigrade_allowed?: boolean;
  blood_types?: string[];
  blood_type?: string | null;
  blood_reagents?: string[];
  blood_reagent?: string | null;
  blood_color?: string | null;
  needs_glasses?: boolean;
  prosthetic_context?: BasicProstheticContext | null;
  preview_only?: boolean;
  preview_sources_alt?: PreviewDirectionSource[];
  preview_asset_registry_alt?: IconAssetRegistry;
  preview_signature_alt?: string | null;
  preview_revision_alt?: number;
  preview_sources_gender_alt?: PreviewDirectionSource[];
  preview_asset_registry_gender_alt?: IconAssetRegistry;
  preview_signature_gender_alt?: string | null;
  preview_revision_gender_alt?: number;
  preview_sources_gender_alt_digitigrade?: PreviewDirectionSource[];
  preview_asset_registry_gender_alt_digitigrade?: IconAssetRegistry;
  preview_signature_gender_alt_digitigrade?: string | null;
  preview_revision_gender_alt_digitigrade?: number;
  preview_sources?: PreviewDirectionSource[];
  preview_asset_registry?: IconAssetRegistry;
  preview_signature?: string | null;
  preview_revision?: number;
  preview_width?: number;
  preview_height?: number;
  canvas_backgrounds?: CanvasBackgroundOption[];
  default_canvas_background?: string;
};

export type BasicAppearanceState = {
  biological_gender: string;
  hair_style: string | null;
  hair_color: string | null;
  hair_gradient_style: string | null;
  hair_gradient_color: string | null;
  facial_hair_style: string | null;
  facial_hair_color: string | null;
  ear_style: string | null;
  ear_colors: (string | null)[];
  horn_style: string | null;
  horn_colors: (string | null)[];
  tail_style: string | null;
  tail_colors: (string | null)[];
  wing_style: string | null;
  wing_colors: (string | null)[];
  eye_color: string | null;
  body_color: string | null;
  digitigrade: boolean;
  blood_type: string;
  blood_reagent: string;
  blood_color: string;
  needs_glasses: boolean;
  limbs: LimbOverrideState;
  limb_operations: LimbOperation[];
  organ_operations: InternalOrganOperation[];
  synth_color_enabled: boolean;
  synth_color: string | null;
  synth_markings: boolean;
};

export type SpeciesSaveBasicAppearance = Pick<
  BasicAppearancePayload,
  | 'species_id'
  | 'custom_base'
  | 'biological_gender'
  | 'base_biological_genders'
  | 'biological_genders'
  | 'preview_gender_suffix'
  | 'definition_revision'
  | 'definition_data'
  | 'allowed_style_ids'
  | 'hair_styles'
  | 'gradient_styles'
  | 'facial_hair_styles'
  | 'ear_styles'
  | 'tail_styles'
  | 'wing_styles'
  | 'hair_style'
  | 'hair_color'
  | 'hair_gradient_style'
  | 'hair_gradient_color'
  | 'facial_hair_style'
  | 'facial_hair_color'
  | 'ear_style'
  | 'ear_colors'
  | 'horn_style'
  | 'horn_colors'
  | 'tail_style'
  | 'tail_colors'
  | 'wing_style'
  | 'wing_colors'
  | 'eye_color'
  | 'body_color'
  | 'digitigrade'
  | 'digitigrade_allowed'
  | 'blood_types'
  | 'blood_type'
  | 'blood_reagents'
  | 'blood_reagent'
  | 'blood_color'
  | 'needs_glasses'
  | 'prosthetic_context'
>;

export type SpeciesSaveResult = {
  revision: number;
  accepted?: boolean;
  species_id: string;
  custom_base?: string | null;
  custom_species?: string | null;
  body_definition_revision?: string | null;
  body_definition_data?: BodyMarkingDefinitionData;
  body_allowed_definition_ids?: string[];
  body_marking_definitions?: BodyMarkingDefinition[];
  body_markings: Record<string, BodyMarkingEntry>;
  order: string[];
  basic_appearance?: SpeciesSaveBasicAppearance | null;
  preview_sources?: PreviewDirectionSource[];
  preview_asset_registry?: IconAssetRegistry;
  preview_signature?: string | null;
  preview_revision?: number;
  preview_sources_alt?: PreviewDirectionSource[];
  preview_asset_registry_alt?: IconAssetRegistry;
  preview_signature_alt?: string | null;
  preview_revision_alt?: number;
  preview_sources_gender_alt?: PreviewDirectionSource[];
  preview_asset_registry_gender_alt?: IconAssetRegistry;
  preview_signature_gender_alt?: string | null;
  preview_revision_gender_alt?: number;
  preview_sources_gender_alt_digitigrade?: PreviewDirectionSource[];
  preview_asset_registry_gender_alt_digitigrade?: IconAssetRegistry;
  preview_signature_gender_alt_digitigrade?: string | null;
  preview_revision_gender_alt_digitigrade?: number;
};

export type SpeciesModifierEntry = {
  id: string;
  label: string;
  description: string;
  value: number | string | boolean;
};

export type SpeciesTraitEntry = {
  id?: string;
  name: string;
  description?: string | null;
};

export type SpeciesDetailEntry = {
  id: string;
  label: string;
  value?: number | string | boolean | null;
  baseline_value?: number | string | boolean | null;
  description?: string | null;
  severity?: 'critical' | 'warning' | 'positive' | 'info' | string | null;
};

export type SpeciesDetailSection = {
  id: string;
  title: string;
  entries: SpeciesDetailEntry[];
};

export type SpeciesDigitigradePreviewAssets = Record<
  number,
  Record<string, IconAssetReference>
>;

export type SpeciesDefinition = {
  id: string;
  name: string;
  blurb?: string | null;
  modifiers: SpeciesModifierEntry[];
  traits: SpeciesTraitEntry[];
  detail_sections?: SpeciesDetailSection[];
  preview_assets?: Record<string, IconAssetReference>;
  body_preview_sources?: PreviewDirectionSource[];
  body_preview_digitigrade_assets?: SpeciesDigitigradePreviewAssets;
  body_color_blend_mode?: number | null;
  icon_base_count?: number;
  selectable?: BooleanLike;
  whitelist_locked?: BooleanLike;
  restricted_reason?: string | null;
};

export type SpeciesIconBaseOption = {
  id: string;
  name: string;
  preview_assets?: Record<string, IconAssetReference>;
  body_preview_sources?: PreviewDirectionSource[];
  body_preview_digitigrade_assets?: SpeciesDigitigradePreviewAssets;
  body_color_blend_mode?: number | null;
};

export type SpeciesPayload = {
  species: SpeciesDefinition[];
  selected_species?: string | null;
  preview_species?: string | null;
  selected_icon_base?: string | null;
  preview_icon_base?: string | null;
  icon_base_options?: SpeciesIconBaseOption[];
  custom_species?: string | null;
  custom_species_max_length?: number;
};

export type TraitCategoryId = 'positive' | 'neutral' | 'negative';

export type TraitPreferenceKind =
  | 'boolean'
  | 'color'
  | 'string'
  | 'number'
  | 'list';

export type TraitPreferenceValue = string | number | BooleanLike | null;

export type TraitPreferenceEntry = {
  id: string;
  label: string;
  kind: TraitPreferenceKind;
  value?: TraitPreferenceValue;
  options?: string[];
};

export type CharacterTraitEntry = {
  id: string;
  name: string;
  description: string;
  extra_language_slots?: number;
  icon_scale_x?: number;
  icon_scale_y?: number;
  tutorial?: string | null;
  selected: BooleanLike;
  disabled_reason?: string | null;
  warning_reason?: string | null;
  conflicts?: string[];
  preferences?: TraitPreferenceEntry[];
};

export type CharacterTraitCategory = {
  id: TraitCategoryId;
  name: string;
  summary: string;
  selected_count: number;
  traits: CharacterTraitEntry[];
};

export type CharacterPersistenceDetailEntry = {
  label: string;
  value: string;
};

export type CharacterExperienceEntry = {
  label: string;
  value: number;
};

export type CharacterNifPersistence = {
  present: BooleanLike;
  name?: string | null;
  durability?: number | null;
  max_durability?: number | null;
  durability_percent?: number | null;
  details: CharacterPersistenceDetailEntry[];
};

export type CharacterPetPersistence = {
  present: BooleanLike;
  name?: string | null;
  species?: string | null;
  details: CharacterPersistenceDetailEntry[];
  error?: string | null;
};

export type CharacterPersistencePayload = {
  character_name: string;
  experience: CharacterExperienceEntry[];
  nif: CharacterNifPersistence;
  pet: CharacterPetPersistence;
};

export type CharacterLanguageEntry = {
  id: string;
  name: string;
  description: string;
  selected: BooleanLike;
  automatic: BooleanLike;
  selectable: BooleanLike;
  preferred_always: BooleanLike;
  preferred_eligible: BooleanLike;
  preferred: BooleanLike;
  custom_key?: string | null;
  disabled_reason?: string | null;
};

export type CharacterLanguagesPayload = {
  base_optional_slots: number;
  optional_limit: number;
  selected_optional_count: number;
  preferred_language: string;
  preferred_fallback: string;
  language_prefixes: string[];
  default_language_prefixes: string[];
  entries: CharacterLanguageEntry[];
};

export type TraitsPayload = {
  revision: number;
  species_id: string;
  species_name: string;
  anatomy: 'Organic' | 'Synthetic';
  max_traits: number;
  limited_traits_selected: number;
  traits_remaining: number;
  neutral_traits_selected: number;
  total_selected: number;
  persistence?: CharacterPersistencePayload;
  languages?: CharacterLanguagesPayload;
  categories: CharacterTraitCategory[];
};

export type TraitsSaveResult = {
  revision: number;
  request_id: string;
  accepted: BooleanLike;
  traits_revision: number;
  error?: string | null;
};

export type TraitsDraftState = {
  revision: number;
  trait_order: string[];
  selected: Record<string, boolean>;
  preferences: Record<string, Record<string, TraitPreferenceValue>>;
  languages: LanguagesDraftState | null;
};

export type LanguagesDraftState = {
  optional_order: string[];
  selected_optional: Record<string, boolean>;
  preferred_language: string;
  custom_keys: Record<string, string>;
  language_prefixes: string[];
};

export type LanguagesSavePayload = {
  alternate_languages: string[];
  preferred_language: string;
  custom_keys: Record<string, string>;
  language_prefixes: string[];
};

export type TraitsSavePayload = {
  revision: number;
  selected_traits: string[];
  trait_preferences: Record<string, Record<string, TraitPreferenceValue>>;
  languages?: LanguagesSavePayload;
};

export type DirectionCanvasSourceOptions = {
  derivedPreviewState: PreviewState;
  currentDirectionKey: number;
  activePartKey: string;
  serverActivePartKey: string;
  serverCanvasGrid: string[][] | null;
  layerPartsWithDrafts?: Record<string, string[][]> | null;
  canvasWidth: number;
  canvasHeight: number;
  activeDirKey: number;
  diff?: DiffEntry[] | null;
  diffSeq?: number;
  stroke?: string | number;
  signalAssetUpdate: () => void;
  showEquipment?: boolean;
  showJobGear?: boolean;
  showLoadoutGear?: boolean;
  partPaintPresenceMap?: Record<string, boolean>;
  partReplacementMap?: Record<string, boolean>;
  referencePartMarkingGrids?: Record<string, string[][]> | null;
  hiddenBodyPartsOverride?: string[] | null;
};

export type DirectionCanvasSourceResult = {
  referenceParts: Record<string, string[][]> | null;
  referenceGrid: string[][] | null;
  referenceSignature?: string;
  serverDiffPayload: DiffEntry[] | null;
  serverDiffSeq?: number;
  serverDiffStroke?: string | number;
  uiCanvasGrid: string[][];
};

export type ColorPickerInitOptions = {
  locked: boolean;
  previewDirs: PreviewDirectionEntry[];
  customSlots: CustomColorSlotsState;
  setCustomSlots: (slots: CustomColorSlotsState) => void;
  previewRevision: number;
  colorSignature: string | null;
  setColorSignature: (signature: string | null) => void;
};

export type CustomPreviewOverride = {
  custom_parts?: Record<string, string[][]>;
  part_order?: string[];
};

export type CustomPreviewOverrideMap = Record<number, CustomPreviewOverride>;

export type PendingPreviewOverrides = {
  overrides: CustomPreviewOverrideMap;
  pendingBody: boolean;
  pendingBasic: boolean;
};
