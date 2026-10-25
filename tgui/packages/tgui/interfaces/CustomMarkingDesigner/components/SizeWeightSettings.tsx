// /////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Expression //
// /////////////////////////////////////////////////////////////////////////////////

import type { InfernoNode } from 'inferno';
import { useLocalState } from '../../../backend';
import {
  Box,
  Button,
  LabeledList,
  NumberInput,
  Section,
} from '../../../components';
import { CHIP_BUTTON_CLASS } from '../constants';
import {
  clampSizeWeightNumber,
  displayRelativeWeight,
  storeRelativeWeight,
  type SizeWeightLimits,
  type SizeWeightState,
  type WeightUnit,
} from '../utils/sizeWeight';

type SizeWeightSettingsProps = Readonly<{
  state: SizeWeightState;
  limits: SizeWeightLimits;
  disabled: boolean;
  onChange: (values: Partial<SizeWeightState>) => void;
  persistenceControl?: InfernoNode;
}>;

export const SizeSettings = ({
  state,
  limits,
  disabled,
  onChange,
  persistenceControl,
}: SizeWeightSettingsProps) => (
  <Box
    as="fieldset"
    disabled={disabled}
    style={{
      border: 0,
      padding: 0,
      margin: 0,
      pointerEvents: disabled ? 'none' : undefined,
      opacity: disabled ? 0.5 : 1,
    }}>
    <LabeledList>
      <LabeledList.Item label="Scale" buttons={persistenceControl}>
        <NumberInput
          className="RogueStar__numberInput"
          width="100px"
          value={Number((state.size_multiplier * 100).toFixed(10))}
          minValue={limits.scale_min}
          maxValue={limits.scale_max}
          step={1}
          unit="%"
          disabled={disabled}
          onChange={(_event, value) => {
            if (typeof value === 'number' && Number.isFinite(value)) {
              onChange({
                size_multiplier:
                  clampSizeWeightNumber(
                    value,
                    limits.scale_min,
                    limits.scale_max
                  ) / 100,
              });
            }
          }}
        />
      </LabeledList.Item>
      <LabeledList.Item label="Scaled Appearance">
        {[false, true].map((fuzzy) => (
          <Button
            key={String(fuzzy)}
            className={CHIP_BUTTON_CLASS}
            selected={state.fuzzy === fuzzy}
            disabled={disabled}
            onClick={() => onChange({ fuzzy })}>
            {fuzzy ? 'Fuzzy' : 'Sharp'}
          </Button>
        ))}
      </LabeledList.Item>
      <LabeledList.Item label="Scaling Center">
        {[true, false].map((offset_override) => (
          <Button
            key={String(offset_override)}
            className={CHIP_BUTTON_CLASS}
            selected={state.offset_override === offset_override}
            disabled={disabled}
            onClick={() => onChange({ offset_override })}>
            {offset_override ? 'Odd' : 'Even'}
          </Button>
        ))}
      </LabeledList.Item>
    </LabeledList>
  </Box>
);

export const WeightSettings = (
  props: SizeWeightSettingsProps & {
    readonly stateToken: string;
  },
  context
) => {
  const { state, limits, disabled, onChange, stateToken } = props;
  const [unit, setUnit] = useLocalState<WeightUnit>(
    context,
    `sizeWeightUnit-${stateToken}`,
    'lb'
  );
  return (
    <Section title="Weight">
      <Box
        as="fieldset"
        disabled={disabled}
        style={{
          border: 0,
          padding: 0,
          margin: 0,
          pointerEvents: disabled ? 'none' : undefined,
          opacity: disabled ? 0.5 : 1,
        }}>
        <LabeledList>
          <LabeledList.Item
            label="Relative Weight"
            buttons={props.persistenceControl}>
            <NumberInput
              key={unit}
              className="RogueStar__numberInput"
              width="100px"
              value={displayRelativeWeight(state.weight_vr, unit)}
              minValue={displayRelativeWeight(limits.weight_min, unit)}
              maxValue={displayRelativeWeight(limits.weight_max, unit)}
              step={unit === 'kg' ? 0.1 : 1}
              format={(value) => value.toFixed(unit === 'kg' ? 1 : 0)}
              unit={unit}
              disabled={disabled}
              onChange={(_event, value) => {
                if (typeof value === 'number' && Number.isFinite(value)) {
                  onChange({
                    weight_vr: storeRelativeWeight(value, unit, limits),
                  });
                }
              }}
            />
            {(['lb', 'kg'] as const).map((choice) => (
              <Button
                key={choice}
                className={CHIP_BUTTON_CLASS}
                selected={unit === choice}
                disabled={disabled}
                onClick={() => setUnit(choice)}>
                {choice}
              </Button>
            ))}
          </LabeledList.Item>
          {(['weight_gain', 'weight_loss'] as const).map((key) => (
            <LabeledList.Item
              key={key}
              label={
                key === 'weight_gain' ? 'Weight Gain Rate' : 'Weight Loss Rate'
              }>
              <NumberInput
                className="RogueStar__numberInput"
                width="100px"
                value={state[key]}
                minValue={limits.rate_min}
                maxValue={limits.rate_max}
                step={1}
                unit="%"
                disabled={disabled}
                onChange={(_event, value) => {
                  if (typeof value === 'number' && Number.isFinite(value)) {
                    onChange({
                      [key]: Math.round(
                        clampSizeWeightNumber(
                          value,
                          limits.rate_min,
                          limits.rate_max
                        )
                      ),
                    });
                  }
                }}
              />
            </LabeledList.Item>
          ))}
        </LabeledList>
      </Box>
      <Box mt={1} color="label">
        Relative weight describes a standard 5′10″ body, independently of your
        character’s scale. Set a rate to 0% to disable that weight change.
      </Box>
    </Section>
  );
};
