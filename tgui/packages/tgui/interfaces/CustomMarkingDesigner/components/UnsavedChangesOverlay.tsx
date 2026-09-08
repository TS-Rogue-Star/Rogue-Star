// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Overlay prompt for handling unsaved changes when switching designer tabs //
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import { Box, Button, Flex, Icon } from '../../../components';
import { CHIP_BUTTON_CLASS } from '../constants';

export type UnsavedChangesOverlayProps = {
  readonly title?: string;
  readonly subtitle?: string;
  readonly saveLabel?: string;
  readonly discardLabel?: string;
  readonly onSave: () => void;
  readonly onDiscard: () => void;
  readonly onCancel?: () => void;
  readonly busy?: boolean;
};

export const UnsavedChangesOverlay = ({
  title = 'Unsaved changes detected',
  subtitle = 'You have local changes that are not saved yet.',
  saveLabel = 'Save and continue',
  discardLabel = 'Discard changes',
  onSave,
  onDiscard,
  onCancel,
  busy = false,
}: UnsavedChangesOverlayProps) => (
  <Box
    position="fixed"
    style={{
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      'z-index': 25,
      background:
        'linear-gradient(135deg, rgba(4, 2, 8, 0.94), rgba(18, 6, 32, 0.92))',
      display: 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      padding: '3rem 1rem',
      'text-align': 'center',
      'pointer-events': 'all',
    }}>
    <Box
      style={{
        width: 'min(520px, 92%)',
        padding: '2.5rem 2rem',
        'border-radius': '20px',
        background: 'rgba(14, 7, 26, 0.95)',
        border: '1px solid rgba(157, 102, 243, 0.5)',
        'box-shadow':
          '0 25px 70px rgba(3, 1, 10, 0.85), 0 0 35px rgba(229, 188, 106, 0.18)',
        'backdrop-filter': 'blur(18px)',
        display: 'flex',
        'flex-direction': 'column',
        'align-items': 'center',
        gap: '1rem',
      }}>
      <Box
        style={{
          width: '96px',
          height: '96px',
          'border-radius': '999px',
          display: 'flex',
          'align-items': 'center',
          'justify-content': 'center',
          border: '3px solid rgba(255, 255, 255, 0.08)',
          'border-top-color': 'rgba(244, 201, 111, 0.65)',
          'border-left-color': 'rgba(147, 94, 255, 0.75)',
          'box-shadow':
            'inset 0 0 24px rgba(139, 78, 255, 0.45), 0 0 28px rgba(229, 188, 106, 0.25)',
        }}>
        <Icon
          name="exclamation-triangle"
          size={4}
          style={{ color: 'rgba(245, 215, 196, 0.9)' }}
        />
      </Box>
      <Box fontSize={1.35} bold>
        {title}
      </Box>
      <Box color="label" lineHeight={1.6}>
        {subtitle}
      </Box>
      <Flex gap={0.75} wrap justify="center">
        <Flex.Item>
          <Button
            icon="save"
            className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--positive`}
            disabled={busy}
            onClick={onSave}>
            {saveLabel}
          </Button>
        </Flex.Item>
        <Flex.Item>
          <Button
            icon="trash"
            className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--negative`}
            color="transparent"
            disabled={busy}
            onClick={onDiscard}>
            {discardLabel}
          </Button>
        </Flex.Item>
        {onCancel ? (
          <Flex.Item>
            <Button
              icon="arrow-left"
              className={CHIP_BUTTON_CLASS}
              disabled={busy}
              onClick={onCancel}>
              Keep Editing
            </Button>
          </Flex.Item>
        ) : null}
      </Flex>
    </Box>
  </Box>
);
