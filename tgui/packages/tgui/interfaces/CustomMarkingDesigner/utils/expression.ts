// /////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Expression //
// /////////////////////////////////////////////////////////////////////////////////

export type ExpressionState = {
  voice_freq: number;
  voice_sound: string;
  autohiss: string;
  custom_say: string;
  custom_whisper: string;
  custom_ask: string;
  custom_exclaim: string;
  custom_heat: string[];
  custom_cold: string[];
};

export type ExpressionVoice = {
  id: string;
  sample_rate: number;
  samples: string[];
};

export const EXPRESSION_VERBS = [
  { key: 'custom_say', label: 'Custom Say', placeholder: 'says' },
  { key: 'custom_whisper', label: 'Custom Whisper', placeholder: 'whispers' },
  { key: 'custom_ask', label: 'Custom Ask', placeholder: 'asks' },
  { key: 'custom_exclaim', label: 'Custom Exclaim', placeholder: 'exclaims' },
] as const;

export const VOICE_FREQUENCIES = [
  { displayText: 'Random', value: 0 },
  { displayText: 'Low', value: 15000 },
  { displayText: 'Middle-low', value: 28750 },
  { displayText: 'Middle', value: 42500 },
  { displayText: 'Middle-high', value: 56250 },
  { displayText: 'High', value: 70000 },
];

export const buildExpressionState = (
  payload?: Partial<ExpressionState> | null
): ExpressionState => ({
  voice_freq: payload?.voice_freq ?? 0,
  voice_sound: payload?.voice_sound || 'beep-boop',
  autohiss: payload?.autohiss || 'Full',
  custom_say: payload?.custom_say || '',
  custom_whisper: payload?.custom_whisper || '',
  custom_ask: payload?.custom_ask || '',
  custom_exclaim: payload?.custom_exclaim || '',
  custom_heat: [...(payload?.custom_heat || [])],
  custom_cold: [...(payload?.custom_cold || [])],
});

export const retainExpressionDraft = (
  incoming: ExpressionState,
  draft?: ExpressionState | null,
  saved?: ExpressionState | null
): ExpressionState => {
  const result = buildExpressionState(incoming);
  if (draft && saved) {
    for (const key of Object.keys(result) as (keyof ExpressionState)[]) {
      if (JSON.stringify(draft[key]) !== JSON.stringify(saved[key])) {
        Object.assign(result, {
          [key]: Array.isArray(draft[key]) ? [...draft[key]] : draft[key],
        });
      }
    }
  }
  return result;
};

export const expressionValidationError = (state: ExpressionState) => {
  if (
    !Number.isInteger(state.voice_freq) ||
    (state.voice_freq !== 0 &&
      (state.voice_freq < 15000 || state.voice_freq > 70000))
  ) {
    return 'Voice frequency must be Random (0) or 15,000–70,000 Hz.';
  }
  for (const { key, label } of EXPRESSION_VERBS) {
    if (state[key].length > 12) {
      return `${label} allows up to 12 characters.`;
    }
  }
  for (const key of ['custom_heat', 'custom_cold'] as const) {
    if (
      state[key].length > 10 ||
      state[key].some((message) => message.length < 3 || message.length > 160)
    ) {
      return `${key === 'custom_heat' ? 'Heat' : 'Cold'} discomfort allows up to 10 messages, each 3–160 characters. Fill in or remove empty messages.`;
    }
  }
  return null;
};

export const voicePlaybackRate = (frequency: number, sampleRate: number) =>
  (frequency || Math.floor(32000 + Math.random() * 23001)) / sampleRate;
