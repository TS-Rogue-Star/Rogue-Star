// //////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Types for custom marking designer //
// //////////////////////////////////////////////////////////////////////////////////

import type { DiffEntry, PreviewDirectionEntry, PreviewDirectionSource, PreviewState } from '../../utils/character-preview';

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
  session_token?: string;
  state_token?: string;
  ui_locked?: boolean;
  preview_sources?: PreviewDirectionSource[];
  preview_revision?: number;
  part_replacements?: Record<string, boolean>;
  part_render_priority?: Record<string, boolean>;
  replacement_dependents?: Record<string, string[]>;
};

export type CustomMarkingDesignerState = {
  tool: string;
  size: number;
  stroke: number;
};

export type CustomColorSlotsState = Array<string | null>;

export type BooleanMapState = {
  map: Record<string, boolean>;
  dirty: boolean;
  sourceHash: string;
};

export type PartReplacementState = BooleanMapState;
export type PartRenderPriorityState = BooleanMapState;

export type PendingCloseMessage = {
  title?: string;
  subtitle?: string;
};

export type SavingProgressState = {
  value: number | null;
  label?: string;
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
};

export type DirectionCanvasSourceResult = {
  referenceParts: Record<string, string[][]> | null;
  referenceGrid: string[][] | null;
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
