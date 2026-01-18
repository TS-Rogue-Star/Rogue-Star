// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Types for custom marking designer ////////////////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Updated to support 64x64 markings ////////////////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support loaout and job gear ///////////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support new body marking selector /////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////

import type {
  DiffEntry,
  IconAssetPayload,
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
  initial_tab?: 'custom' | 'body' | 'basic';
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
  show_job_gear?: boolean;
  show_loadout_gear?: boolean;
  body_markings_payload?: BodyMarkingsPayload | null;
  basic_appearance_payload?: BasicAppearancePayload | null;
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
  assets?: Record<number, Record<string, IconAssetPayload>>;
  digitigrade_assets?: Record<number, Record<string, IconAssetPayload>>;
};

export type BodyMarkingsPayload = {
  body_marking_definitions: BodyMarkingDefinition[];
  body_markings: Record<string, BodyMarkingEntry>;
  order: string[];
  digitigrade?: boolean;
  preview_only?: boolean;
  preview_sources?: PreviewDirectionSource[];
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
  assets?: Record<number, (IconAssetPayload | null)[]>;
  hide_body_parts?: string[] | null;
  lower_layer_dirs?: number[];
  multi_dir?: boolean;
  wing_offset?: number;
  back_assets?: Record<number, (IconAssetPayload | null)[]>;
};

export type BasicAppearanceGradientDefinition = {
  id: string;
  name: string;
  icon_state?: string | null;
  assets?: Record<number, IconAssetPayload>;
};

export type BasicAppearancePayload = {
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
  preview_only?: boolean;
  preview_sources_alt?: PreviewDirectionSource[];
  preview_revision_alt?: number;
  preview_sources?: PreviewDirectionSource[];
  preview_revision?: number;
  preview_width?: number;
  preview_height?: number;
  canvas_backgrounds?: CanvasBackgroundOption[];
  default_canvas_background?: string;
};

export type BasicAppearanceState = {
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
