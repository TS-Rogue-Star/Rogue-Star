// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Part flag state helpers for custom marking designer //
// ////////////////////////////////////////////////////////////////////////////////////////////////////

import { useLocalState } from '../../../backend';
import {
  createLayerPriorityToggler,
  createPartReplacementToggler,
  resolveLayeringState,
  syncFlagStateIfNeeded,
  buildFlagStateFromServer,
} from '../utils';
import type {
  PartCanvasSizeState,
  PartRenderPriorityState,
  PartReplacementState,
} from '../types';

type Params = Readonly<{
  context: any;
  stateToken: string;
  activePartKey: string;
  uiLocked: boolean;
  replacementStateFromServer: Record<string, boolean> | undefined;
  replacementDependents: Record<string, string[]>;
  priorityStateFromServer: Record<string, boolean> | undefined;
  canvasSizeStateFromServer: Record<string, boolean> | undefined;
}>;

export const usePartFlagState = ({
  context,
  stateToken,
  activePartKey,
  uiLocked,
  replacementStateFromServer,
  replacementDependents,
  priorityStateFromServer,
  canvasSizeStateFromServer,
}: Params) => {
  const serverReplacementState = buildFlagStateFromServer(
    replacementStateFromServer
  );
  const [replacementState, setReplacementState] =
    useLocalState<PartReplacementState>(
      context,
      `partReplacements-${stateToken}`,
      serverReplacementState
    );
  const shouldAdoptServerReplacement =
    !replacementState.dirty &&
    replacementState.sourceHash !== serverReplacementState.sourceHash;
  const resolvedReplacementState = shouldAdoptServerReplacement
    ? serverReplacementState
    : replacementState;
  if (shouldAdoptServerReplacement) {
    syncFlagStateIfNeeded(
      serverReplacementState,
      replacementState,
      setReplacementState
    );
  }
  const resolvedPartReplacementMap = resolvedReplacementState.map;

  const serverPriorityState = buildFlagStateFromServer(priorityStateFromServer);
  const [priorityState, setPriorityState] =
    useLocalState<PartRenderPriorityState>(
      context,
      `partRenderPriority-${stateToken}`,
      serverPriorityState
    );
  const shouldAdoptPriorityState =
    !priorityState.dirty &&
    priorityState.sourceHash !== serverPriorityState.sourceHash;
  const resolvedPriorityState = shouldAdoptPriorityState
    ? serverPriorityState
    : priorityState;
  if (shouldAdoptPriorityState) {
    syncFlagStateIfNeeded(serverPriorityState, priorityState, setPriorityState);
  }
  const resolvedPartPriorityBaseMap = resolvedPriorityState.map;

  const serverCanvasSizeState = buildFlagStateFromServer(
    canvasSizeStateFromServer
  );
  const [canvasSizeState, setCanvasSizeState] =
    useLocalState<PartCanvasSizeState>(
      context,
      `partCanvasSize-${stateToken}`,
      serverCanvasSizeState
    );
  const shouldAdoptCanvasSizeState =
    !canvasSizeState.dirty &&
    canvasSizeState.sourceHash !== serverCanvasSizeState.sourceHash;
  const resolvedCanvasSizeState = shouldAdoptCanvasSizeState
    ? serverCanvasSizeState
    : canvasSizeState;
  if (shouldAdoptCanvasSizeState) {
    syncFlagStateIfNeeded(
      serverCanvasSizeState,
      canvasSizeState,
      setCanvasSizeState
    );
  }
  const resolvedPartCanvasSizeMap = resolvedCanvasSizeState.map;
  const resolvedPartPriorityMap = {
    ...resolvedPartPriorityBaseMap,
  };
  Object.keys(resolvedPartCanvasSizeMap || {}).forEach((partKey) => {
    if (resolvedPartCanvasSizeMap[partKey]) {
      resolvedPartPriorityMap[partKey] = true;
    }
  });

  const resolvePartLayeringState = (partKey?: string | null) =>
    resolveLayeringState(partKey, resolvedPartPriorityMap);

  const baseTogglePartLayerPriority = createLayerPriorityToggler({
    uiLocked,
    activePartKey,
    resolvedPartPriorityMap,
    resolvedPriorityState,
    setPriorityState,
    resolveLayeringState: resolvePartLayeringState,
  });

  const togglePartLayerPriority = (partKey?: string) => {
    const targetPart = partKey || activePartKey;
    if (targetPart && resolvedPartCanvasSizeMap[targetPart]) {
      return;
    }
    baseTogglePartLayerPriority(partKey);
  };

  const togglePartReplacement = createPartReplacementToggler({
    uiLocked,
    activePartKey,
    resolvedPartReplacementMap,
    resolvedReplacementState,
    setReplacementState,
    replacementDependents,
  });

  return {
    resolvedReplacementState,
    resolvedPriorityState,
    resolvedCanvasSizeState,
    resolvedPartReplacementMap,
    resolvedPartPriorityMap,
    resolvedPartCanvasSizeMap,
    resolvePartLayeringState,
    togglePartLayerPriority,
    togglePartReplacement,
  };
};
