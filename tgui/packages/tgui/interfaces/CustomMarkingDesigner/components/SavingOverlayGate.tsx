// /////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Gate wrapper for showing the designer saving overlay //
// /////////////////////////////////////////////////////////////////////////////////////////////////////

import type { PendingCloseMessage, SavingProgressState } from '../types';
import { SavingOverlay } from './SavingOverlay';

export type SavingOverlayGateProps = Readonly<{
  pendingClose: boolean;
  pendingSave: boolean;
  pendingCloseMessage: PendingCloseMessage | null;
  savingProgress: SavingProgressState | null;
}>;

export const SavingOverlayGate = ({
  pendingClose,
  pendingSave,
  pendingCloseMessage,
  savingProgress,
}: SavingOverlayGateProps) => {
  if (!pendingClose && !pendingSave) {
    return null;
  }
  return (
    <SavingOverlay
      title={pendingClose ? pendingCloseMessage?.title : 'Saving your changes…'}
      subtitle={
        pendingClose
          ? pendingCloseMessage?.subtitle
          : 'Please keep the client open while we sync your work. The designer will stay open afterward.'
      }
      progress={savingProgress}
    />
  );
};
