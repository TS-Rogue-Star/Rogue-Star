// //////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Gate overlay for enabling custom markings in the designer //
// //////////////////////////////////////////////////////////////////////////////////////////////////////////

import { EnableCustomMarkingsOverlay } from './EnableCustomMarkingsOverlay';

export type EnableCustomMarkingsGateProps = Readonly<{
  open: boolean;
  allowCustomTab: boolean;
  message: string;
  busy: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}>;

export const EnableCustomMarkingsGate = ({
  open,
  allowCustomTab,
  message,
  busy,
  onConfirm,
  onCancel,
}: EnableCustomMarkingsGateProps) => {
  if (!open || allowCustomTab) {
    return null;
  }
  return (
    <EnableCustomMarkingsOverlay
      message={message}
      busy={busy}
      onConfirm={onConfirm}
      onCancel={onCancel}
    />
  );
};
