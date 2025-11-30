// ///////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Pending draft sync for custom marking designer //
// ///////////////////////////////////////////////////////////////////////////////////////////////

import { GENERIC_PART_KEY } from '../../../utils/character-preview';
import { buildSessionDraftDiff, chunkDiffEntries } from '../utils';
import { PREVIEW_DIFF_CHUNK_SIZE } from '../constants';
import type { StrokeDraftState } from '../types';
import type { SavingProgressState } from '../types';

type PendingDraftSession = {
  partKey: string;
  dirKey: number;
  sessionKey: string;
};

type ProgressHandler = (next: SavingProgressState | null) => void;

type CreatePendingDraftSyncConfig = {
  strokeDraftState: StrokeDraftState;
  canvasWidth: number;
  canvasHeight: number;
  getPendingDraftSessions: () => PendingDraftSession[];
  commitPreviewToServer: (args: {
    partKey: string;
    sessionKey: string;
    dirKey: number;
    onProgress: (state: { completedChunks: number }) => void;
  }) => Promise<void>;
  setSavingProgress: ProgressHandler;
  resolveDirectionLabel: (dirKey: number) => string;
  resolvePartLabel: (partKey: string) => string;
};

export const createPendingDraftSync = ({
  strokeDraftState,
  canvasWidth,
  canvasHeight,
  getPendingDraftSessions,
  commitPreviewToServer,
  setSavingProgress,
  resolveDirectionLabel,
  resolvePartLabel,
}: CreatePendingDraftSyncConfig) => {
  return async () => {
    const pendingSessions = getPendingDraftSessions();
    if (!pendingSessions.length) {
      return;
    }
    const sessionChunkPlan = pendingSessions.map((sessionInfo) => {
      const sessionDiff = buildSessionDraftDiff(
        strokeDraftState,
        sessionInfo.sessionKey,
        canvasWidth,
        canvasHeight
      );
      const chunkCount = chunkDiffEntries(
        sessionDiff,
        PREVIEW_DIFF_CHUNK_SIZE
      ).length;
      return {
        ...sessionInfo,
        chunkCount,
      };
    });
    const totalChunks =
      sessionChunkPlan.reduce((sum, entry) => sum + entry.chunkCount, 0) || 0;
    let completedChunks = 0;
    for (const sessionInfo of sessionChunkPlan) {
      const sessionTotal = sessionInfo.chunkCount;
      const handleProgress = (doneChunks: number) => {
        const safeTotal = totalChunks || 1;
        const completed = Math.min(completedChunks + doneChunks, safeTotal);
        const labelPart =
          sessionInfo.partKey === GENERIC_PART_KEY
            ? 'Generic layer'
            : resolvePartLabel(sessionInfo.partKey);
        const label = `${labelPart} — ${resolveDirectionLabel(
          sessionInfo.dirKey
        )}`;
        setSavingProgress({
          value: safeTotal > 0 ? completed / safeTotal : null,
          label: totalChunks
            ? `Syncing strokes (${completed}/${safeTotal}) • ${label}`
            : `Syncing strokes • ${label}`,
        });
      };
      if (sessionTotal === 0) {
        continue;
      }
      await commitPreviewToServer({
        partKey: sessionInfo.partKey,
        sessionKey: sessionInfo.sessionKey,
        dirKey: sessionInfo.dirKey,
        onProgress: ({ completedChunks: doneChunks }) => {
          handleProgress(doneChunks);
        },
      });
      completedChunks += sessionTotal;
      handleProgress(0);
    }
  };
};
