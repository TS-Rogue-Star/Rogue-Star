// /////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Expression //
// /////////////////////////////////////////////////////////////////////////////////

export type SizeWeightState = {
  size_multiplier: number;
  fuzzy: boolean;
  offset_override: boolean;
  weight_vr: number;
  weight_gain: number;
  weight_loss: number;
};

export type SizeWeightLimits = {
  scale_min: number;
  scale_max: number;
  weight_min: number;
  weight_max: number;
  rate_min: number;
  rate_max: number;
};

export type SpeciesPreviewTransform = {
  icon_scale_x: number;
  icon_scale_y: number;
  center_offset: number;
};

export type LivePreviewTransform = {
  scaleX: number;
  scaleY: number;
  offsetX: number;
  fuzzy: boolean;
};

export type WeightUnit = 'lb' | 'kg';

export const POUNDS_PER_KILOGRAM = 2.20462;

export const DEFAULT_SIZE_WEIGHT: SizeWeightState = {
  size_multiplier: 1,
  fuzzy: false,
  offset_override: true,
  weight_vr: 137,
  weight_gain: 100,
  weight_loss: 50,
};

export const DEFAULT_SIZE_WEIGHT_LIMITS: SizeWeightLimits = {
  scale_min: 25,
  scale_max: 200,
  weight_min: 70,
  weight_max: 500,
  rate_min: 0,
  rate_max: 100,
};

export const clampSizeWeightNumber = (
  value: number,
  minimum: number,
  maximum: number
) => Math.min(maximum, Math.max(minimum, value));

const numberOrDefault = (value: unknown, fallback: number) =>
  typeof value === 'number' && Number.isFinite(value) ? value : fallback;

export const buildSizeWeightState = (
  values?: Partial<SizeWeightState> | null
): SizeWeightState => ({
  size_multiplier: numberOrDefault(values?.size_multiplier, 1),
  fuzzy: !!(values?.fuzzy ?? DEFAULT_SIZE_WEIGHT.fuzzy),
  offset_override: !!(
    values?.offset_override ?? DEFAULT_SIZE_WEIGHT.offset_override
  ),
  weight_vr: numberOrDefault(values?.weight_vr, DEFAULT_SIZE_WEIGHT.weight_vr),
  weight_gain: numberOrDefault(
    values?.weight_gain,
    DEFAULT_SIZE_WEIGHT.weight_gain
  ),
  weight_loss: numberOrDefault(
    values?.weight_loss,
    DEFAULT_SIZE_WEIGHT.weight_loss
  ),
});

export const buildSizeWeightSaveParams = (state: SizeWeightState) => ({
  ...buildSizeWeightState(state),
  fuzzy: state.fuzzy ? 1 : 0,
  offset_override: state.offset_override ? 1 : 0,
});

export const retainSizeWeightDraft = (
  incoming: SizeWeightState,
  draft?: SizeWeightState,
  saved?: SizeWeightState
): SizeWeightState => {
  const result = buildSizeWeightState(incoming);
  if (draft && saved) {
    for (const key of Object.keys(
      DEFAULT_SIZE_WEIGHT
    ) as (keyof SizeWeightState)[]) {
      if (draft[key] !== saved[key]) {
        Object.assign(result, { [key]: draft[key] });
      }
    }
  }
  return result;
};

export const displayRelativeWeight = (pounds: number, unit: WeightUnit) =>
  unit === 'kg' ? pounds / POUNDS_PER_KILOGRAM : pounds;

export const storeRelativeWeight = (
  value: number,
  unit: WeightUnit,
  limits: SizeWeightLimits = DEFAULT_SIZE_WEIGHT_LIMITS
) =>
  clampSizeWeightNumber(
    Math.round(unit === 'kg' ? value * POUNDS_PER_KILOGRAM : value),
    limits.weight_min,
    limits.weight_max
  );

const positiveScale = (value?: number) =>
  typeof value === 'number' && Number.isFinite(value) && value > 0 ? value : 1;

export const resolveLivePreviewTransform = (
  values: Partial<SizeWeightState> | null | undefined,
  species: SpeciesPreviewTransform | null | undefined,
  direction: number,
  iconScaleX?: number,
  iconScaleY?: number
): LivePreviewTransform => {
  const state = buildSizeWeightState(values);
  const size = positiveScale(state.size_multiplier);
  const scaleX =
    size * positiveScale(iconScaleX) * positiveScale(species?.icon_scale_x);
  const scaleY =
    size * positiveScale(iconScaleY) * positiveScale(species?.icon_scale_y);
  const center =
    state.fuzzy || state.offset_override || direction === 4 || direction === 8
      ? 0
      : numberOrDefault(species?.center_offset, 0.5);
  return { scaleX, scaleY, offsetX: center * scaleX, fuzzy: state.fuzzy };
};

export const livePreviewTransformSignature = (
  transform?: LivePreviewTransform
) =>
  transform
    ? `${transform.scaleX}|${transform.scaleY}|${transform.offsetX}|${transform.fuzzy}`
    : '';

export const livePreviewCanvasSize = (
  width: number,
  height: number,
  pixelSize: number,
  transform?: LivePreviewTransform
) => ({
  width:
    (width +
      2 *
        Math.ceil(
          (width * Math.max(0, (transform?.scaleX || 1) - 1)) / 2 +
            Math.abs(transform?.offsetX || 0)
        )) *
    pixelSize,
  height: Math.ceil(height * Math.max(1, transform?.scaleY || 1)) * pixelSize,
});

export const livePreviewSourceColumn = (
  column: number,
  sourceWidth: number,
  targetWidth: number,
  transform: LivePreviewTransform
) => {
  const sourceColumn =
    sourceWidth / 2 +
    (column + 0.5 - targetWidth / 2 - Math.fround(transform.offsetX)) /
      Math.fround(transform.scaleX);
  return !transform.offsetX && column + 0.5 < targetWidth / 2
    ? Math.ceil(sourceColumn) - 1
    : Math.floor(sourceColumn);
};
