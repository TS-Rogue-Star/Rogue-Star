// /////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Canvas toolbar component for custom marking designer //
// /////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star August 2026: Character Designer - Species and Prosthetics ////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////////

import { Button, Flex } from '../../../components';
import { CHIP_BUTTON_CLASS, TOOLBAR_GROUP_CLASS } from '../constants';
import type { CanvasBackgroundOption } from '../types';

type CanvasBackgroundToggleProps = Readonly<{
  options: CanvasBackgroundOption[];
  resolvedCanvasBackground: CanvasBackgroundOption | null;
  onCycle: () => void;
}>;

const CanvasBackgroundToggle = ({
  options,
  resolvedCanvasBackground,
  onCycle,
}: CanvasBackgroundToggleProps) => {
  if (!options.length) {
    return null;
  }
  return (
    <Button
      className={CHIP_BUTTON_CLASS}
      icon="image"
      tooltip={`Change canvas background (current: ${resolvedCanvasBackground?.label || 'Default'})`}
      onClick={onCycle}>
      {resolvedCanvasBackground?.label || 'Background'}
    </Button>
  );
};

export type CanvasToolbarProps = Readonly<{
  canvasFitToFrame: boolean;
  toggleCanvasFit: () => void;
  canvasBackgroundOptions: CanvasBackgroundOption[];
  resolvedCanvasBackground: CanvasBackgroundOption | null;
  cycleCanvasBackground: () => void;
  showGearControls?: boolean;
  showEquipment: boolean;
  onToggleEquipment: () => void;
  showJobGear: boolean;
  onToggleJobGear: () => void;
  showLoadoutGear: boolean;
  onToggleLoadout: () => void;
}>;

export const CanvasToolbar = ({
  canvasFitToFrame,
  toggleCanvasFit,
  canvasBackgroundOptions,
  resolvedCanvasBackground,
  cycleCanvasBackground,
  showGearControls = true,
  showEquipment,
  onToggleEquipment,
  showJobGear,
  onToggleJobGear,
  showLoadoutGear,
  onToggleLoadout,
}: CanvasToolbarProps) => (
  <Flex
    align="center"
    justify="flex-start"
    gap={0.5}
    className={TOOLBAR_GROUP_CLASS}
    mb={1}>
    <Button
      className={CHIP_BUTTON_CLASS}
      icon={canvasFitToFrame ? 'compress-arrows-alt' : 'expand-arrows-alt'}
      selected={canvasFitToFrame}
      tooltip="Shrink to show the full 64x64 grid"
      onClick={() => toggleCanvasFit()}>
      Full grid
    </Button>
    <CanvasBackgroundToggle
      options={canvasBackgroundOptions}
      resolvedCanvasBackground={resolvedCanvasBackground}
      onCycle={cycleCanvasBackground}
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
  </Flex>
);
