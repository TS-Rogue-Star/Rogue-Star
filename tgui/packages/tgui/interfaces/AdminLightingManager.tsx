// ////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star October 2025: New panel for managing lighting ///
// ////////////////////////////////////////////////////////////////////////////////

import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  ColorBox,
  LabeledList,
  NoticeBox,
  NumberInput,
  Section,
  Stack,
} from '../components';
import { Window } from '../layouts';

type LightingSummary = {
  total: number;
  total_ceiling: number;
  total_floor: number;
};

type LightingZLevel = {
  id: number;
  label: string;
  total: number;
  ceiling_count: number;
  floor_count: number;
};

type LightingTarget = {
  id: string;
  label: string;
  description?: string;
};

type LightingData = {
  z_levels: LightingZLevel[];
  target_options: LightingTarget[];
  default_z: number[];
  default_targets: string[];
  last_result: string;
  last_changed: number;
  last_considered: number;
  summary: LightingSummary;
  light_color_pick?: string;
  overlay_color_pick?: string;
  light_color_revision?: number;
  overlay_color_revision?: number;
};

const toggleItem = function <T>(list: T[], value: T) {
  if (list.includes(value)) {
    return list.filter((entry) => entry !== value);
  }
  return [...list, value];
};

export const AdminLightingManager = (props, context) => {
  const { act, data } = useBackend<LightingData>(context);
  const {
    z_levels = [],
    target_options = [],
    default_z = [],
    default_targets = [],
    summary,
    last_result,
    last_changed,
    last_considered,
  } = data;

  const initialZ =
    default_z.length > 0
      ? default_z
      : z_levels.slice(0, Math.min(3, z_levels.length)).map((z) => z.id);
  const [selectedZ, setSelectedZ] = useLocalState<number[]>(
    context,
    'lightingZLevels',
    initialZ
  );

  const initialTargets =
    default_targets.length > 0
      ? default_targets
      : target_options.map((target) => target.id);
  const [selectedTargets, setSelectedTargets] = useLocalState<string[]>(
    context,
    'lightingTargets',
    initialTargets
  );

  const [applyRange, setApplyRange] = useLocalState<boolean>(
    context,
    'lightingApplyRange',
    true
  );
  const [rangeValue, setRangeValue] = useLocalState<number>(
    context,
    'lightingRange',
    6
  );

  const [applyPower, setApplyPower] = useLocalState<boolean>(
    context,
    'lightingApplyPower',
    true
  );
  const [powerValue, setPowerValue] = useLocalState<number>(
    context,
    'lightingPower',
    1
  );

  const [applyLightColor, setApplyLightColor] = useLocalState<boolean>(
    context,
    'lightingApplyLightColor',
    true
  );

  const [applyOverlayColor, setApplyOverlayColor] = useLocalState<boolean>(
    context,
    'lightingApplyOverlay',
    true
  );

  const [triggerSpark, setTriggerSpark] = useLocalState<boolean>(
    context,
    'lightingTriggerSpark',
    false
  );
  const [triggerFlicker, setTriggerFlicker] = useLocalState<boolean>(
    context,
    'lightingTriggerFlicker',
    false
  );

  const lightColor = data.light_color_pick || '#E0EFF0';
  const overlayColor = data.overlay_color_pick || '#E0EFF0';

  const sortedZ = [...selectedZ].sort((a, b) => a - b);
  const nothingSelected =
    !applyRange &&
    !applyPower &&
    !applyLightColor &&
    !applyOverlayColor &&
    !triggerSpark &&
    !triggerFlicker;
  const applyDisabled =
    selectedZ.length === 0 || selectedTargets.length === 0 || nothingSelected;

  const applyChanges = () => {
    act('apply', {
      z_levels: sortedZ,
      targets: selectedTargets,
      apply_range: applyRange,
      range: rangeValue,
      apply_power: applyPower,
      power: powerValue,
      apply_light_color: applyLightColor,
      light_color: lightColor,
      apply_overlay_color: applyOverlayColor,
      overlay_color: overlayColor,
      trigger_spark: triggerSpark,
      trigger_flicker: triggerFlicker,
    });
    if (triggerSpark) {
      setTriggerSpark(false);
    }
    if (triggerFlicker) {
      setTriggerFlicker(false);
    }
  };
  const restoreDisabled =
    selectedZ.length === 0 || selectedTargets.length === 0;

  const restoreDefaults = () =>
    act('restore_defaults', {
      z_levels: sortedZ,
      targets: selectedTargets,
    });

  return (
    <Window width={520} height={640} resizable>
      <Window.Content scrollable>
        <Section title="World Snapshot">
          <LabeledList>
            <LabeledList.Item label="Ceiling Fixtures">
              {summary?.total_ceiling ?? 0}
            </LabeledList.Item>
            <LabeledList.Item label="Floor Tubes">
              {summary?.total_floor ?? 0}
            </LabeledList.Item>
            <LabeledList.Item label="Total Lights">
              {summary?.total ?? 0}
            </LabeledList.Item>
            {last_result && (
              <LabeledList.Item label="Last Action">
                <NoticeBox
                  success={last_changed > 0}
                  info={last_changed === 0 && last_considered > 0}
                  danger={last_considered === 0}>
                  {last_result}
                </NoticeBox>
              </LabeledList.Item>
            )}
          </LabeledList>
        </Section>

        <Section
          title="Z Levels"
          buttons={
            <Stack>
              <Stack.Item>
                <Button
                  content="Default"
                  onClick={() => setSelectedZ([...initialZ])}
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  content="All"
                  onClick={() => setSelectedZ(z_levels.map((z) => z.id))}
                />
              </Stack.Item>
              <Stack.Item>
                <Button content="Clear" onClick={() => setSelectedZ([])} />
              </Stack.Item>
            </Stack>
          }>
          <Stack wrap>
            {z_levels.map((zLevel) => (
              <Stack.Item key={zLevel.id}>
                <Button
                  selected={selectedZ.includes(zLevel.id)}
                  content={zLevel.label}
                  tooltip={`Total: ${zLevel.total}\nCeiling: ${zLevel.ceiling_count}\nFloor: ${zLevel.floor_count}`}
                  onClick={() => {
                    const updated = toggleItem(selectedZ, zLevel.id);
                    setSelectedZ([...updated].sort((a, b) => a - b));
                  }}
                />
              </Stack.Item>
            ))}
          </Stack>
        </Section>

        <Section
          title="Fixture Types"
          buttons={
            <Stack>
              <Stack.Item>
                <Button
                  content="Default"
                  onClick={() => setSelectedTargets([...initialTargets])}
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  content="All"
                  onClick={() =>
                    setSelectedTargets(
                      target_options.map((target) => target.id)
                    )
                  }
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  content="Clear"
                  onClick={() => setSelectedTargets([])}
                />
              </Stack.Item>
            </Stack>
          }>
          <Stack wrap>
            {target_options.map((target) => (
              <Stack.Item key={target.id}>
                <Button
                  selected={selectedTargets.includes(target.id)}
                  content={target.label}
                  tooltip={target.description}
                  onClick={() =>
                    setSelectedTargets(toggleItem(selectedTargets, target.id))
                  }
                />
              </Stack.Item>
            ))}
          </Stack>
        </Section>

        <Section
          title="Adjustments"
          buttons={
            <Button
              icon="sync-alt"
              content="Overlay = Light"
              tooltip="Copy the light color into the overlay color field."
              onClick={() => act('set_overlay_color', { color: lightColor })}
            />
          }>
          <LabeledList>
            <LabeledList.Item
              label="Brightness Range"
              buttons={
                <Button
                  icon={applyRange ? 'check-square' : 'square'}
                  selected={applyRange}
                  onClick={() => setApplyRange(!applyRange)}
                />
              }>
              <NumberInput
                value={rangeValue}
                minValue={0}
                maxValue={7}
                stepPixelSize={5}
                onChange={(e, value) =>
                  setRangeValue(Math.max(0, Math.min(value, 7)))
                }
              />
            </LabeledList.Item>

            <LabeledList.Item
              label="Brightness Power"
              buttons={
                <Button
                  icon={applyPower ? 'check-square' : 'square'}
                  selected={applyPower}
                  onClick={() => setApplyPower(!applyPower)}
                />
              }>
              <NumberInput
                value={powerValue}
                minValue={0}
                maxValue={10}
                step={0.1}
                stepPixelSize={7}
                onChange={(e, value) => setPowerValue(value)}
              />
            </LabeledList.Item>

            <LabeledList.Item
              label="Light Color"
              buttons={
                <Button
                  icon={applyLightColor ? 'check-square' : 'square'}
                  selected={applyLightColor}
                  onClick={() => setApplyLightColor(!applyLightColor)}
                />
              }>
              <Stack align="center" spacing={1}>
                <Stack.Item>
                  <ColorBox color={lightColor} width={3} height={1.25} />
                </Stack.Item>
                <Stack.Item grow>
                  <Box monospace>{lightColor}</Box>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="eyedropper"
                    onClick={() =>
                      act('pick_light_color', { current: lightColor })
                    }>
                    Pick…
                  </Button>
                </Stack.Item>
              </Stack>
            </LabeledList.Item>

            <LabeledList.Item
              label="Overlay Color"
              buttons={
                <Button
                  icon={applyOverlayColor ? 'check-square' : 'square'}
                  selected={applyOverlayColor}
                  onClick={() => setApplyOverlayColor(!applyOverlayColor)}
                />
              }>
              <Stack align="center" spacing={1}>
                <Stack.Item>
                  <ColorBox color={overlayColor} width={3} height={1.25} />
                </Stack.Item>
                <Stack.Item grow>
                  <Box monospace>{overlayColor}</Box>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="eyedropper"
                    onClick={() =>
                      act('pick_overlay_color', { current: overlayColor })
                    }>
                    Pick…
                  </Button>
                </Stack.Item>
              </Stack>
            </LabeledList.Item>

            <LabeledList.Item label="Effects">
              <Stack spacing={1}>
                <Stack.Item>
                  <Button
                    icon="bolt"
                    selected={triggerSpark}
                    onClick={() => setTriggerSpark(!triggerSpark)}
                    content="Spark"
                    tooltip="Emit sparks from the selected fixtures when applying."
                  />
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="lightbulb"
                    selected={triggerFlicker}
                    onClick={() => setTriggerFlicker(!triggerFlicker)}
                    content="Flicker"
                    tooltip="Make the selected fixtures flicker when applying."
                  />
                </Stack.Item>
              </Stack>
            </LabeledList.Item>
          </LabeledList>

          <Stack mt={2} justify="space-between" align="center">
            <Stack.Item grow>
              {restoreDisabled ? (
                <NoticeBox info>
                  Select at least one Z-level and fixture type before applying
                  or restoring.
                </NoticeBox>
              ) : (
                applyDisabled && (
                  <NoticeBox info>
                    Enable at least one setting or effect before applying
                    changes.
                  </NoticeBox>
                )
              )}
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="undo"
                content="Restore Defaults"
                disabled={restoreDisabled}
                onClick={restoreDefaults}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="check"
                color="good"
                content="Apply Changes"
                disabled={applyDisabled}
                onClick={applyChanges}
              />
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
