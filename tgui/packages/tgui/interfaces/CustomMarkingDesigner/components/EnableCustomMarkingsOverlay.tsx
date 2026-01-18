// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Overlay prompt for enabling custom markings from within the designer UI //
// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import { Box, Button, Flex, Icon } from '../../../components';
import { CHIP_BUTTON_CLASS } from '../constants';

export type EnableCustomMarkingsOverlayProps = {
  readonly title?: string;
  readonly message: string;
  readonly confirmLabel?: string;
  readonly cancelLabel?: string;
  readonly onConfirm: () => void;
  readonly onCancel: () => void;
  readonly busy?: boolean;
};

export const EnableCustomMarkingsOverlay = ({
  title = 'Enable Custom Markings?',
  message,
  confirmLabel = 'Agree',
  cancelLabel = 'Cancel',
  onConfirm,
  onCancel,
  busy = false,
}: EnableCustomMarkingsOverlayProps) => (
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
        width: 'min(720px, 92%)',
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
          name="paint-brush"
          size={4}
          style={{ color: 'rgba(245, 215, 196, 0.9)' }}
        />
      </Box>
      <Box fontSize={1.35} bold>
        {title}
      </Box>
      <Box color="label" lineHeight={1.6} style={{ 'white-space': 'pre-wrap' }}>
        {message}
      </Box>
      <Flex gap={0.75} wrap justify="center">
        <Flex.Item>
          <Button
            icon="arrow-left"
            className={CHIP_BUTTON_CLASS}
            disabled={busy}
            onClick={onCancel}>
            {cancelLabel}
          </Button>
        </Flex.Item>
        <Flex.Item>
          <Button
            icon="check"
            className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--positive`}
            disabled={busy}
            onClick={onConfirm}>
            {confirmLabel}
          </Button>
        </Flex.Item>
      </Flex>
    </Box>
  </Box>
);
