// ///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Paint tools and brush controls for custom marking designer //
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
  tool: string | null;
  setTool: (tool: string) => void;
  blendMode: string;
  setBlendMode: (mode: string) => void;
  analogStrength: number;
  setAnalogStrength: (value: number) => void;
  canUndoDrafts: boolean;
  handleUndo: () => void;
  handleClear: (confirm: boolean) => void;
  size: number;
  setSize: (size: number) => void;
  brushColor: string;
  customColorSlots: CustomColorSlotsState;
  handleCustomColorUpdate: (colors: (string | null)[]) => void;
  handleColorPickerApply: (hex: string) => void;
};

export const PaintToolsSection = ({
  tool,
  setTool,
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
}: PaintToolsSectionProps) => (
  <Section title="Paint Tools">
    <Flex gap={2} wrap={false} align="stretch">
      <Flex.Item basis="260px" shrink={0}>
        <LabeledList>
          <LabeledList.Item label="Brush Type">
            <Box className={TOOLBAR_GROUP_CLASS}>
              <Button
                className={CHIP_BUTTON_CLASS}
                icon="paint-brush"
                selected={tool === 'brush'}
                onClick={() => setTool('brush')}>
                Brush
              </Button>
              <Button
                className={CHIP_BUTTON_CLASS}
                icon="eraser"
                selected={tool === 'eraser'}
                onClick={() => setTool('eraser')}>
                Eraser
              </Button>
              <Button
                className={CHIP_BUTTON_CLASS}
                icon="slash"
                selected={tool === 'line'}
                onClick={() => setTool('line')}>
                Line
              </Button>
              <Button
                className={CHIP_BUTTON_CLASS}
                icon="fill-drip"
                selected={tool === 'fill'}
                onClick={() => setTool('fill')}>
                Fill
              </Button>
              <Button
                className={CHIP_BUTTON_CLASS}
                icon="eye-dropper"
                selected={tool === 'eyedropper'}
                onClick={() => setTool('eyedropper')}>
                Eyedropper
              </Button>
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
