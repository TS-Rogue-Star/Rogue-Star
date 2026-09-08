// //////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Reference opacity helpers for custom marking designer //
// //////////////////////////////////////////////////////////////////////////////////////////////////////

import { GENERIC_PART_KEY } from '../../../utils/character-preview';
import {
  DEFAULT_BODY_PART_REFERENCE_OPACITY,
  DEFAULT_GENERIC_REFERENCE_OPACITY,
} from '../constants';
import type { CustomMarkingDesignerData } from '../types';
import { buildReferenceOpacityMapForDesigner } from './previewState';

const OVERLAY_PART_KEY = 'overlay';
const HEAD_PART_KEY = 'head';

export type ReferenceOpacityControls = Readonly<{
  currentReferenceOpacity: number;
  genericReferenceOpacity: number;
  resolvedReferenceOpacityMap: Record<string, number>;
  getReferenceOpacityForPart: (partId: string) => number;
  setReferenceOpacityForPart: (partId: string, value: number) => void;
}>;

export const createReferenceOpacityControls = ({
  referenceOpacityByPart,
  setReferenceOpacityByPart,
  referenceParts,
  bodyParts,
  showJobGear,
  showLoadoutGear,
  activePartKey,
}: {
  referenceOpacityByPart: Record<string, number>;
  setReferenceOpacityByPart: (map: Record<string, number>) => void;
  referenceParts: any;
  bodyParts: CustomMarkingDesignerData['body_parts'];
  showJobGear: boolean;
  showLoadoutGear: boolean;
  activePartKey: string;
}): ReferenceOpacityControls => {
  const getDefaultReferenceOpacityForPart = (partId: string) =>
    partId === GENERIC_PART_KEY
      ? DEFAULT_GENERIC_REFERENCE_OPACITY
      : DEFAULT_BODY_PART_REFERENCE_OPACITY;

  const getReferenceOpacityForPart = (partId: string) => {
    const targetId =
      partId === OVERLAY_PART_KEY ? GENERIC_PART_KEY : partId || HEAD_PART_KEY;
    const stored = referenceOpacityByPart[targetId];
    if (typeof stored === 'number') {
      return stored;
    }
    return getDefaultReferenceOpacityForPart(targetId);
  };

  const setReferenceOpacityForPart = (partId: string, value: number) => {
    const clamped = Math.min(1, Math.max(0, value));
    const targetId =
      partId === OVERLAY_PART_KEY ? GENERIC_PART_KEY : partId || HEAD_PART_KEY;
    setReferenceOpacityByPart({
      ...referenceOpacityByPart,
      [targetId]: clamped,
    });
  };

  const currentReferenceOpacity = getReferenceOpacityForPart(activePartKey);
  const genericReferenceOpacity = getReferenceOpacityForPart(GENERIC_PART_KEY);

  const referenceOpacityMap = buildReferenceOpacityMapForDesigner(
    referenceParts,
    bodyParts,
    getReferenceOpacityForPart
  );
  const resolvedReferenceOpacityMap: Record<string, number> = {
    ...referenceOpacityMap,
    overlay: genericReferenceOpacity,
  };
  if (referenceParts?.markings) {
    resolvedReferenceOpacityMap.markings = genericReferenceOpacity;
  }
  if (referenceParts?.gear_job) {
    resolvedReferenceOpacityMap.gear_job = showJobGear
      ? genericReferenceOpacity
      : 0;
  }
  if (referenceParts?.gear_loadout) {
    resolvedReferenceOpacityMap.gear_loadout = showLoadoutGear
      ? genericReferenceOpacity
      : 0;
  }

  return {
    currentReferenceOpacity,
    genericReferenceOpacity,
    resolvedReferenceOpacityMap,
    getReferenceOpacityForPart,
    setReferenceOpacityForPart,
  };
};
