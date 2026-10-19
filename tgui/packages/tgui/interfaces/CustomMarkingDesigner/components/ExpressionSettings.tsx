// /////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Expression //
// /////////////////////////////////////////////////////////////////////////////////

import { Component } from 'inferno';
import { resolveAsset } from '../../../assets';
import {
  Box,
  Button,
  Collapsible,
  Dropdown,
  Flex,
  Input,
  LabeledList,
  NoticeBox,
  NumberInput,
  Section,
  TextArea,
} from '../../../components';
import { CHIP_BUTTON_CLASS } from '../constants';
import type { SpeechBubbleStyle } from '../types';
import {
  EXPRESSION_VERBS,
  VOICE_FREQUENCIES,
  voicePlaybackRate,
  type ExpressionState,
  type ExpressionVoice,
} from '../utils/expression';
import { SpeechBubblePreview, speechBubbleName } from './SpeechBubbleGallery';

type ExpressionSettingsProps = Readonly<{
  state: ExpressionState;
  voices: ExpressionVoice[];
  bubble: SpeechBubbleStyle;
  disabled: boolean;
  onChange: (values: Partial<ExpressionState>) => void;
  onAssetReady: () => void;
}>;

export class ExpressionSettings extends Component<
  ExpressionSettingsProps,
  { audioError: string | null }
