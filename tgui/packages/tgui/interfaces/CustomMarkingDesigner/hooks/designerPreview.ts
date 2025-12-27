// /////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Preview plumbing for custom marking designer //
// /////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support loaout and job gear ////////
// /////////////////////////////////////////////////////////////////////////////////////////////

import {
  applyDraftDiffsToLayerMap,
  buildDraftDiffIndex,
  buildDraftPixelLookup,
  buildLocalSessionKey,
  buildOverlayLayerParts,
  buildPartPaintPresenceMap,
  buildRenderedPreviewDirs,
  buildSessionDraftDiff,
  convertCompositeGridToUi,
  updatePreviewEntryCustomLayer,
  resolveDirectionCanvasSources,
  syncPreviewStateIfNeeded,
  updatePreviewStateFromPayload,
} from '../utils';
import {
  createBlankGrid,
  GENERIC_PART_KEY,
} from '../../../utils/character-preview';
import type {
  DiffEntry,
  PreviewDirectionEntry,
  PreviewDirState,
  PreviewState,
} from '../../../utils/character-preview';
import type { CustomMarkingDesignerData, StrokeDraftState } from '../types';

export type RenderedPreviewCache = {
  signature: string;
  previewByDir: Record<number, PreviewDirectionEntry>;
};

type Params = Readonly<{
  data: CustomMarkingDesignerData;
  previewState: PreviewState;
  setPreviewState: (state: PreviewState) => void;
  strokeDraftState: StrokeDraftState;
  currentDirectionKey: number;
  activePartKey: string;
  layerParts: Record<string, string[][]> | null;
  layerOrder: string[] | null;
  canvasWidth: number;
  canvasHeight: number;
  notifyAssetReady: () => void;
  bodyPartLabelMap: Record<string, string>;
  resolvedPartPriorityMap: Record<string, boolean>;
  resolvedPartReplacementMap: Record<string, boolean>;
  sessionToken: string | null;
  showJobGear: boolean;
  showLoadoutGear: boolean;
  referencePartMarkingGridsByDir?: Record<
    number,
    Record<string, string[][]>
  > | null;
  markingsHiddenParts?: string[] | null;
  renderedPreviewCache?: RenderedPreviewCache | null;
  renderedPreviewSignature?: string;
  draftMutationToken?: number;
  enabled?: boolean;
}>;

type RenderedPreviewOptions = {
  cache?: RenderedPreviewCache | null;
  signature?: string;
  draftMutationToken?: number;
  dirStates: Record<number, PreviewDirState>;
  directions: { dir: number; label: string }[];
  labelMap: Record<string, string>;
  canvasWidth: number;
  canvasHeight: number;
  activeDirKey: number;
  activePartKey: string;
  draftDiffIndex?: Record<number, Record<string, DiffEntry[]>> | null;
  activeDraftDiff?: DiffEntry[] | null;
  partRenderPriorityMap?: Record<string, boolean>;
  partReplacementMap?: Record<string, boolean>;
  partPaintPresenceMap?: Record<string, boolean>;
  showJobGear?: boolean;
  showLoadoutGear?: boolean;
  signalAssetUpdate?: () => void;
};

const buildPreviewByDir = (
  preview: PreviewDirectionEntry[]
): Record<number, PreviewDirectionEntry> => {
  const previewByDir: Record<number, PreviewDirectionEntry> = {};
  preview.forEach((entry) => {
    previewByDir[entry.dir] = entry;
  });
  return previewByDir;
};

const buildPreviewListFromCache = (
  previewByDir: Record<number, PreviewDirectionEntry>,
  directions: { dir: number; label: string }[]
): PreviewDirectionEntry[] => {
  if (Array.isArray(directions) && directions.length) {
    const ordered = directions
      .map((entry) => previewByDir[entry.dir])
      .filter((entry): entry is PreviewDirectionEntry => entry !== undefined);
    if (ordered.length) {
      return ordered;
    }
  }
  return Object.values(previewByDir);
};

