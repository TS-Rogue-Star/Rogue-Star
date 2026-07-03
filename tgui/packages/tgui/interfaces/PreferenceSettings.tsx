// //////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star July 2026 for new preferences settings panel //
// //////////////////////////////////////////////////////////////////////////////

import { useBackend } from '../backend';
import { Box, Button, Section, Stack } from '../components';
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
  enabled: boolean;
  enabled_label: string;
  disabled_label: string;
  tooltip: string;
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
