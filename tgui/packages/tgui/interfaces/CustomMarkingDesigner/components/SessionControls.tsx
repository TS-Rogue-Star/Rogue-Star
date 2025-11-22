// /////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Session controls for custom marking designer //
// /////////////////////////////////////////////////////////////////////////////////////////////

import { Button, Flex, Section } from '../../../components';
import { CHIP_BUTTON_CLASS } from '../constants';

type SessionControlsProps = {
  pendingSave: boolean;
  pendingClose: boolean;
  uiLocked: boolean;
  handleSaveProgress: () => void;
  handleSafeClose: () => void;
  handleDiscardAndClose: () => void;
  handleImport: (type: 'png' | 'dmi') => Promise<void>;
  handleExport: (type: 'png' | 'dmi') => Promise<void>;
};

export const SessionControls = ({
  pendingSave,
  pendingClose,
  uiLocked,
  handleSaveProgress,
  handleSafeClose,
  handleDiscardAndClose,
  handleImport,
  handleExport,
}: SessionControlsProps) => {
  const showImportButtons = false;

  return (
    <Section title="Session">
      <Flex justify="space-between" wrap className="RogueStar__sessionButtons">
        <Flex.Item>
          <Button
            className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--positive`}
            icon={pendingSave ? 'spinner-third' : 'save'}
            iconSpin={pendingSave}
            disabled={pendingClose || pendingSave || uiLocked}
            tooltip="Save all pending changes without closing the designer."
            onClick={handleSaveProgress}>
            Save
          </Button>
        </Flex.Item>
        <Flex.Item>
          <Button
            className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--positive`}
            icon={pendingClose ? 'spinner-third' : 'floppy-disk'}
            iconSpin={pendingClose}
            disabled={pendingClose || pendingSave || uiLocked}
            tooltip="Save all pending changes and close the designer."
            onClick={handleSafeClose}>
            Save &amp; Close
          </Button>
        </Flex.Item>
        <Flex.Item>
          <Button.Confirm
            className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--negative`}
            icon="door-open"
            confirmIcon="triangle-exclamation"
            content="Close Without Saving"
            confirmContent="Confirm Close"
            color="transparent"
            confirmColor="bad"
            disabled={pendingClose || pendingSave || uiLocked}
            tooltip="Discard all changes, clear local storage, and close the designer."
            onClick={handleDiscardAndClose}
          />
        </Flex.Item>
        {showImportButtons && (
          <>
            <Flex.Item>
              <Button
                className={CHIP_BUTTON_CLASS}
                icon="folder-open"
                disabled={pendingClose || pendingSave || uiLocked}
                onClick={() => handleImport('png')}>
                Import PNG
              </Button>
            </Flex.Item>
            <Flex.Item>
              <Button
                className={CHIP_BUTTON_CLASS}
                icon="folder-open"
                disabled={pendingClose || pendingSave || uiLocked}
                onClick={() => handleImport('dmi')}>
                Import DMI
              </Button>
            </Flex.Item>
          </>
        )}
        <Flex.Item>
          <Button
            className={CHIP_BUTTON_CLASS}
            icon="file-image"
            disabled={pendingClose || pendingSave || uiLocked}
            onClick={() => handleExport('png')}>
            Export PNG
          </Button>
        </Flex.Item>
        <Flex.Item>
          <Button
            className={CHIP_BUTTON_CLASS}
            icon="file"
            disabled={pendingClose || pendingSave || uiLocked}
            onClick={() => handleExport('dmi')}>
            Export DMI
          </Button>
        </Flex.Item>
      </Flex>
    </Section>
  );
};