const resolveCachedRenderedPreview = (
  options: RenderedPreviewOptions
): PreviewDirectionEntry[] => {
  const {
    cache,
    signature,
    draftMutationToken,
    dirStates,
    directions,
    labelMap,
    canvasWidth,
    canvasHeight,
    activeDirKey,
    activePartKey,
    draftDiffIndex,
    activeDraftDiff,
    partRenderPriorityMap,
    partReplacementMap,
    partPaintPresenceMap,
    showJobGear,
    showLoadoutGear,
    signalAssetUpdate,
  } = options;
  const mutationSignature = Number.isFinite(draftMutationToken)
    ? `m${draftMutationToken}`
    : '';
  const cacheSignature =
    signature && signature.length
      ? [signature, mutationSignature].filter((entry) => entry.length).join('|')
      : '';
  const renderFullPreview = (nextSignature?: string) => {
    const preview = buildRenderedPreviewDirs(
      dirStates,
      directions,
      labelMap,
      canvasWidth,
      canvasHeight,
      activeDirKey,
      activePartKey,
      draftDiffIndex,
      activeDraftDiff,
      partRenderPriorityMap,
      partReplacementMap,
      partPaintPresenceMap,
      showJobGear,
      showLoadoutGear,
      signalAssetUpdate
    );
    if (cache && nextSignature) {
      cache.signature = nextSignature;
      cache.previewByDir = buildPreviewByDir(preview);
    }
    return preview;
  };
  if (!cache || !cacheSignature) {
    return renderFullPreview(cacheSignature || signature);
  }
  if (cache.signature !== cacheSignature) {
    return renderFullPreview(cacheSignature);
  }
  const previewByDir = cache.previewByDir || {};
  if (!activePartKey || !Number.isFinite(activeDirKey)) {
    return buildPreviewListFromCache(previewByDir, directions);
  }
  const cachedEntry = previewByDir[activeDirKey];
  if (!cachedEntry) {
    return renderFullPreview(cacheSignature);
  }
  const pendingDirDiffs = draftDiffIndex?.[activeDirKey] || null;
  const pendingDiff = pendingDirDiffs?.[activePartKey] || null;
  const diffToApply =
    pendingDiff && pendingDiff.length ? pendingDiff : activeDraftDiff;
  if (!diffToApply || !diffToApply.length) {
    return buildPreviewListFromCache(previewByDir, directions);
  }
  const baseGrid =
    dirStates?.[activeDirKey]?.customParts?.[activePartKey]?.grid || null;
  const updateResult = updatePreviewEntryCustomLayer({
    entry: cachedEntry,
    partKey: activePartKey,
    baseGrid,
    diff: diffToApply,
    canvasWidth,
    canvasHeight,
  });
  if (updateResult.requiresRebuild) {
    return renderFullPreview(cacheSignature);
  }
  if (updateResult.updated) {
    previewByDir[activeDirKey] = updateResult.entry;
  }
  return buildPreviewListFromCache(previewByDir, directions);
};