> {
  private samples = new Map<string, HTMLAudioElement>();
  private playing: HTMLAudioElement | null = null;
  private mounted = false;

  state = { audioError: null as string | null };

  componentDidMount() {
    this.mounted = true;
    this.preloadVoices();
  }

  componentDidUpdate() {
    this.preloadVoices();
    if (this.props.disabled) {
      this.playing?.pause();
    }
  }

  componentWillUnmount() {
    this.mounted = false;
    this.samples.forEach((sample) => {
      sample.pause();
      sample.removeAttribute('src');
      sample.load();
    });
    this.samples.clear();
    this.playing = null;
  }

  private preloadVoices() {
    for (const voice of this.props.voices) {
      for (const name of voice.samples) {
        if (!this.samples.has(name)) {
          const sample = new Audio(resolveAsset(name));
          sample.preload = 'auto';
          sample.volume = 0.5;
          sample.preservesPitch = false;
          this.samples.set(name, sample);
        }
      }
    }
  }

  private handleTestVoice = () => {
    const { state, voices, disabled } = this.props;
    if (disabled) {
      return;
    }
    const voice = voices.find(({ id }) => id === state.voice_sound);
    if (!voice?.samples.length) {
      return;
    }
    const name =
      voice.samples[Math.floor(Math.random() * voice.samples.length)];
    const sample = this.samples.get(name);
    if (!sample) {
      return;
    }
    this.playing?.pause();
    this.playing = sample;
    sample.currentTime = 0;
    sample.playbackRate = voicePlaybackRate(
      state.voice_freq,
      voice.sample_rate
    );
    this.setState({ audioError: null });
    const playback = sample.play();
    playback?.catch(() => {
      if (this.mounted && this.playing === sample) {
        this.setState({
          audioError: 'Voice preview could not play. Try again.',
        });
      }
    });
  };

  render() {
    const { state, voices, bubble, disabled, onChange, onAssetReady } =
      this.props;
    const change = (values: Partial<ExpressionState>) => {
      if (!disabled) {
        onChange(values);
      }
    };
    return (
      <Section
        title="Expression"
        fill
        scrollable
        minHeight={0}
        style={{ flex: '1 1 0' }}>
        <Box
          as="fieldset"
          disabled={disabled}
          style={{ border: 0, margin: 0, padding: 0 }}>
          <LabeledList>
            <LabeledList.Item label="Speech Bubble">
              <Flex align="center">
                <Flex.Item>
                  <SpeechBubblePreview
                    compact
                    style={bubble}
                    onAssetReady={onAssetReady}
                    pixelSize={2}
                  />
                </Flex.Item>
                <Flex.Item ml={1}>{speechBubbleName(bubble.id)}</Flex.Item>
              </Flex>
            </LabeledList.Item>
            <LabeledList.Item label="Voice Frequency">
              <Flex align="center" gap={0.5}>
                <Flex.Item>
                  <Dropdown
                    className={`${CHIP_BUTTON_CLASS} RogueStar__physiologyDropdown`}
                    color="transparent"
                    dropdownStyle="rogue-star"
                    controlContentClassName="Button__content RogueStar__physiologyDropdownContent RogueStar__physiologyDropdownContent--textOnly"
                    width="130px"
                    options={VOICE_FREQUENCIES}
                    selected={state.voice_freq}
                    displayText={
                      VOICE_FREQUENCIES.find(
                        ({ value }) => value === state.voice_freq
                      )?.displayText || 'Custom'
                    }
                    disabled={disabled}
                    onSelected={(value) =>
                      change({ voice_freq: Number(value) })
                    }
                  />
                </Flex.Item>
                <Flex.Item>
                  <NumberInput
                    className="RogueStar__numberInput"
                    width="110px"
                    value={state.voice_freq}
                    minValue={15000}
                    maxValue={70000}
                    step={250}
                    allowZero
                    syncWithValue
                    unit="Hz"
                    disabled={disabled}
                    onChange={(_event, value) => {
                      if (typeof value === 'number' && Number.isFinite(value)) {
                        change({
                          voice_freq:
                            value === 0
                              ? 0
                              : Math.round(
                                  Math.max(15000, Math.min(70000, value))
                                ),
                        });
                      }
                    }}
                  />
                </Flex.Item>
              </Flex>
            </LabeledList.Item>
            <LabeledList.Item label="Voice Sounds">
              <Flex align="center" gap={0.5}>
                <Flex.Item>
                  <Dropdown
                    className={`${CHIP_BUTTON_CLASS} RogueStar__physiologyDropdown`}
                    color="transparent"
                    dropdownStyle="rogue-star"
                    controlContentClassName="Button__content RogueStar__physiologyDropdownContent RogueStar__physiologyDropdownContent--textOnly"
                    width="160px"
                    options={voices.map(({ id }) => id)}
                    selected={state.voice_sound}
                    disabled={disabled}
                    onSelected={(voice_sound) => change({ voice_sound })}
                  />
                </Flex.Item>
                <Flex.Item>
                  <Button
                    className={CHIP_BUTTON_CLASS}
                    icon="volume-high"
                    disabled={disabled || !voices.length}
                    onClick={this.handleTestVoice}>
                    Test Voice
                  </Button>
                </Flex.Item>
              </Flex>
            </LabeledList.Item>
            <LabeledList.Item label="Autohiss">
              {['Full', 'Basic', 'Off'].map((autohiss) => (
                <Button
                  key={autohiss}
                  className={CHIP_BUTTON_CLASS}
                  selected={state.autohiss === autohiss}
                  disabled={disabled}
                  onClick={() => change({ autohiss })}>
                  {autohiss}
                </Button>
              ))}
            </LabeledList.Item>
            {EXPRESSION_VERBS.map(({ key, label, placeholder }) => (
              <LabeledList.Item key={key} label={label}>
                <Input
                  width="160px"
                  value={state[key]}
                  placeholder={placeholder}
                  maxLength={12}
                  disabled={disabled}
                  onInput={(_event, value) => change({ [key]: value })}
                />
                <Button
                  className={CHIP_BUTTON_CLASS}
                  icon="rotate-left"
                  disabled={disabled || !state[key]}
                  onClick={() => change({ [key]: '' })}>
                  Reset
                </Button>
              </LabeledList.Item>
            ))}
          </LabeledList>
          <Box my={1} color="label">
            Use 0 Hz for Random or enter a custom frequency from 15,000–70,000
            Hz. Empty custom verbs use your species’ defaults.
          </Box>
          {this.state.audioError && (
            <NoticeBox>{this.state.audioError}</NoticeBox>
          )}
          {(['custom_heat', 'custom_cold'] as const).map((key) => {
            const label = key === 'custom_heat' ? 'Heat' : 'Cold';
            const messages = state[key];
            return (
              <Collapsible
                key={key}
                className={CHIP_BUTTON_CLASS}
                title={`Custom ${label} Discomfort (${messages.length}/10)`}>
                <Box mb={1} color="label">
                  Each message needs 3–160 characters. An empty list uses your
                  species’ defaults.
                </Box>
                {messages.map((message, index) => (
                  <Box key={index} mb={1}>
                    <TextArea
                      fluid
                      height="54px"
                      value={message}
                      placeholder={`${label} discomfort message ${index + 1}`}
                      maxLength={160}
                      disabled={disabled}
                      dontUseTabForIndent
                      onInput={(_event, value) =>
                        change({
                          [key]: messages.map((entry, i) =>
                            i === index ? value : entry
                          ),
                        })
                      }
                    />
                    <Button
                      className={CHIP_BUTTON_CLASS}
                      icon="minus"
                      disabled={disabled}
                      onClick={() =>
                        change({
                          [key]: messages.filter((_entry, i) => i !== index),
                        })
                      }>
                      Remove Message {index + 1}
                    </Button>
                  </Box>
                ))}
                <Button
                  className={CHIP_BUTTON_CLASS}
                  icon="plus"
                  disabled={disabled || messages.length >= 10}
                  onClick={() => change({ [key]: [...messages, ''] })}>
                  Add Message
                </Button>
                <Button
                  className={CHIP_BUTTON_CLASS}
                  icon="rotate-left"
                  disabled={disabled || !messages.length}
                  onClick={() => change({ [key]: [] })}>
                  Reset to Defaults
                </Button>
              </Collapsible>
            );
          })}
        </Box>
      </Section>
    );
  }
}
