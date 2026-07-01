// //////////////////////////////////////////////////////////////////////////////
// Refactored by Lira for Rogue Star June 2026 for new sound preferences panel //
// //////////////////////////////////////////////////////////////////////////////

import { round } from 'common/math';
import { useBackend } from '../backend';
import {
  Box,
  Button,
  LabeledList,
  Section,
  Slider,
  Stack,
} from '../components';
import { Window } from '../layouts';
import CustomEyeIconAsset from '../../../public/Icons/Rogue Star/eye 1.png';

const ROGUE_STAR_THEME = 'nanotrasen rogue-star-window';
const CHIP_BUTTON_CLASS = 'RogueStar__chip';
const SOUND_PANEL_CLICK_ACTION_DELAY_MS = 500;
const VOLUME_CHANNEL_STEP_PIXEL_SIZE = 2;
const MEDIA_VOLUME_STEP_PIXEL_SIZE = 4;

let nextClickActionAt = 0;

const canSendClickAction = () => {
  const now = Date.now();
  if (now < nextClickActionAt) {
    return false;
  }

  nextClickActionAt = now + SOUND_PANEL_CLICK_ACTION_DELAY_MS;
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

type MediaPlayer = {
  id: number;
  label: string;
};

type SoundPreference = {
  key: string;
  label: string;
  enabled: boolean;
};

type SoundPreferenceGroup = {
  name: string;
  preferences: SoundPreference[];
};

type Data = {
  error?: boolean;
  volume_channels: Record<string, number>;
  media_volume: number;
  media_player: number;
  media_players: MediaPlayer[];
  sound_preferences: SoundPreferenceGroup[];
};

export const VolumePanel = (props, context) => {
  const { act, data } = useBackend<Data>(context);

  const {
    error,
    volume_channels = {},
    media_volume = 1,
    media_player = 2,
    media_players = [],
    sound_preferences = [],
  } = data;

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
            <Section title="Sound Settings">
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
      height={720}
      theme={ROGUE_STAR_THEME}
      statusIcon={statusIcon}
      resizable>
      <Window.Content scrollable>
        <Box
          className="RogueStar RogueStar__soundSettings"
          position="relative"
          minHeight="100%">
          <Section title="Volume Channels">
            <LabeledList>
              {Object.keys(volume_channels).map((key) => (
                <LabeledList.Item label={key} key={key}>
                  <Slider
                    className="RogueStar__soundSettingsSlider"
                    width="88%"
                    minValue={0}
                    maxValue={200}
                    step={1}
                    stepPixelSize={VOLUME_CHANNEL_STEP_PIXEL_SIZE}
                    value={volume_channels[key] * 100}
                    format={(value) => `${round(value, 0)}%`}
                    onChange={(e, value) =>
                      act('adjust_volume', {
                        channel: key,
                        vol: round(value / 100, 2),
                      })
                    }
                  />
                  <Button
                    className="RogueStar__soundSettingsReset"
                    ml={1}
                    icon="undo"
                    tooltip="Reset"
                    onClick={() =>
                      guardedClickAct('adjust_volume', { channel: key, vol: 1 })
                    }
                  />
                </LabeledList.Item>
              ))}
            </LabeledList>
          </Section>

          <Section title="Jukebox and Media">
            <LabeledList>
              <LabeledList.Item label="Jukebox">
                <Slider
                  className="RogueStar__soundSettingsSlider"
                  width="88%"
                  minValue={0}
                  maxValue={100}
                  step={1}
                  stepPixelSize={MEDIA_VOLUME_STEP_PIXEL_SIZE}
                  value={media_volume * 100}
                  format={(value) => `${round(value, 0)}%`}
                  onChange={(e, value) =>
                    act('set_media_volume', {
                      volume: round(value / 100, 2),
                    })
                  }
                />
                <Button
                  className="RogueStar__soundSettingsReset"
                  ml={1}
                  icon="undo"
                  tooltip="Reset"
                  onClick={() =>
                    guardedClickAct('set_media_volume', { volume: 1 })
                  }
                />
              </LabeledList.Item>
              <LabeledList.Item label="Player">
                <Stack wrap="wrap" gap={0.5}>
                  {media_players.map((player) => (
                    <Stack.Item key={player.id}>
                      <Button
                        className={CHIP_BUTTON_CLASS}
                        selected={media_player === player.id}
                        onClick={() =>
                          guardedClickAct('set_media_player', {
                            player: player.id,
                          })
                        }>
                        {player.label}
                      </Button>
                    </Stack.Item>
                  ))}
                </Stack>
              </LabeledList.Item>
            </LabeledList>
          </Section>

          <Stack vertical gap={1}>
            {sound_preferences.map((group) => (
              <Stack.Item key={group.name}>
                <Section title={group.name}>
                  <Box className="RogueStar__soundSettingsToggleGrid">
                    {group.preferences.map((preference) => (
                      <Box
                        className="RogueStar__soundSettingsToggle"
                        key={preference.key}>
                        <Button.Checkbox
                          className={`${CHIP_BUTTON_CLASS} RogueStar__soundSettingsToggleButton`}
                          checked={preference.enabled}
                          onClick={() =>
                            guardedClickAct('set_preference', {
                              key: preference.key,
                              enabled: preference.enabled ? 0 : 1,
                            })
                          }>
                          <Box className="RogueStar__soundSettingsToggleLabel">
                            {preference.label}
                          </Box>
                        </Button.Checkbox>
                      </Box>
                    ))}
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
