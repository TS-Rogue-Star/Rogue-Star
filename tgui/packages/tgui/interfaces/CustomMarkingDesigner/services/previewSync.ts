// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Preview sync controller for custom marking designer //
// ////////////////////////////////////////////////////////////////////////////////////////////////////

import { selectBackend } from '../../../backend';
import { PREVIEW_DIFF_ACK_TIMEOUT, PREVIEW_DIFF_CHUNK_DELAY, PREVIEW_DIFF_CHUNK_SIZE } from '../constants';
import { buildSessionDraftDiff, chunkDiffEntries } from '../utils';
import type { CustomMarkingDesignerData, StrokeDraftState } from '../types';

type PreviewSyncProgress = {
  completedChunks: number;
  totalChunks: number;
  partKey: string;
  dirKey: number;
};

type ContextLike = {
  store: {
    getState: () => unknown;
  };
};

type PreviewSyncOptions = {
  context: ContextLike;
  act: (action: string, payload: Record<string, unknown>) => unknown;
  sessionToken: string | null;
  canvasWidth: number;
  canvasHeight: number;
  getStoredStrokeDrafts: () => StrokeDraftState;
  clearSessionDrafts: (sessionKey?: string) => void;
  getActivePartKey: () => string;
  getCurrentDirectionKey: () => number;
  buildLocalSessionKey: (dirKey: number, partKey: string) => string;
};

export type PreviewSyncController = {
  sendAction: (action: string, payload?: Record<string, unknown>) => void;
  sendActionAfterSync: (
    action: string,
    payload?: Record<string, unknown>
  ) => Promise<void>;
  commitPreviewToServer: (options?: {
    partKey?: string;
    sessionKey?: string;
    dirKey?: number;
    onProgress?: (progress: PreviewSyncProgress) => void;
  }) => Promise<void>;
  reportClientWarning: (
    message: string,
    details?: Record<string, unknown>
  ) => void;
  describeError: (error: unknown) => string;
};

const delay = (ms: number) =>
  new Promise<void>((resolve) => setTimeout(resolve, Math.max(0, ms)));

