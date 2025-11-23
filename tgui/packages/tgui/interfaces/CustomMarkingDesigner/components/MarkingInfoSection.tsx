// /////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Marking info section for custom marking designer //
// /////////////////////////////////////////////////////////////////////////////////////////////////

import {
  Button,
  Flex,
  LabeledList,
  NumberInput,
  Section,
  Tooltip,
} from '../../../components';
import { GENERIC_PART_KEY } from '../../../utils/character-preview';
import type { BodyPartEntry, DirectionEntry } from '../types';
import { CHIP_BUTTON_CLASS } from '../constants';

type FadeControlProps = {
  readonly tooltip: string;
  readonly value: number;
  readonly onChange: (value: number) => void;
};

const FadeControl = ({ tooltip, value, onChange }: FadeControlProps) => (
  <Flex.Item grow={0} shrink={0} basis="auto">
    <Tooltip content={tooltip}>
      <NumberInput
        className="RogueStar__numberInput"
        minValue={0}
        maxValue={100}
        step={1}
        unit="%"
        width={5}
        value={value}
        onChange={(e, next) => onChange(Number(next ?? 0))}
      />
    </Tooltip>
  </Flex.Item>
);

type MarkingInfoSectionProps = {
  readonly bodyParts: BodyPartEntry[];
  readonly directions: DirectionEntry[];
  readonly currentDirectionKey: number;
  readonly setDirection: (dir: number) => void;
  readonly activePartKey: string;
  readonly activePartLabel: string;
  readonly resolvedPartReplacementMap: Record<string, boolean>;
  readonly resolvePartLayeringState: (partKey: string | null | undefined) => boolean;
  readonly togglePartLayerPriority: (partKey?: string) => void;
  readonly togglePartReplacement: (partKey?: string) => void;
  readonly setBodyPart: (id: string) => void;
  readonly uiLocked: boolean;
  readonly getReferenceOpacityForPart: (partId: string) => number;
  readonly setReferenceOpacityForPart: (partId: string, value: number) => void;
};

export const MarkingInfoSection = ({
  bodyParts,
  directions,
  currentDirectionKey,
  setDirection,
  activePartKey,
  activePartLabel,
  resolvedPartReplacementMap,
  resolvePartLayeringState,
  togglePartLayerPriority,
  togglePartReplacement,
  setBodyPart,
  uiLocked,
  getReferenceOpacityForPart,
  setReferenceOpacityForPart,
}: MarkingInfoSectionProps) => (
  <Section title="Marking Information">
    <LabeledList>
      <LabeledList.Item label="Body Parts">
        <Flex wrap="wrap" gap={1} className="RogueStar__pillGroup">
          {bodyParts.map((part) => {
            const isActive = part.id === activePartKey;
            const canToggleExtras = part.id !== GENERIC_PART_KEY;
            const partLayeringOnTop = resolvePartLayeringState(part.id);
            const isPartReplaced = !!resolvedPartReplacementMap[part.id];
            return (
              <Flex.Item key={part.id} basis="15%">
                <Flex align="center" gap={0.5}>
                  <Flex.Item grow>
                    <Button
                      className={CHIP_BUTTON_CLASS}
                      fluid
                      selected={isActive}
                      disabled={uiLocked}
                      onClick={() => setBodyPart(part.id)}>
                      {part.label}
                    </Button>
                  </Flex.Item>
                  {canToggleExtras ? (
                    <>
                      <Tooltip content={`Render ${part.label} above the body`}>
                        <Button
                          className={CHIP_BUTTON_CLASS}
                          icon="layer-group"
                          selected={partLayeringOnTop}
                          disabled={uiLocked}
                          onClick={() => togglePartLayerPriority(part.id)}
                        />
                      </Tooltip>
                      <Tooltip
                        content={`Replace the base sprite for ${part.label}`}>
                        <Button
                          className={CHIP_BUTTON_CLASS}
                          icon="user-slash"
                          selected={isPartReplaced}
                          disabled={uiLocked}
                          onClick={() => togglePartReplacement(part.id)}
                        />
                      </Tooltip>
                    </>
                  ) : null}
                </Flex>
              </Flex.Item>
            );
          })}
        </Flex>
      </LabeledList.Item>
      <LabeledList.Item label="Direction">
        <Flex wrap="wrap" gap={1} className="RogueStar__pillGroup">
          {directions.map((entry) => (
            <Flex.Item key={entry.dir} basis="15%">
              <Button
                className={CHIP_BUTTON_CLASS}
                fluid
                selected={entry.dir === currentDirectionKey}
                disabled={uiLocked}
                onClick={() => setDirection(entry.dir)}>
                {entry.label}
              </Button>
            </Flex.Item>
          ))}
        </Flex>
      </LabeledList.Item>
      <LabeledList.Item label="Fades">
        <Flex gap={1} wrap align="center">
          <FadeControl
            tooltip="Controls how visible the generic reference body is."
            value={Math.round(
              getReferenceOpacityForPart(GENERIC_PART_KEY) * 100
            )}
            onChange={(value) =>
              setReferenceOpacityForPart(GENERIC_PART_KEY, value / 100)
            }
          />
          {activePartKey !== GENERIC_PART_KEY ? (
            <FadeControl
              tooltip={`Fade for the ${activePartLabel} reference overlay.`}
              value={Math.round(
                getReferenceOpacityForPart(activePartKey) * 100
              )}
              onChange={(value) =>
                setReferenceOpacityForPart(activePartKey, value / 100)
              }
            />
          ) : null}
        </Flex>
      </LabeledList.Item>
    </LabeledList>
  </Section>
);
