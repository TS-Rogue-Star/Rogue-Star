// //////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star July 2026 for new preferences settings panel //
// //////////////////////////////////////////////////////////////////////////////

import { round } from 'common/math';
import { useBackend } from '../backend';
import {
  Box,
  Button,
  Icon,
  NumberInput,
  Section,
  Stack,
  Tooltip,
} from '../components';
import { Window } from '../layouts';
import CustomEyeIconAsset from '../../../public/Icons/Rogue Star/eye 1.png';

const ROGUE_STAR_THEME = 'nanotrasen rogue-star-window';
const CHIP_BUTTON_CLASS = 'RogueStar__chip';
const PREFERENCE_PANEL_CLICK_ACTION_DELAY_MS = 500;

let nextClickActionAt = 0;

const canSendClickAction = () => {
  const now = Date.now();
  if (now < nextClickActionAt) {
    return false;
  }

  nextClickActionAt = now + PREFERENCE_PANEL_CLICK_ACTION_DELAY_MS;
  return true;
};

type ActionPayload = Record<string, unknown>;

const sendGuardedClickAction = (
  act: (action: string, payload?: ActionPayload) => void,
  action: string,
  payload?: ActionPayload
) => {
  if (!canSendClickAction()) {
    return;
  }

  act(action, payload);
};

type Preference = {
  key: string;
  label: string;
  type?: string;
  enabled: boolean;
  enabled_label: string;
  disabled_label: string;
  tooltip: string;
  value?: string | number;
  display_value?: string;
  using_default?: boolean;
  min_value?: number;
  max_value?: number;
  step?: number;
};

type PreferenceGroup = {
  name: string;
  preferences: Preference[];
};

type Data = {
  error?: boolean;
  preference_groups: PreferenceGroup[];
};

export const PreferenceSettings = (props, context) => {
  const { act, data } = useBackend<Data>(context);

  const { error, preference_groups = [] } = data;

  const guardedClickAct = (action: string, payload?: ActionPayload) =>
    sendGuardedClickAction(act, action, payload);

  const statusIcon = (
    <img
      className="TitleBar__statusIcon RogueStar__statusIcon"
      src={CustomEyeIconAsset}
      alt=""
    />
  );

  if (error) {
    return (
      <Window
        width={420}
        height={180}
        theme={ROGUE_STAR_THEME}
        statusIcon={statusIcon}>
        <Window.Content>
          <Box className="RogueStar" position="relative" minHeight="100%">
            <Section title="Preference Settings">
              Preferences are unavailable.
            </Section>
          </Box>
        </Window.Content>
      </Window>
    );
  }

  return (
    <Window
      width={620}
      height={700}
      theme={ROGUE_STAR_THEME}
      statusIcon={statusIcon}
      resizable>
      <Window.Content scrollable>
        <Box
          className="RogueStar RogueStar__soundSettings RogueStar__preferenceSettings"
          position="relative"
          minHeight="100%">
          <Stack vertical gap={1}>
            {preference_groups.map((group) => (
              <Stack.Item key={group.name}>
                <Section title={group.name}>
                  <Box className="RogueStar__soundSettingsToggleGrid">
                    {group.preferences.map((preference) => {
                      if (preference.type === 'color') {
                        return (
                          <PreferenceColorControl
                            key={preference.key}
                            preference={preference}
                            guardedClickAct={guardedClickAct}
                          />
                        );
                      }

                      if (preference.type === 'input') {
                        return (
                          <PreferenceNumberControl
                            key={preference.key}
                            preference={preference}
                            guardedClickAct={guardedClickAct}
                          />
                        );
                      }

                      const enabled = !!preference.enabled;

                      return (
                        <Box
                          className="RogueStar__soundSettingsToggle"
                          key={preference.key}>
                          <Button.Checkbox
                            className={`${CHIP_BUTTON_CLASS} RogueStar__soundSettingsToggleButton`}
                            checked={enabled}
                            tooltip={preference.tooltip}
                            onClick={() =>
                              guardedClickAct('set_preference', {
                                key: preference.key,
                                enabled: enabled ? 0 : 1,
                              })
                            }>
                            <Box className="RogueStar__soundSettingsToggleLabel">
                              {preference.label}
                            </Box>
                          </Button.Checkbox>
                        </Box>
                      );
                    })}
                  </Box>
                </Section>
              </Stack.Item>
            ))}
          </Stack>
        </Box>
      </Window.Content>
    </Window>
  );
};

