// ///////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star February 2026: TGUI interface for says, emotes, and related verbs //
// ///////////////////////////////////////////////////////////////////////////////////////////////////

import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Dropdown,
  Flex,
  Section,
  Stack,
  TextArea,
} from '../components';
import { Window } from '../layouts';
import CustomEyeIconAsset from '../../../public/Icons/Rogue Star/eye 1.png';

type UnifiedSayEmoteInputData = {
  autowhisper_enabled: boolean;
  autowhisper_mode: string;
  channel: string;
  emote_vore_mode: string;
  max_length: number;
  mode: string;
  size_bucket: string;
  swapped_buttons: boolean;
  subtle_enabled: boolean;
  subtle_mode: string;
  subtle_mode_options: string[];
  title: string;
  window_height: number;
  window_width: number;
};

export const UnifiedSayEmoteInput = (_props, context) => {
  const { act, data } = useBackend<UnifiedSayEmoteInputData>(context);
  const {
    autowhisper_enabled,
    autowhisper_mode = 'Default whisper/subtle',
    max_length,
    channel = 'say',
    emote_vore_mode = 'none',
    mode = 'say',
    size_bucket = 'say_whisper',
    swapped_buttons,
    subtle_enabled,
    subtle_mode,
    subtle_mode_options = [],
    title = 'Communication',
    window_height = 259,
    window_width = 460,
  } = data;
  const [input, setInput] = useLocalState<string>(context, 'input', '');
  const getCurrentWindowSize = () => ({
    width: Math.max(1, Math.round(window.innerWidth || window_width)),
    height: Math.max(1, Math.round(window.innerHeight || window_height)),
  });
  const submitInput = (nextEmoteVoreMode = emote_vore_mode) => {
    const { width, height } = getCurrentWindowSize();
    act('submit', {
      entry: input,
      width,
      height,
      emote_vore_mode: nextEmoteVoreMode,
    });
  };
  const cancelInput = () => {
    const { width, height } = getCurrentWindowSize();
    act('cancel', { width, height });
  };
  const saveWindowPref = () => {
    const { width, height } = getCurrentWindowSize();
    act('save_window_pref', { width, height });
  };
  const submitWithEmoteVoreMode = (nextMode: 'none' | 'pred' | 'prey') => {
    submitInput(nextMode);
  };
  const sizeBucketLabel =
    size_bucket === 'emote_subtle' ? 'Emote/Subtle' : 'Say/Whisper';
  const modeOptions = [
    { displayText: 'Say', value: 'say' },
    { displayText: 'Emote', value: 'emote' },
    { displayText: 'Whisper', value: 'whisper' },
    { displayText: 'Subtle', value: 'subtle' },
    { displayText: 'Custom Subtle', value: 'custom_subtle' },
    { displayText: 'Psay', value: 'psay' },
    { displayText: 'Pme', value: 'pme' },
    { displayText: 'NSay', value: 'nsay' },
    { displayText: 'NMe', value: 'nme' },
    { displayText: 'OOC', value: 'ooc' },
    { displayText: 'LOOC', value: 'looc' },
  ];
  const modeLongestChoiceLength = modeOptions.reduce(
    (longest, option) => Math.max(longest, option.displayText.length),
    0
  );
  const modeDropdownWidth =
    modeLongestChoiceLength > 0
      ? `${modeLongestChoiceLength + 5}ch`
      : '8.75rem';
  const fallbackModeSelection =
    mode === 'emote'
      ? subtle_enabled
        ? 'subtle'
        : 'emote'
      : subtle_enabled
        ? 'whisper'
        : 'say';
  const modeSelection = [
    'say',
    'emote',
    'whisper',
    'subtle',
    'custom_subtle',
    'psay',
    'pme',
    'nsay',
    'nme',
    'ooc',
    'looc',
  ].includes(channel)
    ? channel
    : fallbackModeSelection;
  const supportsSubtleMode = modeSelection === 'custom_subtle';
  const subtleModeLongestChoiceLength = subtle_mode_options.reduce(
    (longest, option) => Math.max(longest, option.length),
    0
  );
  const subtleModeDropdownWidth =
    subtleModeLongestChoiceLength > 0
      ? `${subtleModeLongestChoiceLength}ch`
      : '16.5rem';
  const modeDisplayText =
    {
      emote: 'Emote',
      whisper: 'Whisper',
      subtle: 'Subtle',
      custom_subtle: 'Custom Subtle',
      psay: 'Psay',
      pme: 'Pme',
      nsay: 'NSay',
      nme: 'NMe',
      ooc: 'OOC',
      looc: 'LOOC',
      say: 'Say',
    }[modeSelection] || 'Say';
  const statusIcon = (
    <img
      className="TitleBar__statusIcon RogueStar__statusIcon"
      src={CustomEyeIconAsset}
      alt=""
    />
  );
  const submitButton = (
    <Button
      className="RogueStar__chip RogueStar__glowButton--positive"
      fluid
      onClick={submitInput}
      textAlign="center">
      Submit ({input.length}/{max_length})
    </Button>
  );
  const cancelButton = (
    <Button
      className="RogueStar__chip RogueStar__glowButton--negative"
      fluid
      onClick={cancelInput}
      textAlign="center">
      Cancel
    </Button>
  );
  const emotePredButton = (
    <Button
      className="RogueStar__chip RogueStar__glowButton--positive"
      content="Pred"
      selected={emote_vore_mode === 'pred'}
      tooltip="Submit with Emote Vore (Pred): Eat compatible people within one tile, holding you, or in your hand while sending this message."
      onClick={() => submitWithEmoteVoreMode('pred')}
    />
  );
  const emotePreyButton = (
    <Button
      className="RogueStar__chip RogueStar__glowButton--positive"
      content="Prey"
      selected={emote_vore_mode === 'prey'}
      tooltip="Submit with Emote Vore (Prey): Be eaten by one compatible person within one tile, holding you, or in your hand while sending this message."
      onClick={() => submitWithEmoteVoreMode('prey')}
    />
  );

  return (
    <Window
      title={title}
      width={window_width}
      height={window_height}
      onClose={cancelInput}
      statusIcon={statusIcon}
      theme="nanotrasen rogue-star-window">
      <Window.Content
        onEscape={cancelInput}
        onEnter={(event) => {
          submitInput();
          event.preventDefault();
        }}>
        <Box
          className="RogueStar RogueStar--sayEmote"
          position="relative"
          height="100%">
          <Section fill>
            <Stack fill vertical>
              <Stack.Item>
                <Flex wrap align="center" fill justify="space-between" gap={1}>
                  <Flex.Item className="RogueStar__toolbarGroup">
                    <Dropdown
                      className="RogueStar__dropdown"
                      dropdownStyle="rogue-star"
                      width={modeDropdownWidth}
                      menuWidth={modeDropdownWidth}
                      options={modeOptions}
                      selected={modeSelection}
                      displayText={modeDisplayText}
                      onSelected={(value) =>
                        act('set_channel', { channel: value })
                      }
                    />
                    {supportsSubtleMode && (
                      <Dropdown
                        className="RogueStar__dropdown"
                        dropdownStyle="rogue-star"
                        width={subtleModeDropdownWidth}
                        menuWidth={subtleModeDropdownWidth}
                        options={subtle_mode_options}
                        selected={subtle_mode}
                        onSelected={(value) =>
                          act('set_subtle_mode', { subtle_mode: value })
                        }
                      />
                    )}
                  </Flex.Item>
                  <Flex.Item className="RogueStar__toolbarGroup">
                    <Button
                      className="RogueStar__chip"
                      icon="save"
                      tooltip={`Save current size as your ${sizeBucketLabel} default.`}
                      onClick={saveWindowPref}
                    />
                  </Flex.Item>
                </Flex>
              </Stack.Item>
              {!!autowhisper_enabled && (
                <Stack.Item>
                  <Box
                    className="RogueStar__noticeBar"
                    title={`Autowhisper is enabled. Mode: ${autowhisper_mode}.`}>
                    <Box className="RogueStar__noticeText">
                      Autowhisper enabled. Mode: {autowhisper_mode}
                    </Box>
                  </Box>
                </Stack.Item>
              )}
              <Stack.Item grow minHeight={0}>
                <TextArea
                  autoFocus
                  autoSelect
                  height="100%"
                  width="100%"
                  maxLength={max_length}
                  onEscape={cancelInput}
                  onEnter={(event) => {
                    submitInput();
                    event.preventDefault();
                  }}
                  onInput={(_, value) => setInput(value)}
                  placeholder="Type something..."
                  value={input}
                />
              </Stack.Item>
              <Stack.Item>
                <Flex
                  align="center"
                  direction="row"
                  fill
                  justify="space-around">
                  {swapped_buttons ? (
                    <>
                      <Flex.Item grow>{submitButton}</Flex.Item>
                      <Flex.Item>{emotePredButton}</Flex.Item>
                      <Flex.Item>{emotePreyButton}</Flex.Item>
                      <Flex.Item grow>{cancelButton}</Flex.Item>
                    </>
                  ) : (
                    <>
                      <Flex.Item grow>{cancelButton}</Flex.Item>
                      <Flex.Item>{emotePredButton}</Flex.Item>
                      <Flex.Item>{emotePreyButton}</Flex.Item>
                      <Flex.Item grow>{submitButton}</Flex.Item>
                    </>
                  )}
                </Flex>
              </Stack.Item>
            </Stack>
          </Section>
        </Box>
      </Window.Content>
    </Window>
  );
};
