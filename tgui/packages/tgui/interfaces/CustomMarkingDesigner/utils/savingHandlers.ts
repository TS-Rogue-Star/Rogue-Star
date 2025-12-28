// ///////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Saving handler helpers for custom marking designer //
// ///////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Updated to support 64x64 markings ///////////////////
// ///////////////////////////////////////////////////////////////////////////////////////////////////

import type { PendingCloseMessage, SavingProgressState } from '../types';
import { buildFlagSavePayload } from './flags';
import type { BooleanMapState } from '../types';

export type SavingHandlerOptions = {
  pendingClose: boolean;
  pendingSave: boolean;
  setPendingClose: (value: boolean) => void;
  setPendingSave: (value: boolean) => void;
  setPendingCloseMessage: (value: PendingCloseMessage | null) => void;
  syncAllPendingDraftSessions: () => Promise<void>;
  resolvedReplacementState: BooleanMapState;
  resolvedPartReplacementMap: Record<string, boolean>;
  resolvedPriorityState: BooleanMapState;
  resolvedPartPriorityMap: Record<string, boolean>;
  resolvedCanvasSizeState: BooleanMapState;
  resolvedPartCanvasSizeMap: Record<string, boolean>;
  sendActionAfterSync: (
    actionName: string,
    payload?: Record<string, unknown>
  ) => Promise<void>;
  clearAllLocalDrafts: () => void;
  setSavingProgress: (value: SavingProgressState | null) => void;
  sendAction: (
    actionName: string,
    payload?: Record<string, unknown>
  ) => Promise<void> | void;
  reportClientWarning: (
    message: string,
    details?: Record<string, unknown>
  ) => void;
  formatError: (error: unknown) => string;
};

export const createSavingHandlers = ({
  pendingClose,
  pendingSave,
  setPendingClose,
  setPendingSave,
  setPendingCloseMessage,
  syncAllPendingDraftSessions,
  resolvedReplacementState,
  resolvedPartReplacementMap,
  resolvedPriorityState,
  resolvedPartPriorityMap,
  resolvedCanvasSizeState,
  resolvedPartCanvasSizeMap,
  sendActionAfterSync,
  clearAllLocalDrafts,
  setSavingProgress,
  sendAction,
  reportClientWarning,
  formatError,
}: SavingHandlerOptions) => {
  const buildPayloads = () => ({
    replacementPayload: resolvedReplacementState.dirty
      ? buildFlagSavePayload(resolvedPartReplacementMap)
      : null,
    priorityPayload: resolvedPriorityState.dirty
      ? buildFlagSavePayload(resolvedPartPriorityMap)
      : null,
    canvasPayload: resolvedCanvasSizeState.dirty
      ? buildFlagSavePayload(resolvedPartCanvasSizeMap)
      : null,
  });

  const handleSafeClose = async () => {
    if (pendingClose || pendingSave) {
      return;
    }
    setSavingProgress({
      value: null,
      label: 'Syncing your changes…',
    });
    setPendingCloseMessage(null);
    setPendingClose(true);
    try {
      await syncAllPendingDraftSessions();
      setSavingProgress({
        value: null,
        label: 'Finalizing with server…',
      });
      const { replacementPayload, priorityPayload, canvasPayload } =
        buildPayloads();
      await sendActionAfterSync('save_and_close', {
        ...(replacementPayload
          ? { part_replacements: replacementPayload }
          : {}),
        ...(priorityPayload ? { part_render_priority: priorityPayload } : {}),
        ...(canvasPayload ? { part_canvas_size: canvasPayload } : {}),
      });
    } catch (error) {
      setPendingClose(false);
      setPendingCloseMessage(null);
      setSavingProgress(null);
      reportClientWarning(
        'Save before closing failed. Your designer window will stay open so you can retry.',
        {
          source: 'handleSafeClose',
          error: formatError(error),
        }
      );
    }
  };

  const handleSaveProgress = async (): Promise<boolean> => {
    if (pendingClose || pendingSave) {
      return false;
    }
    setPendingSave(true);
    setSavingProgress({
      value: null,
      label: 'Syncing your changes…',
    });
    let saved = false;
    try {
      await syncAllPendingDraftSessions();
      setSavingProgress({
        value: null,
        label: 'Finalizing with server…',
      });
      const { replacementPayload, priorityPayload, canvasPayload } =
        buildPayloads();
      await sendActionAfterSync('save_progress', {
        ...(replacementPayload
          ? { part_replacements: replacementPayload }
          : {}),
        ...(priorityPayload ? { part_render_priority: priorityPayload } : {}),
        ...(canvasPayload ? { part_canvas_size: canvasPayload } : {}),
      });
      saved = true;
    } catch (error) {
      reportClientWarning(
        'Progress save failed. Your latest brush strokes are still local and not on the server.',
        {
          source: 'handleSaveProgress',
          error: formatError(error),
        }
      );
    } finally {
      setPendingSave(false);
      setSavingProgress(null);
    }
    return saved;
  };

  const handleDiscardAndClose = async () => {
    if (pendingClose || pendingSave) {
      return;
    }
    setPendingCloseMessage({
      title: 'Discarding your changes…',
      subtitle: 'Closing without saving or syncing any drafts.',
    });
    setSavingProgress({
      value: null,
      label: 'Discarding local changes…',
    });
    setPendingClose(true);
    try {
      await sendAction('discard_and_close'); // Consolidate to avoid race condition (Lira, November 2025)
      clearAllLocalDrafts();
    } catch (error) {
      setPendingClose(false);
      setPendingCloseMessage(null);
      setSavingProgress(null);
      reportClientWarning(
        'Discard failed. Your unsaved work is still present.',
        {
          source: 'handleDiscardAndClose',
          error: formatError(error),
        }
      );
    }
  };

  return {
    handleSafeClose,
    handleSaveProgress,
    handleDiscardAndClose,
  };
};