export const useDesignerPreview = ({
  data,
  previewState,
  setPreviewState,
  strokeDraftState,
  currentDirectionKey,
  activePartKey,
  layerParts,
  layerOrder,
  canvasWidth,
  canvasHeight,
  notifyAssetReady,
  bodyPartLabelMap,
  resolvedPartPriorityMap,
  resolvedPartReplacementMap,
  sessionToken,
  showJobGear,
  showLoadoutGear,
  referencePartMarkingGridsByDir,
  markingsHiddenParts,
  renderedPreviewCache,
  renderedPreviewSignature,
  draftMutationToken,
  enabled = true,
}: Params) => {
  const localSessionKey = buildLocalSessionKey(
    currentDirectionKey,
    activePartKey
  );

  if (!enabled) {
    const overlayLayerOrder = Array.isArray(layerOrder)
      ? layerOrder.filter((part) => part !== activePartKey)
      : layerOrder;
    return {
      serverCanvasGrid: null,
      derivedPreviewState: previewState,
      overlayLayerParts: null,
      overlayLayerOrder,
      referenceParts: null,
      referenceGrid: null,
      serverDiffPayload: null,
      serverDiffSeq: undefined,
      serverDiffStroke: undefined,
      uiCanvasGrid: createBlankGrid(canvasWidth, canvasHeight),
      draftDiffIndex: {} as Record<number, Record<string, DiffEntry[]>>,
      layerPartsWithDrafts: layerParts,
      localSessionKey,
      activeDraftDiff: [],
      draftPixelLookup: null,
      partPaintPresenceMap: {},
      renderedPreviewDirs: [],
      previewRevision: previewState.revision,
    };
  }

  const serverActivePartKey = data.active_body_part || GENERIC_PART_KEY;
  const serverCanvasGrid = convertCompositeGridToUi(
    data.grid,
    canvasWidth,
    canvasHeight
  );

  const serverSessionSyncKey = `${sessionToken || 'session'}-${
    data.active_dir_key
  }-${serverActivePartKey}`;
  const derivedPreviewState = updatePreviewStateFromPayload(previewState, {
    data,
    sessionKey: serverSessionSyncKey,
    activePartKey: serverActivePartKey,
    canvasWidth,
    canvasHeight,
    canvasGrid: serverCanvasGrid,
  });

  syncPreviewStateIfNeeded(derivedPreviewState, previewState, setPreviewState);

  const draftDiffIndex = buildDraftDiffIndex(strokeDraftState);
  const pendingActiveDirDiffs =
    draftDiffIndex[currentDirectionKey] || ({} as Record<string, DiffEntry[]>);
  const layerPartsWithDrafts = applyDraftDiffsToLayerMap(
    layerParts,
    pendingActiveDirDiffs,
    canvasWidth,
    canvasHeight
  );

  const fallbackOverlayParts =
    currentDirectionKey === data.active_dir_key ? layerPartsWithDrafts : null;
  const overlayLayerParts = buildOverlayLayerParts({
    previewState: derivedPreviewState,
    dirKey: currentDirectionKey,
    activePartKey,
    fallbackLayerParts: fallbackOverlayParts,
    draftDiffIndex,
    canvasWidth,
    canvasHeight,
  });
  const overlayLayerOrder = Array.isArray(layerOrder)
    ? layerOrder.filter((part) => part !== activePartKey)
    : layerOrder;

  const activeDraftDiff = buildSessionDraftDiff(
    strokeDraftState,
    localSessionKey,
    canvasWidth,
    canvasHeight
  );
  const draftPixelLookup = buildDraftPixelLookup(activeDraftDiff);
  const partPaintPresenceMap = buildPartPaintPresenceMap({
    dirStates: derivedPreviewState.dirs,
    draftDiffIndex,
    activeDirKey: currentDirectionKey,
    activePartKey,
    activeDraftDiff,
    canvasWidth,
    canvasHeight,
    replacementDependents: data.replacement_dependents,
  });
  const referencePartMarkingGrids =
    referencePartMarkingGridsByDir?.[currentDirectionKey] || null;
  const hiddenBodyPartsOverride =
    Array.isArray(markingsHiddenParts) && markingsHiddenParts.length
      ? markingsHiddenParts
      : null;
  const {
    referenceParts,
    referenceGrid,
    referenceSignature,
    serverDiffPayload,
    serverDiffSeq,
    serverDiffStroke,
    uiCanvasGrid,
  } = resolveDirectionCanvasSources({
    derivedPreviewState,
    currentDirectionKey,
    activePartKey,
    serverActivePartKey,
    serverCanvasGrid,
    layerPartsWithDrafts,
    canvasWidth,
    canvasHeight,
    activeDirKey: data.active_dir_key,
    diff: data.diff,
    diffSeq: data.diff_seq,
    stroke: data.stroke,
    signalAssetUpdate: notifyAssetReady,
    showJobGear,
    showLoadoutGear,
    partPaintPresenceMap,
    partReplacementMap: resolvedPartReplacementMap,
    referencePartMarkingGrids,
    hiddenBodyPartsOverride,
  });
  const renderedPreviewDirs = resolveCachedRenderedPreview({
    cache: renderedPreviewCache || undefined,
    signature: renderedPreviewSignature,
    draftMutationToken,
    dirStates: derivedPreviewState.dirs,
    directions: data.directions,
    labelMap: bodyPartLabelMap,
    canvasWidth,
    canvasHeight,
    activeDirKey: currentDirectionKey,
    activePartKey,
    draftDiffIndex,
    activeDraftDiff,
    partRenderPriorityMap: resolvedPartPriorityMap,
    partReplacementMap: resolvedPartReplacementMap,
    partPaintPresenceMap,
    showJobGear,
    showLoadoutGear,
    signalAssetUpdate: notifyAssetReady,
  });

  return {
    serverCanvasGrid,
    derivedPreviewState,
    overlayLayerParts,
    overlayLayerOrder,
    referenceParts,
    referenceGrid,
    referenceSignature,
    serverDiffPayload,
    serverDiffSeq,
    serverDiffStroke,
    uiCanvasGrid,
    draftDiffIndex,
    layerPartsWithDrafts,
    localSessionKey,
    activeDraftDiff,
    draftPixelLookup,
    partPaintPresenceMap,
    renderedPreviewDirs,
    previewRevision: derivedPreviewState.revision,
  };
};
