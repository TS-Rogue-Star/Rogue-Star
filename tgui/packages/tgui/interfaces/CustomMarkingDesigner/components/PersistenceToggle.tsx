// ////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Misc Settings //
// ////////////////////////////////////////////////////////////////////////////////////

import { Button } from '../../../components';
import { CHIP_BUTTON_CLASS } from '../constants';

type Props = Readonly<{
  subject: 'scale' | 'weight' | 'organs' | 'markings' | 'spawn';
  enabled: boolean;
  disabled?: boolean;
  onChange: (enabled: boolean) => void;
}>;

const SETTINGS = {
  scale: {
    label: 'Keep scale between rounds',
    description: 'Saves your scale at round end or cryo.',
  },
  weight: {
    label: 'Keep weight between rounds',
    description: 'Saves your weight at round end or cryo.',
  },
  organs: {
    label: 'Keep organs between rounds',
    description:
      'Saves limb, organ, and prosthetic changes at round end or cryo.',
  },
  markings: {
    label: 'Keep markings between rounds',
    description: 'Saves marking styles and colors at round end or cryo.',
  },
  spawn: {
    label: 'Remember spawn location',
    description: 'Sets your next spawn based on where you leave the round.',
  },
};

export const PersistenceToggle = ({
  subject,
  enabled: enabledValue,
  disabled,
  onChange,
}: Props) => {
  const { label, description } = SETTINGS[subject];
  const enabled = !!enabledValue;
  return (
    <Button
      className={`${CHIP_BUTTON_CLASS} RogueStar__persistenceToggle`}
      icon="history"
      role="button"
      selected={enabled}
      disabled={disabled}
      aria-label={`${label}: ${enabled ? 'On' : 'Off'}`}
      aria-pressed={enabled}
      tooltip={`${label}: ${enabled ? 'On' : 'Off'}. ${description}`}
      onClick={() => onChange(!enabled)}
    />
  );
};
