// ////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Brush color helpers for custom marking designer //
// ////////////////////////////////////////////////////////////////////////////////////////////////

import { useLocalState } from '../../../backend';
import { normalizeHex } from '../../../utils/color';
import { DEFAULT_BRUSH_HEX } from '../constants';

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
