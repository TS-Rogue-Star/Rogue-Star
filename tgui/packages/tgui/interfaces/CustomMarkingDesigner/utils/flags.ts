// /////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Flag helpers for custom marking designer //
// /////////////////////////////////////////////////////////////////////////////////////////

import { GENERIC_PART_KEY } from '../../../utils/character-preview';
import type { BooleanMapState, PartRenderPriorityState, PartReplacementState } from '../types';

export const normalizeFlagMap = (
  map?: Record<string, boolean> | null
): Record<string, boolean> => {
  if (!map) {
    return {};
  }
  const normalized: Record<string, boolean> = {};
  Object.keys(map).forEach((key) => {
    if (!key) {
      return;
    }
    normalized[key] = !!map[key];
  });
  return normalized;
};

export const buildFlagMapHash = (
  map?: Record<string, boolean> | null
): string => {
  if (!map) {
    return '';
  }
  const entries = Object.keys(map || {})
    .filter(Boolean)
    .sort();
  if (!entries.length) {
    return '';
  }
  return entries.map((key) => `${key}:${map?.[key] ? 1 : 0}`).join('|');
};

export const buildFlagStateFromServer = (
  map?: Record<string, boolean> | null
): BooleanMapState => ({
  map: normalizeFlagMap(map),
  dirty: false,
  sourceHash: buildFlagMapHash(map),
});

export const syncFlagStateIfNeeded = (
  nextState: BooleanMapState,
  currentState: BooleanMapState,
  setState: (state: BooleanMapState) => void
) => {
  if (nextState !== currentState) {
    setState(nextState);
  }
};

export const collectReplacementCascadeTargets = (
  partId: string,
  dependencyMap?: Record<string, string[]>
): string[] => {
  if (!partId) {
    return [];
  }
  const visited: Record<string, boolean> = {};
  const queue: string[] = [partId];
  const targets: string[] = [];
  while (queue.length) {
    const next = queue.shift();
    if (!next || visited[next]) {
      continue;
    }
    visited[next] = true;
    targets.push(next);
    const children = dependencyMap?.[next];
    if (Array.isArray(children)) {
      for (const child of children) {
        if (child && !visited[child]) {
          queue.push(child);
        }
      }
    }
  }
  return targets;
};

export const applyReplacementCascadeToMap = (
  map: Record<string, boolean>,
  partId: string,
  enabled: boolean,
  dependencyMap?: Record<string, string[]>
): Record<string, boolean> => {
  const targets = collectReplacementCascadeTargets(partId, dependencyMap);
  if (!targets.length) {
    return map;
  }
  let mutated = false;
  const next = { ...map };
  for (const target of targets) {
    if (!target || target === GENERIC_PART_KEY) {
      continue;
    }
    if (next[target] === enabled) {
      continue;
    }
    next[target] = enabled;
    mutated = true;
  }
  return mutated ? next : map;
};

export const buildFlagSavePayload = (
  map: Record<string, boolean>
): Record<string, number> | null => {
  const payload: Record<string, number> = {};
  let hasEntry = false;
  for (const key of Object.keys(map || {})) {
    if (!key) {
      continue;
    }
    payload[key] = map[key] ? 1 : 0;
    hasEntry = true;
  }
  return hasEntry ? payload : null;
};

export const resolveLayeringState = (
  partKey: string | null | undefined,
  priorityMap: Record<string, boolean>
) => {
  if (!partKey) {
    return false;
  }
  if (Object.prototype.hasOwnProperty.call(priorityMap, partKey)) {
    return !!priorityMap[partKey];
  }
  return false;
};

export type LayerPriorityToggleConfig = {
  uiLocked: boolean;
  activePartKey: string | null | undefined;
  resolvedPartPriorityMap: Record<string, boolean>;
  resolvedPriorityState: PartRenderPriorityState;
  setPriorityState: (next: PartRenderPriorityState) => void;
  resolveLayeringState: (partKey: string | null | undefined) => boolean;
};

export const createLayerPriorityToggler = ({
  uiLocked,
  activePartKey,
  resolvedPartPriorityMap,
  resolvedPriorityState,
  setPriorityState,
  resolveLayeringState,
}: LayerPriorityToggleConfig) => {
  return (targetPartKey?: string) => {
    const partKey = targetPartKey || activePartKey;
    if (uiLocked || !partKey || partKey === GENERIC_PART_KEY) {
      return;
    }
    const nextState = !resolveLayeringState(partKey);
    setPriorityState({
      map: {
        ...resolvedPartPriorityMap,
        [partKey]: nextState,
      },
      dirty: true,
      sourceHash: resolvedPriorityState.sourceHash,
    });
  };
};

export type ReplacementToggleConfig = {
  uiLocked: boolean;
  activePartKey: string | null | undefined;
  resolvedPartReplacementMap: Record<string, boolean>;
  resolvedReplacementState: PartReplacementState;
  setReplacementState: (next: PartReplacementState) => void;
  replacementDependents?: Record<string, string[]>;
};

export const createPartReplacementToggler = ({
  uiLocked,
  activePartKey,
  resolvedPartReplacementMap,
  resolvedReplacementState,
  setReplacementState,
  replacementDependents,
}: ReplacementToggleConfig) => {
  return (targetPartKey?: string) => {
    const partKey = targetPartKey || activePartKey;
    if (uiLocked || !partKey || partKey === GENERIC_PART_KEY) {
      return;
    }
    const nextEnabled = !resolvedPartReplacementMap[partKey];
    const updatedMap = applyReplacementCascadeToMap(
      resolvedPartReplacementMap,
      partKey,
      nextEnabled,
      replacementDependents
    );
    if (updatedMap === resolvedPartReplacementMap) {
      return;
    }
    setReplacementState({
      map: updatedMap,
      dirty: true,
      sourceHash: resolvedReplacementState.sourceHash,
    });
  };
};
