// ///////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Color slot helpers for custom marking designer //
// ///////////////////////////////////////////////////////////////////////////////////////////////

import { buildColorSignatureFromCounts, buildSuggestedColorsFromCounts, collectPreviewColorCounts, hasPreviewLayerContent } from '../../../utils/character-preview';
import { COLOR_PICKER_CUSTOM_SLOTS } from '../constants';
import type { ColorPickerInitOptions, CustomColorSlotsState } from '../types';

export const buildDefaultCustomColorSlots = (): CustomColorSlotsState =>
  Array.from(
    { length: COLOR_PICKER_CUSTOM_SLOTS },
    () => null as string | null
  );

export const initializeColorPickerSlotsIfNeeded = ({
  locked,
  previewDirs,
  customSlots,
  setCustomSlots,
  previewRevision,
  colorSignature,
  setColorSignature,
}: ColorPickerInitOptions) => {
  if (locked || !previewRevision) {
    return;
  }
  if (!hasPreviewLayerContent(previewDirs)) {
    return;
  }
  const colorCounts = collectPreviewColorCounts(previewDirs);
  if (!colorCounts.size) {
    return;
  }
  const signature = buildColorSignatureFromCounts(colorCounts);
  if (!signature || signature === colorSignature) {
    return;
  }
  const suggestedColors = buildSuggestedColorsFromCounts(
    colorCounts,
    COLOR_PICKER_CUSTOM_SLOTS
  );
  if (suggestedColors.length) {
    const slotCount = Array.isArray(customSlots)
      ? customSlots.length
      : COLOR_PICKER_CUSTOM_SLOTS;
    const nextSlots = locked
      ? mergeSuggestedColorsIntoSlots(customSlots, suggestedColors)
      : buildSuggestedSlotsFromColors(suggestedColors, slotCount);
    if (!areCustomColorSlotsEqual(nextSlots, customSlots)) {
      setCustomSlots(nextSlots);
    }
  }
  setColorSignature(signature);
};

export const mergeSuggestedColorsIntoSlots = (
  existing: CustomColorSlotsState,
  suggestions: string[]
): CustomColorSlotsState => {
  const result: CustomColorSlotsState = Array.isArray(existing)
    ? [...existing]
    : buildDefaultCustomColorSlots();
  let slotIndex = 0;
  for (const color of suggestions) {
    if (!color) {
      continue;
    }
    if (result.includes(color)) {
      continue;
    }
    while (slotIndex < result.length && result[slotIndex]) {
      slotIndex += 1;
    }
    if (slotIndex >= result.length) {
      break;
    }
    result[slotIndex] = color;
    slotIndex += 1;
  }
  return result;
};

export const buildSuggestedSlotsFromColors = (
  suggestions: string[],
  slotCount: number
): CustomColorSlotsState => {
  const count = Math.max(COLOR_PICKER_CUSTOM_SLOTS, slotCount || 0);
  const result: CustomColorSlotsState = Array.from(
    { length: count },
    () => null
  );
  for (let i = 0; i < result.length && i < suggestions.length; i += 1) {
    result[i] = suggestions[i];
  }
  return result;
};

export const areCustomColorSlotsEqual = (
  a: CustomColorSlotsState,
  b: CustomColorSlotsState
): boolean => {
  if (a === b) {
    return true;
  }
  if (!a || !b || a.length !== b.length) {
    return false;
  }
  for (let i = 0; i < a.length; i += 1) {
    if (a[i] !== b[i]) {
      return false;
    }
  }
  return true;
};
