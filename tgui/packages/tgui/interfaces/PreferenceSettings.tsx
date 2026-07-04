// //////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star July 2026 for new preferences settings panel //
// //////////////////////////////////////////////////////////////////////////////

import { useBackend } from '../backend';
import { Box, Button, Icon, Section, Stack, Tooltip } from '../components';
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
  value?: string;
  display_value?: string;
  using_default?: boolean;
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

type PreferenceColorControlProps = {
  readonly preference: Preference;
  readonly guardedClickAct: (action: string, payload?: ActionPayload) => void;
};

const PreferenceColorControl = (props: PreferenceColorControlProps) => {
  const { preference, guardedClickAct } = props;
  const usingDefault = !!preference.using_default;
  const colorValue = preference.value || '#000000';
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
