// //////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Hooks for custom marking designer //
// //////////////////////////////////////////////////////////////////////////////////

import { useLocalState } from '../../backend';
import { normalizeHex } from '../../utils/color';
import { DEFAULT_BRUSH_HEX } from './constants';

const normalizeBrushHexValue = (value?: string | null): string | null => {
  const normalized = normalizeHex(value);
  return normalized ? normalized.toUpperCase() : null;
};

export type BrushColorController = {
  brushColor: string;
  applyBrushColorChange: (hex: string | null | undefined) => Promise<void>;
};

export const useBrushColorController = (
  context: any,
  stateToken: string
): BrushColorController => {
  const brushColorStateKey = `brushColor-${stateToken}`;
  const [storedBrushColor, setBrushColorState] = useLocalState<string | null>(
    context,
    brushColorStateKey,
    DEFAULT_BRUSH_HEX
  );
  const effectiveBrushColor = storedBrushColor || DEFAULT_BRUSH_HEX;
  const applyBrushColorChange = async (hex: string | null | undefined) => {
    const normalized = normalizeBrushHexValue(hex);
    if (!normalized) {
      return;
    }
    setBrushColorState(normalized);
  };
  return {
    brushColor: effectiveBrushColor,
    applyBrushColorChange,
  };
};

const resolveCurrentDirectionKey = (
  serverDirection: number,
  uiDirection: number | undefined,
  snapshot: number,
  setSnapshot: (dir: number) => void,
  setUiDirection: (dir: number) => void
): number => {
  if (snapshot !== serverDirection) {
    setSnapshot(serverDirection);
    if (typeof uiDirection !== 'number' || uiDirection === snapshot) {
      setUiDirection(serverDirection);
      return serverDirection;
    }
  }
  return typeof uiDirection === 'number' ? uiDirection : serverDirection;
};

export const useSyncedDirectionState = (
  context: any,
  sessionToken: string | null,
  serverDirection: number
) => {
  const directionStateKey = `uiDirection-${sessionToken || 'session'}`;
  const [uiDirectionKey, setUiDirectionKey] = useLocalState(
    context,
    directionStateKey,
    serverDirection
  );
  const directionSnapshotKey = `serverDirectionSnapshot-${
    sessionToken || 'session'
  }`;
  const [serverDirectionSnapshot, setServerDirectionSnapshot] = useLocalState(
    context,
    directionSnapshotKey,
    serverDirection
  );
  const currentDirectionKey = resolveCurrentDirectionKey(
    serverDirection,
    uiDirectionKey,
    serverDirectionSnapshot,
    setServerDirectionSnapshot,
    setUiDirectionKey
  );
  return {
    currentDirectionKey,
    setUiDirectionKey,
  };
};
