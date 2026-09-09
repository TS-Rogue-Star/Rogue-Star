// ///////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star August 2026: Interactive prosthetic body target mannequin //
// ///////////////////////////////////////////////////////////////////////////////////////////

import { Box, Button } from '../../../components';
import {
  PROSTHETIC_TARGET_LABELS,
  resolveHighlightedProstheticTargets,
  type ProstheticTarget,
} from '../utils/prosthetics';

type ProstheticMannequinProps = Readonly<{
  activeTargets: ProstheticTarget[];
  uiLocked: boolean;
  isTargetEditable: (target: ProstheticTarget) => boolean;
  onToggleTarget: (target: ProstheticTarget) => void;
}>;

const MANNEQUIN_SEGMENTS: Array<{
  target: ProstheticTarget;
  slot: string;
  content?: string;
}> = [
  { target: 'l_arm', slot: 'left-arm', content: 'L' },
  { target: 'r_arm', slot: 'right-arm', content: 'R' },
  { target: 'l_hand', slot: 'left-hand' },
  { target: 'r_hand', slot: 'right-hand' },
  { target: 'l_leg', slot: 'left-leg', content: 'L' },
  { target: 'r_leg', slot: 'right-leg', content: 'R' },
  { target: 'l_foot', slot: 'left-foot' },
  { target: 'r_foot', slot: 'right-foot' },
  { target: 'torso', slot: 'core', content: 'TORSO' },
  { target: 'groin', slot: 'groin', content: 'GROIN' },
  { target: 'head', slot: 'head' },
];

export const ProstheticMannequin = ({
  activeTargets,
  uiLocked,
  isTargetEditable,
  onToggleTarget,
}: ProstheticMannequinProps) => {
  const fullBodyActive = activeTargets.includes('full_body');
  const highlightedTargets = resolveHighlightedProstheticTargets(activeTargets);
  return (
    <Box
      className={`RogueStar__prostheticMannequin${
        fullBodyActive ? ' RogueStar__prostheticMannequin--fullBody' : ''
      }`}
      role="group"
      aria-label="Prosthetic body targets">
      <Box className="RogueStar__prostheticMannequinGlow" />
      <Box className="RogueStar__prostheticMannequinScan" />
      {MANNEQUIN_SEGMENTS.map(({ target, slot, content }) => {
        const editable = isTargetEditable(target);
        const active = highlightedTargets.includes(target);
        const label = PROSTHETIC_TARGET_LABELS[target];
        return (
          <Button
            key={target}
            className={`RogueStar__prostheticMannequinPart RogueStar__prostheticMannequinPart--${slot}`}
            color="transparent"
            selected={active}
            disabled={uiLocked || !editable}
            role="button"
            aria-label={`Target ${label}`}
            aria-pressed={active}
            tooltip={
              editable && fullBodyActive && target !== 'full_body'
                ? `${label}: click to target this region instead of the full body.`
                : editable
                  ? `${label}: click to ${active ? 'remove from' : 'add to'} the active targets.`
                  : `${label} is unavailable for this character's current anatomy.`
            }
            onClick={() => onToggleTarget(target)}>
            {content ? (
              <Box as="span" className="RogueStar__prostheticMannequinPartText">
                {content}
              </Box>
            ) : null}
          </Button>
        );
      })}
      <Box className="RogueStar__prostheticMannequinAxis" aria-hidden="true">
        <Box as="span">R</Box>
        <Box as="span">Front</Box>
        <Box as="span">L</Box>
      </Box>
    </Box>
  );
};

export type { ProstheticMannequinProps };
