// /////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: UI state for custom marking designer //
// /////////////////////////////////////////////////////////////////////////////////////

import { useLocalState } from '../../backend';
import type { PreviewState } from '../../utils/character-preview';
import { buildDefaultCustomColorSlots } from './utils';
import type { CustomColorSlotsState, PendingCloseMessage, SavingProgressState } from './types';

type Setter<T> = (value: T) => void;

export type DesignerUiState = {
  size: number;
  setSize: Setter<number>;
  blendMode: string;
  setBlendMode: Setter<string>;
  analogStrength: number;
  setAnalogStrength: Setter<number>;
  draftSequence: number;
  setDraftSequence: Setter<number>;
  allocateDraftSequence: () => number;
  canvasFlushToken: number;
  setCanvasFlushToken: Setter<number>;
  pendingClose: boolean;
  setPendingClose: Setter<boolean>;
  pendingSave: boolean;
  setPendingSave: Setter<boolean>;
  pendingCloseMessage: PendingCloseMessage | null;
  setPendingCloseMessage: Setter<PendingCloseMessage | null>;
  customColorSlots: CustomColorSlotsState;
  setCustomColorSlots: Setter<CustomColorSlotsState>;
  colorPickerSlotsSignature: string | null;
  setColorPickerSlotsSignature: Setter<string | null>;
  colorPickerSlotsLocked: boolean;
  setColorPickerSlotsLocked: Setter<boolean>;
  referenceOpacityByPart: Record<string, number>;
  setReferenceOpacityByPart: Setter<Record<string, number>>;
  previewState: PreviewState;
  setPreviewState: Setter<PreviewState>;
  assetRevision: number;
  setAssetRevision: Setter<number>;
  savingProgress: SavingProgressState | null;
  setSavingProgress: Setter<SavingProgressState | null>;
};

export const useDesignerUiState = (
  context: any,
  stateToken: string
): DesignerUiState => {
  const [size, setSize] = useLocalState(context, `size-${stateToken}`, 1);
  const [blendMode, setBlendMode] = useLocalState(
    context,
    `blendMode-${stateToken}`,
    'analog'
  );
  const [analogStrength, setAnalogStrength] = useLocalState(
    context,
    `analogStrength-${stateToken}`,
    1
  );
  const [draftSequence, setDraftSequence] = useLocalState(
    context,
    `strokeDraftSequence-${stateToken}`,
    0
  );
  const allocateDraftSequence = () => {
    const nextValue = (draftSequence + 1) % 1000000;
    setDraftSequence(nextValue);
    return nextValue;
  };
  const [canvasFlushToken, setCanvasFlushToken] = useLocalState(
    context,
    `canvasFlushToken-${stateToken}`,
    0
  );
  const [pendingClose, setPendingClose] = useLocalState(
    context,
    `pendingClose-${stateToken}`,
    false
  );
  const [pendingSave, setPendingSave] = useLocalState(
    context,
    `pendingSave-${stateToken}`,
    false
  );
  const [pendingCloseMessage, setPendingCloseMessage] =
    useLocalState<PendingCloseMessage | null>(
      context,
      `pendingCloseMessage-${stateToken}`,
      null
    );
  const [customColorSlots, setCustomColorSlots] =
    useLocalState<CustomColorSlotsState>(
      context,
      'colorPickerCustomColors',
      buildDefaultCustomColorSlots()
    );
  const [colorPickerSlotsSignature, setColorPickerSlotsSignature] =
    useLocalState<string | null>(
      context,
      `colorPickerSlotsSignature-${stateToken}`,
      null
    );
  const [colorPickerSlotsLocked, setColorPickerSlotsLocked] =
    useLocalState<boolean>(
      context,
      `colorPickerSlotsLocked-${stateToken}`,
      false
    );
  const [referenceOpacityByPart, setReferenceOpacityByPart] = useLocalState<
    Record<string, number>
  >(context, `referenceOpacityByPart-${stateToken}`, {});
  const [previewState, setPreviewState] = useLocalState<PreviewState>(
    context,
    `previewState-${stateToken}`,
    {
      revision: 0,
      lastDiffSeq: 0,
      dirs: {},
    }
  );
  const [assetRevision, setAssetRevision] = useLocalState(
    context,
    `previewAssetRevision-${stateToken}`,
    0
  );
  const [savingProgress, setSavingProgress] =
    useLocalState<SavingProgressState | null>(
      context,
      `savingProgress-${stateToken}`,
      null
    );
  return {
    size,
    setSize,
    blendMode,
    setBlendMode,
    analogStrength,
    setAnalogStrength,
    draftSequence,
    setDraftSequence,
    allocateDraftSequence,
    canvasFlushToken,
    setCanvasFlushToken,
    pendingClose,
    setPendingClose,
    pendingSave,
    setPendingSave,
    pendingCloseMessage,
    setPendingCloseMessage,
    customColorSlots,
    setCustomColorSlots,
    colorPickerSlotsSignature,
    setColorPickerSlotsSignature,
    colorPickerSlotsLocked,
    setColorPickerSlotsLocked,
    referenceOpacityByPart,
    setReferenceOpacityByPart,
    previewState,
    setPreviewState,
    assetRevision,
    setAssetRevision,
    savingProgress,
    setSavingProgress,
  };
};
