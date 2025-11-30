// ///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Paint tools and brush controls for custom marking designer //
// ///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Updated to support 64x64 markings ///////////////////////////
// ///////////////////////////////////////////////////////////////////////////////////////////////////////////

import {
  Box,
  Button,
  Flex,
  LabeledList,
  NumberInput,
  RogueStarColorPicker,
  Section,
  Tooltip,
} from '../../../components';
import { CHIP_BUTTON_CLASS, TOOLBAR_GROUP_CLASS } from '../constants';
import type { CustomColorSlotsState } from '../types';

type PaintToolsSectionProps = {
  readonly primaryTool: string | null;
  readonly secondaryTool: string | null;
  readonly onPrimarySelect: (tool: string) => void;
  readonly onSecondarySelect: (tool: string) => void;
  readonly blendMode: string;
  readonly setBlendMode: (mode: string) => void;
  readonly analogStrength: number;
  readonly setAnalogStrength: (value: number) => void;
  readonly canUndoDrafts: boolean;
  readonly handleUndo: () => void;
  readonly handleClear: (confirm: boolean) => void;
  readonly size: number;
  readonly setSize: (size: number) => void;
  readonly brushColor: string;
  readonly customColorSlots: CustomColorSlotsState;
  readonly handleCustomColorUpdate: (colors: (string | null)[]) => void;
  readonly handleColorPickerApply: (hex: string) => void;
};

export const PaintToolsSection = ({
  primaryTool,
  secondaryTool,
  onPrimarySelect,
  onSecondarySelect,
  blendMode,
  setBlendMode,
  analogStrength,
  setAnalogStrength,
  canUndoDrafts,
  handleUndo,
  handleClear,
  size,
  setSize,
  brushColor,
  customColorSlots,
  handleCustomColorUpdate,
  handleColorPickerApply,
}: PaintToolsSectionProps) => {
  const renderToolButton = (
    id: string,
    icon: string,
    label: string,
    tooltip?: string
  ) => {
    const isPrimary = primaryTool === id;
    const isSecondary = secondaryTool === id;
    const classNames = [CHIP_BUTTON_CLASS];
    if (isSecondary) {
      classNames.push('RogueStar__chip--goldGlow');
    }
    return (
      <Button
        key={id}
        className={classNames.join(' ')}
        icon={icon}
        tooltip={tooltip}
        selected={isPrimary}
        onMouseDown={(event) => {
          if (event?.button === 2) {
            event.preventDefault();
            onSecondarySelect(id);
            return;
          }
          onPrimarySelect(id);
        }}
        onContextMenu={(event) => {
          event.preventDefault();
        }}>
        {label}
      </Button>
    );
  };

  return (
    <Section title="Paint Tools">
      <Flex gap={2} wrap={false} align="stretch">
        <Flex.Item basis="260px" shrink={0}>
          <LabeledList>
            <LabeledList.Item label="Brush Type">
              <Box className={TOOLBAR_GROUP_CLASS}>
                {renderToolButton('brush', 'paint-brush', 'Brush')}
                {renderToolButton(
                  'mirror-brush',
                  'arrows-left-right',
                  'Mirror',
                  'Paint with a mirrored stroke across the canvas.'
                )}
                {renderToolButton('eraser', 'eraser', 'Eraser')}
                {renderToolButton('line', 'slash', 'Line')}
                {renderToolButton('fill', 'fill-drip', 'Fill')}
                {renderToolButton('eyedropper', 'eye-dropper', 'Eyedropper')}
              </Box>
            </LabeledList.Item>

            <LabeledList.Item label="Mode">
              <Box className={TOOLBAR_GROUP_CLASS}>
                <Button
                  className={CHIP_BUTTON_CLASS}
                  tooltip="Classic: blend brush and canvas colors."
                  selected={blendMode === 'analog'}
                  onClick={() => setBlendMode('analog')}>
                  Classic
                </Button>
                <Button
                  className={CHIP_BUTTON_CLASS}
                  tooltip="Lighten: adds brush color to lighten pixels."
                  selected={blendMode === 'add'}
                  onClick={() => setBlendMode('add')}>
                  Lighten
                </Button>
                <Button
                  className={CHIP_BUTTON_CLASS}
                  tooltip="Darken: multiplies colors to darken pixels."
                  selected={blendMode === 'multiply'}
                  onClick={() => setBlendMode('multiply')}>
                  Darken
                </Button>
              </Box>
            </LabeledList.Item>

            <LabeledList.Item label="Strength">
              <Tooltip content="Weight of the selected color relative to the canvas.">
                <NumberInput
                  className="RogueStar__numberInput"
                  minValue={1}
                  maxValue={100}
                  step={1}
                  unit="%"
                  width={5}
                  value={Math.round(analogStrength * 100)}
                  onChange={(e, value) => setAnalogStrength(value / 100)}
                />
              </Tooltip>
            </LabeledList.Item>

            <LabeledList.Item label="Revert">
              <Box className={TOOLBAR_GROUP_CLASS}>
                <Button
                  className={CHIP_BUTTON_CLASS}
                  tooltip="Ctrl+Z or Cmd+Z also works."
                  disabled={!canUndoDrafts}
                  onClick={() => handleUndo()}>
                  Undo
                </Button>
                <Button
                  className={CHIP_BUTTON_CLASS}
                  tooltip="Clear the entire canvas."
                  onClick={() => handleClear(true)}>
                  Clear
                </Button>
              </Box>
            </LabeledList.Item>

            <LabeledList.Item label="Thickness">
              <Box className={TOOLBAR_GROUP_CLASS}>
                {[1, 2, 3, 4, 5].map((value) => (
                  <Button
                    key={value}
                    className={CHIP_BUTTON_CLASS}
                    selected={size === value}
                    onClick={() => setSize(value)}>
                    {value}
                  </Button>
                ))}
              </Box>
            </LabeledList.Item>

            <LabeledList.Item label="Color">
              <Box className={TOOLBAR_GROUP_CLASS}>
                <Box
                  inline
                  className="RogueStar__colorSwatch"
                  style={{ background: brushColor }}
                />
              </Box>
            </LabeledList.Item>
          </LabeledList>
        </Flex.Item>

        <Flex.Item grow>
          <Box className="RogueStar__inlineColorPicker">
            <RogueStarColorPicker
              color={brushColor}
              currentColor={brushColor}
              customColors={customColorSlots}
              onCustomColorsChange={handleCustomColorUpdate}
              onChange={(hex) => handleColorPickerApply(hex)}
              onCommit={(hex) => handleColorPickerApply(hex)}
              showPreview={false}
            />
          </Box>
        </Flex.Item>
      </Flex>
    </Section>
  );
};
