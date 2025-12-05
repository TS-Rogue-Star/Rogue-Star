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
  resolveDirectionCanvasSources,
  syncPreviewStateIfNeeded,
  updatePreviewStateFromPayload,
} from '../utils';
import { GENERIC_PART_KEY } from '../../../utils/character-preview';
import type { DiffEntry, PreviewState } from '../../../utils/character-preview';
import type { CustomMarkingDesignerData, StrokeDraftState } from '../types';

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
}>;

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
}: Params) => {
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

  const localSessionKey = buildLocalSessionKey(
    currentDirectionKey,
    activePartKey
  );
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
  const {
    referenceParts,
    referenceGrid,
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
  });
  const renderedPreviewDirs = buildRenderedPreviewDirs(
    derivedPreviewState.dirs,
    data.directions,
    bodyPartLabelMap,
    canvasWidth,
    canvasHeight,
    currentDirectionKey,
    activePartKey,
    draftDiffIndex,
    activeDraftDiff,
    resolvedPartPriorityMap,
    resolvedPartReplacementMap,
    partPaintPresenceMap,
    showJobGear,
    showLoadoutGear,
    notifyAssetReady
  );

  return {
    serverCanvasGrid,
    derivedPreviewState,
    overlayLayerParts,
    overlayLayerOrder,
    referenceParts,
    referenceGrid,
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
