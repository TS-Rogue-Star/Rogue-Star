// /////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star August 2026: Shared live preview card for designer tabs //
// /////////////////////////////////////////////////////////////////////////////////////////

import { Box, Button, Flex, Section } from '../../../components';
import type { PreviewDirectionEntry } from '../../../utils/character-preview';
import { CHIP_BUTTON_CLASS, PREVIEW_PIXEL_SIZE } from '../constants';
import type { CanvasBackgroundOption } from '../types';
import { DirectionPreviewCanvas } from './DirectionPreviewCanvas';

type LivePreviewCardProps = Readonly<{
  preview: PreviewDirectionEntry[];
  canvasWidth: number;
  canvasHeight: number;
  previewFitToFrame: boolean;
  onTogglePreviewFit: () => void;
  previewBackgroundImage: string | null;
  backgroundFallbackColor: string;
  canvasBackgroundScale: number;
  previewBackgroundTileWidth?: number;
  previewBackgroundTileHeight?: number;
  iconScaleX?: number;
  iconScaleY?: number;
  showGearControls?: boolean;
  showEquipment: boolean;
  onToggleEquipment: () => void;
  showJobGear: boolean;
  onToggleJobGear: () => void;
  showLoadoutGear: boolean;
  onToggleLoadout: () => void;
  canvasBackgroundOptions: CanvasBackgroundOption[];
  resolvedCanvasBackground: CanvasBackgroundOption | null;
  cycleCanvasBackground: () => void;
}>;

export const LivePreviewCard = ({
  preview,
  canvasWidth,
  canvasHeight,
  previewFitToFrame,
  onTogglePreviewFit,
  previewBackgroundImage,
  backgroundFallbackColor,
  canvasBackgroundScale,
  previewBackgroundTileWidth,
  previewBackgroundTileHeight,
  iconScaleX,
  iconScaleY,
  showGearControls = true,
  showEquipment,
  onToggleEquipment,
  showJobGear,
  onToggleJobGear,
  showLoadoutGear,
  onToggleLoadout,
  canvasBackgroundOptions,
  resolvedCanvasBackground,
  cycleCanvasBackground,
}: LivePreviewCardProps) => (
  <Section
    fill
    noTopPadding
    className="RogueStar__previewCard RogueStar__previewCard--flush">
    <Flex align="center" wrap gap={0.5} mb={1} ml={0.5}>
      <Box
        color="label"
        fontWeight="bold"
        className="RogueStar__previewTitle"
        mr={0.5}>
        Live Preview
      </Box>
      <Button
        className={CHIP_BUTTON_CLASS}
        icon={previewFitToFrame ? 'compress-arrows-alt' : 'expand-arrows-alt'}
        selected={previewFitToFrame}
        tooltip="Shrink to show the full 64x64 grid"
        onClick={onTogglePreviewFit}
      />
      {showGearControls ? (
        <>
          <Button
            className={CHIP_BUTTON_CLASS}
            icon="shopping-bag"
            selected={showEquipment}
            aria-label="Toggle equipment visibility"
            tooltip="Show or hide underwear, socks, undershirt, and the selected bag."
            onClick={onToggleEquipment}
          />
          <Button
            className={CHIP_BUTTON_CLASS}
            icon="id-card"
            selected={showJobGear}
            aria-label="Toggle job gear visibility"
            tooltip="Show or hide job gear overlays."
            onClick={onToggleJobGear}
          />
          <Button
            className={CHIP_BUTTON_CLASS}
            icon="toolbox"
            selected={showLoadoutGear}
            aria-label="Toggle loadout visibility"
            tooltip="Show or hide loadout overlays."
            onClick={onToggleLoadout}
          />
        </>
      ) : null}
      {canvasBackgroundOptions.length ? (
        <Button
          className={CHIP_BUTTON_CLASS}
          icon="image"
          tooltip={`Change preview background (current: ${resolvedCanvasBackground?.label || 'Default'})`}
          onClick={cycleCanvasBackground}>
          {resolvedCanvasBackground?.label || 'Background'}
        </Button>
      ) : null}
    </Flex>
    <Flex wrap gap={1}>
      {preview.map((entry) => (
        <Flex.Item
          key={entry.dir}
          basis="45%"
          className="RogueStar__previewItem">
          <DirectionPreviewCanvas
            layers={entry.layers}
            bodyAlpha={entry.bodyAlpha}
            pixelSize={Math.max(1, PREVIEW_PIXEL_SIZE)}
            width={canvasWidth}
            height={canvasHeight}
            fitToFrame={previewFitToFrame}
            backgroundImage={previewBackgroundImage}
            backgroundColor={backgroundFallbackColor}
            backgroundScale={canvasBackgroundScale}
            backgroundTileWidth={previewBackgroundTileWidth}
            backgroundTileHeight={previewBackgroundTileHeight}
            iconScaleX={iconScaleX}
            iconScaleY={iconScaleY}
          />
        </Flex.Item>
      ))}
    </Flex>
  </Section>
);

export type { LivePreviewCardProps };
