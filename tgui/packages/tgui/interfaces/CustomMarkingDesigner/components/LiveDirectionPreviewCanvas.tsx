// //////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Size and Weight //
// //////////////////////////////////////////////////////////////////////////////////////

import { useBackend } from '../../../backend';
import { SOUTH } from '../constants';
import type {
  BasicAppearancePayload,
  BasicAppearanceState,
  CustomMarkingDesignerData,
  SpeciesPayload,
} from '../types';
import { resolveLivePreviewTransform } from '../utils/sizeWeight';
import {
  DirectionPreviewCanvas,
  type DirectionPreviewCanvasProps,
} from './DirectionPreviewCanvas';

export const LiveDirectionPreviewCanvas = (
  props: DirectionPreviewCanvasProps & {
    readonly direction: number;
    readonly showSizeOptions?: boolean;
  },
  context
) => {
  const { data, shared } = useBackend<CustomMarkingDesignerData>(context);
  const basicPayload = shared?.basicPayload as
    BasicAppearancePayload | undefined;
  const draft = shared?.basicAppearanceState as
    BasicAppearanceState | undefined;
  const speciesPayload = shared?.speciesPayload as SpeciesPayload | undefined;
  const speciesPreview =
    shared?.customMarkingTab === 'species'
      ? speciesPayload?.species.find(
          (entry) =>
            entry.id ===
            (shared?.speciesSelection || speciesPayload.selected_species)
        )?.preview_transform
      : null;
  const transform = resolveLivePreviewTransform(
    props.showSizeOptions ? draft || basicPayload || data.size_weight : null,
    speciesPreview || basicPayload?.preview_transform || data.preview_transform,
    SOUTH,
    props.iconScaleX,
    props.iconScaleY
  );
  return <DirectionPreviewCanvas {...props} characterTransform={transform} />;
};
