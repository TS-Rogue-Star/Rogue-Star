// ///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Preview initialization helpers for custom marking designer //
// ///////////////////////////////////////////////////////////////////////////////////////////////////////////

import type { CustomMarkingDesignerData } from '../types';

export const areAllPreviewLayersLoaded = ({
  previewRevision,
  renderedPreviewDirs,
  directions,
}: {
  previewRevision: number;
  renderedPreviewDirs: ReadonlyArray<any>;
  directions: CustomMarkingDesignerData['directions'];
}) =>
  previewRevision > 0 &&
  renderedPreviewDirs.length > 0 &&
  directions.every((dir) =>
    renderedPreviewDirs.some((entry) => entry.dir === dir.dir)
  );

type PreviewInitializationParams = Readonly<{
  loadingOverlay: boolean;
  allPreviewLayersLoaded: boolean;
  previewRevision: number;
  loadingOverlayTargetRevision: number;
  loadingOverlayMinUntil: number;
  referenceBuildInProgress: boolean;
  setLoadingOverlay: (value: boolean) => void;
  colorPickerSlotsLocked: boolean;
  colorPickerSlotsSignature: string | null;
  setColorPickerSlotsLocked: (value: boolean) => void;
}>;

export const applyPreviewInitialization = ({
  loadingOverlay,
  allPreviewLayersLoaded,
  previewRevision,
  loadingOverlayTargetRevision,
  loadingOverlayMinUntil,
  referenceBuildInProgress,
  setLoadingOverlay,
  colorPickerSlotsLocked,
  colorPickerSlotsSignature,
  setColorPickerSlotsLocked,
}: PreviewInitializationParams) => {
  const targetSatisfied =
    !loadingOverlayTargetRevision ||
    previewRevision >= loadingOverlayTargetRevision;
  if (
    loadingOverlay &&
    allPreviewLayersLoaded &&
    targetSatisfied &&
    !referenceBuildInProgress
  ) {
    const now = Date.now();
    const minDelay =
      loadingOverlayMinUntil && loadingOverlayMinUntil > now
        ? loadingOverlayMinUntil - now
        : 0;
    setTimeout(() => setLoadingOverlay(false), Math.max(50, minDelay));
  }

  if (
    allPreviewLayersLoaded &&
    !colorPickerSlotsLocked &&
    colorPickerSlotsSignature
  ) {
    setColorPickerSlotsLocked(true);
  }
};
