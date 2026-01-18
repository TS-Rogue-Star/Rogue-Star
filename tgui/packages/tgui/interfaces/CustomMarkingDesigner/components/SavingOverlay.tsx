// ///////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Saving overlay for custom marking designer //
// ///////////////////////////////////////////////////////////////////////////////////////////

import { Box, Icon, ProgressBar } from '../../../components';
import type { SavingProgressState } from '../types';

export type SavingOverlayProps = {
  readonly title?: string;
  readonly subtitle?: string;
  readonly progress?: SavingProgressState | null;
};

export const SavingOverlay = ({
  title = 'Saving your changes…',
  subtitle = 'Please keep the client open. Window will close upon completion.',
  progress,
}: SavingOverlayProps) => {
  const hasProgress = !!progress;
  const rawProgressValue =
    hasProgress && typeof progress?.value === 'number' ? progress.value : null;
  const isDeterminate =
    hasProgress &&
    typeof rawProgressValue === 'number' &&
    isFinite(rawProgressValue);
  const progressValue = isDeterminate
    ? Math.max(0, Math.min(1, rawProgressValue as number))
    : 0;
  const progressLabel = progress?.label;

  return (
    <Box
      position="fixed"
      style={{
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        'z-index': 20,
        background:
          'linear-gradient(135deg, rgba(4, 2, 8, 0.95), rgba(18, 6, 32, 0.92))',
        display: 'flex',
        'align-items': 'center',
        'justify-content': 'center',
        padding: '3rem 1rem',
        'text-align': 'center',
        'pointer-events': 'all',
      }}>
      <Box
        style={{
          width: 'min(440px, 90%)',
          padding: '2.5rem 2rem',
          'border-radius': '20px',
          background: 'rgba(14, 7, 26, 0.92)',
          border: '1px solid rgba(157, 102, 243, 0.45)',
          'box-shadow':
            '0 25px 70px rgba(3, 1, 10, 0.85), 0 0 35px rgba(229, 188, 106, 0.15)',
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
            name="circle-notch"
            spin
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
        {hasProgress ? (
          <Box mt={0.5} width="100%" className="RogueStar__savingProgress">
            {isDeterminate ? (
              <ProgressBar
                className="RogueStar__savingProgressBar"
                value={progressValue}
                minValue={0}
                maxValue={1}>
                {progressLabel || 'Syncing strokes…'}
              </ProgressBar>
            ) : (
              progressLabel && (
                <Box color="label" mt={0.5}>
                  {progressLabel}
                </Box>
              )
            )}
          </Box>
        ) : null}
      </Box>
    </Box>
  );
};