type PreferenceNumberControlProps = {
  readonly preference: Preference;
  readonly guardedClickAct: (action: string, payload?: ActionPayload) => void;
};

const PreferenceNumberControl = (props: PreferenceNumberControlProps) => {
  const { preference, guardedClickAct } = props;
  const currentValue =
    typeof preference.value === 'number' ? preference.value : 0;
  const minValue =
    typeof preference.min_value === 'number' ? preference.min_value : 0;
  const maxValue =
    typeof preference.max_value === 'number' ? preference.max_value : 100;
  const step = typeof preference.step === 'number' ? preference.step : 1;

  return (
    <Box className="RogueStar__soundSettingsToggle" key={preference.key}>
      <Button
        className={`${CHIP_BUTTON_CLASS} RogueStar__soundSettingsToggleButton RogueStar__soundSettingsInputButton`}
        icon="expand"
        tooltip={preference.tooltip}>
        <Box className="RogueStar__soundSettingsValueLabel">
          <Box className="RogueStar__soundSettingsToggleLabel">
            {preference.label}
          </Box>
          <NumberInput
            className="RogueStar__soundSettingsInlineNumber"
            width="40px"
            height="13px"
            lineHeight="13px"
            minValue={minValue}
            maxValue={maxValue}
            step={step}
            stepPixelSize={8}
            wheelStep={step}
            wheelStepShift={step}
            wheelUpdateRate={200}
            value={currentValue}
            format={(value) => `${round(value, 0)}x`}
            onChange={(e, value) =>
              guardedClickAct('set_numeric_preference', {
                key: preference.key,
                value: round(value, 0),
              })
            }
          />
        </Box>
      </Button>
    </Box>
  );
};

type PreferenceColorControlProps = {
  readonly preference: Preference;
  readonly guardedClickAct: (action: string, payload?: ActionPayload) => void;
};

const PreferenceColorControl = (props: PreferenceColorControlProps) => {
  const { preference, guardedClickAct } = props;
  const usingDefault = !!preference.using_default;
  const colorValue =
    typeof preference.value === 'string' ? preference.value : '#000000';
  const displayValue = usingDefault
    ? 'Default'
    : preference.display_value || colorValue;

  return (
    <Box
      className="RogueStar__soundSettingsToggle RogueStar__preferenceSettingsColorControl"
      key={preference.key}>
      <Button
        className={`${CHIP_BUTTON_CLASS} RogueStar__soundSettingsToggleButton RogueStar__preferenceSettingsColorButton`}
        color="transparent"
        icon={usingDefault ? 'square-o' : 'square'}
        iconColor={usingDefault ? undefined : colorValue}
        tooltip={preference.tooltip}
        onClick={() => guardedClickAct('set_ooc_color')}>
        <Box className="RogueStar__preferenceSettingsColorLabel">
          <Box className="RogueStar__preferenceSettingsColorName">
            {preference.label}
          </Box>
          <Box className="RogueStar__preferenceSettingsColorValue">
            {displayValue}
          </Box>
        </Box>
        {!usingDefault && (
          <Tooltip content="Reset OOC color to default">
            <Box
              className="RogueStar__preferenceSettingsColorReset"
              onClick={(event: MouseEvent) => {
                event.stopPropagation();
                guardedClickAct('reset_ooc_color');
              }}>
              <Icon name="undo" />
            </Box>
          </Tooltip>
        )}
      </Button>
    </Box>
  );
};