export const createPreviewSyncController = (
  options: PreviewSyncOptions
): PreviewSyncController => {
  const {
    context,
    act,
    sessionToken,
    canvasWidth,
    canvasHeight,
    getStoredStrokeDrafts,
    clearSessionDrafts,
    getActivePartKey,
    getCurrentDirectionKey,
    buildLocalSessionKey,
  } = options;

  const resolveLiveSessionToken = (): string | null => {
    const backendState = selectBackend(context.store.getState()) as {
      data?: CustomMarkingDesignerData;
    };
    const liveToken = backendState?.data?.session_token;
    if (typeof liveToken === 'string' && liveToken.length) {
      return liveToken;
    }
    return sessionToken;
  };

  const dispatchActionWithToken = (
    action: string,
    payload: Record<string, unknown> = {},
    tokenOverride?: string | null
  ) => {
    const resolvedToken =
      tokenOverride === undefined ? resolveLiveSessionToken() : tokenOverride;
    const finalPayload =
      resolvedToken && resolvedToken.length
        ? { ...payload, session_token: resolvedToken }
        : payload;
    return act(action, finalPayload);
  };

  const sendAction = (
    action: string,
    payload: Record<string, unknown> = {}
  ): void => {
    dispatchActionWithToken(action, payload);
  };

  const describeError = (error: unknown): string => {
    if (error instanceof Error && typeof error.message === 'string') {
      return error.message;
    }
    if (typeof error === 'string') {
      return error;
    }
    try {
      return JSON.stringify(error);
    } catch {
      return String(error);
    }
  };

  const reportClientWarning = (
    message: string,
    details?: Record<string, unknown>
  ) => {
    if (!message) {
      return;
    }
    const payload = {
      message,
      ...(details || {}),
    };
    try {
      sendAction('client_warning', payload);
    } catch {}
  };

  const getCurrentDiffSeq = (): number => {
    const backendState = selectBackend(context.store.getState()) as {
      data?: Record<string, unknown>;
    };
    const raw = backendState?.data?.diff_seq;
    const seq = Number(raw);
    return Number.isFinite(seq) ? seq : 0;
  };

  const waitForDiffAck = async (
    previousSeq: number,
    timeout = PREVIEW_DIFF_ACK_TIMEOUT
  ): Promise<{ seq: number; acknowledged: boolean }> => {
    const start = Date.now();
    let currentSeq = previousSeq;
    while (Date.now() - start < timeout) {
      currentSeq = getCurrentDiffSeq();
      if (currentSeq !== previousSeq) {
        return {
          seq: currentSeq,
          acknowledged: true,
        };
      }
      await delay(10);
    }
    return {
      seq: currentSeq,
      acknowledged: false,
    };
  };

  const commitPreviewToServer = async (options?: {
    partKey?: string;
    sessionKey?: string;
    dirKey?: number;
    onProgress?: (progress: PreviewSyncProgress) => void;
  }) => {
    const fallbackPart = getActivePartKey();
    const fallbackDir = getCurrentDirectionKey();
    const targetPartKey = options?.partKey || fallbackPart;
    const targetDirKey =
      options?.dirKey !== undefined ? options.dirKey : fallbackDir;
    const targetSessionKey =
      options?.sessionKey || buildLocalSessionKey(targetDirKey, targetPartKey);
    const drafts = getStoredStrokeDrafts();
    const pendingDiff = buildSessionDraftDiff(
      drafts,
      targetSessionKey,
      canvasWidth,
      canvasHeight
    );
    if (!pendingDiff.length) {
      options?.onProgress?.({
        completedChunks: 0,
        totalChunks: 0,
        partKey: targetPartKey,
        dirKey: targetDirKey,
      });
      return;
    }
    const chunks = chunkDiffEntries(pendingDiff, PREVIEW_DIFF_CHUNK_SIZE);
    const totalChunks = chunks.length;
    let chunkIndex = 0;
    let lastSeq = getCurrentDiffSeq();
    let actionToken = resolveLiveSessionToken();
    const emitProgress = (completed: number) => {
      options?.onProgress?.({
        completedChunks: completed,
        totalChunks,
        partKey: targetPartKey,
        dirKey: targetDirKey,
      });
    };
    const baseWarningContext = {
      partKey: targetPartKey,
      dirKey: targetDirKey,
      sessionKey: targetSessionKey,
      chunkCount: chunks.length,
    };
    let failureContext: Record<string, unknown> | null = null;
    emitProgress(0);
    try {
      for (const chunk of chunks) {
        const currentChunkIndex = chunkIndex;
        await dispatchActionWithToken(
          'apply_preview_diff',
          {
            diff: chunk,
            width: canvasWidth,
            height: canvasHeight,
            part: targetPartKey,
            dir: targetDirKey,
          },
          actionToken
        );
        const ackResult = await waitForDiffAck(lastSeq);
        if (!ackResult.acknowledged) {
          failureContext = {
            reason: 'ack_timeout',
            chunkIndex: currentChunkIndex,
          };
          throw new Error(
            'Preview diff acknowledgement timed out; please try again.'
          );
        }
        lastSeq = ackResult.seq;
        actionToken = resolveLiveSessionToken();
        chunkIndex += 1;
        emitProgress(chunkIndex);
        if (chunkIndex < chunks.length) {
          await delay(PREVIEW_DIFF_CHUNK_DELAY);
        }
      }
      emitProgress(totalChunks);
    } catch (error) {
      reportClientWarning(
        'Preview sync failed. Your custom marking changes are still stored locally—please retry or export before closing.',
        {
          ...baseWarningContext,
          chunkIndex,
          ...(failureContext || { reason: 'unknown' }),
          error: describeError(error),
        }
      );
      throw error;
    }
    clearSessionDrafts(targetSessionKey);
  };

  const sendActionAfterSync = async (
    actionName: string,
    payload: Record<string, unknown> = {}
  ) => {
    await commitPreviewToServer();
    sendAction(actionName, payload);
  };

  return {
    sendAction,
    sendActionAfterSync,
    commitPreviewToServer,
    reportClientWarning,
    describeError,
  };
};
