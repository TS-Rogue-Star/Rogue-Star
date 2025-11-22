// /////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Stroke draft storage for custom marking designer //
// /////////////////////////////////////////////////////////////////////////////////////////////////

import type { DiffEntry } from '../../../utils/character-preview';
import { arePixelListsEqual, clearAllLocalDraftsInStore, getStoredStrokeDraftsFromStore, mergeStrokePixels, normalizeStrokeKey, updateStrokeDraftsInStore } from '../utils';
import type { StrokeDraftState } from '../types';

type ContextLike = {
  store: {
    getState: () => unknown;
  };
};

export type PendingDraftSession = {
  sessionKey: string;
  dirKey: number;
  partKey: string;
};

type StrokeDraftManagerOptions = {
  context: ContextLike;
  getLocalSessionKey: () => string | null;
  getActivePartKey: () => string;
  getCurrentDirectionKey: () => number;
  allocateDraftSequence: () => number;
};

export type StrokeDraftManager = {
  getStoredStrokeDrafts: () => StrokeDraftState;
  updateStrokeDrafts: (
    updater: (prev: StrokeDraftState) => StrokeDraftState
  ) => void;
  clearAllLocalDrafts: () => void;
  appendStrokePreviewPixels: (stroke: unknown, pixels: DiffEntry[]) => void;
  removeStrokeDraft: (stroke: unknown) => void;
  clearSessionDrafts: (targetSessionKey?: string) => void;
  getPendingDraftSessions: () => PendingDraftSession[];
  removeLastLocalStroke: () => boolean;
};

export const createStrokeDraftManager = (
  options: StrokeDraftManagerOptions
): StrokeDraftManager => {
  const {
    context,
    getLocalSessionKey,
    getActivePartKey,
    getCurrentDirectionKey,
    allocateDraftSequence,
  } = options;

  const getStoredStrokeDrafts = (): StrokeDraftState =>
    getStoredStrokeDraftsFromStore(context.store);

  const updateStrokeDrafts = (
    updater: (prev: StrokeDraftState) => StrokeDraftState
  ) => {
    updateStrokeDraftsInStore(context.store, updater);
  };

  const clearAllLocalDrafts = () => {
    clearAllLocalDraftsInStore(context.store);
  };

  const buildStrokeDraftKey = (
    stroke: unknown,
    sessionId?: string | null
  ): string | null => {
    if (!sessionId) {
      return null;
    }
    const strokeKey = normalizeStrokeKey(stroke);
    if (!strokeKey) {
      return null;
    }
    return `${sessionId}::${strokeKey}`;
  };

  const appendStrokePreviewPixels = (stroke: unknown, pixels: DiffEntry[]) => {
    const localSessionKey = getLocalSessionKey();
    const currentDirKey = getCurrentDirectionKey();
    const currentPartKey = getActivePartKey();
    const storageKey = buildStrokeDraftKey(stroke, localSessionKey);
    const logicalStrokeKey = normalizeStrokeKey(stroke);
    if (
      typeof localSessionKey !== 'string' ||
      !storageKey ||
      !logicalStrokeKey ||
      !pixels.length
    ) {
      return;
    }
    updateStrokeDrafts((prev) => {
      const existing = prev[storageKey];
      const mergedPixels = mergeStrokePixels(existing?.pixels, pixels);
      if (
        existing &&
        existing.session === localSessionKey &&
        arePixelListsEqual(existing.pixels, mergedPixels)
      ) {
        return prev;
      }
      const next = { ...prev };
      next[storageKey] = existing
        ? {
          ...existing,
          pixels: mergedPixels,
        }
        : {
          stroke: logicalStrokeKey,
          session: localSessionKey,
          dirKey: currentDirKey,
          part: currentPartKey,
          sequence: allocateDraftSequence(),
          pixels: mergedPixels,
        };
      return next;
    });
  };

  const removeStrokeDraft = (stroke: unknown) => {
    const strokeKey = normalizeStrokeKey(stroke);
    if (!strokeKey) {
      return;
    }
    updateStrokeDrafts((prev) => {
      let changed = false;
      const next = { ...prev };
      for (const key of Object.keys(prev)) {
        const entry = prev[key];
        if (entry?.stroke !== strokeKey) {
          continue;
        }
        delete next[key];
        changed = true;
      }
      return changed ? next : prev;
    });
  };

  const clearSessionDrafts = (targetSessionKey?: string) => {
    const sessionToClear = targetSessionKey || getLocalSessionKey();
    if (!sessionToClear) {
      return;
    }
    updateStrokeDrafts((prev) => {
      let changed = false;
      const next = { ...prev };
      for (const key of Object.keys(prev)) {
        if (prev[key]?.session === sessionToClear) {
          delete next[key];
          changed = true;
        }
      }
      return changed ? next : prev;
    });
  };

  const getPendingDraftSessions = (): PendingDraftSession[] => {
    const drafts = getStoredStrokeDrafts();
    const sessions = new Map<string, { dirKey: number; part: string }>();
    const fallbackPart = getActivePartKey();
    const fallbackDir = getCurrentDirectionKey();
    for (const entry of Object.values(drafts || {})) {
      if (!entry || typeof entry.session !== 'string') {
        continue;
      }
      if (sessions.has(entry.session)) {
        continue;
      }
      const resolvedPart = entry.part || fallbackPart;
      if (!resolvedPart) {
        continue;
      }
      sessions.set(entry.session, {
        dirKey: Number.isFinite(entry.dirKey)
          ? (entry.dirKey as number)
          : fallbackDir,
        part: resolvedPart,
      });
    }
    return Array.from(sessions.entries()).map(([token, info]) => ({
      sessionKey: token,
      dirKey: info.dirKey,
      partKey: info.part,
    }));
  };

  const removeLastLocalStroke = (): boolean => {
    const drafts = getStoredStrokeDrafts();
    const localSessionKey = getLocalSessionKey();
    let targetKey: string | null = null;
    let bestSeq = -Infinity;
    for (const [key, entry] of Object.entries(drafts || {})) {
      if (!entry || entry.session !== localSessionKey) {
        continue;
      }
      const seq = Number(entry.sequence);
      let weight = Number.isFinite(seq) ? seq : Number(entry.stroke);
      if (!Number.isFinite(weight)) {
        weight = -Infinity;
      }
      if (weight > bestSeq) {
        bestSeq = weight;
        targetKey = key;
      }
    }
    if (!targetKey) {
      return false;
    }
    updateStrokeDrafts((prev) => {
      if (!targetKey || !prev[targetKey]) {
        return prev;
      }
      const next = { ...prev };
      delete next[targetKey];
      return next;
    });
    return true;
  };

  return {
    getStoredStrokeDrafts,
    updateStrokeDrafts,
    clearAllLocalDrafts,
    appendStrokePreviewPixels,
    removeStrokeDraft,
    clearSessionDrafts,
    getPendingDraftSessions,
    removeLastLocalStroke,
  };
};
