// ///////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Left column layout for custom marking designer //
// ///////////////////////////////////////////////////////////////////////////////////////////////

import { Box, Flex } from '../../../components';
import type { CustomMarkingDesignerData } from '../types';
import { MarkingInfoSection } from './MarkingInfoSection';
import { PaintToolsSection } from './PaintToolsSection';
import { SessionControls } from './SessionControls';

export type DesignerLeftColumnProps = Readonly<{
  data: CustomMarkingDesignerData;
  currentDirectionKey: number;
  setDirection: (dir: number) => void;
  activePartKey: string;
  activePartLabel: string;
  resolvedPartReplacementMap: Record<string, any>;
  partPaintPresenceMap: Record<string, any>;
  resolvedPartCanvasSizeMap: Record<string, any>;
  resolvePartLayeringState: any;
  togglePartLayerPriority: (partKey: string) => void;
  togglePartReplacement: (partKey: string) => void;
  setBodyPart: (partKey: string) => void;
  uiLocked: boolean;
  getReferenceOpacityForPart: (partId: string) => number;
  setReferenceOpacityForPart: (partId: string, value: number) => void;
  pendingSave: boolean;
  pendingClose: boolean;
  handleSaveProgress: () => void;
  handleSafeClose: () => void;
  handleDiscardAndClose: () => void;
  handleImport: (type: 'png' | 'dmi') => Promise<void>;
  handleExport: (type: 'png' | 'dmi') => Promise<void>;
  primaryTool: string | null;
  secondaryTool: string | null;
  onPrimarySelect: (tool: string) => void;
  onSecondarySelect: (tool: string) => void;
  blendMode: string;
  setBlendMode: (mode: string) => void;
  analogStrength: number;
  setAnalogStrength: (value: number) => void;
  canUndoDrafts: boolean;
  handleUndo: () => void;
  handleClear: (confirm: boolean) => void;
  size: number;
  setSize: (value: number) => void;
  brushColor: string;
  customColorSlots: (string | null)[];
  handleCustomColorUpdate: (colors: (string | null)[]) => void;
  handleColorPickerApply: (hex: string) => void;
}>;

export const DesignerLeftColumn = ({
  data,
  currentDirectionKey,
  setDirection,
  activePartKey,
  activePartLabel,
  resolvedPartReplacementMap,
  partPaintPresenceMap,
  resolvedPartCanvasSizeMap,
  resolvePartLayeringState,
  togglePartLayerPriority,
  togglePartReplacement,
  setBodyPart,
  uiLocked,
  getReferenceOpacityForPart,
  setReferenceOpacityForPart,
  pendingSave,
  pendingClose,
  handleSaveProgress,
  handleSafeClose,
  handleDiscardAndClose,
  handleImport,
  handleExport,
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
}: DesignerLeftColumnProps) => (
  <Flex.Item basis="600px" shrink={0}>
    <Flex
      direction="column"
      gap={2}
      height="100%"
      className="RogueStar__column"
      justify="space-between">
      <Flex.Item>
        <SessionControls
          pendingSave={pendingSave}
          pendingClose={pendingClose}
          uiLocked={uiLocked}
          handleSaveProgress={handleSaveProgress}
          handleSafeClose={handleSafeClose}
          handleDiscardAndClose={handleDiscardAndClose}
          handleImport={handleImport}
          handleExport={handleExport}
        />
      </Flex.Item>

      <Flex.Item>
        <MarkingInfoSection
          bodyParts={data.body_parts}
          directions={data.directions}
          currentDirectionKey={currentDirectionKey}
          setDirection={setDirection}
          activePartKey={activePartKey}
          activePartLabel={activePartLabel}
          resolvedPartReplacementMap={resolvedPartReplacementMap}
          partPaintPresenceMap={partPaintPresenceMap}
          resolvedPartCanvasSizeMap={resolvedPartCanvasSizeMap}
          resolvePartLayeringState={resolvePartLayeringState}
          togglePartLayerPriority={togglePartLayerPriority}
          togglePartReplacement={togglePartReplacement}
          setBodyPart={setBodyPart}
          uiLocked={uiLocked}
          getReferenceOpacityForPart={getReferenceOpacityForPart}
          setReferenceOpacityForPart={setReferenceOpacityForPart}
        />
      </Flex.Item>

      <Flex.Item>
        <Box className="RogueStar__leftFill">
          <PaintToolsSection
            primaryTool={primaryTool}
            secondaryTool={secondaryTool}
            onPrimarySelect={onPrimarySelect}
            onSecondarySelect={onSecondarySelect}
            blendMode={blendMode}
            setBlendMode={setBlendMode}
            analogStrength={analogStrength}
            setAnalogStrength={setAnalogStrength}
            canUndoDrafts={canUndoDrafts}
            handleUndo={handleUndo}
            handleClear={handleClear}
            size={size}
            setSize={setSize}
            brushColor={brushColor}
            customColorSlots={customColorSlots}
            handleCustomColorUpdate={handleCustomColorUpdate}
            handleColorPickerApply={handleColorPickerApply}
          />
        </Box>
      </Flex.Item>
    </Flex>
  </Flex.Item>
);
